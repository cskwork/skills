#!/usr/bin/env python3
import json
import sys


role = sys.argv[1]
events = [json.loads(line) for line in sys.stdin if line.strip()]
init = next(event for event in events if event.get("subtype") == "init")
expected = {"Glob", "Grep", "Read"}
if role == "review":
    expected.add("Bash")
builtins = {tool for tool in init["tools"] if not tool.startswith("mcp__")}
assert builtins == expected, (builtins, expected)
assert not ({"Edit", "Write"} & builtins)

tool_ids = set()
for event in events:
    for content in event.get("message", {}).get("content", []):
        if content.get("type") == "tool_use" and content.get("name", "").endswith("__list_projects"):
            tool_ids.add(content["id"])
assert tool_ids, "list_projects was not called"

results = []
for event in events:
    for content in event.get("message", {}).get("content", []):
        if content.get("type") == "tool_result" and content.get("tool_use_id") in tool_ids:
            results.append(content)
assert results and all(not result.get("is_error") for result in results)
final = next(event for event in reversed(events) if event.get("type") == "result")
assert not final.get("is_error") and final.get("result") == "MCP_OK"
assert final.get("permission_denials") == []
