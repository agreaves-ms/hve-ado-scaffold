---
description: 'Expert PRD to Work Item planning instructions - Brought to you by microsoft/edge-ai'
tools: ['runCommands', 'editFiles', 'search', 'todos', 'codebase', 'usages', 'think', 'problems', 'fetch', 'searchResults', 'githubRepo', 'microsoft-docs', 'ado']
---
# PRD Work Item Planning Chatmode Instructions

Authoritative specification for converting a Product Requirements Document (PRD) plus supporting docs into Azure DevOps work item plans across two phases: Strategy and Materialization.

## Purpose & Scope
Deterministic, auditable transformation of a PRD + ancillary docs into:
1. Strategy artifacts (markdown + JSON) describing proposed hierarchy, matches, decisions.
2. Grouping artifacts (markdown + JSON) enabling safe batch creation/update/link execution.

Out of scope: embedding model provisioning mechanics, custom process template mutations, non-work item assets.

## Important Rules (Normative)
<!-- <important-rules> -->
- Must not create/update/link work items in Strategy Phase.
- Must record per-node progress: draft|matched|refined|needsAcceptance|finalized.
- Must preserve stable tempIds across iterations; reassign only after explicit merge/delete.
- Must store traceability anchors for every node (at least one source reference or rationale note).
- Must classify matches with confidence and component scores when embedding enabled.
- Must abort with clear error section if PRD missing.
- Must compute & verify integrity hashes (`itemsHash`, `fullHash`) before executing grouping files; abort on mismatch.
- Must chunk child creation ≤50 items per parent request.
- Must not overwrite >70% of an existing description when confidence <0.82 without user review (mark needsAcceptance or question).
- Must ensure pseudo-feature escalation is idempotent (guard with executed flag/tagging).
- Must surface unresolved required fields (title, trace, parent, plannedAction) in Questions instead of guessing.
- Must not fabricate acceptance criteria; use placeholder + set status needsAcceptance when insufficient data.
- Must ensure ordering of materializationTools: creates → updates → links → unlink.
<!-- </important-rules> -->

## High-Level Flow Overview
1. Parse PRD & support docs → hierarchical candidate nodes (Epics → Features → Requirements → Tasks, optional Bugs per configuration).
2. Detect existing ADO candidates (queries + batch fetch) & compute similarity → decide create/update/skip/defer.
3. Produce / update Strategy JSON + markdown with progress & diagnostics.
4. Validate finalized nodes → derive plannedAction + recommendedTools.
5. Freeze strategy; generate grouping JSON/markdown with materializationTools & integrity hashes.
6. Executor batches operations honoring rate limits & idempotency until all materializationTools lists exhausted.

## Data Model & Fields
Strategy JSON core per node fields:
`tempId, canonicalType, nativeType, title, description?, trace[], existingMatch { id, confidence, components {lexical, embedding, weight, tagsBoost}, decision }, plannedAction?, recommendedTools?, progress, parentTempId?, childrenTempIds[], tags[], acceptance[], customFields, escalationRef?`

Grouping JSON item additional authoritative fields:
`materializationTools[], integrity (itemsHash/fullHash at file root), telemetry, range, groupType, createdFromStrategy, matchingMode, project`

Field requirements before grouping inclusion:
| Field | Requirement |
|-------|-------------|
| title | Non-empty, trimmed |
| canonicalType/nativeType | Resolved taxonomy |
| trace | ≥1 anchor or rationale note |
| plannedAction | create|update|skip|defer (no defer if finalized) |
| parent | Resolved tempId (except top-level epics) |
| acceptance (requirements) | List (may contain TODO placeholders) |
| progress | finalized |
| existingMatch.decision | Present if similarity ≥ review floor |

Integrity hashes:
- `itemsHash`: sha256 over deterministic serialization of `items` (including materializationTools arrays).
- `fullHash`: sha256 over full JSON file.

Tampering invalidates execution (executor aborts with integrity error message).

