#!/usr/bin/env python3
"""Build ko/index.html (Korean page) from index.html by exact replacements.

Run after editing index.html: python3 scripts/build_ko.py. It exits with MISS when an English string
it translates has changed; update the matching pair here, then rerun."""
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
s = (root / "index.html").read_text(encoding="utf-8")

def rep(old, new, count=1):
    global s
    n = s.count(old)
    if (count == "all" and n == 0) or (count != "all" and n != count):
        sys.exit(f"MISS ({n}x, expected {count}): {old[:90]}")
    s = s.replace(old, new)

# ---- head, assets, fonts, language links
rep('<html lang="en">', '<html lang="ko">')
rep('<title>cskwork/skills: the skills, system prompt, and toolkit I use every day</title>',
    '<title>cskwork/skills: 매일 쓰는 스킬, 시스템 프롬프트, 도구 모음</title>')
rep('content="31 agent skills, one system prompt (AGENTS.md), and 12 CLIs I run every day with Claude Code and Codex. Install with npx skills@latest add cskwork/skills."',
    'content="Claude Code와 Codex로 매일 쓰는 에이전트 스킬, 시스템 프롬프트(AGENTS.md) 하나, CLI 12개. npx skills@latest add cskwork/skills 로 설치합니다."')
rep('content="31 agent skills, one system prompt, and 12 CLIs. Every skill credited to its author and upstream commit."',
    'content="에이전트 스킬, 시스템 프롬프트 하나, CLI 12개. 스킬마다 작성자와 원본 커밋을 밝힙니다."')
rep('<meta property="og:url" content="https://cskwork.github.io/skills/">',
    '<meta property="og:url" content="https://cskwork.github.io/skills/ko/">\n'
    '<link rel="alternate" hreflang="en" href="https://cskwork.github.io/skills/">\n'
    '<link rel="alternate" hreflang="ko" href="https://cskwork.github.io/skills/ko/">')
rep('href="assets/fonts/archivo-latin.woff2"', 'href="../assets/fonts/archivo-latin.woff2"')
rep('url("assets/fonts/archivo-latin.woff2")', 'url("../assets/fonts/archivo-latin.woff2")')
rep('--sans: "Archivo", "Helvetica Neue", Arial, sans-serif;',
    '--sans: "Archivo", "Pretendard", "Apple SD Gothic Neo", "Noto Sans KR", "Malgun Gothic", "Helvetica Neue", Arial, sans-serif;')
rep('code, .mono {', 'body { word-break: keep-all; overflow-wrap: break-word; }\ncode, .mono {')
# Hangul needs more leading than the Latin display settings; appended so it wins the cascade.
rep('</style>', '.pitch .lede, .head h2, .liner blockquote { line-height: 1.18; letter-spacing: 0; }\n.liner blockquote { max-width: 18em; }\n</style>')
rep('<a href="./" aria-label="cskwork/skills home">', '<a href="./" aria-label="cskwork/skills 홈">')
rep('<a class="lang" href="ko/" lang="ko" hreflang="ko">한국어</a>',
    '<a class="lang" href="../" lang="en" hreflang="en">English</a>')

# ---- repeated labels
rep('<span>Copy</span>', '<span>복사</span>', "all")
s, n = re.subn(r'aria-label="Copy install command for ([^"]+)"', r'aria-label="\1 설치 명령 복사"', s)
assert n > 30, n
rep('aria-label="Copy ego-browser install command"', 'aria-label="ego-browser 설치 명령 복사"')
rep('aria-label="Copy hindsight install command"', 'aria-label="hindsight 설치 명령 복사"')
rep('aria-label="Copy install command"', 'aria-label="설치 명령 복사"')
rep('aria-label="Copy system prompt install command"', 'aria-label="시스템 프롬프트 설치 명령 복사"')
rep('aria-label="Sections"', 'aria-label="섹션"')
rep('>Read SKILL.md</a>', '>SKILL.md 읽기</a>', "all")
rep('<span>Matrix</span>', '<span>출처</span>', "all")
rep('<i>this repo</i>', '<i>이 저장소</i>', "all")
rep('>Landing page</a>', '>소개 페이지</a>')
rep(' tracks</small>', '곡</small>', "all")

# ---- header, hero
rep('<a class="skip" href="#tracklist">Skip to the tracklist</a>', '<a class="skip" href="#tracklist">트랙리스트로 건너뛰기</a>')
rep('<a href="#tracklist">Tracklist</a>', '<a href="#tracklist">트랙리스트</a>')
rep('<a href="#liner-notes">Liner notes</a>', '<a href="#liner-notes">라이너 노트</a>')
rep('<a href="#recorded-with">Recorded with</a>', '<a href="#recorded-with">함께 쓴 도구</a>')
rep('<a href="#credits">Credits</a>', '<a href="#credits">크레딧</a>')
rep('<span>Skills · Side A</span>', '<span>Skills · A면</span>')
rep('<small>Daily rotation</small>', '<small>매일 듣는 목록</small>')
rep('<span>35 tracks</span><span>1 system prompt</span><span>12 tools</span>',
    '<span>35곡</span><span>시스템 프롬프트 1개</span><span>도구 12개</span>')
