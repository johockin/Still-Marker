# PROJECT_SPEC_TEMPLATE.md

⚠️ This is the **starter spec file** for any new Claude Code project. This document is the first and most important file in any repo. It acts as the **living god file** for all project decisions, architectural intentions, user needs, tech stack context, and collaborator expectations. 

Call it what you like—CLAUDE.md, PROJECT_SPEC.md, or GOD.md—but this file must always exist and be treated as the *source of truth*. Every coder must reference and maintain it. Every AI collaborator must not make a single move without knowing it up and down. Every architectural decision must be documented here.

---

## 🔰 PURPOSE OF THIS FILE

- Serves as the **canonical source of truth** for the project.
- Evolves over time, **growing with every decision**, mistake, fix, or insight.
- **Future collaborators (human or AI)** must be able to read this file and understand how the project works, why it’s built the way it is, and what to do next.

---

## 🧭 INITIAL INSTRUCTIONS FOR FIRST CLAUDE (OR HUMAN) CODER

Before writing a single line of code:

1. **Prompt the user (me) with clarification questions** that will help define:
   - Project purpose
   - Core priorities (e.g. performance, SEO, maintainability)
   - What is the *most important outcome* of the project? (e.g. speed, look/feel, design quality, polish, accessibility, maintainability, etc)
   - How should we balance *visual flare* vs *performance* vs *design excellence*? (Be explicit.)
   - Are there specific design sensibilities or references to keep in mind?
   - Target users or use cases
   - Known constraints or preferences
   - Deployment context or platforms
   - Anything else you feel you need to know to begin well

2. **Reflect back my answers as a short summary** in the section below ("🔍 Level Set Summary").

3. Help shape the foundational architecture and tech choices **based on the ethos below**, and record your recommendations.

4. Do *not* do more than one step at a time. Get explicit confirmation to proceed at each major decision point. Err on the side of slow, documented progress—do not sprint ahead or make large changes without pause and agreement. This is essential for high-trust, high-control iterative development.

---

## ✍️ ETHOS AND EXPECTATIONS

### ✅ My Expectations:

- **You must document everything.**
  - Every architectural decision
  - Every design tradeoff
  - Every mistake made and fixed
  - Why a dependency was added (if ever)
  - What each config or CLI command is doing (and why)
- **Specs over assumptions.**
  - When in doubt, ask me.
  - If there's ambiguity, propose 2–3 interpretations and we’ll decide.
- **No magic.**
  - Code must be explainable.
  - Every collaborator (human or AI) must be able to trace how the project works without reverse engineering codebase spaghetti.
- **Work in stable milestones.**
  - Each chunk of progress must be committable and testable.
  - Label milestone commits clearly in the spec and Git history.
- **I do the QA.**
  - You will guide me on how to test, and I’ll run the tests locally or in browser, giving feedback.
- **This file is allowed to be sprawling.**
  - It’s the beating heart of the project. Make it exhaustive and clear.
  - Use headings, sections, bullets, and dividers.
- **You are encouraged to prompt me regularly.**
  - Ask for clarification, priorities, and updates.
  - Especially if stuck, or if something needs approval before proceeding.
- **The roadmap is alive.**
  - Maintain a clearly structured list of upcoming, in-progress, and completed tasks.
  - Triaging is expected—priorities shift, and you should record that evolution.
  - Document when bugs are deprioritized or promoted to urgent.
  - All roadmap updates must be reflected in the CHANGELOG or ROADMAP section.
- **Font rendering / antialiasing:**
  - Unless visually intended for a specific look, use the smoothest possible, most legible antialiasing for all text. Prioritize readability and polish in UI text.

### 🧠 Guiding Philosophy:

- **Transparency > Cleverness**
- **Stability > Speed**
- **Performance > Convention**
- **Explicitness > DRY if it aids readability**
- **Centralization of knowledge > scattershot insight buried in files**

---

## 🔍 LEVEL SET SUMMARY (TO BE FILLED OUT BY FIRST CODER)

*Use this section to reflect the answers to your initial prompts. Keep it short and scannable.*

- **Project name**:
- **Purpose**:
- **Audience / users**:
- **Most important outcome**:
- **Visual vs performance vs design**:
- **Performance priority**: High / Medium / Low
- **SEO priority**: High / Medium / Low
- **Maintenance over time**: Ongoing / Single release
- **Deployment target(s)**:
- **Initial feature list**:
  - [ ]
  - [ ]
  - [ ]
- **Tech constraints / requests from user**:
  - [ ]
- **Other notes**:

---

## 🏗️ INITIAL TECH ARCHITECTURE (TO BE DEFINED BY CODER)

*Document initial proposed architecture decisions. This may change over time, but the rationale must always be explained.*

- **Framework / language**:
- **Styling approach**:
- **State management**:
- **Directory structure plan**:
- **Key dependencies**:
- **Planned dev workflow (e.g. Turbopack, Vite, etc)**:
- **Testing tools / approach**:

> For each above, include a 1-sentence explanation of why it was chosen. If still undecided, note what tradeoffs are being considered.

---

## 📒 CHANGELOG (REVERSE CHRONOLOGICAL)

*Document every change or decision here with date, author, and rationale.*

---

## 🧱 ROADMAP & PIPELINE

*A running list of features, fixes, and technical goals—regularly updated.*

- Group tasks into: `NOW`, `NEXT`, `LATER`, `SOMEDAY`, or `DEPRECATED`
- Flag issues that block progress or require user decision
- If a task changes status, add a note in the CHANGELOG
- Document all roadmap and pipeline requests or changes from the user (johnny@juniperisland.ca) with clarity and date

---

## 📌 MILESTONE COMMITS

*Use this to track stable points where the repo is working, testable, and safe to branch from.*

- **M1**: Project skeleton scaffolded
- **M2**: First working feature
- **M3**: Core functionality live
- **M4**: Performance optimization pass

(These can be edited or redefined per project.)

---

## 📌 OPEN QUESTIONS

*Use this section to collect things that are unclear, still being decided, or need user feedback.*

---

## 🤖 AI COLLABORATOR INSTRUCTIONS

- Always refer to this file first
- Before continuing any work, read this entire document top to bottom, and know it well
- Never introduce dependencies or frameworks without explaining and getting approval
- Always update this spec file whenever you make a move:
  - A new milestone is completed
  - A new file is created
  - A config is modified
  - An issue is found
  - A feature is added or removed
  - The roadmap changes
  - We realize something about the project
  - A bug is found or squashed 
- **For local-only web projects (like a static index.html), pushing to git after local QA is fine. For web apps and anything requiring live QA, push every step to git (user: johnny@juniperisland.ca) for web-based QA before proceeding.**

---

## 📁 OTHER FILES TO CREATE EARLY

- `README.md` with link to this file and short onboarding summary
- `.env.example` for environment variables

---

This file is sacred. Tend to it.

