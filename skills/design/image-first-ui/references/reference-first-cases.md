# Reference-first regression cases

Use when changing either design skill's Reference first gate. Read each prompt against both skills; check the first planned actions before generating images or writing UI code. These are manual behavior cases, not claims that an image-generation run occurred.

| Prompt / available evidence | Expected observable behavior |
|---|---|
| “Design a mobile reading dashboard.” No supplied reference. | Search relevant web/image references, inspect actual visual examples, then record source URLs and observed hierarchy/type/material traits before proposing a direction. |
| “Make a screen inspired by a named series' lead.” Identity is searchable. | Inspect original/official reliable references and establish the correct lead/version, documented gender/role, palette, silhouette and defining motifs. No basic identity question to the user before research; no generic stock substitute. |
| “Use the character with the same name from either of two unrelated works.” Search leaves two materially different identities. | Search first, document what each source establishes, then ask which identity/version the user means before adapting. |
| User supplies a sufficient official reference sheet and palette. | Inspect and reuse those files/URLs; record traits and provenance. No redundant discovery search or extra approval gate. |
| “Do not browse; use this screenshot.” | Honor no-browse, inspect supplied screenshot, record the restriction, and label unknown identity details as unknown. No invented verification. |
| “Keep the concept, but avoid the show's logo and the actor's likeness.” | Keep verified concept/motifs and create original forms/composition; exclude requested identifiers. No claim of copyright-free status. |
| A search snippet describes a character; no full page or image opened. | Gate remains incomplete. Open original/reliable visual evidence before asserting appearance or producing the design. |
| Named-source search tools are unavailable. | State the evidence gap and use sufficient supplied evidence; if an unresolved identity changes the design, clarify it rather than inventing traits. |
| Existing app refinement with current representative captures and fixed identity. | Inspect those captures, preserve incumbent identity and scope, and reuse sufficient references; no unrelated visual-world replacement. |

Review URLs/traits/adaptation notes separately: a source must support its attributed observation; creative interpretation must be labelled as interpretation. Preserve each skill's existing generation/approval/build/QA flow after this gate. A content-only or backend task does not invoke these design workflows.
