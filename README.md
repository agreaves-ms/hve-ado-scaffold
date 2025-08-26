# Hyper-Velocity Engineering (HVE) ADO Scaffold 🚀

Lightweight, composable scaffolding to supercharge GitHub Copilot + Azure DevOps (AzDO) workflows: pull @Me work items, enrich with repository context, generate a research → plan → implement loop, manage PRDs & ADRs, and produce clean conventional commits - all inside Copilot Chat.

Use it as‑is or cherry‑pick only the folders you want.

## Table of Contents

* [Hyper-Velocity Engineering (HVE) ADO Scaffold 🚀](#hyper-velocity-engineering-hve-ado-scaffold-)
  * [Table of Contents](#table-of-contents)
  * [Quick start 🏁](#quick-start-)
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

Located in [`.github/prompts/`](./.github/prompts/). Each prompt is an executable mini-workflow. Current catalog:

* [`get-my-work-items.prompt.md`](./.github/prompts/get-my-work-items.prompt.md)
  * `/get-my-work-items` - Full @Me retrieval with paging + progressive JSON hydration (`.copilot-tracking/workitems/YYYYMMDD-assigned-to-me.raw.json`).
  * Prioritized + fallback types, strict field list persistence, no WIQL dependency.

* [`create-my-work-items-handoff.prompt.md`](./.github/prompts/create-my-work-items-handoff.prompt.md)
  * `/create-my-work-items-handoff` - Generates a rich, resumable markdown handoff (`*.handoff.md`) from the raw file with repository file context, selecting a top recommendation.

* [`ado-update-wit-prd-items.prompt.md`](./.github/prompts/ado-update-wit-prd-items.prompt.md)
  * `/ado-update-wit-prd-items` - Consumes a PRD→WIT handoff to create/update/link work items (Epics → Features → Stories) with batching, retries, relationship linking, and execution report artifacts.

* [`gen-commit-message.prompt.md`](./.github/prompts/gen-commit-message.prompt.md)
  * `/gen-commit-message` - Conventional Commit generation using staged changes only.

* [`commit.prompt.md`](./.github/prompts/commit.prompt.md)
  * `/commit` - Stages everything, generates & applies commit message, then displays it (atomic workflow).

* [`git-setup.prompt.md`](./.github/prompts/git-setup.prompt.md)
  * `/git-setup` - Verification‑first Git configuration assistant (identity, signing, editor/diff/merge tooling) with safe, confirm-before-change flow.

Why these prompts? Together they implement: collect → contextualize → handoff → plan/execute → commit.

### Copilot Chat Modes (.github/chatmodes) for workflow automation 🤖

Located in [`.github/chatmodes/`](./.github/chatmodes/). Specialized persistent personas:

* [`task-researcher.chatmode.md`](./.github/chatmodes/task-researcher.chatmode.md) - Deep evidence-driven research (creates `.copilot-tracking/research/*.md`).
* [`task-planner.chatmode.md`](./.github/chatmodes/task-planner.chatmode.md) - Produces synchronized plan / details / implementation prompt triplet.
* [`prompt-builder.chatmode.md`](./.github/chatmodes/prompt-builder.chatmode.md) - Prompt + instruction authoring & validation (dual Builder/Tester persona).
* [`adr-creation.chatmode.md`](./.github/chatmodes/adr-creation.chatmode.md) - Socratic ADR coaching, progressive draft to finalized decision artifact.
* [`prd-builder.chatmode.md`](./.github/chatmodes/prd-builder.chatmode.md) - Structured Product Requirements Document creation with state resumption.
* [`prd-to-wit.chatmode.md`](./.github/chatmodes/prd-to-wit.chatmode.md) - (Used upstream of `ado-update-wit-prd-items`) transforms PRD analysis into executable work item handoff.

Why chat modes? They reduce drift: each mode enforces domain‑specific rigor and artifacts.

### Instruction files (what guides Copilot) 🧭

Located in [`.github/instructions/`](./.github/instructions/) - these shape how Copilot behaves when generating content.

* [`commit-message.instructions.md`](./.github/instructions/commit-message.instructions.md)
  * Conventional Commit rules and examples; used by the commit message prompt.
* [`markdown.instructions.md`](./.github/instructions/markdown.instructions.md)
  * Markdown style guide used by markdownlint and by Copilot when drafting docs.
* [`task-implementation.instructions.md`](./.github/instructions/task-implementation.instructions.md)
  * For progressive task execution and change logging in `.copilot-tracking/**` (useful for larger feature work tracked across steps).
* [`csharp/`](./.github/instructions/csharp/) folder
  * [`csharp.instructions.md`](./.github/instructions/csharp/csharp.instructions.md) and [`csharp-tests.instructions.md`](./.github/instructions/csharp/csharp-tests.instructions.md) define coding and testing conventions if you build C# projects here.

### Docs you can reuse 📚

* [`docs/solution-adr-library/adr-template-solutions.md`](./docs/solution-adr-library/adr-template-solutions.md)
  * A practical ADR template with a YAML drafting guide to speed up architecture decisions.
  * Works seamlessly with the `adr-creation.chatmode.md` for guided ADR creation.

## Core Workflows

### Azure DevOps Work Items Loop

1. `/get-my-work-items` → Progressive raw + hydration JSON
2. `/create-my-work-items-handoff` → Rich markdown handoff (top recommendation + seeds)
3. `task-researcher` → Deep evidence doc for chosen item
4. `task-planner` → Plan + details + implementation prompt
5. Implementation prompt (executes plan via task implementation instructions)
6. `/commit` or `/gen-commit-message` → Clean commit

### Work Item Handoff Generation

Adds repository context (relevant files, tags, risks) + structured seeds so research begins with grounded hypotheses instead of blank exploration.

### Research → Plan → Implement Loop

| Phase | Chat Mode / Prompt | Artifact(s) |
|-------|--------------------|-------------|
| Research | task-researcher | `.copilot-tracking/research/*.md` |
| Plan | task-planner | `plans/`, `details/`, `prompts/` files |
| Implement | implementation prompt | `changes/*.md` progressive log + code edits |
| Commit | commit / gen-commit-message | Conventional commit message |

### PRD Authoring Flow

Use `prd-builder` when you need a structured product specification prior to backlog seeding:

1. Start ambiguous idea → builder asks refinement questions.
2. Creates `docs/prds/<name>.md` + state JSON in `.copilot-tracking/prd-sessions/`.
3. Iteratively populates: goals, personas, FR/NFR tables, risks, metrics.
4. Handoff to `prd-to-wit` to synthesize work item creation plan.
5. Execute with `/ado-update-wit-prd-items` to realize backlog.

### ADR Creation Flow

`adr-creation` guides: discover decision context → draft rationale → compare alternatives → finalize ADR (using template in `docs/solution-adr-library`).

## Recommended setup in your repo 🔧

If you're copying things into a different repository:

1. Copy [`.vscode/settings.json`](./.vscode/settings.json) so Copilot Chat discovers your prompts/instructions.
2. Copy [`.vscode/mcp.json`](./.vscode/mcp.json) so Copilot Chat has required external tools; **keep secrets out of source control**.
3. Copy [`.github/instructions/`](./.github/instructions/), [`.github/prompts/`](./.github/prompts/), and [`.github/chatmodes/`](./.github/chatmodes/) directories.
4. Copy [`docs/solution-adr-library/`](./docs/solution-adr-library/) for the ADR template.

Tip: You can start simple-use the prompts and instructions as-is-and grow over time.

## Quick Reference Tables

### Prompts

| Command | Purpose | Primary Artifact |
|---------|---------|------------------|
| `/get-my-work-items` | Retrieve & hydrate @Me items | `*.raw.json` |
| `/create-my-work-items-handoff` | Build enriched handoff | `*.handoff.md` |
| `/ado-update-wit-prd-items` | Create/update/link WITs from PRD handoff | Execution log / ID map |
| `/gen-commit-message` | Generate commit message | (message only) |
| `/commit` | Stage + generate + commit | Git commit |
| `/git-setup` | Audit & propose git config | (none) |

### Chat Modes

| Mode | Focus | Output |
|------|-------|--------|
| task-researcher | Deep evidence research | `research/*.md` |
| task-planner | Actionable plan & details | `plans/`, `details/`, `prompts/` |
| prompt-builder | Prompt/instructions authoring | Updated `.github/prompts\|instructions` |
| adr-creation | Architecture decisions | ADR drafts/finals |
| prd-builder | Product requirements | `docs/prds/*.md`, state JSON |
| prd-to-wit | PRD → backlog handoff | Work item handoff JSON/markdown |

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
4. Run `/gen-commit-message` to standardize the commit message.

## FAQ ❓

**Can I reorder or rename folders?**
Yes - just keep the [settings](./.vscode/settings.json) pointing to the right locations so Copilot can find your files. Update the `chat.instructionsFilesLocations` and `chat.promptFilesLocations` accordingly.

**Do I have to use MCP?**
Yes for AzDO prompts/instructions/chatmodes - The AzDO prompts require the Azure DevOps MCP server, but you can use the instruction files and chatmodes without MCP.

**Will this work outside VS Code?**
The [VS Code settings](./.vscode/settings.json) are editor-specific, but the prompts, instructions, and chatmodes are just Markdown files - you can adapt them to other editors or use them manually.

**How do I add my own prompts or instructions?**
Add a `*.prompt.md` to [`.github/prompts/`](./.github/prompts/), a `*.instructions.md` to [`.github/instructions/`](./.github/instructions/), or a `*.chatmode.md` to[`.github/chatmodes/](./.github/chatmodes/). VS Code will automatically discover them.

**What if I don't use Azure DevOps?**
You can adapt the workflow to other project management tools by modifying the prompts and using different MCP servers (GitHub, Jira, etc.).