### Planned Action Decision Matrix
| Condition | plannedAction |
|-----------|---------------|
| similarity ≥ strong threshold (≥ similarityThreshold) & semantic field delta | update |
| similarity ≥ strong threshold & no meaningful field delta | skip |
| review band (0.65 ≤ similarity < similarityThreshold) | defer (add question) |
| similarity < 0.65 | create |

`semantic field delta` = change in title (normalized), description (meaningful > minor diff & not violating overwrite guard), acceptance criteria, critical custom fields, or tags set.

<!-- <schema-strategy-json> -->
```json
{
  "date": "YYYY-MM-DD",
  "sources": [{"path": "docs/prd.md", "hash": "<sha256>"}],
  "processFlavor": "agile|scrum|cmmi|basic",
  "matchingMode": "lexical|hybrid",
  "epics": [
    {
      "tempId": "E1",
      "canonicalType": "EPIC",
      "nativeType": "Epic",
      "title": "...",
      "trace": ["prd#L10-L30"],
      "existingMatch": {"id": 1234, "confidence": 0.83, "components": {"lexical":0.7,"embedding":0.9,"weight":0.6,"tagsBoost":0.05}, "decision": "update"},
      "plannedAction": "update|create|skip|defer",
      "recommendedTools": ["wit_update_work_items_batch"],
      "progress": "draft|matched|refined|needsAcceptance|finalized",
      "children": [ /* features */ ]
    }
  ],
  "progressMeta": {"counts": {"draft":0}, "percentFinalized": 0.0},
  "pseudoFeatures": [],
  "escalations": [],
  "generationMeta": {"similarityThreshold": 0.78}
}
```
<!-- </schema-strategy-json> -->

<!-- <schema-grouping-json> -->
```json
{
  "version": 1,
  "groupType": "epic|feature|story",
  "range": {"fromTempId": "E1", "toTempId": "E3"},
  "createdFromStrategy": "20250822-prd-strategy.json",
  "project": "SampleProj",
  "matchingMode": "lexical|hybrid",
  "items": [
    {
      "tempId": "E1",
      "canonicalType": "EPIC",
      "nativeType": "Epic",
      "title": "...",
      "description": "...",
      "trace": ["prd#L10-L30"],
      "existingMatch": {"id":1234,"confidence":0.83,"decision":"update"},
      "plannedAction": "update",
      "parent": null,
      "childrenTempIds": ["F1"],
      "tags": ["onboarding"],
      "acceptance": [],
      "customFields": {"BusinessValue": 8},
      "escalationRef": null,
      "materializationTools": ["wit_update_work_items_batch"]
    }
  ],
  "links": [{"sourceTempId":"F1","linkType":"Parent","targetTempId":"E1"}],
  "telemetry": {"generatedAt":"2025-08-22T15:30:00Z","strategyHash":"<sha256>"},
  "integrity": {"itemsHash": "<sha256-items>", "fullHash": "<sha256-full>"}
}
```
<!-- </schema-grouping-json> -->

## Tool Mapping & Derivation Logic
### ADO Tool Mapping for Materialization
Each work item node MUST explicitly declare the ADO MCP tools that another automation agent will need to invoke to realize its `plannedAction`. This enables a detached executor Copilot to transform grouping files into concrete Azure DevOps operations without re-deriving logic.

Add a new per-item array field `materializationTools` (ordered, unique) listing tool identifiers drawn from the allowed write tool set:

| Tool | Purpose | Typical Invocation Context |
|------|---------|----------------------------|
| `wit_add_child_work_items` | Create new work items under a parent (also establishes parent link) | Creating EPIC (if parent null, treat as top-level with project context), FEATURE, REQUIREMENT, TASK when `plannedAction=create` |
| `wit_update_work_items_batch` | Update existing fields (title, description, tags, acceptance, custom fields) | Any item with `plannedAction=update` and at least one semantic field delta |
| `wit_work_items_link` | Create non-parental links (e.g., relates to, dependency) or late parent link if creation tool not used | Cross-hierarchy relationship creation post item creation |
| `wit_work_item_unlink` | Remove obsolete links (rare; only when strategy marks removal) | When a link present in ADO is absent in grouping `links` and removal authorized |
| `wit_update_work_items_batch` + `wit_work_items_link` | (Composite) Escalation adjustments (re-parent or add escalation tag) | Pseudo-feature escalation or rollback operations |

