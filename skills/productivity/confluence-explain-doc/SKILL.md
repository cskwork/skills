---
name: confluence-explain-doc
description: "Write and publish a Confluence page (or Jira/report text) that explains a bug's cause, logic, and fix so a first-time reader understands it. Code-capture first: real source lines with red/green/blue line highlights and line-numbered captions, one section per problem, how problems connect, git blame plus the original reason for each cause, details folded. Use for \"write this up in Confluence\", \"explain the root cause\", \"I don't understand this explanation\", \"progressive disclosure\", 컨플 정리, 설명 문서, 원인 설명."
---

# confluence-explain-doc

Goal: a reader who opens the page once can explain the problem to someone else. **Real code carries the explanation; prose stays minimal.**

## 0. Load the domain profile first

Company/project specifics (site, space, branch names, glossary, label language, token location) live outside this skill so the skill stays portable. Read the first one that exists:

1. the file in `$EXPLAIN_DOC_DOMAIN`
2. `<repo root>/.explain-doc/domain.md`
3. `<repo root>/docs/agents/explain-doc-domain.md`

No profile: ask for the Confluence site, space key, and the "before" ref (usually the production branch). Template: `references/domain-profile.md`.

## 1. Page structure (fixed order)

No format headings ("Summary", "Overview", "TL;DR", "Click to expand"). Headings name the content.

1. **Opening paragraph (no heading, 2-3 sentences):** how many problems, the shared object they touch (one table, one value), and how they differ (e.g. one writes the wrong value, the other reads it and sends it).
2. **One section per problem**, numbered in the priority the user sets (`<h2>Problem N. <keyword>: <symptom in one line></h2>`). When you renumber, fix every "Problem N" reference too.
   - **Four lines** (`<ul>`, `<strong>keyword</strong> — one plain sentence`): symptom → cause → evidence it really happened *or* original background (with blame) → fix (commits). Define each term the first time it appears; put job/batch IDs in parentheses, not as the subject.
   - **One example line:** one person or record, with real values.
   - **Code captures:** one `Flow · <function>` capture, then each cause as `Cause · …` with *before* and *after* captures. Wrap cause captures in a light-red panel. The caption names line numbers and example values ("line 179 reads B from the stored table → line 135 writes B into the result").
   - Raw logs and API responses go in a titled `code` macro, not an image.
3. **How the problems connect** (only if they do, one paragraph): the path from one to the other, what remains if only one is fixed (with line numbers and an example), and which fix cuts the link.
4. **Release and status** (two lines): scope (which repos/jobs) and status, including pending approvals and follow-up actions.
5. **Details** (at most 4 folds, no nested folds): pictures · glossary · cause/background/verification (blame table, real-occurrence data, test evidence, review) · open items and pending decisions.

## 2. Code captures

Colors mean the same thing everywhere, and every capture header shows the legend:
**red** = line that causes the problem · **green** = line that fixes it · **blue** = normal flow worth following.

1. Pull the exact files: *before* from the production ref, *after* from the fix branch: `git show "<ref>:<path>" > src/<name>`. Quote `"<ref>:<path>"`; in zsh `$VAR:l` lowercases.
2. Write a spec (format: `examples/code_capture.example.json`): ranges keep real line numbers, `hl` colors lines, `notes` add a short label on the line. Set `legend` labels in the reader's language (the domain profile can set them).
3. Render and screenshot:
   ```bash
   S=<skill dir>/scripts
   python3 $S/code_capture.py --spec caps.json --src-dir src --out-dir out
   bash $S/screenshot.sh out        # agent-browser; any headless browser works
   ```
4. Open a few PNGs yourself: no clipped notes, no red error boxes, right lines highlighted.
5. Insert with `<ac:image ac:width="1200">` and set the page to full width (POST content properties `content-appearance-published` and `content-appearance-draft` = `full-width`).

## 3. Cause rows: blame plus original background

For every cause give who/when (commit, date, author, subject) **and why it was built that way**, with a verdict: *intended design* · *spec interpreted differently* · *mistake* · *no source found*. Never write "unknown" before running:

```bash
git log <prod-ref> --reverse --format='%h %ad %an %s' --date=short -S'<code fragment>' -- <path> | head -2
git blame -L <a>,<b> <prod-ref> -- <file>
```

Then search the same 1-2 months for the reason: full commit diff and comments, wiki pages (CQL `text ~ "<keyword>"`, read attachments' text), tickets. Label inference as inference.

## 4. Noise removal (before every publish)

- Say each thing once: one picture per idea, one "how they connect" paragraph, status only in the status section.
- Nothing above the first problem section except the opening paragraph.
- No edit history ("correction:", "previous version said"), no navigation filler ("see below").
- Code identifiers appear in captions, captures, and blame cells, not as sentence subjects.
- Red cells in tables: `<td data-highlight-colour="#ffebe6">`; Confluence strips `style="background-color"`.

## 5. Publish and check

```bash
S=<skill dir>/scripts   # env from the domain profile: ATL_SITE, ATL_EMAIL, ATL_TOKEN or ATL_TOKEN_FILE
python3 $S/publish.py create --space-key <KEY> --title "<title>" --body body.xml --attach a.png
python3 $S/publish.py update --page-id <ID> --body body.xml --attach a.png   # same-name attachments replaced
python3 $S/publish.py check  --page-id <ID>                                   # images, folds, red cells
xmllint --noout <(echo "<root xmlns:ac='a' xmlns:ri='r'>$(cat body.xml)</root>")
```

After publishing, open the page in a real browser and look at it: the opening, each problem section, and one cause capture.

## Writing

- Plain words in the reader's language; one fact per sentence; every sentence has a subject (which job, which person, which system).
- When explaining a cause to a first-time reader: one-line concept → example → process. If the reader still struggles twice, offer an infographic or a short motion explainer that shows the same sections.
- Keep exact numbers, conditions, and "not verified" notes; separate checked facts from inference.