rep('<span>Claude Code · Codex · any agent</span><span>Sides A–D + bonus</span>',
    '<span>Claude Code · Codex · 모든 에이전트</span><span>A–D면 + 보너스</span>')
rep('<p>Installs every track you pick</p>', '<p>고른 트랙을 모두 설치합니다</p>')
rep('<p class="lede">The skills, system prompt, and CLIs I run every day.</p>',
    '<p class="lede">제가 매일 쓰는 스킬, 시스템 프롬프트, CLI입니다.</p>')
rep('<p>A working kit for Claude Code, Codex, and other coding agents. Pick the skills you want; the installer asks which agents to put them on.</p>',
    '<p>Claude Code, Codex 같은 코딩 에이전트에 바로 쓰는 도구 모음입니다. 원하는 스킬을 고르면 설치기가 어느 에이전트에 넣을지 묻습니다.</p>')
rep('<p>Every track is credited to the person who wrote it, with the upstream commit it was copied from.</p>',
    '<p>트랙마다 만든 사람과 복사해 온 원본 커밋을 적어 두었습니다.</p>')
rep('</svg>See the tracklist</a>', '</svg>트랙리스트 보기</a>')
rep('</svg>View on GitHub</a>', '</svg>GitHub에서 보기</a>')
rep('<h2 id="tracklist-h">Tracklist</h2>', '<h2 id="tracklist-h">트랙리스트</h2>')
rep('<p>Open a track for its notes, its source, and a command that installs just that skill.</p>',
    '<p>트랙을 열면 설명과 출처, 그 스킬만 설치하는 명령이 나옵니다.</p>')
rep('Side A · Engineering<small>', 'A면 · 엔지니어링<small>')
rep('Side B · Productivity<small>', 'B면 · 생산성<small>')
rep('Side C · Design<small>', 'C면 · 디자인<small>')
rep('Side D · Agents<small>', 'D면 · 에이전트<small>')

