# Hyper-Velocity Engineering (HVE) ADO Scaffold 🚀

This project is a lightweight scaffold to supercharge your GitHub Copilot workflows with Azure DevOps (AzDO): pull your @Me work items, summarize them with repo context, plan your next move, and start building!

Use it as-is or copy the bits you need into your own repo.

## Quick start 🏁

1. Clone the repo
   - You can work directly in this scaffold or copy the pieces into your own repo.

2. VS Code setup
   - This repo includes helpful workspace settings in [`.vscode/settings.json`](./.vscode/settings.json) that wire Copilot Chat to read instruction files and prompts in this repo.
   - Recommended: add and copy over the MCP server config ([`.vscode/mcp.json`](./.vscode/settings.json)) for connecting Copilot Chat to external tools, such as AzDO.

3. Try the built-in prompts, instructions, and chatmodes
   - Open Copilot Chat and run the prompts from [`.github/prompts`](./.github/prompts/) (details below) to fetch and summarize your AzDO work items.

## What's in the box 📦

Here are the key parts and why you'd want them:

### VS Code settings ⚙️

- [`.vscode/settings.json`](./.vscode/settings.json)
  - Enables Copilot Chat settings for this project and sets up auto-linting and auto-formatting, key parts to look at:

    ```json
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
        - Task Planner generates prompts and instructions under .copilot-tracking
        - Framework specific grouping for instructions files
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

- **🔷 Azure DevOps MCP Server** (`@modelcontextprotocol/server-azure-devops`)
  - Enables work item retrieval, querying, and management directly from Copilot Chat
  - Required for the AzDO workflow prompts to function
  - Supports custom WIQL queries and work item operations
  - Refer to [azure-devops-mcp troubleshooting guide](https://github.com/microsoft/azure-devops-mcp/blob/main/docs/TROUBLESHOOTING.md) for troubleshooting issues

- **📚 Microsoft Docs MCP Server** (`@modelcontextprotocol/server-microsoft-docs`)
  - Provides access to official Microsoft documentation and Azure docs
  - Enables real-time documentation lookup during development

#### Security considerations

- **Never commit `.vscode/mcp.json`** with real credentials
- Use environment variables or `inputs` for sensitive data like PATs

### Copilot Prompts (.github/prompts) for AzDO 🔧

Located in [`.github/prompts/`](./.github/prompts/) - these are ready-to-run, task-focused prompts you can invoke from Copilot Chat.

- [`get-my-work-items.prompt.md`](./.github/prompts/get-my-work-items.prompt.md):
  - *Usage, `/get-my-work-items`*
  - Retrieves your prioritized AzDO work items and saves a raw JSON snapshot under `.copilot-tracking/workitems/`.
  - Honors a saved server-side query if you provide one; falls back to AzDO's assigned-to-me results when you don't.
  - **Requires**: Azure DevOps MCP server configured pointing at the correct AzDo instance.

- [`summarize-my-work-items.prompt.md`](./.github/prompts/summarize-my-work-items.prompt.md):
  - Usage, `/summarize-my-work-items`
  - Reads the latest raw JSON and produces a concise, resumable summary (Markdown + JSON), enriched with repository file context.
  - Designed to hand off into a deeper research chatmode you can add later if desired.

- [`gen-commit-message.prompt.md`](./.github/prompts/gen-commit-message.prompt.md): Usage `/gen-commit-message`
  - Generates clean, Conventional Commit messages based on staged changes.

Why these prompts? They create a simple "pull → understand → plan → build → commit" loop you can use day-to-day.

### Copilot Chat Modes (.github/chatmodes) for workflow automation 🤖

Located in [`.github/chatmodes/`](./.github/chatmodes/) - these are specialized AI assistants that guide complex workflows.

- [`task-researcher.chatmode.md`](./.github/chatmodes/task-researcher.chatmode.md):
  - *Usage, select `task-researcher` from chat mode drop-down*
  - Deep research specialist for comprehensive project analysis and documentation.
  - Creates evidence-based research documents under `.copilot-tracking/research/`.
  - Validates findings from multiple sources and consolidates into actionable guidance.

- [`task-planner.chatmode.md`](./.github/chatmodes/task-planner.chatmode.md):
  - *Usage, select `task-planner` from chat mode drop-down*
  - Creates actionable implementation plans based on verified research findings.
  - Generates plan checklists, implementation details, and prompts under `.copilot-tracking/`.
  - Ensures comprehensive research exists before any planning activity.

- [`adr-creation.chatmode.md`](./.github/chatmodes/adr-creation.chatmode.md):
  - *Usage, select `adr-creation` from chat mode drop-down*
  - Assists with creating Architecture Decision Records (ADRs).
  - Uses the ADR template from [`docs/solution-adr-library/`](./docs/solution-adr-library/).

- [`prompt-builder.chatmode.md`](./.github/chatmodes/prompt-builder.chatmode.md):
  - *Usage, select `prompt-builder` from chat mode drop-down*
  - Helps create custom prompts and instructions for your specific workflows.

Why chat modes? They provide specialized expertise for different phases of development work, ensuring consistent, high-quality outputs.

### Instruction files (what guides Copilot) 🧭

Located in [`.github/instructions/`](./.github/instructions/) - these shape how Copilot behaves when generating content.

- [`commit-message.instructions.md`](./.github/instructions/commit-message.instructions.md)
  - Conventional Commit rules and examples; used by the commit message prompt.
- [`markdown.instructions.md`](./.github/instructions/markdown.instructions.md)
  - Markdown style guide used by markdownlint and by Copilot when drafting docs.
- [`task-implementation.instructions.md`](./.github/instructions/task-implementation.instructions.md)
  - For progressive task execution and change logging in `.copilot-tracking/**` (useful for larger feature work tracked across steps).
- [`csharp/`](./.github/instructions/csharp/) folder
  - [`csharp.instructions.md`](./.github/instructions/csharp/csharp.instructions.md) and [`csharp-tests.instructions.md`](./.github/instructions/csharp/csharp-tests.instructions.md) define coding and testing conventions if you build C# projects here.

### Docs you can reuse 📚

- [`docs/solution-adr-library/adr-template-solutions.md`](./docs/solution-adr-library/adr-template-solutions.md)
  - A practical ADR template with a YAML drafting guide to speed up architecture decisions.
  - Works seamlessly with the `adr-creation.chatmode.md` for guided ADR creation.

## Recommended setup in your repo 🔧

If you're copying things into a different repository:

1. Copy [`.vscode/settings.json`](./.vscode/settings.json) so Copilot Chat discovers your prompts/instructions.
2. Copy [`.vscode/mcp.json`](./.vscode/mcp.json) so Copilot Chat has required external tools; **keep secrets out of source control**.
3. Copy [`.github/instructions/`](./.github/instructions/), [`.github/prompts/`](./.github/prompts/), and [`.github/chatmodes/`](./.github/chatmodes/) directories.
4. Copy [`docs/solution-adr-library/`](./docs/solution-adr-library/) for the ADR template.

Tip: You can start simple-use the prompts and instructions as-is-and grow over time.

## How to use the AzDO workflow 🧵

Here's a typical flow you can drive completely from Copilot Chat:

### 1. 🔍 Get your work items

- **Action**: Run `/get-my-work-items` in Copilot Chat
- **Outcome**: Raw JSON saved under `.copilot-tracking/workitems/YYYYMMDD-assigned-to-me.raw.json`
- **Prerequisites**: Azure DevOps MCP server configured with valid PAT

### 2. 📋 Summarize and pick next task

- **Action**: Run `/summarize-my-work-items` in Copilot Chat
- **Outcome**:
  - `YYYYMMDD-assigned-to-me.summary.md` with prioritized work items
  - `YYYYMMDD-assigned-to-me.summary.json` with structured data
  - "Top Recommendation" and handoff payload for deep research

### 3. 🔬 Research and plan

- **Action**: Use `#file:task-researcher.chatmode.md` for deep analysis
- **Outcome**: Comprehensive research document under `.copilot-tracking/research/`
- **Next**: Use `#file:task-planner.chatmode.md` to create implementation plans

### 4. ⚡ Implement

- **Action**: Follow the generated implementation prompts from `.copilot-tracking/prompts/`
- **Tracking**: Changes logged progressively in `.copilot-tracking/changes/`

### 5. ✅ Commit cleanly

- **Action**: Stage your changes, then run `/gen-commit-message` in Copilot Chat
- **Outcome**: Clean, Conventional Commit message ready to use

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

## Contributing 🤝

This is a scaffold-tweak it freely. If you find a great prompt or instruction tweak, consider standardizing it here first, then copy it to your repo.

---

Happy shipping! 🏎️
