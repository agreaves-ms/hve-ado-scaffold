---
description: "Required instructions for workitem planning leveraging mcp ado tool calls."
applyTo: '**/.copilot-tracking/workitems/**'
---

# Azure DevOps Work Items Planning Instructions

Provide a single, consistent source of truth for:
* Defining and maintaining planning workitem artifacts
* Determining similarity against existing Azure DevOps work items
* Routine state persistence for summarization and resumable work item planning
* Define a stable execution handoff for workitem creation and updating

## Artifact Definitions & Directory Conventions

Root planning workspace structure (PRD-focused planning only):

<!-- <artifact-structure> -->
```plain
.copilot-tracking/
  workitems/
    <prds|features|user-stories>/
      <{prd,feature,user-story}-normalized-name>/
        artifact-analysis.md                    # Human-readable table + recommendations
        work-items.md                           # Human/Machine-readable plan (source of truth)
        handoff.md                              # Handoff for workitem creation/updating (references work-tiems.json)
        planning-log.md                         # Structured operational & state log (routinely updated sections)
```
Normalization: lower-case, hyphenated base filename without extension (e.g. `Customer Onboarding PRD.md` → `customer-onboarding-prd`).
<!-- </artifact-structure> -->

### Artifact Field / Section Requirements

**Markdown required format**:
* `*.md` files MUST start with:
  ```
  <!-- markdownlint-disable-file -->
  <!-- markdown-table-prettify-ignore-start -->
  ```
* `*.md` files MUST end with:
  ```
  <!-- markdown-table-prettify-ignore-end -->
  ```

#### artifact-analysis.md
Sections (fixed order):
1. Title line: e.g., `# PRD Work Item Analysis - [Summarized Title]`
2. Source Metadata (bolded bullet list): e.g., File, Parsed, Project, AreaPath?, IterationPath?
3. Planned Work Items (sections with bolded bullet list of details): e.g.,
  ````markdown
  ## Planned Work Items

  ### WI002 - Update Component Functionality A
  * **Working Title**: As a user, I want functionality A in Component
  * **Working Type**: User Story
  * **Working Action**: Create
  * **Key Search Terms**: "example term", "another", "term"
  * **Existing IDs**: N/A [or Related WorkItemID (confidence) e.g., 102 (0.5), 103 (0.9), 104 (0.1)]

  #### WI002 - Working Related & Discovered Information
  * Key details from file: Identifies this functionality as a high priority, Suggests related work for this functionality
  * `Specific Section X` refers to specific requirement described here for functionality A
  * `Specific Section X` refers to specific requirement described here for functionality C that needs functionality A
  * `Specific Section W` refers to functional requirements that relates to functionality A:
    * Functionality A becomes possible
  * User mentioned specific requirement in conversation
  * Functionality A needed in codefiles found in codebase [searched codebase]:
    * relative/path/to/file.ext - supports component but missing functionality A
    * relative/path/to/file2.ext - references functionality related to functionality A
  * `Specific Section Y` refers to functionality that's no longer needed after functionality A found in codebase [searched codebsae]:
    * relative/path/to/old-file-3.ext

  #### WI002 - Working Description
    ```markdown
    ## As a user (updated to match style and tone from mcp ado searched work items)
    As a user, I want to update component with new functionality A. So I can do this specific thing that I want with this component that was called out in the document.

    ## Requirements
    * Functionality A becomes possible
    ```
    -
  #### WI002 - ADO Work Item Discovery


  ````
4. Recommendations (counts create/update/review)
5. Notes (optional)

#### work-items.md (Authoritative Plan)

**Detailed Template:**
<!-- <template-work-items-md> -->
````markdown
<!-- markdownlint-disable-file -->
<!-- markdown-table-prettify-ignore-start -->
# Work Items
* **Project**: [`projects` field for mcp ado tool]
* **Area Path**: [(Optional) `areaPath` field for mcp ado tool]
* **Iteration Path**: [(Optional) `iterationPath` field for mcp ado tool]
* **Repository**: [(Optional) `repository` field for mcp ado tool]