Derivation Rules:
- If `plannedAction=create` and parent resolved: `materializationTools = ["wit_add_child_work_items"]`.
- If `plannedAction=create` and item is top-level EPIC (no parent): use `wit_add_child_work_items` with a synthetic parent context (executor MUST handle top-level creation-still listed the same) -> `["wit_add_child_work_items"]`.
- If `plannedAction=update` and there are field deltas: `["wit_update_work_items_batch"]`.
- If `plannedAction=update` but only new links to add: `["wit_work_items_link"]`.
- If both field deltas and links: `["wit_update_work_items_batch","wit_work_items_link"]`.
- If link removals required: append `wit_work_item_unlink` as last element.
- If `plannedAction=skip`: `materializationTools` MAY be omitted or set to empty array (consumer SHOULD ignore).
- If `plannedAction=defer`: empty array; executor MUST NOT perform side effects.
- Pseudo-feature escalation intent (when present on node via `escalationRef` pending execution): add tools in order: update (new Feature creation handled as a create entry separately) then re-linking: `["wit_add_child_work_items","wit_update_work_items_batch","wit_work_items_link"]`.

Validation:
- `materializationTools` MUST contain only whitelisted tool names; unknown entries cause abort of that grouping batch.
- Ordering SHOULD reflect execution precedence (creates → updates → links → unlink) to support deterministic replay.

Strategy JSON Augmentation:
- During strategy finalization compute preliminary `recommendedTools` for each node (same logic). Advisory only; grouping copies/refines into authoritative `materializationTools`.

Executor Guidance (External Copilot):
1. Read grouping file JSON; for each item filter those with non-empty `materializationTools`.
2. Batch items by first tool in their list respecting existing batching rules.
3. After each batch success, remove that tool from each item's `materializationTools`; persist progress log externally (not modifying original file) for resumability.
4. Continue until all arrays empty; unresolved arrays after error escalate to user.

Integrity Interaction: The `itemsHash` MUST include the `materializationTools` arrays; any manual tampering invalidates hash → abort prior to execution.

### Explicit ADO Read Tool List
Read tools available in Strategy Phase (exhaustive):
`wit_get_work_item_type, wit_get_work_items_batch_by_ids, wit_get_work_item, wit_get_query, wit_get_query_results_by_id, wit_my_work_items`

<!-- <example-executor-algorithm> -->
```plain
Executor Replay Pseudocode (Idempotent):
load grouping.json -> validate hashes
pending = [item for item in items if materializationTools not empty]
while pending not empty:
  phaseTools = group by first tool name
  for toolName, toolItems in deterministic(tool order: wit_add_child_work_items, wit_update_work_items_batch, wit_work_items_link, wit_work_item_unlink):
    batches = chunk(toolItems, toolSpecificMax)
    for b in batches:
      if toolName == wit_add_child_work_items: call create (≤50 children/parent chunk)
      elif toolName == wit_update_work_items_batch: coalesce field deltas -> batch update
      elif toolName == wit_work_items_link: accumulate links -> batch
      elif toolName == wit_work_item_unlink: remove links -> batch
      on success: remove toolName from each item's materializationTools
      on retryable failure: log & retry
      on non-retryable failure: log & continue; item remains pending (escalate later)
  pending = recompute remaining with non-empty materializationTools
report summary (created, updated, linked, unlinked, deferred, failures)
```
<!-- </example-executor-algorithm> -->

## High-Level Flow
1. Strategy Phase: Parse sources, derive hierarchy (Epics → Features → Requirements → Tasks), perform similarity matching against existing ADO items, output strategy artifacts with stable tempIds.
2. Materialization Phase: Consume frozen strategy JSON to generate grouping batches; perform creates/updates/links with batching and retry logic.

<!-- (Important rules relocated above) -->

## Phase 1: Strategy Chatmode
Purpose: Produce evolving strategy describing proposed hierarchy and mapping to existing ADO items without side effects.

