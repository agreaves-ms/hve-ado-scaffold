---
mode: "agent"
description: "Retrieve Azure DevOps build metadata and relevant diagnostic logs for either a specific build ID or the latest build of a Pull Request branch; persist summarized status and filtered problem-focused log excerpts to tracking artifacts."
---

# ADO Build Info & Log Extraction (Targeted or Latest PR Build)

You WILL retrieve Azure DevOps build information and (when needed) diagnostic logs using ONLY these tools:
- mcp_ado_repo_list_pull_requests_by_repo
- mcp_ado_repo_get_repo_by_name_or_id (repository ID resolution when repository name supplied)
- mcp_ado_build_get_builds
- mcp_ado_build_get_log
- mcp_ado_build_get_log_by_id

The goal is to surface the status/result of a target build (explicit buildId or the latest for a PR) and persist a curated log artifact containing only relevant failure / diagnostic segments (unless configured to include all). You MUST follow the phases and rules verbatim.

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

## Core Decision Rules

1. If buildId present -> operate ONLY on that build (skip PR / commit discovery).
2. Else if prId present -> derive branch as `refs/pull/<prId>/merge` (unless branchOverride provided).
3. Else if branchOverride provided -> use it directly (treat as non-PR branch, prId unknown) and SKIP commit discovery.
4. Else if autoDiscoverPr=true ->
  - Resolve repository ID (if repository supplied as name) using mcp_ado_repo_get_repo_by_name_or_id.
  - Attempt to derive prId via current `mcp_ado_repo_list_pull_requests_by_repo` with `created_by_me` set to `true` and `status` set to `Active`, look for pull requests with the current branch.
  - Select single PR per allowMultiplePrSelection strategy; set prId.
  - Derive branch `refs/pull/<prId>/merge`.
5. If after steps above no buildId and no branch resolved -> STOP with message "Unable to resolve branch: provide buildId, prId, branchOverride, or enable autoDiscoverPr with a repo".
6. Locate latest build for resolved branch (most recent finishTime, fallback queueTime) using mcp_ado_build_get_builds.
7. If multiple candidate builds and definitionFilter provided, filter to those whose definition name contains definitionFilter; if still multiple choose latest.
8. If no builds found -> respond with explicit message and stop (no artifact created) after compliance checklist self-eval marking not applicable items.
9. If build found but status indicates still in progress (e.g., not completed) -> capture current metadata; attempt partial logs (only top-level log ids 1..N enumerated) but mark artifact as partial.

## Outputs

You MUST produce (unless no builds found) the following artifacts:

1. Build Summary JSON (inline in conversation) containing: buildId, prId (if any), branchName, status, result, queueTime, startTime, finishTime, definition (id & name), requestedFor (id & displayName), sourceVersion (commit), repository info (if present), keepForever, retainedByRelease, tags, properties for attempt, trigger, and reason if available.
2. Markdown Log Artifact File: `.copilot-tracking/pr/pr-<prId|branch-sanitized>-build-<buildId>-logs.md` containing structured sections (See Log Artifact Structure). If prId unknown (only buildId given) use `no-pr` placeholder: `.copilot-tracking/pr/pr-no-pr-build-<buildId>-logs.md`.
3. Conversation Summary Section: High-level status, path to artifact, counts of extracted error segments, whether truncated by limits, and compliance checklist rendered with boxes.

## Log Artifact Structure

<!-- <log-artifact-structure> -->
````markdown
<!-- markdownlint-disable-file -->
<!-- markdown-table-prettify-ignore-start -->
# Build Log Diagnostic Extraction

## Metadata
- Project: <project>
- PR: <prId or "(none)" >
- Branch: <branchName>
- Build ID: <buildId>
- Definition: <definitionName> (ID <definitionId>)
- Status: <status>
- Result: <result>
- Queue Time: <queueTime>
- Start Time: <startTime>
- Finish Time: <finishTime or pending>
- Source Version: <commit>
- Requested For: <user>
- Tags: tag1, tag2
- Retrieved At (UTC): <timestamp>
- Partial: true|false (true if build still running OR some logs inaccessible)
- includeAllLogs: true|false
- fetchSuccessfulLogs: true|false
- definitionFilter Applied: <filter or "(none)">

## Summary
- Error Segments: <count>
- Warning Segments: <count>
- Total Captured Lines: <count>
- Truncated Segments Due To Limits: <count>
- Targeted Log IDs: [list]