# ---- track notes
NOTES = [
 ("Four-phase SDLC loop with human gates: intent, plan, build, evidence. A script scores the proof and sends failures back to plan or build.",
  "사람이 확인하는 관문이 있는 4단계 SDLC 루프입니다. 의도, 계획, 구현, 증거 순서로 진행하고, 스크립트가 증거를 채점해 실패하면 계획이나 구현 단계로 되돌립니다."),
 ("Build and run the app to prove a change works end to end. For agents without a built-in verify, such as Codex; in Claude Code use the bundled /verify.",
  "앱을 빌드하고 실행해서 변경이 처음부터 끝까지 동작하는지 증명합니다. Codex처럼 verify가 내장되지 않은 에이전트용입니다. Claude Code에서는 내장 /verify를 쓰세요."),
 ("One skill for PostgreSQL, MySQL, SQLite, and MongoDB: detect the engine, connect credential-safe, read the schema, read before writing, never write to prod.",
  "PostgreSQL, MySQL, SQLite, MongoDB를 스킬 하나로 다룹니다. 엔진을 알아내고, 자격 증명을 안전하게 다뤄 접속하고, 스키마를 읽고, 쓰기 전에 먼저 읽으며, 운영 DB에는 절대 쓰지 않습니다."),
 ("Explain SQL and batch logic to a non-expert: numbered source lines, the real rows they read, per-line arithmetic, a results table where only the input changes, and an executed counter-example.",
  "SQL과 배치 로직을 비전문가에게 설명합니다. 번호를 붙인 소스 줄, 그 줄이 읽는 실제 행, 줄마다의 계산, 입력만 바꾼 결과 표, 실제로 실행한 반례를 보여 줍니다."),
 ("Find deepening opportunities, show them as an HTML report, then grill through the one you pick.",
  "구조를 깊게 다듬을 기회를 찾아 HTML 보고서로 보여 주고, 고른 하나를 질문으로 끝까지 파고듭니다."),
 ("Build a throwaway prototype to answer a design question.",
  "설계 질문 하나에 답하려고 버릴 프로토타입을 만듭니다."),
 ("Run a retrospective on a coding session.", "코딩 세션을 회고합니다."),
 ("Drive Jenkins from the terminal with the jk CLI: jobs, runs, logs, artifacts, credentials.",
  "jk CLI로 터미널에서 Jenkins를 다룹니다. 잡, 실행, 로그, 산출물, 자격 증명을 관리합니다."),
 ("Find and fix interaction bugs with seeded personas, invariant oracles, reproducible failures, and replay. App profiles fit it to games, CRUD apps (double submit, drafts, Korean IME, two sessions), AI chat (streaming, stop, safe rendering), and media (recording, permissions, interruptions). Godot, native iOS, and web adapters.",
  "시드를 고정한 페르소나, 불변 조건 오라클, 재현 가능한 실패와 리플레이로 상호작용 버그를 찾아 고칩니다. 앱 프로필로 게임, CRUD 앱(중복 제출, 임시 저장, 한글 IME, 두 세션), AI 채팅(스트리밍, 중지, 안전한 렌더링), 미디어(녹음, 권한, 중단)에 맞춥니다. Godot, 네이티브 iOS, 웹 어댑터가 있습니다."),
 ("Review SwiftUI code for modern API use, data flow, navigation, accessibility, and performance, with before/after fixes. Targets the latest iOS and Swift; respects a project's existing deployment target.",
  "SwiftUI 코드를 최신 API 사용, 데이터 흐름, 내비게이션, 접근성, 성능 기준으로 리뷰하고 수정 전·후 코드를 보여 줍니다. 최신 iOS와 Swift를 기준으로 하되 프로젝트의 기존 배포 대상은 그대로 존중합니다."),
 ("One quality bar and improvement loop for apps, sites, and games: four dimensions (experience, function, consumer trust, engineering), hard floors, an independent judge for release candidates, and a ledger where every fix leaves a guard. Every report opens with a quality % (target 90% or higher) and why each point was lost.",
  "앱, 사이트, 게임에 하나의 품질 기준과 개선 루프를 적용합니다. 네 가지 축(경험, 기능, 소비자 신뢰, 엔지니어링), 넘어야 하는 최저선, 출시 후보를 판정하는 독립 심사자, 고칠 때마다 재발 방지 장치를 남기는 원장이 있습니다. 보고서는 항상 품질 %(목표 90% 이상)와 점수가 깎인 이유로 시작합니다."),
 ("Default way to test iOS apps: render SwiftUI screens as accessibility trees, hot-reload views and run unit tests on the Mac without booting a simulator. The simulator is kept for the final pass. Modified here with that policy and one-time Mac setup.",
  "iOS 앱을 시험하는 기본 방법입니다. 시뮬레이터를 띄우지 않고 Mac에서 SwiftUI 화면을 접근성 트리로 렌더링하고, 뷰를 핫 리로드하고, 단위 시험을 돌립니다. 시뮬레이터는 마지막 확인에만 씁니다. 이 정책과 Mac 최초 설정을 여기서 덧붙였습니다."),
 ("Relentless design interview that sharpens a plan while keeping GLOSSARY.md and ADRs updated as decisions settle.",
  "끈질긴 설계 인터뷰로 계획을 다듬고, 결정이 정해질 때마다 GLOSSARY.md와 ADR을 갱신합니다."),
 ("Actively build and sharpen a project's domain model: challenge terms, probe edge cases, and keep GLOSSARY.md and ADRs current.",
  "프로젝트의 도메인 모델을 적극적으로 만들고 다듬습니다. 용어를 따져 묻고, 경계 사례를 파고들고, GLOSSARY.md와 ADR을 최신으로 유지합니다."),
 ("Investigate a question against primary sources in a background agent and record cited findings in Markdown.",
  "백그라운드 에이전트가 1차 출처로 질문을 조사하고, 출처를 단 결과를 Markdown으로 남깁니다."),
 ("Type /qa to launch five QA subagents at once. Frontend: real users who drive the app in a browser the way people actually do, mistakes and unexpected actions included (first-timer, mistake maker, impatient, interrupted, off-path), judged by whether they reach the goal, understand what happened, recover, and keep their work. Backend: analysts who check recent API and query changes against real rows and cited domain intent, not against what the code does. The coordinator reproduces every finding before reporting, and fixes are applied only after you approve them. Default Sonnet 5.5 medium; model, effort, and agent count are arguments.",
  "/qa를 입력하면 QA 하위 에이전트 다섯 개가 한꺼번에 시작합니다. 프런트엔드에서는 실제 사용자처럼 브라우저로 앱을 씁니다. 실수와 예상 밖 행동(처음 쓰는 사람, 자주 실수하는 사람, 성급한 사람, 중간에 끊기는 사람, 정해진 길을 벗어나는 사람)도 포함하고, 목표에 닿는지, 무슨 일이 일어났는지 이해하는지, 되돌릴 수 있는지, 작업이 남는지로 판정합니다. 백엔드에서는 분석가가 최근 API와 쿼리 변경을 코드 동작이 아니라 실제 행과 출처가 있는 도메인 의도에 비춰 확인합니다. 조율자는 보고 전에 모든 발견을 재현하고, 수정은 승인한 뒤에만 적용합니다. 기본값은 Sonnet 5.5 medium이고, 모델, 노력 수준, 에이전트 수는 인자로 바꿉니다."),
 ("One ordered gate before every commit, the same in Claude Code, Codex, and Kiro: every step that edits code runs before every step that judges it. Simplify only for large changes, verify with evidence, an independent review, then a receipt; a git hook blocks code commits whose staged tree did not pass.",
  "커밋 전마다 거치는 순서 있는 관문으로, Claude Code, Codex, Kiro에서 똑같이 동작합니다. 코드를 고치는 단계는 모두 판정하는 단계보다 먼저 돕니다. 큰 변경에만 단순화를 하고, 증거로 검증하고, 독립 리뷰를 거친 뒤 영수증을 남깁니다. 스테이징한 트리가 통과하지 못한 코드 커밋은 git 훅이 막습니다."),
 ("Drive Jira and Confluence from the terminal with Atlassian's acli: check auth first, search with JQL, edit and transition in bulk, and export CSV or JSON.",
  "Atlassian의 acli로 터미널에서 Jira와 Confluence를 다룹니다. 먼저 인증을 확인하고, JQL로 검색하고, 여러 건을 한 번에 수정하거나 상태를 옮기고, CSV나 JSON으로 내보냅니다."),
 ("Compact the conversation into a handoff document for another agent to pick up.",
  "대화를 다른 에이전트가 이어받을 인수인계 문서로 압축합니다."),
 ("How to write skills, AGENTS.md, and CLAUDE.md that agents follow.",
  "에이전트가 실제로 따르는 스킬, AGENTS.md, CLAUDE.md를 쓰는 방법입니다."),
 ("Lazy-senior-dev mode: the simplest, shortest solution that actually works.",
  "게으른 시니어 개발자 모드입니다. 실제로 동작하는 가장 단순하고 짧은 해법을 고릅니다."),
 ("Interview the user relentlessly in frontier rounds until a plan or design tree is settled with nothing silently assumed.",
  "몰래 가정한 것이 하나도 남지 않을 때까지, 아직 정하지 않은 지점부터 차례로 사용자를 끈질기게 인터뷰해 계획이나 설계 트리를 확정합니다."),
 ("Ask the agent to explain its last message again, with missing context, plain language, and project glossary terms.",
  "에이전트에게 직전 답을 빠진 맥락을 채우고, 쉬운 말과 프로젝트 용어집의 용어로 다시 설명하게 합니다."),
 ("Report progress on the current request in numbers: items done, in progress, todo, and blocked, evidence for each done item, and an ETA for the rest.",
  "현재 요청의 진행 상황을 숫자로 보고합니다. 완료, 진행 중, 할 일, 막힘 항목 수와 완료 항목마다의 증거, 남은 일의 예상 완료 시점을 알려 줍니다."),
 ("Terse reply style: answer first, preserve every technical fact, number, warning, and exact code payload. Local voice skill only.",
  "짧게 답하는 말투입니다. 답을 먼저 하고, 기술 사실, 숫자, 경고, 정확한 코드는 모두 그대로 남깁니다. 로컬 말투 스킬만 설치합니다."),
 ("Teach a new skill or concept over multiple sessions in a stateful workspace with a mission, glossary, resources, and learning records.",
  "목표, 용어집, 자료, 학습 기록이 남는 작업 공간에서 여러 세션에 걸쳐 새 기술이나 개념을 가르칩니다."),
 ("Write clear, fluent Korean: keep particles and endings, end sentences with a predicate, use plain words instead of metaphors, and avoid em-dashes. Converted from an output style to a skill.",
  "분명하고 자연스러운 한국어를 씁니다. 조사와 어미를 살리고, 문장은 서술어로 끝내고, 비유 대신 쉬운 말을 쓰고, 줄표(—)를 피합니다. 출력 스타일을 스킬로 바꾼 것입니다."),
 ("Explain a bug's cause and fix in Confluence so a first-time reader gets it: real code captures with red/green/blue line highlights, one section per problem, how the problems connect, git blame plus the original reason, details folded. Project specifics live in a separate domain profile.",
  "처음 읽는 사람도 이해하도록 Confluence에 버그 원인과 수정을 설명합니다. 빨강·초록·파랑 줄 강조를 넣은 실제 코드 캡처, 문제마다 한 절, 문제끼리 이어지는 방식, git blame과 원래 이유를 담고, 세부 내용은 접어 둡니다. 프로젝트 고유 내용은 별도 도메인 프로필에 둡니다."),
 ("Design, critique, audit, and polish frontend interfaces.",
  "프런트엔드 화면을 디자인하고, 비평하고, 점검하고, 다듬습니다."),
 ("44 diagram and chart types (architecture, flowchart, sequence, state, ER, timeline, Sankey, and more) as self-contained HTML/SVG/PNG, with Mermaid, .drawio, and .excalidraw import.",
  "다이어그램과 차트 44종(아키텍처, 순서도, 시퀀스, 상태, ER, 타임라인, Sankey 등)을 독립 실행되는 HTML/SVG/PNG로 만듭니다. Mermaid, .drawio, .excalidraw 파일을 가져올 수 있습니다."),
 ("Generate and edit images with ChatGPT's current image model through your ChatGPT plan and the Codex CLI. It never names a model, so a newer ChatGPT image model works without changes. Modified here to keep working on future Codex releases.",
  "ChatGPT 요금제와 Codex CLI로 ChatGPT의 현재 이미지 모델을 써서 이미지를 만들고 편집합니다. 모델 이름을 지정하지 않으므로 더 새로운 이미지 모델이 나와도 고칠 것이 없습니다. 이후 Codex 버전에서도 계속 동작하도록 여기서 수정했습니다."),
 ("Code-driven motion-graphics videos: keynote-style product launch videos built from real captures of your running app, and vertical YouTube Shorts, Reels, and TikTok.",
  "코드로 만드는 모션 그래픽 영상입니다. 실행 중인 앱을 실제로 캡처해 키노트 스타일 제품 출시 영상을 만들고, 세로형 YouTube Shorts, Reels, TikTok도 만듭니다."),
 ("Measurable UI/UX rules for iPhone apps, mobile web, and mobile games: touch targets, safe areas, contrast, Korean line breaks, HUD and combat readability. Ships a 7-category scoring rubric, an independent-judge prompt, a pre-ship checklist, and per-project overrides. Pairs with impeccable.",
  "iPhone 앱, 모바일 웹, 모바일 게임에 쓰는 측정 가능한 UI/UX 규칙입니다. 터치 영역, 안전 영역, 대비, 한글 줄바꿈, HUD와 전투 화면 가독성을 다룹니다. 7개 항목 채점표, 독립 심사자 프롬프트, 출시 전 점검표, 프로젝트별 예외 설정이 들어 있습니다. impeccable과 함께 쓰면 좋습니다."),
 ("Image-first UI: three UX-distinct interface options generated as images through your ChatGPT plan; the one you pick becomes the reference the real build must match. Adds production sizing, stack choice, a domain pattern list, and a release gate with an independent judge. Admin, web app, landing page, or game screens.",
  "이미지 먼저 UI입니다. ChatGPT 요금제로 UX가 서로 다른 화면 시안 세 가지를 이미지로 만들고, 고른 시안을 실제 구현이 맞춰야 할 기준으로 삼습니다. 실서비스 크기 맞춤, 기술 스택 선택, 도메인 패턴 목록, 독립 심사자가 판정하는 출시 관문을 더했습니다. 관리자 화면, 웹 앱, 랜딩 페이지, 게임 화면에 씁니다."),
 ("Hand a bounded task to a peer CLI: Codex, Claude, Antigravity, Kiro, NotebookLM, ChatGPT Pro.",
  "범위를 정한 작업을 다른 CLI에 맡깁니다. Codex, Claude, Antigravity, Kiro, NotebookLM, ChatGPT Pro를 지원합니다."),
 ("Update all coding agent harnesses (Codex, Claude Code, pi, Antigravity CLI) in one run and print a before/after version table with exact stderr on failures.",
  "코딩 에이전트 도구(Codex, Claude Code, pi, Antigravity CLI)를 한 번에 모두 업데이트하고, 업데이트 전·후 버전 표를 출력합니다. 실패하면 stderr를 그대로 보여 줍니다."),
 ("Orchestrate app work through GPT-6.1 Sol workers: one brief per slice, one git worktree per parallel slice, a sandbox-aware preflight, retries that resume the worker's own session, and acceptance checks the orchestrator runs itself.",
  "GPT-6.1 Sol 작업자로 앱 작업을 조율합니다. 조각마다 작업 지시서 하나, 병렬 조각마다 git worktree 하나를 두고, 샌드박스를 고려한 사전 점검, 작업자 자신의 세션을 이어 가는 재시도, 조율자가 직접 돌리는 인수 확인을 합니다."),
]
for en, ko in NOTES:
    rep(f"<p>{en}</p>", f"<p>{ko}</p>")

