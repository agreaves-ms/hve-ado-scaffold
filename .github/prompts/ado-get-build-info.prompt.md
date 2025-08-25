---
mode: "agent"
description: "Retrieve Azure DevOps build metadata and relevant diagnostic logs for either a specific build ID or the latest build of a Pull Request branch; persist summarized status and filtered problem-focused log excerpts to tracking artifacts."
---

# ADO Build Info & Log Extraction (Targeted or Latest PR Build)

**MANDATORY**: Follow all instructions from #file:../instructions/ado-get-build-info.instructions.md

## Inputs

- ${input:project:edge-ai}: Azure DevOps project name or ID (REQUIRED)
- ${input:repository:edge-ai}: Repository name or ID (RECOMMENDED when deriving PR from commit; required if using commit discovery without prId/buildId)
- ${input:prId}: Pull Request numeric ID (OPTIONAL if buildId supplied OR derivable from current commit). Used to derive branchName `refs/pull/${input:prId}/merge`.
- ${input:buildId}: Explicit Build ID to inspect (OPTIONAL). If provided, it TAKES PRIORITY over prId or commit discovery.
- ${input:includeAllLogs:false}: Boolean; when true, persist entire logs (not just filtered excerpts) in addition to summary sections.
- ${input:maxLogLinesPerSection:400}: Cap for lines captured per logical failing section (ignored when includeAllLogs=true).
- ${input:errorContextWindow:40}: Number of context lines (before + after) around each detected error anchor (split as evenly as possible, bias earlier if odd).
- ${input:definitionFilter}: Optional build definition name substring (case-insensitive) to narrow PR build selection when multiple parallel builds exist.
- ${input:branchOverride}: Optional explicit branchName (overrides prId & commit derived branch).
- ${input:fetchSuccessfulLogs:false}: When true, still capture key success indicators (final steps, test summaries) even if Result = Succeeded.
- ${input:logIds}: Optional comma-separated list of specific logId integers to force retrieval focus (used only after metadata enumeration; others skipped unless includeAllLogs=true).
- ${input:autoDiscoverPr:true}: Boolean; when true AND prId & buildId absent, attempt to derive prId via current `mcp_ado_repo_list_pull_requests_by_repo` with `created_by_me` set to `true` and `status` set to `Active`.
- ${input:allowMultiplePrSelection:"latest"}: Strategy when multiple PRs reference same commit. Choices: "fail" (stop with message), "latest" (choose highest prId), "first" (choose lowest prId). Defaults to latest.
- ${input:executionTimelineEnabled:true}: Boolean; when true you MUST create / append to the artifact file incrementally after EACH phase (and major tool batch) so collected metadata & decisions are never lost to internal summarization.
- ${input:timelineAppendMode:"phase"}: Enum controlling when timeline entries flush to disk. Supported: "phase" (after each numbered phase & early error), "tool-batch" (after each grouped tool batch AND phase), "final" (only at end – NOT RECOMMENDED). Default phase. If value not recognized, fall back to phase.
- ${input:maxTimelineEntries:500}: Upper bound of timeline event entries retained in-memory before forcing a prune (oldest removed AFTER they have already been written to disk). This protects memory if very long sessions.

---

Proceed with build retrieval and log extraction by following all phases in order.