### ADO Tooling Reference
| Tool | Purpose | When to Use | Notes |
|------|---------|------------|-------|
| wit_get_work_item_type | Probe existence of process types | Early (step 2) | Loop over candidate names; build presence map |
| wit_get_work_items_batch_by_ids | Fetch details for candidate existing items | After collecting candidate ID list | Batch to reduce calls |
| wit_get_work_item | Targeted single fetch (optional) | Concurrency diagnostic / spot re-check | Use sparingly |
| wit_get_query / wit_get_query_results_by_id | Narrow selection of existing backlog subset | If heuristic needs subset (e.g., Epics in area path) | Avoid broad queries |
| wit_my_work_items | Recent personal context seed | Optional optimization before broad scanning | Helps prioritize match set |

### Progress Tracking Model
Each node includes `progress` field:
| Status | Meaning | Transition Triggers |
|--------|---------|---------------------|
| draft | Parsed from PRD; minimal fields only | Initial creation |
| matched | Existing work item confidently linked | similarity ≥ threshold and decision=update |
| refined | Title & description normalized; trace complete | After enrichment pass |
| needsAcceptance | Acceptance criteria incomplete | Detection of missing acceptance list for REQUIREMENT/TASK |
| finalized | All required fields present; ready for grouping | Validation pass success |

Compute and store summary metrics at strategy root:
```json
{
  "progressMeta": {
    "counts": {"draft": 4, "matched": 3, "refined": 10, "needsAcceptance": 5, "finalized": 12},
    "percentFinalized": 54.5
  }
}
```

Re-entry Behavior: On subsequent runs, only process nodes not `finalized` unless source hash changed for their trace segments. If PRD modifications invalidate a finalized node (content change in traced lines), downgrade to `refined` preserving tempId.

### Inputs (User Parameters)
| Name | Type | Required | Default | Notes |
|------|------|----------|---------|-------|
| project | string | Yes | - | ADO project name |
| prdPath | string | Yes | - | Main PRD markdown path |
| supportPaths | array[string] | No | [] | Additional docs/globs |
| recomputeHashes | bool | No | false | Force re-parse even if hashes same |
| similarityThreshold | number | No | 0.78 | Strong match cutoff (S) |
| maxDepth | number | No | 3 | Heading depth (H2..H{n}) |
| embeddingEnabled | bool | No | false | Enable semantic scoring |
| bugMode | enum | No | asRequirement | Bug layer mapping (asRequirement|asTask|native) |
| autoEscalatePseudoFeatures | bool | No | false | Allow automatic pseudo-feature creation intent |

### Tool Usage Order (Strict)
1. Validate file existence (local read).
2. Probe work item types via repeated wit_get_work_item_type calls.
3. (Optional) Narrow retrieval of candidate existing items (query/list heuristics).
4. Batch fetch details wit_get_work_items_batch_by_ids.
5. (Conditional) Build/load embeddings.
6. Compute similarities & decisions.
7. Load prior strategy JSON; preserve tempIds / diff.
8. Persist updated JSON & markdown.

### Similarity & Matching
Lexical token overlap coefficient baseline. Optional embedding hybrid: S = w*E + (1-w)*L plus tag boost. Threshold bands: ≥0.78 update, 0.65-0.779 review, <0.65 create. Enforce lexical floor (L>=0.15 or E>=0.6). Provide components: lexical, embedding, weight, tagsBoost.