# ---- bonus
rep('<h3>Bonus tracks</h3>', '<h3>보너스 트랙</h3>')
rep('<p>Available separately. These ship with a tool or a machine setup, so get them from their own home.</p>',
    '<p>따로 설치합니다. 도구나 기기 설정과 함께 배포되므로 각자의 원래 저장소에서 받으세요.</p>')
rep("""<p>Claude Code's own <code>/verify</code>: builds and runs your app to confirm a change does what it should. Comes with Claude Code v2.1.200 and later; nothing to install. Type <code>/verify</code> in a session. On Codex, use track A2. <a href="https://code.claude.com/docs/en/skills#run-and-verify-your-app">Docs</a>.</p>""",
    """<p>Claude Code에 내장된 <code>/verify</code>입니다. 앱을 빌드하고 실행해서 변경이 의도대로 동작하는지 확인합니다. Claude Code v2.1.200 이상에 들어 있어 따로 설치할 것이 없습니다. 세션에서 <code>/verify</code>를 입력하세요. Codex에서는 A2 트랙을 쓰세요. <a href="https://code.claude.com/docs/en/skills#run-and-verify-your-app">문서</a>.</p>""")
rep('<p>A browser for agents that shares your logged-in sessions. Comes with the ego lite app; by citrolabs.</p>',
    '<p>로그인한 세션을 함께 쓰는 에이전트용 브라우저입니다. ego lite 앱에 들어 있습니다. citrolabs가 만들었습니다.</p>')