## Failure / Diagnostic Segments
### Segment <n> (logId=<id>, lines=<start>-<end>, type=Error|Warning)
```
<excerpt>
```
(Context reason: <anchor phrase>)

(repeat for each segment)

## Success Indicators (optional)
```
<Selected success lines when fetchSuccessfulLogs or includeAllLogs>
```

## Full Logs (optional when includeAllLogs=true)
### Log <logId>
```
<entire log content>
```

## Extraction Rules Applied
- Patterns: <comma separated list>
- Context Window: <errorContextWindow> (approx split around anchor)
- Max Lines Per Section: <maxLogLinesPerSection>
- Redactions: <summary of any secret-like redactions>

## Execution Timeline (Incremental)
```
<timestamp ISO8601Z> [PHASE-START] Phase 1 Enumerate Candidate Builds
<timestamp ISO8601Z> [TOOL] mcp_ado_build_get_builds branch=refs/pull/123/merge returned=3
<timestamp ISO8601Z> [DECISION] Selected buildId=456 rationale="latest finished"
<timestamp ISO8601Z> [PHASE-END] Phase 2 Select Target Build durationMs=87
<timestamp ISO8601Z> [ERROR] mcp_ado_build_get_log_by_id logId=7 attempt=1 message="HTTP 500" (will retry)
<timestamp ISO8601Z> [RETRY-SUCCESS] mcp_ado_build_get_log_by_id logId=7 attempt=2
<timestamp ISO8601Z> [SEGMENT] logId=12 anchors=error lines=233-260
...
```
Notes:
- This section is APPENDED to *incrementally* during execution – do NOT rewrite prior lines.
- Always open with a header if the file did not previously exist.
- Never duplicate identical consecutive entries.
- Keep each line <= 500 characters; truncate with ellipsis if longer after redaction.
- If pruning due to maxTimelineEntries, write a line: `<timestamp> [PRUNE] Removed X oldest in-memory entries (already persisted).`
- If run terminates early, partial timeline remains valid.

## Compliance Checklist
(duplicated from conversation for traceability)
<!-- markdown-table-prettify-ignore-end -->
````
<!-- </log-artifact-structure> -->

## Phases (Overview)

Update the task list with the following:

0. Resolve Inputs & Branch / Commit Target
0a. (Conditional) Auto-Discover PR From Current Commit
1. Enumerate Candidate Builds
2. Select Target Build
3. Retrieve Build Metadata
4. Enumerate & Plan Log Retrieval
5. Fetch Logs & Detect Segments
6. Persist Markdown Artifact
7. Output Summary & Compliance Self-Check

## Detailed Required Behavior

### 0. Resolve Inputs & Branch / Commit Target

- Validate ${input:project} present.
- Parse booleans & numeric inputs (buildId, prId) robustly.
- Short-circuit if buildId provided (branch may be inferred later) and skip PR/commit discovery.
- Determine if branchOverride provided; if so record it (and skip PR & commit discovery unless buildId also provided).
- If neither buildId nor prId nor branchOverride and autoDiscoverPr=true prepare for Phase 0a.
- Initialize in-memory execution state object (not persisted yet).
- If executionTimelineEnabled=true immediately create (or open existing) artifact file path (even before build selection) and write a minimal header + initial Execution Timeline section header if not present. Record a timeline line `[PHASE-START] Phase 0 Resolve Inputs`.

### 0a. (Conditional) Auto-Discover PR From Current Commit

Only execute when: buildId absent, prId absent, branchOverride absent, autoDiscoverPr=true.

Steps:
- run_in_terminal: `git rev-parse --abbrev-ref HEAD` to capture currentBranch (ignore detached heads; if "HEAD" then also run `git branch --contains HEAD --format='%(refname:short)' | head -n 1`).
- run_in_terminal: `git rev-parse HEAD` to capture commitSha.
- (Optional) run_in_terminal: `git remote get-url origin` (for diagnostics only, not mandatory).
- Ensure repository input present: if repository appears to be a GUID treat as ID; else call mcp_ado_repo_get_repo_by_name_or_id with project & repository to obtain its ID.
- Call mcp_ado_repo_list_pull_requests_by_commits with:
  - project: ${input:project}
  - repository: resolved repository ID
  - commits: [commitSha]
- Filter returned PRs to Active status first; if none Active, consider Completed (still usable for historic build retrieval); ignore Abandoned.
- If zero PRs -> STOP with message "No PRs reference commit <shortSha>; supply prId or branchOverride." (no artifact).
- If multiple PRs after filtering, apply allowMultiplePrSelection strategy:
  - latest: choose highest numeric id
  - first: choose lowest numeric id
  - fail: STOP with message listing PR IDs requiring manual selection.