## WI[Reference Number (e.g, 002)] - [Action (one of, Create|Update)] - [Summarized Title (e.g., Update Component Functionality A)]
[1-5 Sentence Explanation of Change (e.g., Adding user story for functionality A called out in [Section](../../docs/document.md#the-specific-section))]

* WI[Reference Number] - [Work Item Type Fields (e.g., System.Id, System.WorkItemType, System.Title)]: [Single Line Value (e.g., As a user, I want functionality A in Component)]

### WI[Reference Number] - [Work Item Type Fields (e.g., System.Description, Microsoft.VSTS.Common.AcceptanceCriteria)]
```[Format (e.g., markdown, html, json)]
[Multi Line Value]
```

### WI[Reference Number] - Relationships
* WI[Reference Number] - [Link Type (e.g., Child, Predecessor, Successor, Related)] - [Relation ID (either, WI[Related Reference Number], System.Id: [Work Item ID from mcp ado tool])]: [Single Line Reason (e.g., New user story for feature around component)]

<!-- markdown-table-prettify-ignore-end -->
````
<!-- </template-work-items-md> -->

**Detailed Example:**
<!-- <example-work-items-md> -->
````markdown
<!-- markdownlint-disable-file -->
<!-- markdown-table-prettify-ignore-start -->
# Work Items
* **Project**: Project Name
* **Area Path**: Project Name\\Area\\Path
* **Iteration Path**: Project Name\\Sprint 1
* **Repository**: project-repo

## WI002 - Update - Update Component Functionality A
Updating existing user story to add functionality A called out in [Section](../../docs/document.md#the-specific-section) from provided document. Found [User Story Title](https://dev.azure.com/Organization/Project%20Name/_workitems/edit/1071/) through conversation with the user and agreed to update. User agreed System.Title should be updated as well.

* WI002 - System.Id: 1071
* WI002 - System.WorkItemType: User Story
* WI002 - System.Title: As a user, I want to update component and include functionality A with functionality B

### WI002 - System.Description
```markdown
## As a user (continue to match existing style and tone)
As a user, I want to update component with new functionality B and new functionality A. So I can do this specific thing that I want with this component.

## Requirements
* Functionality A becomes possible
* Functionality B becomes possible
* Side-effect is then something
* Existing requirement from workitem that should stay in

## Non-Functional Requirements
* Non-functional requirement from parent feature
* Non-functional requirement from document.md
* Non-functional requirement mentioned by user
* Existing non-functional requirement that should stay in
```

### WI002 - Microsoft.VSTS.Common.AcceptanceCriteria
```markdown
* Able to do specific thing
* Able to do something else for verification
* Existing acceptance criteria that should stay in
```

### WI002 - Relationships
* WI002 - Successor - WI003: Functionality A required in Component before able to add functionality C in new user story WI003

<!-- markdown-table-prettify-ignore-end -->
````
<!-- </example-work-items-md> -->
Top-level keys:
* `metadata`: { sourceFile, project, generatedAt(ISO), areaPath?, iterationPath? }
* `workItems`: array of objects (see Section 3 definitions)
* `relationships`: array `{ parentId, childId }`
* `summary`: { totalItems, actions:{ create, update, review }, types:{ Epic, Feature, User Story } }

#### planning-log.md (Structured Mutable Log)
Generic, process-agnostic markdown log (usable for PRD planning, feature refinement, user story elaboration). Sections are routinely UPDATED in-place (tables grow; snapshot replaced; keyword groups rewritten). Historical fidelity is maintained through additive table rows and optional Decisions notes rather than enforcing append-only semantics.

**Detailed Template:**
<!-- <template-work-items-md> -->
````markdown
<!-- markdownlint-disable-file -->
<!-- markdown-table-prettify-ignore-start -->
# Work Item Planning Log
* **Project**: [`projects` field for mcp ado tool]
* **Area Path**: [(Optional) `areaPath` field for mcp ado tool]
* **Iteration Path**: [(Optional) `iterationPath` field for mcp ado tool]
* **Repository**: [(Optional) `repository` field for mcp ado tool]

## Work Items
**WI[Reference Number]**:
[WI[Reference Number] - Work Item Section](./doc-analysis.md)


## Doc Analysis - doc-analysis.md
### [relative/path/to/referenced/doc.ext]
* WI[Reference Number] - [WI[Reference Number] - Work Item Section](./doc-analysis.md): [Summary of what was done (e.g., New section made)]
### [relative/path/to/another/referenced/doc.ext]
* WI[Reference Number] - [WI[Reference Number] - Work Item Section](./doc-analysis.md): [Summary of what was done (e.g., Section was updated)]

## Codebase

## WI[Reference Number (e.g, 002)] - [Action (one of, Create|Update)] - [Summarized Title (e.g., Update Component Functionality A)]
[1-5 Sentence Explanation of Change (e.g., Adding user story for functionality A called out in [Section](../../docs/document.md#the-specific-section))]

* WI[Reference Number] - [Work Item Type Fields (e.g., System.Id, System.WorkItemType, System.Title)]: [Single Line Value (e.g., As a user, I want functionality A in Component)]

### WI[Reference Number] - [Work Item Type Fields (e.g., System.Description, Microsoft.VSTS.Common.AcceptanceCriteria)]
```[Format (e.g., markdown, html, json)]
[Multi Line Value]
```

### WI[Reference Number] - Relationships
* WI[Reference Number] - [Link Type (e.g., Child, Predecessor, Successor, Related)] - [Relation ID (either, WI[Related Reference Number], System.Id: [Work Item ID from mcp ado tool])]: [Single Line Reason (e.g., New user story for feature around component)]

<!-- markdown-table-prettify-ignore-end -->
````
<!-- </template-work-items-md> -->

Title Convention:
`# <Process Name> Planning Log` (examples: `# PRD Work Item Planning Log`, `# Feature Refinement Planning Log`).

Required Sections (always present):
1. `## Active Keyword Groups` – numbered list (update by rewriting section; retain historical groups only if analytically relevant).
2. `## Search Process Log` – table columns (fixed):
  `Timestamp | Keyword Expression | Skip | Candidate ID | Similarity Score | Action | Notes`
  * Append a row per candidate or structural event (start, no-results, scope-change notice). Use `-` where not applicable.
3. `## State Snapshot` – single fenced JSON block (latest resumable state). Replace entirely on update (do not stack multiples) unless auditing requires versioning.

Optional Sections (include zero or more as needed): `## Scope Reduction Log`, `## Decisions`, `## Risks`, `## Assumptions`, `## Process Completion`, `## Changes`, `## Open Questions`.

Completion Section (`## Process Completion`) should summarize: status, final hierarchy count, readiness, artifact list.

General Rules:
* Append new table rows for new events; if a prior row contained an error, add a corrective row (do not silently mutate earlier rows beyond trivial typo fixes).
* Keyword groups section is rewritten wholesale when groups change (do not duplicate stale groups below).
* State Snapshot section is replaced (single authoritative JSON block).
* Similarity Score: round to two decimals.
* Use ISO 8601 UTC timestamps.
* Keep Notes concise; reference work item IDs or temp IDs where relevant.
* Maintain a valid `## State Snapshot` at session end.

Example (abbreviated):

<!-- <planning-log-section-template> -->
````markdown
<!-- markdownlint-disable-file -->
<!-- markdown-table-prettify-ignore-start -->
# Work Item Discovery Planning Log

## Active Keyword Groups
1. (azureml workspace OR azure machine learning OR ml workspace)
2. (mlops OR machine learning operations OR ml pipeline)

## Search Process Log
| Timestamp (based on <context>) | Keyword Expression | Skip | Candidate ID | Similarity Score | Action | Notes |
|-----------|-------------------|------|--------------|------------------|--------|-------|
| 2025-08-24T10:30:00Z | Starting discovery process | - | - | - | - | Initialized Active Keyword Groups |
| 2025-08-24T10:35:00Z | (azureml workspace OR azure machine learning OR ml workspace) | 0 | 1071 | 0.75 | update | Matches planned FR-008 scope |
| 2025-08-24T10:35:00Z | (azureml workspace OR azure machine learning OR ml workspace) | 0 | 988 | 0.45 | review | Documentation oriented |

## Scope Reduction Log
| Timestamp (based on <context>) | Action | Original Scope | Revised Scope | Items Retained | Notes |
|-----------|--------|----------------|---------------|----------------|-------|
| 2025-08-24T11:00:00Z | User requested scope reduction | 12 items | 3 items | WI001, WI002, WI003 | Consolidated overlapping features |

## State Snapshot
```json
{
  "activeGroups": [
    "(azureml workspace OR azure machine learning OR ml workspace)",
    "(mlops OR machine learning operations OR ml pipeline)"
  ],
  "currentExpressionIndex": 2,
  "lastSkip": 0,
  "pendingCandidateIds": [],
  "reviewIds": ["WI003"],
  "timestamp": "2025-08-24T11:05:00Z"
}
```

#### handoff.md
Purpose: Stable concise execution handoff. Required sections:
1. Source Information (PRD file, project, generated timestamp)
2. Execution Parameters (Area Path, Iteration Path, Work Items File relative path)
3. Summary (Totals + Action counts + Type counts)
4. Work Items Overview Table (schema below)
5. Special Instructions (optional)
6. Next Steps (simple ordered list)

Work Items Overview Table columns (exact):
`Type | Title | Summary | Action | Existing? | Confidence | Search Terms`

## Process Completion
* Status: Analysis complete (reduced scope)
* Hierarchy: Single Epic → Feature → Story
* Files Generated: prd-analysis.md, work-items.md, handoff.md
* Ready for Execution: Yes
<!-- markdown-table-prettify-ignore-end -->
````
<!-- </planning-log-section-template> -->

## 3. Hierarchy & Work Item Type Definitions

Only three planned types: Epic, Feature, User Story.

Rules:
* Feature requires Epic parent.
* User Story requires Feature parent.
* If parent unknown yet, set `parentId: null` and `pendingParent: true` (boolean) until resolved.
* No deeper nesting defined here.

Work item object fields in `work-items.md` > `workItems[]`:

<!-- <workitem-type-definitions> -->
| Field | Description | Applies To | Required | Notes |
|-------|-------------|-----------|----------|-------|
| id | Temporary internal identifier (string) | All | Yes | Stable within file; not ADO ID |
| level | 1 Epic, 2 Feature, 3 User Story | All | Yes | Derived from type |
| type | `Epic` | `Feature` | `User Story` | All | Yes | Case-sensitive |
| title | Concise business/functional name | All | Yes | Avoid trailing punctuation |
| description | Markdown description / context | All | Yes | Can include headings & lists |
| parentId | id of parent item | Feature, User Story | Yes (unless pendingParent) | Null for Epics |
| pendingParent | Indicates parent not yet resolved | Feature, User Story | No | When true, parentId must be null |
| action | create | update | review | All | Yes | Derived from similarity matrix |
| existingMatch | { id, confidence, reason } | When update/review | Conditional | Omit if action=create |
| acceptance | Array of acceptance criteria strings | User Story | No | Empty array if none |
| tags | Array of tag strings | All | No | Lower-case recommended |
| customFields | KV pairs for additional fields | All | No | e.g. { "Priority": 2 } |
| searchTerms | Array of canonical term tokens | All | Yes | Lower-case, deduped |
| similarity | Numeric 0..1 rounded 2 decimals | All | Yes | Basis for action selection |
<!-- </workitem-type-definitions> -->

Similarity Decision Matrix (intent-based across title + description + acceptance):

<!-- <similarity-decision-matrix> -->
| Similarity | Action | Interpretation |
|------------|--------|----------------|
| ≥ 0.70 | update | Strong alignment with existing item intent |
| 0.50–0.69 | review | Potential alignment; needs manual confirmation |
| < 0.50 | create | No sufficiently aligned existing item |
<!-- </similarity-decision-matrix> -->

## 4. Search Keyword & Search Text Protocol

Goal: Deterministic, resumable discovery of existing work items.

<!-- <search-keyword-protocol> -->
Steps:
1. Maintain ACTIVE KEYWORD GROUPS: ordered list, each group = 1–4 specific terms (multi‑word allowed) joined by OR.
2. Prohibited as lone group terms (must pair with a specific group via AND if used): `api`, `service`, `data`, `platform`, `integration`.
3. Compose `searchText`:
  * Single group → `(term1 OR "multi word")`
  * Multiple groups → `(group1) AND (group2)` etc.
4. Before each new search expression (or after any change), rewrite the `## Active Keyword Groups` section.
5. Execute search (page size suggested: 50). For every result ID:
  * Fetch full work item immediately.
  * Compute similarity (semantic intent focus, not token count).
  * Assign action via matrix.
  * Append a row to `## Search Process Log` table BEFORE processing next candidate.
6. After each page (or logical batch): update the single `## State Snapshot` JSON block.
7. When user adds/refines terms: update groups (step 4) then continue with next expression.

Similarity Computation Guidance:
* Use combined semantic representation of (title + description + acceptance).
* Boost for aligned outcome/goal verbs; penalize scope or persona mismatch.
* Store raw float, round to 2 decimals for `similarity` field.
<!-- </search-keyword-protocol> -->

## 5. Artifact Purposes & Usage

<!-- <artifact-templates> -->
| Artifact | Purpose | Update Trigger | Source of Truth? | Key Consistency Rules |
|----------|---------|---------------|------------------|-----------------------|
| prd-analysis.md | Human-readable planning snapshot | After any batch reclassification or structural change | No (mirrors JSON) | Table must mirror JSON `workItems` subset (Type/Title/Action/Existing ID/Confidence/Key Terms) |
| work-items.md | Primary human/machine-readable plan | After every candidate fetch & classification | Yes | All similarity/action changes land here first |
| handoff.md | Execution-facing summary | When plan considered stable or on explicit user request | No (derivative) | Table must align with JSON (counts, actions, search terms) |
| planning-log.md | Operational & recovery log | Whenever keyword groups change, candidates processed, scope shifts, or state updates | N/A (log) | Sections mutable: groups & snapshot replaced; tables accrue rows |

Work Items Overview Table (handoff.md) schema:
`Type | Title | Summary | Action | Existing? | Confidence | Search Terms`
* Summary: ≤120 chars distilled value (not full description)
* Existing?: `Yes (<id>)` or `No`
* Confidence: similarity value or `-` if pending review without computed similarity yet (should normally be present)
* Search Terms: canonical semicolon-separated (from `searchTerms` array)
<!-- </artifact-templates> -->

## 6. Routine State Persistence & Summarization Protocol

<!-- <state-persistence-protocol> -->
Minimum persistence after EACH fetched candidate:
* Update corresponding `## Work Items` entry (similarity, action, existingMatch?) in `work-items.md`.
* Append a row to the `## Search Process Log` table (one row per candidate or summarized event).

Minimum persistence after EACH search page:
* Replace the `## State Snapshot` fenced JSON block with the newest state.
* If keyword groups changed, rewrite the `## Active Keyword Groups` section.

`State Snapshot` JSON fields (exact keys):
```
{
  "activeGroups": ["(customer onboarding OR onboarding experience)", "(self-service portal)"],
  "currentExpressionIndex": 1,
  "lastSkip": 50,
  "pendingCandidateIds": [],
  "reviewIds": ["WI007","WI010"],
  "timestamp": "2025-08-25T14:32:11Z"
}
```

### Required Pre-Summarization
Summarization must also include the following (or else you will likely cause breaking changes):
* Full paths to all working files with summary describing each file and its purpose
* Anything that was not captured into the planning-log.md file or other artifacts that should have been captured before summarization
  * Specifically state exactly what needs to be done again (use the mcp_ado_wit_get_work_item tool with ID ### again, etc)
* Exact work item IDs that were already reviewed
* Exact work item IDs that are left to be reviewed
* Exact work item IDs that were already reviewed but likely not captured into the planning-log.md file or other artifacts
* Exact planning steps that you were previously on (must repeat if data was not captured into artifacts)
* Exact planning steps that are still required
* Any potential work item search criteria that is still required

### Required Post-Summarization Recovery
If context has `<summary>` and only one tool call, then immediately do the following protocol before any additional edits/decisions:

1. **State File Validation**:
  * It's likely you've lost valuable information and you are now required to recover your context to avoid broken changes
  * Use the `list_dir` tool under the `.copilot-tracking/workitems/<prds|features|user-stories>/<{prd,feature,user-story}-normalized-name>` working folder
  * Use the `read_file` tool to read back in all of the planning-log.md to build back context

2. **Context Reconstruction User Update**:
  Let the user know that you are working on rebuilding your context:

  ```markdown
  ## Resuming After Context Summarization

  I notice our conversation history was summarized. Let me rebuild context:

  📋 **[Analyzing Title]**: [Analyze planning-log.md and current workitem content]

  To ensure continuity, I'll do the following:
  * [List protocol that you plan to follow next]

  Would you like me to proceed with this approach?
  ```

Snapshot Emission (conversation summarization trigger): Output a snapshot block (without editing the log) showing: active groups, expression index, last skip, review IDs, plan directory path.
<!-- </state-persistence-protocol> -->