rep('<p>One shared long-term memory for Claude Code, Codex, Hermes, and Pi. By cskwork.</p>',
    '<p>Claude Code, Codex, Hermes, Pi가 함께 쓰는 장기 기억입니다. cskwork가 만들었습니다.</p>')
rep("<p>Send messages and clickable links to a selected Teams chat through the signed-in web client's native service, without Microsoft Graph or webhooks. Install from the linked standalone repository.</p>",
    "<p>Microsoft Graph나 웹훅 없이, 로그인한 Teams 웹 클라이언트의 자체 서비스로 고른 채팅방에 메시지와 클릭할 수 있는 링크를 보냅니다. 링크한 별도 저장소에서 설치하세요.</p>")
PRIVATE_EN = " Private repository; access is required. Not included in the public install.</p>"
PRIVATE_KO = " 비공개 저장소라 접근 권한이 필요하며, 공개 설치에는 들어 있지 않습니다.</p>"
rep(PRIVATE_EN, PRIVATE_KO, 4)
rep('<p>Jira Cloud comments with ADF formatting, inline evidence, and saved-content checks.',
    '<p>ADF 서식, 본문 안 증거, 저장된 내용 확인을 갖춘 Jira Cloud 댓글을 씁니다.')
rep('<p>One weekday schedule that watches Jira for mentions and assigned tickets, acts only when intent is at least 90% clear (sdlc-kit), reproduces as-is and to-be locally, ships to dev with evidence comments, and waits for approval before staging.',
    '<p>평일 일정 하나로 Jira의 멘션과 배정된 티켓을 지켜봅니다. 의도가 90% 이상 분명할 때만 움직이고(sdlc-kit), 수정 전·후를 로컬에서 재현하고, 증거 댓글과 함께 dev에 배포한 뒤, 스테이징 전에는 승인을 기다립니다.')
