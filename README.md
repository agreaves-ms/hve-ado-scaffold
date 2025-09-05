# Hyper-Velocity Engineering (HVE) ADO Scaffold 🚀

Lightweight, composable scaffolding to supercharge GitHub Copilot + Azure DevOps (AzDO) workflows: pull @Me work items, enrich with repository context, generate a research → plan → implement loop, manage PRDs & ADRs, and produce clean conventional commits - all inside Copilot Chat.

Use it as‑is or cherry‑pick only the folders you want.

## Table of Contents

* [Hyper-Velocity Engineering (HVE) ADO Scaffold 🚀](#hyper-velocity-engineering-hve-ado-scaffold-)
  * [Table of Contents](#table-of-contents)
  * [Quick start 🏁](#quick-start-)
    * [Prerequisites (Mac users only)](#prerequisites-mac-users-only)
    * [Option 1: Automated Installation (Recommended) 🤖](#option-1-automated-installation-recommended-)
    * [Option 2: Manual Setup 📋](#option-2-manual-setup-)
  * [What's available 📦](#whats-available-)
    * [VS Code settings ⚙️](#vs-code-settings-️)
    * [MCP configuration 🧩](#mcp-configuration-)
      * [Security considerations](#security-considerations)
    * [Copilot Prompts (.github/prompts) for AzDO 🔧](#copilot-prompts-githubprompts-for-azdo-)
    * [Copilot Chat Modes (.github/chatmodes) for workflow automation 🤖](#copilot-chat-modes-githubchatmodes-for-workflow-automation-)
    * [Instruction files (what guides Copilot) 🧭](#instruction-files-what-guides-copilot-)
    * [Docs you can reuse 📚](#docs-you-can-reuse-)
  * [Core Workflows](#core-workflows)
    * [Azure DevOps Work Items Loop](#azure-devops-work-items-loop)
    * [Work Item Handoff Generation](#work-item-handoff-generation)
    * [Research → Plan → Implement Loop](#research--plan--implement-loop)
    * [PRD Authoring Flow](#prd-authoring-flow)
    * [ADR Creation Flow](#adr-creation-flow)
  * [Recommended setup in your repo 🔧](#recommended-setup-in-your-repo-)
  * [Quick Reference Tables](#quick-reference-tables)
    * [Prompts](#prompts)
    * [Chat Modes](#chat-modes)
  * [Security \& Secrets](#security--secrets)
  * [Adapting to Other Trackers](#adapting-to-other-trackers)
  * [Adding Your Own Assets](#adding-your-own-assets)
  * [FAQ ❓](#faq-)

## Quick start 🏁

### Prerequisites (Mac users only)

```bash
# Install PowerShell on macOS
brew install powershell

# Start a PowerShell session
pwsh
```

### Option 1: Automated Installation (Recommended) 🤖

Install HVE ADO Scaffold into your existing repository using the PowerShell script:

1. **Download and run the installer:**

   ```powershell
   # Download the installer script
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/agreaves-ms/hve-ado-scaffold/main/Install-HveAdoScaffold.ps1" -OutFile "Install-HveAdoScaffold.ps1"

   # Run the installer from your repository root
   .\Install-HveAdoScaffold.ps1
   ```

2. **Start using the workflows:**
   * Open VS Code and try the prompts from `.github/prompts/` in Copilot Chat

**Installation options:**

```powershell
# Install with prompts for existing files
.\Install-HveAdoScaffold.ps1

# Install to a specific directory
.\Install-HveAdoScaffold.ps1 -TargetPath "./my-project"

# Preview changes that installation would perform
.\Install-HveAdoScaffold.ps1 -WhatIf
```

### Option 2: Manual Setup 📋

1. Clone the repo
   * You can work directly in this scaffold or copy the pieces into your own repo.

2. VS Code setup
   * This repo includes helpful workspace settings in [`.vscode/settings.json`](./.vscode/settings.json) that wire Copilot Chat to read instruction files and prompts in this repo.
   * Recommended: add and copy over the MCP server config ([`.vscode/mcp.json`](./.vscode/settings.json)) for connecting Copilot Chat to external tools, such as AzDO.

3. Try the built-in prompts, instructions, and chatmodes
   * Open Copilot Chat and run the prompts from [`.github/prompts`](./.github/prompts/) (details below) to fetch and summarize your AzDO work items.

## What's available 📦

Here are the key parts and why you'd want them:

### VS Code settings ⚙️

* [`.vscode/settings.json`](./.vscode/settings.json)
  * Enables Copilot Chat settings for this project and sets up auto-linting and auto-formatting, key parts to look at:

    ```jsonc
    /*
        Important GitHub Copilot settings
    */

    // Enables the thinking tool used by models that want to think
    "github.copilot.chat.agent.thinkingTool": true,
    // Enables semantic search on the codebase
    "github.copilot.chat.codesearch.enabled": true,
    // Specifies which instructions to use for automatic commit message generation
    "github.copilot.chat.commitMessageGeneration.instructions": [
        {
            "file": "./.github/instructions/commit-message.instructions.md"
        }
    ],
    // (08-21-2025 Currently Preview) Enables a task list directly in Copilot Chat
    "chat.todoListTool.enabled": true,

    /*
        Important GitHub Copilot Chat instruction and prompt file locations
        * Task Planner generates prompts and instructions under .copilot-tracking
        * Framework specific grouping for instructions files
    */

    // *.instruction.md locations
    "chat.instructionsFilesLocations": {
        ".github/instructions": true,
        ".github/instructions/csharp": true,
        "/Users/vscode/repos/instructions": true,
        ".copilot-tracking/instructions": true,
        ".copilot-tracking/plans": true
    },
    // *.prompt.md locations
    "chat.promptFilesLocations": {
        ".github/prompts": true,
        "/Users/vscode/repos/prompts": true,
        ".copilot-tracking/prompts": true
    },
    ```

### MCP configuration 🧩

**Model Context Protocol (MCP)** servers extend Copilot Chat with external tool access. This scaffold includes a ready-to-use configuration for Azure DevOps integration.

[`.vscode/mcp.json`](./.vscode/mcp.json) includes:

* **🔷 Azure DevOps MCP Server** (`@modelcontextprotocol/server-azure-devops`)
  * Enables work item retrieval, querying, and management directly from Copilot Chat
  * Required for the AzDO workflow prompts to function
  * Supports custom WIQL queries and work item operations
  * Refer to [azure-devops-mcp troubleshooting guide](https://github.com/microsoft/azure-devops-mcp/blob/main/docs/TROUBLESHOOTING.md) for troubleshooting issues

* **📚 Microsoft Docs MCP Server** (`@modelcontextprotocol/server-microsoft-docs`)
  * Provides access to official Microsoft documentation and Azure docs
  * Enables real-time documentation lookup during development

#### Security considerations

* **Never commit `.vscode/mcp.json`** with real credentials
* Use environment variables or `inputs` for sensitive data like PATs

### Copilot Prompts (.github/prompts) for AzDO 🔧

Located in [`.github/prompts/`](./.github/prompts/). Each prompt is an executable, opinionated workflow. Updated catalog (filenames now use consistent `ado-` / `git-` prefixes):

* [`ado-get-my-work-items.prompt.md`](./.github/prompts/ado-get-my-work-items.prompt.md)
  * `/ado-get-my-work-items` - Retrieve & hydrate ALL @Me items (prioritized types first, optional fallback) with progressive JSON persistence to `.copilot-tracking/workitems/YYYYMMDD-assigned-to-me.raw.json` and strict field merge rules (no WIQL queries, no deprecated shortcuts).

* [`ado-process-my-work-items-for-task-planning.prompt.md`](./.github/prompts/ado-process-my-work-items-for-task-planning.prompt.md)
  * `/ado-process-my-work-items-for-task-planning` - Generates a resumable enriched handoff (`*.handoff.md`) from the latest raw JSON: selects a top recommendation (boost / force logic), adds repository context (files, hypotheses, risks) & seeds Task Researcher.

* [`ado-update-wit-items.prompt.md`](./.github/prompts/ado-update-wit-items.prompt.md)
  * `/ado-update-wit-items` - Executes a `handoff.md` (Create/Update ordering, hierarchy, relationships) following planning + update instructions to create/update/link Epics → Features → Stories with resilient batching & structured `handoff-logs.md` tracking.

* [`ado-get-build-info.prompt.md`](./.github/prompts/ado-get-build-info.prompt.md)
  * `/ado-get-build-info` - Targeted or latest PR build metadata + focused log extraction into `.copilot-tracking/pr/*-build-*-logs.md` (error/warning segments, optional full logs, execution timeline, compliance checklist).

* [`git-commit-message.prompt.md`](./.github/prompts/git-commit-message.prompt.md)
  * `/git-commit-message` - Generates a Conventional Commit message (staged changes only) per strict rules (type + <=4 change points, optional body, emoji footer).

* [`git-commit.prompt.md`](./.github/prompts/git-commit.prompt.md)
  * `/git-commit` - Atomic stage → generate → commit workflow using only allowed git commands; prints authoritative message after committing.

* [`git-setup.prompt.md`](./.github/prompts/git-setup.prompt.md)
  * `/git-setup` - Safe, verification‑first Git config assistant (identity, signing, diff/merge tooling) with confirm-before-change guidance.

Why these prompts? Together they implement: collect → contextualize → handoff → plan/research → implement → validate (build) → commit.

### Copilot Chat Modes (.github/chatmodes) for workflow automation 🤖

Located in [`.github/chatmodes/`](./.github/chatmodes/). Specialized persistent personas (filenames normalized; one new ADO-prefixed mode):

* [`task-researcher.chatmode.md`](./.github/chatmodes/task-researcher.chatmode.md) - Deep, evidence-driven research (`.copilot-tracking/research/*.md`) using a mandated research template & aggressive context recovery.
* [`task-planner.chatmode.md`](./.github/chatmodes/task-planner.chatmode.md) - Generates synchronized `plans/`, `details/`, and implementation prompt triplet enabling progressive execution.
* [`prompt-builder.chatmode.md`](./.github/chatmodes/prompt-builder.chatmode.md) - Author / refactor prompts & instruction files with builder + tester roles.
* [`adr-creation.chatmode.md`](./.github/chatmodes/adr-creation.chatmode.md) - Guided ADR flow (context, alternatives, decision) leveraging reusable ADR template.
* [`prd-builder.chatmode.md`](./.github/chatmodes/prd-builder.chatmode.md) - Structured PRD authoring with resumable session state.
* [`ado-prd-to-wit.chatmode.md`](./.github/chatmodes/ado-prd-to-wit.chatmode.md) - Transforms PRD output into actionable WI planning artifacts consumed by update prompt.

Why chat modes? They stabilize multi-phase flows: each encapsulates domain rigor, artifact lifecycle, and compliance checklists reducing conversational drift.

### Instruction files (what guides Copilot) 🧭

Located in [`.github/instructions/`](./.github/instructions/) - these are loaded automatically (see VS Code settings) and layered with a global meta policy file (`copilot-instructions.md`). Key files:

* Root Meta: [`copilot-instructions.md`](./.github/copilot-instructions.md)
  * Declares HIGHEST PRIORITY policies: breaking changes allowed, no unrequested tests/docs, minimal factual comments, proactive fixes, mandatory re-reads before edits.
* Commits: [`commit-message.instructions.md`](./.github/instructions/commit-message.instructions.md) - Conventional Commit syntax (types, scopes, body/footer rules, emoji footer contract).
* Markdown: [`markdown.instructions.md`](./.github/instructions/markdown.instructions.md) - Style guide aligned with `.markdownlint.json` (headings, spacing, code fences, lists, tables, links consistency).
* Implementation Loop: [`task-implementation.instructions.md`](./.github/instructions/task-implementation.instructions.md) - Progressive plan execution & `.copilot-tracking/changes/*.md` logging (Added / Modified / Removed + release summary gating).
* ADO Planning: [`ado-wit-planning.instructions.md`](./.github/instructions/ado-wit-planning.instructions.md) - Canonical planning workspace (artifact-analysis, work-items, handoff, planning-log) + normalization & similarity matrix.
* ADO Update Execution: [`ado-update-wit-items.instructions.md`](./.github/instructions/ado-update-wit-items.instructions.md) - Handoff-driven create/update/link protocol + resilient sequencing & logging.
* ADO Build Diagnostics: [`ado-get-build-info.instructions.md`](./.github/instructions/ado-get-build-info.instructions.md) - Deterministic build selection + error-focused segmented log artifact with execution timeline & compliance checklist.
* Language Conventions: [`csharp.instructions.md`](./.github/instructions/csharp/csharp.instructions.md) & [`csharp-tests.instructions.md`](./.github/instructions/csharp/csharp-tests.instructions.md) - Coding + test architecture (SOLID, ordering, BDD XUnit patterns, base test reuse).

Layering Model: meta > domain (build / planning / update / implementation) > content-type (markdown / commit) > language (csharp + tests). Conflicts resolve by earliest file declaring **HIGHEST PRIORITY** segment. Always re-read relevant instruction files before edits (enforced by meta policy & prompt logic).

### Docs you can reuse 📚

* [`docs/solution-adr-library/adr-template-solutions.md`](./docs/solution-adr-library/adr-template-solutions.md)
  * A practical ADR template with a YAML drafting guide to speed up architecture decisions.
  * Works seamlessly with the `adr-creation.chatmode.md` for guided ADR creation.

## Core Workflows

### Azure DevOps Work Items Loop

1. `/ado-get-my-work-items` → Progressive raw + hydration JSON
2. `/ado-process-my-work-items-for-task-planning` → Enriched markdown handoff (top recommendation + seeds)
3. `task-researcher` → Evidence-driven research doc for chosen item
4. `task-planner` → Plan + details + implementation prompt triplet
5. Implementation prompt (guided by task implementation instructions) → code changes + `.copilot-tracking/changes/*`
6. `/git-commit-message` or `/git-commit` → Conventional commit
7. (Optional) `/ado-get-build-info` → Diagnose failing build for feedback loop

### Work Item Handoff Generation

Adds repository context (candidate & top files, hypotheses, risks, relationships) + ready-to-research seed so research begins grounded (idempotent & resumable). Supports boost / force top selection strategies.

### Research → Plan → Implement Loop

| Phase | Chat Mode / Prompt | Artifact(s) |
|-------|--------------------|-------------|
| Research | task-researcher | `.copilot-tracking/research/*.md` |
| Plan | task-planner | `.copilot-tracking/plans/**`, `details/**`, `prompts/**` |
| Implement | implementation prompt | `.copilot-tracking/changes/*.md` + code edits |
| Commit | git-commit / git-commit-message | Conventional commit message |
| Diagnose (optional) | ado-get-build-info | `.copilot-tracking/pr/*-build-*-logs.md` |

### PRD Authoring Flow

Use `prd-builder` for structured product specification prior to backlog seeding:

1. Ambiguous idea → refinement Q&A.
2. Produces `docs/prds/<name>.md` + session state under `.copilot-tracking/prd-sessions/`.
3. Populates goals, personas, FR/NFR, risks, metrics iteratively.
4. Handoff to `ado-prd-to-wit` to synthesize WI plan artifacts.
5. Execute with `/ado-update-wit-items` to realize backlog (Epics → Features → Stories).

### ADR Creation Flow

`adr-creation` guides: context discovery → alternative evaluation → single decision → final ADR using reusable template (`docs/solution-adr-library`).

## Recommended setup in your repo 🔧

**🤖 Automated (Recommended):**

Use the PowerShell installer script (see [Quick start](#quick-start-)) - it handles all the file copying and directory structure automatically.

**📋 Manual approach:**

If you prefer to copy things manually into a different repository:

1. Copy [`.vscode/settings.json`](./.vscode/settings.json) so Copilot Chat discovers your prompts/instructions.
2. Copy [`.vscode/mcp.json`](./.vscode/mcp.json) so Copilot Chat has required external tools; **keep secrets out of source control**.
3. Copy [`.github/instructions/`](./.github/instructions/), [`.github/prompts/`](./.github/prompts/), and [`.github/chatmodes/`](./.github/chatmodes/) directories.
4. Copy [`docs/solution-adr-library/`](./docs/solution-adr-library/) for the ADR template.

Tip: You can start simple-use the prompts and instructions as-is-and grow over time.

## Quick Reference Tables

### Prompts

| Command | Purpose | Primary Artifact |
|---------|---------|------------------|
| `/ado-get-my-work-items` | Retrieve & hydrate @Me items | `*-assigned-to-me.raw.json` |
| `/ado-process-my-work-items-for-task-planning` | Build enriched handoff | `*-assigned-to-me.handoff.md` |
| `/ado-update-wit-items` | Create/update/link WIs from handoff | `handoff-logs.md` |
| `/ado-get-build-info` | Build + log diagnostics | `pr-*-build-*-logs.md` |
| `/git-commit-message` | Generate commit message | (message only) |
| `/git-commit` | Stage + generate + commit | Git commit |
| `/git-setup` | Audit & propose git config | (none) |

### Chat Modes

| Mode | Focus | Output |
|------|-------|--------|
| task-researcher | Deep evidence research | `research/*.md` |
| task-planner | Actionable plan & details | `plans/`, `details/`, `prompts/` |
| prompt-builder | Prompt / instruction authoring | Updated `.github/{prompts,instructions}` |
| adr-creation | Architecture decisions | ADR drafts/finals |
| prd-builder | Product requirements | `docs/prds/*.md`, session state |
| ado-prd-to-wit | PRD → backlog planning | WI planning artifacts |
| (implementation prompt) | Execute plan | `.copilot-tracking/changes/*.md` |

## Security & Secrets

* Never commit real PATs, client secrets, or tokens.
* Keep `.vscode/mcp.json` either out of source control or templated with placeholders.
* Validate prompt / chatmode edits for accidental secret inclusion before committing.
* Use environment variables for any local dev secrets referenced in examples.

## Adapting to Other Trackers

Swap AzDO prompts with equivalents (e.g., GitHub Issues MCP server) by:

1. Duplicating a prompt file.
2. Replacing tool invocations to new server (`github_` / `jira_` tools, etc.).
3. Updating field lists + output JSON schema comments.

## Adding Your Own Assets

1. New prompt: add `*.prompt.md` under `.github/prompts/` (follow existing structure, include frontmatter `mode:` + `description:`).
2. New instructions: drop into `.github/instructions/` or a subfolder; update settings if relocating.
3. New chat mode: create `*.chatmode.md` under `.github/chatmodes/` with `description`, `tools` array, and clear role directives.
4. Run `/git-commit-message` to standardize the commit message.

## FAQ ❓

**Can I reorder or rename folders?**
Yes - just keep the [settings](./.vscode/settings.json) pointing to the right locations so Copilot can find your files. Update the `chat.instructionsFilesLocations` and `chat.promptFilesLocations` accordingly.

**Do I have to use MCP?**
Yes for AzDO-centric prompts/chatmodes: they rely on Azure DevOps + Microsoft Docs MCP servers. Non-AzDO instruction files (markdown, commit, C#) work without MCP.

**Will this work outside VS Code?**
The [VS Code settings](./.vscode/settings.json) are editor-specific, but the prompts, instructions, and chatmodes are just Markdown files - you can adapt them to other editors or use them manually.

**How do I add my own prompts or instructions?**
Add a `*.prompt.md` to [`.github/prompts/`](./.github/prompts/), a `*.instructions.md` to [`.github/instructions/`](./.github/instructions/), or a `*.chatmode.md` to [`.github/chatmodes/`](./.github/chatmodes/). VS Code auto-discovers per workspace settings.

**What if I don't use Azure DevOps?**
Replace ADO prompts with equivalents (e.g., GitHub Issues or Jira MCP servers) keeping artifact contracts (raw JSON → handoff → planning → implementation → commit) intact.