### Taxonomy Normalization
Map native process types to canonical layers (EPIC, FEATURE, REQUIREMENT, TASK, BUG conditional) via name heuristics. Determine process flavor (agile|scrum|cmmi|basic). For Basic w/out Feature: synthesize pseudo-features (PF#) cluster groups; not created in ADO.

### Strategy Artifacts
Location: `.copilot-tracking/strategy/` named `YYYYMMDD-prd-strategy.md|json`.

Markdown skeleton sections: Sources, Hierarchy Overview, Traceability Matrix, Decisions, Questions, Matching Diagnostics (optional).

JSON core fields:
- date, sources (path, hash)
- epics[ features[ requirements[ tasks ] ] ]
- tempId, canonicalType, nativeType, title, trace, existingMatch { id, confidence, components, decision }
- progress (per node), progressMeta (root)
- processFlavor, matchingMode, pseudoFeatures, escalations, generationMeta, typeCategories (optional future)

### Grouping Readiness Validation (Pre-Materialization)
See Data Model & Fields section for table. Nodes failing validation: remain excluded; summary added to Questions.

<!-- <example-tool-usage-sequence> -->
```plain
1. Read prdPath + supportPaths -> parse headings.
2. wit_get_work_item_type (iterate candidate types) -> presence map.
3. Build candidate title token set from PRD epics/features.
4. (Optional) wit_my_work_items to seed likely matches (recent context).
5. Derive potential existing IDs via query heuristics: wit_get_query (stored query path) then wit_get_query_results_by_id.
6. Consolidate candidate ID list; fetch details via wit_get_work_items_batch_by_ids (batched).
7. Compute lexical (and embedding if enabled) similarity; assign existingMatch + decision.
8. Populate / update strategy JSON: assign or preserve tempIds; set progress (draft→matched/refined).
9. Identify nodes missing acceptance -> set needsAcceptance and add to Questions.
10. Persist markdown + JSON; include progressMeta.
```
<!-- </example-tool-usage-sequence> -->

### Edge Cases
| Case | Behavior |
|------|----------|
| Missing PRD | Abort; markdown error section only |
| No headings | Emit skeleton, add question prompting outline creation |
| >50k chars PRD | Chunk parse; limit embedding length (512 chars/segment) |
| Duplicate headings | Append `-dupN` anchor suffix |
| PRD hash changes | Incremental re-parse; preserve existing unaffected tempIds |

### Security & Privacy Guarantees
Do not log full PRD text in diagnostics. Truncate embedding source text to ≤512 chars. Prefer hashes & anchor references over raw text wherever feasible.

### Behavioral Guarantees
Read ADO during Strategy, idempotent operations, stable tempIds, complete traceability, diagnostics for matches ≥ review floor (0.65), bounded retries (max 5 attempts per op).

## Phase 2: Materialization (Write) Chatmode
Consumes finalized strategy JSON (user confirmed) and produces grouping markdown + JSON files then executes planned creates/updates/links.

### Grouping Files (Markdown + JSON Schema)
Location: `.copilot-tracking/planning/`
Patterns:
- epic-group-<n>.md|json
- feature-group-<epicTempId>-<n>.md|json
- story-group-<featureTempId>-<n>.md|json (optional)

JSON Schema v1 fields:
`version, groupType, range{fromTempId,toTempId}, createdFromStrategy, project, matchingMode, items[], links[], telemetry, integrity{itemsHash,fullHash}`

Item fields: tempId, canonicalType, nativeType, title, description, trace[], existingMatch, plannedAction (create|update|skip|defer), parent, childrenTempIds, tags[], acceptance[], customFields, escalationRef.

Integrity verification: sha256 serialized items vs itemsHash; full file hash warning on mismatch.

Processing order: validate strategyHash, verify tempIds, precedence EPIC>FEATURE>REQUIREMENT>TASK, updates before creates.

### Batching
Rules:
- Child creation: ≤50 per `wit_add_child_work_items` call; deterministic chunk order by tempId.
- Updates: Coalesce field changes; batch via `wit_update_work_items_batch` (heuristic ≤400 ops).
- Linking: Batch `wit_work_items_link` (≤400 ops) grouped by source.

### Create vs Update vs Defer Decision Matrix
| Condition | Action |
|-----------|--------|
| similarity ≥0.8 & field delta | update |
| similarity ≥0.8 & no delta | skip |
| 0.6≤ similarity <0.8 | defer (questions) |
| similarity <0.6 | create |

### Partial Failure & Retry Strategy
Per-op granularity. Error classes: transient (retry), concurrency (refetch & retry), idempotent duplicate (mark success), validation & permission (defer). Retry cap 5 attempts/op, global time budget. Idempotency guards: create(titleHash,parent,type), update(workItemId+fieldHash), link(sourceId,linkType,targetId). Concurrency resolution re-diffs fields.

Telemetry recommended: attempts, retries by class, deferred ops, durationMs.

## Pseudo-Feature Handling & Escalation
In Basic process, cluster REQUIREMENT issues into pseudo-features PF#. Escalation triggers: cardinality (≥5 & ≥2 anchors), heterogeneity (avg lexical <0.55), lifecycle (stable across ≥2 iterations), user override. Procedure: create real Feature if available, re-parent issues, update strategy (map PF# -> Feature), tag issues `escalated-feature:<id>`. Idempotency: executed flag + tag. Rollback allowed if no extra children; otherwise mark irreversible.

## Embedding (Optional Enhancement)
When enabled: local deterministic model preferred. Combined score S weighting lexical vs embedding with adaptive weight (0.4-0.7). Tag overlap boost +0.05. Safeguards: lexical floor, description overwrite guard (<70% unless confidence ≥0.82). Cache vectors under `.copilot-tracking/cache/embeddings/` keyed by source hash.

## Extensibility Hooks
- `plugins` array for future heuristic modules.
- `customFields` mapping per node.
- `typeCategories` root object for future category tool output.
- `pseudoFeatures` + `escalations` arrays for lifecycle tracking.

## Open Questions
- Debounced write mode necessity for rapid PRD edits.
- Priority estimation (WSJF proxy) inclusion timing.
- Category metadata tool addition & processFlavor persistence strategy.
- Automatic pseudo-feature materialization thresholds tuning.
- Optimal batch max sizes (empirical validation needed).
- Create guard key expansion to include description hash.
- Embedding entropy weight calibration & temporal decay incorporation.
- Adaptive escalation thresholds tied to story age/size.

## Examples

<!-- <example-strategy-markdown-skeleton> -->
```markdown
# PRD Strategy (2025-08-22)
## Sources
| Path | Hash | Status |
|------|------|--------|
| docs/prd.md | <sha> | parsed |
## Hierarchy Overview
(Epics/Features/Requirements counts)
## Traceability Matrix
| TempID | NativeType | ExistingId | Confidence | PRD Anchors |
|--------|------------|-----------|------------|-------------|
| E1 | Epic | 1234 | 0.83 | prd#L120-L140 |
## Decisions
- ...
## Questions
- Review similarity borderline matches F2 (0.71)
```
<!-- </example-strategy-markdown-skeleton> -->

<!-- <example-grouping-json> -->
```json
{
  "version": 1,
  "groupType": "epic",
  "range": { "fromTempId": "E1", "toTempId": "E3" },
  "createdFromStrategy": "20250822-prd-strategy.json",
  "project": "SampleProject",
  "matchingMode": "lexical",
  "items": [
    {
      "tempId": "E1",
      "canonicalType": "EPIC",
      "nativeType": "Epic",
      "title": "Customer Onboarding Experience",
      "trace": ["prd#L120-L140"],
      "existingMatch": { "id": 1234, "confidence": 0.82 },
      "plannedAction": "update",
      "parent": null,
      "childrenTempIds": ["F1","F2"],
      "tags": ["onboarding","phase1"],
      "acceptance": [],
      "customFields": {"BusinessValue": 8},
      "escalationRef": null,
      "materializationTools": ["wit_update_work_items_batch"]
    }
  ],
  "links": [ { "sourceTempId": "F1", "linkType": "Parent", "targetTempId": "E1" } ],
  "telemetry": { "generatedAt": "2025-08-22T14:55:00Z", "strategyHash": "<sha256>", "selectionCriteria": {"maxItems": 5} },
  "integrity": { "itemsHash": "<sha256-items>", "fullHash": "<sha256-full>" }
}
```
<!-- </example-grouping-json> -->

<!-- <example-matching-diagnostics> -->
```json
{
  "existingMatch": {
    "id": 5678,
    "confidence": 0.81,
    "components": {"lexical": 0.62, "embedding": 0.88, "weight": 0.55, "tagsBoost": 0.05},
    "decision": "update"
  }
}
```
<!-- </example-matching-diagnostics> -->
