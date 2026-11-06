# Domain profile template (copy to `<repo>/.explain-doc/domain.md` or `<repo>/docs/agents/explain-doc-domain.md`, or point `$EXPLAIN_DOC_DOMAIN` at it)

Keep secrets out of this file; point to where they live.

## Confluence
- Site (`ATL_SITE`): https://<org>.atlassian.net
- Account email (`ATL_EMAIL`): <how to get it, e.g. `acli jira auth status`>
- Token (`ATL_TOKEN_FILE`): <path to the token file, never the token>
- Default space key: <KEY> (personal or team)
- Title pattern: `[<TICKET>] <subject> (<YYYY-MM-DD>)`

## Git refs
- "Before" ref (production): <e.g. origin/main, origin/release>
- "After" ref: <ticket branch pattern, e.g. origin/fix/<TICKET>>
- Repos in scope: <list>

## Language and labels
- Reader language: <e.g. Korean>
- Capture legend labels: red = <…>, green = <…>, blue = <…>
- Capture tags: before = "<…>", after = "<…>"

## Glossary pointers
- Where the domain glossary lives: <path or URL>
- Terms that readers confuse, with the name to use: <term> → <use this>

## Evidence rules
- Which environments may be queried, how to confirm the environment, what must never be touched.
- Where tickets live and how to link them.