rep('<p>Authenticate Claude Code accounts through Ego Lite, renew OAuth credentials, register with cswap, and verify account health.',
    '<p>Ego Lite로 Claude Code 계정을 인증하고, OAuth 자격 증명을 갱신하고, cswap에 등록하고, 계정 상태를 확인합니다.')
rep('<p>Rewrite small task prompts and agent workflows into ambitious ones along altitude (outcomes and ownership loops), depth (expert instruments, raw data, external verifiers), and range (noun-to-verb, borrowed methods, symptom diagnosis).',
    '<p>작은 작업 프롬프트와 에이전트 작업 흐름을 더 큰 목표로 다시 씁니다. 높이(결과와 책임 루프), 깊이(전문가 도구, 원자료, 외부 검증자), 폭(명사를 동사로, 빌려 온 방법, 증상 진단)의 세 방향으로 넓힙니다.')
rep('<span class="private-badge">Private</span>', '<span class="private-badge">비공개</span>', 4)

# ---- liner notes (system prompt)
rep('<h2 id="liner-h">Liner notes</h2>', '<h2 id="liner-h">라이너 노트</h2>')
rep('<p>The system prompt every agent gets: <a href="https://github.com/cskwork/skills/blob/main/system-prompt/AGENTS.md">system-prompt/AGENTS.md</a>, printed here in full.</p>',
    '<p>모든 에이전트가 받는 시스템 프롬프트 <a href="https://github.com/cskwork/skills/blob/main/system-prompt/AGENTS.md">system-prompt/AGENTS.md</a> 전문을 한국어로 옮겼습니다. 설치되는 원문은 영어입니다.</p>')
rep('<blockquote>Use the simplest existing solution that meets the current requirement.</blockquote>',
    '<blockquote>지금 요구를 충족하는 가장 단순한 기존 해법을 쓴다.</blockquote>')
