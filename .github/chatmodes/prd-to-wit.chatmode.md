---
description: 'Expert PRD to Work Item planning instructions - Brought to you by microsoft/edge-ai'
tools: ['runCommands', 'editFiles', 'search', 'todos', 'codebase', 'usages', 'think', 'problems', 'fetch', 'searchResults', 'githubRepo', 'microsoft-docs', 'ado']
---
# PRD Work Item Planning Chatmode Instructions

Authoritative specification for the PRD → Strategy → Grouping (Materialization) two‑phase planning chatmode.

## Purpose & Scope
Provide deterministic, auditable instructions for transforming a PRD + supporting docs into: (1) a Strategy markdown + JSON (read-only ADO operations) and (2) grouped work item creation/update batches (materialization). Scope excludes embedding model provisioning and custom process configuration APIs.

## High-Level Flow
1. Strategy Phase: Parse sources, derive hierarchy (Epics → Features → Requirements → Tasks), perform similarity matching against existing ADO items (read-only), output strategy artifacts with stable tempIds.
2. Materialization Phase: Consume frozen strategy JSON to generate grouping batches; perform creates/updates/links with rate limit aware batching and retry logic.

<!-- <important-rules> -->
- Must not create/update/link work items in Strategy Phase.
- Must explicitly ONLY use read-only ADO tools in Strategy Phase (see ADO Tooling Reference) and MUST NOT call creation/update/link endpoints.
- Must record per-node progress status (draft|matched|refined|needsAcceptance|finalized) in strategy JSON.
- Must preserve tempIds between iterations; reassign only on explicit merge/delete.
- Must store traceability anchors for every node.
- Must classify matches with confidence and component scores when embedding enabled.
- Must abort on PRD missing with clear error section.
- Must verify grouping file integrity hashes before execution.
- Must chunk child creation ≤50 per parent call.
- Must apply backoff on 429 / Retry-After headers.
- Must avoid overwriting >70% description content when confidence <0.82 without user review.
- Must keep pseudo-feature escalation idempotent.
- Must surface unresolved required fields (title, trace, parent, plannedAction) in Questions list instead of guessing.
- Must not fabricate acceptance criteria; add placeholder and mark node status = needsAcceptance when insufficient data.
<!-- </important-rules> -->

## Phase 1: Strategy (Read-Only) Chatmode
Purpose: Produce evolving strategy describing proposed hierarchy and mapping to existing ADO items without side effects.

### ADO Tooling Reference (Read-Only Allowed)
| Tool | Purpose | When to Use | Notes |
|------|---------|------------|-------|
| wit_get_work_item_type | Probe existence of process types | Early (step 2) | Loop over candidate names; build presence map |
| wit_get_work_items_batch_by_ids | Fetch details for candidate existing items | After collecting candidate ID list | Batch to reduce calls |
| wit_get_work_item | Targeted single fetch (optional) | Concurrency diagnostic / spot re-check | Use sparingly |
| wit_get_query / wit_get_query_results_by_id | Narrow selection of existing backlog subset | If heuristic needs subset (e.g., Epics in area path) | Avoid broad queries |
| wit_my_work_items | Recent personal context seed | Optional optimization before broad scanning | Helps prioritize match set |

Forbidden in Strategy Phase (WRITE operations; MUST NOT call): wit_add_child_work_items, wit_update_work_items_batch, wit_work_items_link, wit_work_item_unlink, wit_work_items_link (any create/update/link batch variants).

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
Before generating grouping files, each candidate node MUST satisfy:
| Field | Requirement |
|-------|-------------|
| title | Non-empty, trimmed |
| canonicalType/nativeType | Resolved via taxonomy |
| trace | ≥1 anchor or rationale note |
| plannedAction | create|update|skip|defer resolved (no defer for finalized nodes) |
| parent | Resolved tempId except top-level epics |
| acceptance (requirements) | List (may contain TODO placeholders if needsAcceptance) |
| existingMatch.decision | Present when similarity ≥ review floor |
| progress | finalized |

Nodes failing validation: remain out of grouping; summary added to Questions.

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

### Security & Privacy
Do not log full PRD text in diagnostics. Truncate embedding source text (≤512 chars). Store hashes & anchors only where possible.

### Behavioral Guarantees
Read-only ADO, idempotent, stable tempIds, complete traceability, transparent diagnostics for matches ≥ review floor (0.65), no unbounded retries.

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

### Batching & Rate Limits
Rules:
- Child creation: ≤50 per `wit_add_child_work_items` call; deterministic chunk order by tempId.
- Updates: Coalesce field changes; batch via `wit_update_work_items_batch` (heuristic ≤400 ops).
- Linking: Batch `wit_work_items_link` (≤400 ops) grouped by source.
- Rate handling: Honor Retry-After; if remaining/limit <5% add jittered delay (1-2s). Backoff exponential (base 1.5x) on 429/503.
- Revision minimization: Skip if no semantic delta.

### Create vs Update vs Defer Decision Matrix
| Condition | Action |
|-----------|--------|
| similarity ≥0.8 & field delta | update |
| similarity ≥0.8 & no delta | skip |
| 0.6≤ similarity <0.8 | defer (questions) |
| similarity <0.6 | create |
| revision count >9500 | skip non-critical; warn |

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
      "escalationRef": null
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

## Important Rules
See Important Rules block above; those are normative (MUST). Others in this document are SHOULD unless explicitly stated.

<!-- <reference-sources> -->
- Internal research specification: `.copilot-tracking/research/20250822-prd-work-item-planning-chatmode-research.md`
- Azure DevOps Work Item Hierarchies (official docs) - referenced in research (fetched 2025-08-22)
<!-- </reference-sources> -->