- Set prId and derived branch `refs/pull/<prId>/merge` and continue.
- Timeline: After successful PR discovery or decision to skip, append `[PHASE-END] Phase 0a Auto-Discover PR` with duration. On multiple PR resolution include selected & strategy in `[DECISION]` line. On failure (no PRs, or fail strategy) append `[ERROR]` line before stopping.

### 1. Enumerate Candidate Builds

- If buildId specified: skip enumeration and proceed to Phase 3.
- Else call `mcp_ado_build_get_builds` with:
  - project: ${input:project}
  - branchName: effective branch (derived earlier)
  - top: (optional) you MAY pass a small number like 10 to limit if tool supports; otherwise rely on API default.
- If zero builds returned -> STOP after producing conversation output: "No builds found for branch <branchName>" plus compliance checklist (mark artifact steps as N/A). Do not create artifact file.
- Collect minimal metadata for each build: id, status, result, finishTime, queueTime, definition name, definition id.
- Timeline: Append `[PHASE-START] Phase 1 Enumerate Candidate Builds` before tool call, and `[TOOL]` line summarizing result count. On zero builds add `[DECISION]` line and proceed to stop logic.

### 2. Select Target Build

- If buildId pre-specified: target = buildId.
- Else choose build whose finishTime is latest (non-null). If all finishTime null (still running), choose one with most recent queueTime.
- If ${input:definitionFilter} provided, filter candidates first (case-insensitive substring match on definition name). If post-filter empty -> revert to unfiltered set with a note that filter produced no matches.
- Record selection rationale in memory (will surface later in Summary).
- Timeline: Append `[PHASE-START] Phase 2 Select Target Build` at start; after selection append `[DECISION] Selected buildId=<id> rationale="<reason>" filtered=<definitionFilterApplied|false>` then `[PHASE-END] Phase 2 Select Target Build`.

### 3. Retrieve Build Metadata

- Use metadata already available from enumeration OR if direct buildId path, call `mcp_ado_build_get_builds` with `buildIds` array containing only that id to obtain details.
- Extract and store fields enumerated in Outputs #1. Missing fields must not be fabricated.
- Determine build problem state: result in {Failed, PartiallySucceeded, Canceled} OR status not completed.
- Timeline: Append `[PHASE-START] Phase 3 Retrieve Build Metadata`; after metadata extraction append `[PHASE-END] Phase 3 Retrieve Build Metadata problemState=<true|false>`.

### 4. Enumerate & Plan Log Retrieval

- If build problem state OR ${input:includeAllLogs} OR ${input:fetchSuccessfulLogs}: proceed.
- Call `mcp_ado_build_get_log` with buildId + project to enumerate logs (this returns content for each log or an index depending on API behavior; treat each top-level log as retrievable by logId with `mcp_ado_build_get_log_by_id`). If tool already returns full text for all logs, still treat each as if individually fetched for filtering.
- Determine list of logIds to fetch:
  - If ${input:logIds} provided: intersect with enumerated ids (preserve specified order).
  - Else all enumerated ids.
- If zero logIds after intersection -> skip log fetching (note in summary) unless includeAllLogs true (then still attempt all enumerated).
- Timeline: Append `[PHASE-START] Phase 4 Enumerate & Plan Log Retrieval` and `[DECISION] PlannedLogIds=[list] (skipped|count=N)` then `[PHASE-END] Phase 4 Enumerate & Plan Log Retrieval`.

### 5. Fetch Logs & Detect Segments

For each planned logId (respect order):
- Fetch content (if not already acquired) with `mcp_ado_build_get_log_by_id` (project, buildId, logId). Use pagination with startLine/endLine if extremely large (Implementation detail: you may attempt full retrieval first; if truncated or size-limited, fall back to chunking with 5000-line windows; mark partial if any chunk fails).
- Scan lines for ANCHOR PATTERNS (case-insensitive regex list below). Each match starts a segment.
- Collect context lines before/after anchored line: half of errorContextWindow before, half after (floor before, ceil after). Ensure boundaries within log.
- Merge overlapping or adjacent segments (<5 line gap) into a single segment.
- Classify segment type: Error if anchor contained error/fail/exception; Warning if only 'warn' matched.
- Truncate each segment to maxLogLinesPerSection (keeping anchor line) unless includeAllLogs true.
- Timeline: For each log fetch append `[TOOL] mcp_ado_build_get_log_by_id logId=<id> lines=<count>`; on failure `[ERROR] ... attempt=1` then if retry succeeds `[RETRY-SUCCESS]` else `[RETRY-FAIL]` and continue. For each detected segment append `[SEGMENT] logId=<id> type=<Error|Warning> lines=<start>-<end> anchors=<matchedTokens>`.