ESSAY = [
 ("Explore first, and ground decisions",
  "먼저 탐색하고, 결정은 코드, 실제 데이터, 권위 있는 출처, 저장소 지침, 그리고 있으면 <code>~/.agents/rules/rules.md</code>에 근거한다. 요청이 이름을 대지 않은 관련 출처도 포함한다. 증거와 어긋나는 주장은 사용자 자신의 주장이라도 따져 묻는다. 말한 사실이 틀렸거나, 지시가 코드나 데이터나 사용자의 이전 지시와 충돌하거나, 더 근거 있는 해법이 있으면 증거와 권장안을 함께 말한다. 결과를 바꾸는 것만 꺼내고, 사용자가 그 증거를 보고 결정하면 그 결정을 따른다. 새 작업을 구현하기 전에 결과, 범위, 성공 확인 방법, 그리고 그런 이의를 다시 정리하고, 작업을 가장 크게 바꾸는 질문을 하나 하고, 합의를 기다린다. 의도가 분명하고 어긋난 전제가 없는 작고 되돌릴 수 있는 변경이라면 이해한 바를 말하고 바로 진행한다."),
 ("After agreement, finish implementation",
  "합의한 뒤에는 중간 확인 없이 구현, 검증, 전달을 끝낸다. 상태와 권장 사항은 다음 행동과 같은 메시지에 담고, 다음 단계를 예고하거나 계속할지 묻거나 아무것도 막지 않는 결정을 나열하며 턴을 끝내지 않는다. 확인이 통과하고 결과를 이루면 멈춘다. 일찍 멈추는 경우는 사용자 없이는 아무것도 진행할 수 없을 때, 보호된 자원이 막을 때, 합의한 범위를 크게 바꿔야 할 때, 또는 어떤 단계가 데이터 손실, 공개 API 변경, 보안 문제, 승인받지 않은 마이그레이션을 일으킬 때뿐이다. 다 못 하고 멈추거나 확인이 실패하면 증거와 남은 일을 함께 말한다. 머지나 공개는 승인받았을 때만 한다."),
 ("Use the simplest existing solution that meets the current requirement; add complexity",
  "지금 요구를 충족하는 가장 단순한 기존 해법을 쓰고, 복잡도는 실제로 드러난 빈틈이 있을 때만 더한다. 그 자리의 패턴을 따르고, 실패는 드러나게 두고, 호환성과 관련 없는 작업은 보존하며, 범위 밖 문제는 고치지 말고 권장 사항으로 보고한다. 근본 원인을 고치고, 실패를 숨기려고 확인을 약하게 하거나 지우지 않는다. 시험은 사용자나 저장소 지침이 요구할 때만, 요구한 것만 쓰거나 돌린다. 그 밖에는 빌드하고 실제 동작을 관찰해서 검증하고, 시험을 돌리지 않았다고 보고한다."),
 ("On implementation work, coordinate:",
  "구현 작업에서는 조율한다. 나눌 수 있는 조각(구현, 리뷰, 문서, 점검, QA, 넓은 검색)은 기본적으로 하위 에이전트에 맡기고, 범위, 통합, 검증, 보고는 직접 맡는다. 도구 호출 몇 번이면 되는 일이나 사용자와 실시간으로 고쳐 가는 작업만 혼자 한다. 맡기기 전에 <code>rules.md</code>의 배정 규칙에서 조각마다 모델과 추론 수준을 고른다. 규칙이 없으면 작업의 품질 기준을 맞추는 가장 저렴한 모델을 쓰고, 기본값은 medium 추론의 <code>claude-opus-5-5</code>이다. 작업은 파일, 상태, 순서를 공유하지 않는 조각으로 나누고, 그래야 전달이 빨라질 때 병렬 에이전트 팀으로 돌린다. 서로 의존하는 단계는 차례로 한다. 맡는 쪽에게는 목표, 맡은 경로, 지켜야 할 인터페이스, 제약, 인수 기준, 검증된 발견을 깔끔하게 전한다. 맡은 쪽은 진행 메시지 없이 최종 결과나 막힌 질문 하나로 한 번만 보고한다. 조율자는 맡긴 일을 다시 하지 않고 전체를 통합해 검증한다. 맡은 쪽이 일하는 동안에는 다른 일을 하거나 분 단위로 기다리며, 상태 확인 메시지나 짧은 간격의 확인은 하지 않는다."),
 ("Write to the user for a reader with limited attention:",
  "사용자에게는 주의를 오래 기울이기 어려운 독자를 위해 쓴다. 첫 문장에 답하고, 그다음에는 빠짐없이 답하는 가장 적은 말을 짧은 문단으로 쓴다. 사용자가 행동하는 데 필요한 경고, 정확한 숫자, 조건은 절대 빼지 않는다. 요청한 산출물은 그것만 돌려준다. 질문은 한 번에 하나씩 하고, 막힌 질문은 마지막에 둔다. 새 말을 만들지 말고 스키마 주석, 용어집, 코드에 있는 도메인 용어를 쓰며, 처음 쓸 때 출처와 함께 정의한다. 원인, 사고, 이력은 누가, 무엇을, 언제, 어디서, 왜, 어떻게로 보고하고, 환경마다 커밋이나 티켓을 밝힌다. 추측하지 말고 \"알 수 없음\"이라고 말한다. 원인의 세부를 말하기 전에 처음 읽는 사람에게 배경을 준다. 시스템이 평소 어떻게 동작하는지, 어느 단계가 깨졌는지, 그 단계가 어떻게 증상을 만드는지 설명한다. 코드 로직이 원인이면 수정 전·후 코드를 보여 주고, 한 줄씩 설명하고, 실제 데이터 한 행을 대입하고, 반례를 든다."),
]
for start, ko in ESSAY:
    m = re.search(r"<p>" + re.escape(start) + r".*?</p>", s, re.S)
    if not m: sys.exit(f"MISS essay: {start}")
    s = s[:m.start()] + f"<p>{ko}</p>" + s[m.end():]
rep('— cskwork · from <a href="https://github.com/cskwork/THE-SYSTEM-PROMPT">THE-SYSTEM-PROMPT</a>',
    '— cskwork · 원문 <a href="https://github.com/cskwork/THE-SYSTEM-PROMPT">THE-SYSTEM-PROMPT</a>')

# ---- gear
rep('<h2 id="gear-h">Recorded with</h2>', '<h2 id="gear-h">함께 쓴 도구</h2>')
rep("<p>The CLIs around the agents. Install commands come from each project's README; check upstream before you run one.</p>",
    "<p>에이전트 곁에서 쓰는 CLI입니다. 설치 명령은 각 프로젝트의 README에서 가져왔으니, 실행하기 전에 원본을 확인하세요.</p>")
for en, ko in [("Status line", "상태 표시줄"), ("Safety", "안전"), ("Accounts", "계정"), ("Deploy", "배포"),
               ("Workspace", "업무 도구"), ("Runtime", "런타임"), ("Agent", "에이전트"), ("CI", "CI"),
               ("Token usage", "토큰 사용량"), ("iOS testing", "iOS 시험")]:
    rep(f'<div class="row"><dt>{en}</dt>', f'<div class="row"><dt>{ko}</dt>', "all")
