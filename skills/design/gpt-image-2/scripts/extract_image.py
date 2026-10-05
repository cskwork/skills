#!/usr/bin/env python3
"""Extract a generated image from a Codex CLI session rollout JSONL."""

from __future__ import annotations

import base64
import json
import pathlib
import re
import sys

IMAGE_MAGIC_PREFIXES: dict[str, str] = {
    "iVBORw0KGgo": "png",
    "/9j/": "jpg",
    "UklGR": "webp",
}

MIN_BLOB_LENGTH = 200
BASE64_BLOB_PATTERN = re.compile(r'"([A-Za-z0-9+/=]{' + str(MIN_BLOB_LENGTH) + r',})"')


def find_best_image_blob(session_paths: list[pathlib.Path]) -> tuple[str, str] | None:
    """Return the largest (base64, ext) image payload found across given files."""
    best: tuple[str, str, int] | None = None
    for session_path in session_paths:
        try:
            text = session_path.read_text(errors="replace")
        except OSError:
            continue
        for line in text.splitlines():
            try:
                obj = json.loads(line)
            except ValueError:
                continue
            flat = json.dumps(obj)
            for match in BASE64_BLOB_PATTERN.finditer(flat):
                blob = match.group(1)
                for magic, ext in IMAGE_MAGIC_PREFIXES.items():
                    if blob.startswith(magic):
                        if best is None or len(blob) > best[2]:
                            best = (blob, ext, len(blob))
                        break
    if best is None:
        return None
    return best[0], best[1]


GENERATED_IMAGES_ROOT = pathlib.Path.home() / ".codex" / "generated_images"
SESSION_ID_PATTERN = re.compile(r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.jsonl$")
SAVED_IMAGE_SUFFIXES: frozenset[str] = frozenset({".png", ".jpg", ".jpeg", ".webp"})


def find_saved_image_file(session_paths: list[pathlib.Path]) -> pathlib.Path | None:
    """Return the largest image Codex saved for these sessions, if any.

    Newer Codex CLIs also write each generated image to
    ~/.codex/generated_images/<session-id>/. This fallback keeps working if a
    future CLI stops embedding the base64 payload in the rollout. Only the
    directories of the sessions this run created are read.
    """
    best: pathlib.Path | None = None
    for session_path in session_paths:
        match = SESSION_ID_PATTERN.search(session_path.name)
        if not match:
            continue
        session_dir = GENERATED_IMAGES_ROOT / match.group(1)
        if not session_dir.is_dir():
            continue
        for candidate in session_dir.rglob("*"):
            if candidate.is_file() and candidate.suffix.lower() in SAVED_IMAGE_SUFFIXES:
                if best is None or candidate.stat().st_size > best.stat().st_size:
                    best = candidate
    return best


ALLOWED_OUTPUT_EXTENSIONS: frozenset[str] = frozenset({".png", ".jpg", ".jpeg", ".webp"})

FORBIDDEN_OUTPUT_PREFIXES: tuple[str, ...] = (
    "/bin", "/boot", "/dev", "/etc", "/lib", "/proc",
    "/sbin", "/sys", "/usr", "/System", "/Library",
    "/var/root", "/var/log", "/var/db",
)


def validate_output_path(raw_out: str) -> pathlib.Path:
    """Canonicalise the output path; reject non-image extensions and system dirs."""
    candidate = pathlib.Path(raw_out)
    ext = candidate.suffix.lower()
    if ext not in ALLOWED_OUTPUT_EXTENSIONS:
        raise ValueError(
            f"output path must end in one of {sorted(ALLOWED_OUTPUT_EXTENSIONS)}; got {ext!r}"
        )

    resolved = candidate.expanduser().resolve()
    resolved_str = str(resolved)
    alt_str = (
        resolved_str[len("/private"):] if resolved_str.startswith("/private/") else None
    )

    def _is_under_forbidden(path_str: str) -> bool:
        return any(
            path_str == f or path_str.startswith(f + "/")
            for f in FORBIDDEN_OUTPUT_PREFIXES
        )

    if _is_under_forbidden(resolved_str) or (alt_str and _is_under_forbidden(alt_str)):
        raise ValueError(f"refusing to write under a system directory: {resolved}")

    return resolved


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(
            "usage: extract_image.py <out_path> <sessions_list_file>",
            file=sys.stderr,
        )
        return 2

    try:
        out_path = validate_output_path(argv[1])
    except ValueError as err:
        print(f"invalid output path: {err}", file=sys.stderr)
        return 2

    sessions_list_path = pathlib.Path(argv[2])
    session_paths = [
        pathlib.Path(line)
        for line in sessions_list_path.read_text().splitlines()
        if line.strip()
    ]

    result = find_best_image_blob(session_paths)
    if result is not None:
        image_bytes = base64.b64decode(result[0])
    else:
        saved = find_saved_image_file(session_paths)
        if saved is None:
            print("IMAGE_NOT_FOUND_IN_SESSION", file=sys.stderr)
            return 1
        image_bytes = saved.read_bytes()

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(image_bytes)
    print(out_path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