**Anchor Regex Patterns (case-insensitive):**
```
(error|fail|failed|exception|stack trace|traceback|panic:|segmentation fault|unhandled|could not|permission denied|refused|timeout|timed out|ecconnreset|enoent|undefined reference|linker error|build step failed|##\[error\]|##\[warning\]|warn:)
```

### 6. Persist Markdown Artifact

- Construct path using prId if available else "no-pr".
- Write file with Log Artifact Structure ordering.
- Populate segments sequentially with stable numbering.
- Include Extraction Rules Applied section listing patterns & parameters used.
- Duplicate compliance checklist inside artifact (mirrors conversation version) marking states (checked/unchecked) identically at time of writing.
- If executionTimelineEnabled=true you MUST have been appending timeline entries progressively; at this phase only ensure static sections (Metadata, Summary, etc.) are updated/inserted WITHOUT removing prior timeline lines.
- Timeline: Append `[PHASE-START] Phase 6 Persist Artifact` and `[PHASE-END] Phase 6 Persist Artifact` once write complete.

### 7. Output Summary & Compliance Self-Check

- Provide Build Summary JSON inline.
- Provide path to artifact (or note none created).
- Provide counts: segments (error/warning), total captured lines, truncated segments count, whether logs were partial.
- Provide rationale for build selection (if not explicit buildId).
- Render Compliance Checklist with boxes.
- Timeline: Append `[PHASE-START] Phase 7 Output Summary` at start and `[PHASE-END] Phase 7 Output Summary` after checklist. Append final `[COMPLETED] buildId=<id>` line. If stopping early (errors/no builds) append `[TERMINATED] reason="<message>"`.

## Error Handling & Resilience

- Any tool failure: surface raw error immediately, mark remaining unchecked items in checklist, stop further phases.
- If a particular logId retrieval fails: mark partial=true; continue with remaining logIds.
- Retry a failed log fetch once before marking partial.
- If no anchors found and includeAllLogs=false and fetchSuccessfulLogs=false: include a placeholder message in Failure / Diagnostic Segments: "No error or warning anchors detected.".
- If executionTimelineEnabled=true ALWAYS flush (append) a timeline line for any error before aborting so cause is captured.
- If early stop BEFORE build selection still write a minimal artifact containing: header, Execution Timeline (with events so far), and a short note explaining stop reason (unless zero required inputs making even file path ambiguous – then skip file but still output reason).

## Performance & Limits

- Avoid re-fetching same build metadata multiple times; reuse enumeration result.
- Limit large log processing by respecting maxLogLinesPerSection.
- Provide note if total unfiltered log size appears huge (heuristic: > 50k lines across logs) and user did not set includeAllLogs=true.

## Compliance Checklist (Self-Evaluate Before Responding)

<!-- <important-compliance-checklist> -->
- [ ] Inputs resolved & validated
- [ ] Commit & branch discovered (when autoDiscoverPr path taken)
- [ ] Repository ID resolved (when repository name provided)
- [ ] PR(s) enumerated from commit (autoDiscoverPr path)
- [ ] PR selection strategy applied (allowMultiplePrSelection) when multiple PRs
- [ ] Candidate builds enumerated OR buildId path taken
- [ ] Target build selection rationale recorded
- [ ] Build metadata fields extracted (no fabrication)
- [ ] Problem state correctly determined
- [ ] Logs enumeration executed when required
- [ ] Planned logId list derived (respecting logIds filter)
- [ ] Each fetched log scanned with anchor patterns
- [ ] Segments merged & truncated per rules
- [ ] Artifact file written (or explicitly skipped if none)
- [ ] Summary JSON produced inline
- [ ] Segment counts & truncation reported
- [ ] Partial flag set correctly when applicable
- [ ] Checklist duplicated inside artifact
- [ ] No disallowed tools used
- [ ] Execution timeline section initialized (when enabled)
- [ ] Timeline appended after each phase (when enabled)
- [ ] Timeline captured tool batches & decisions
- [ ] Timeline flushed on errors / early termination
- [ ] Timeline pruning respected (if max exceeded)
<!-- </important-compliance-checklist> -->

---

Proceed with build retrieval and log extraction by following all phases in order.