GEAR = [
 ("Context usage, active tools, running agents, and todos in Claude Code's status line.",
  "Claude Code 상태 표시줄에 컨텍스트 사용량, 사용 중인 도구, 실행 중인 에이전트, 할 일을 보여 줍니다."),
 ("Dry-runs risky Bash commands (recursive deletes, destructive git, kubectl delete, SQL wipes) and asks Proceed or Cancel first.",
  "위험한 Bash 명령(재귀 삭제, 파괴적인 git, kubectl delete, SQL 전체 삭제)을 먼저 모의 실행하고 진행할지 취소할지 묻습니다."),
 ("Switch Claude Code accounts, with rate-limit rotation and a usage dashboard.",
  "Claude Code 계정을 바꿉니다. 사용량 한도에 걸리면 계정을 돌려 쓰고, 사용량 대시보드도 있습니다."),
 ("Switch and manage Codex CLI accounts.", "Codex CLI 계정을 바꾸고 관리합니다."),
 ("Firebase command-line tools: deploys, emulators, project config.",
  "Firebase 명령줄 도구입니다. 배포, 에뮬레이터, 프로젝트 설정을 다룹니다."),
 ("Google Workspace from the terminal: Drive, Gmail, Calendar, Sheets, Docs, Chat, Admin.",
  "터미널에서 Google Workspace를 씁니다. Drive, Gmail, Calendar, Sheets, Docs, Chat, Admin을 다룹니다."),
 ("Terminal workspace manager and runtime for coding agents.",
  "코딩 에이전트를 위한 터미널 작업 공간 관리자이자 런타임입니다."),
 ("Nous Research's self-improving agent: it writes skills from experience and keeps its own memory.",
  "Nous Research의 스스로 개선하는 에이전트입니다. 경험에서 스킬을 쓰고 자기 기억을 유지합니다."),
 ("My Pi coding agent setup: this repository as a Pi package, extensions, subagent model routing, a permission policy, and Hindsight memory through pi-hindsight-memory.",
  "제 Pi 코딩 에이전트 설정입니다. 이 저장소를 Pi 패키지로 묶고, 확장, 하위 에이전트 모델 배정, 권한 정책, pi-hindsight-memory를 통한 Hindsight 기억을 넣었습니다."),
 ("GitHub-style CLI for Jenkins: contexts, runs, logs, admin. Pairs with track A8.",
  "GitHub CLI 스타일의 Jenkins CLI입니다. 컨텍스트, 실행, 로그, 관리를 다룹니다. A8 트랙과 함께 씁니다."),
 ("Compress shell command output before it reaches coding agents.",
  "셸 명령 출력이 코딩 에이전트에 닿기 전에 압축합니다."),
 ("Headless, simulator-free SwiftUI checks: accessibility-tree renders, hot reload, and unit tests on the Mac. Pairs with track A12.",
  "화면도 시뮬레이터도 없이 SwiftUI를 확인합니다. Mac에서 접근성 트리 렌더링, 핫 리로드, 단위 시험을 돌립니다. A12 트랙과 함께 씁니다."),
]
for en, ko in GEAR:
    rep(f"<p>{en}</p>", f"<p>{ko}</p>")

# ---- credits
rep('<h2 id="credits-h">Credits</h2>', '<h2 id="credits-h">크레딧</h2>')
rep('<p>Borrowed skills keep their own license file in their folder. Sources and exact commits: <a href="https://github.com/cskwork/skills/blob/main/THIRD_PARTY.md">THIRD_PARTY.md</a>.</p>',
    '<p>빌려 온 스킬은 각 폴더에 원래 라이선스 파일을 그대로 둡니다. 출처와 정확한 커밋은 <a href="https://github.com/cskwork/skills/blob/main/THIRD_PARTY.md">THIRD_PARTY.md</a>에 있습니다.</p>')
rep(', the system prompt, hindsight setup<span class="lic">MIT · this repository</span>',
    ', 시스템 프롬프트, hindsight 설정<span class="lic">MIT · 이 저장소</span>')
rep('impeccable, which also designed this page<span', 'impeccable(이 페이지 디자인도 맡음)<span')
rep('gpt-image-2, modified here<span', 'gpt-image-2(여기서 수정)<span')
rep('fluent-korean, converted to a skill here<span', 'fluent-korean(여기서 스킬로 변환)<span')
rep('simless, modified here<span', 'simless(여기서 수정)<span')
rep('<span>Copied from upstream 2026-10-05 · upstream stays the source of truth</span>',
    '<span>2026-10-05 원본에서 복사 · 정본은 계속 원본 저장소입니다</span>')
rep('<span>Set in <a href="https://github.com/Omnibus-Type/Archivo">Archivo</a> (OFL) · © cskwork, MIT</span>',
    '<span>글꼴 <a href="https://github.com/Omnibus-Type/Archivo">Archivo</a> (OFL) · © cskwork, MIT</span>')

# ---- copy script strings
rep('label.textContent = ok ? "Copied" : "Select it";', 'label.textContent = ok ? "복사됨" : "직접 선택";')
rep('live.textContent = ok ? "Command copied to clipboard." : "Copy failed. Select the command and copy it by hand.";',
    'live.textContent = ok ? "명령을 클립보드에 복사했습니다." : "복사하지 못했습니다. 명령을 선택해 직접 복사하세요.";')
rep('label.textContent = "Copy";', 'label.textContent = "복사";')

out = root / "ko" / "index.html"
out.parent.mkdir(exist_ok=True)
out.write_text(s, encoding="utf-8")
print(f"wrote {out}")
