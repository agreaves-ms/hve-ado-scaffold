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
    <artifact-type>/
      <artifact-normalized-name>/
        artifact-analysis.md                    # Human-readable table + recommendations
        work-items.md                           # Human/Machine-readable plan (source of truth)
        handoff.md                              # Handoff for workitem execution (optionally references work-items.json if JSON variant produced)
        planning-log.md                         # Structured operational & state log (routinely updated sections)
```
Normalization: lower-case, hyphenated base filename without extension (e.g. `docs/Customer Onboarding PRD.md` → `docs--customer-onboarding-prd`). Avoid spaces and punctuation besides hyphens.
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
  * `Specific Section Y` refers to functionality that's no longer needed after functionality A found in codebase [searched codebase]:
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
````
<!-- </template-work-items-md> -->

**Detailed Example:**
<!-- <example-work-items-md> -->
````markdown
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
````
<!-- </example-work-items-md> -->


#### planning-log.md (Structured Mutable Log)
Generic, process-agnostic markdown log. Sections are routinely UPDATED in-place (tables grow; snapshot replaced; keyword groups rewritten). Historical fidelity is maintained through additive table rows and optional Decisions notes rather than enforcing append-only semantics.

**Detailed Template:**
<!-- <template-planning-log-md> -->
````markdown
# Work Item Planning Log
* **Project**: [`projects` field for mcp ado tool]
* **Repository**: [(Optional) `repository` field for mcp ado tool]

## Status
[e.g., 1/20 docs reviewed, 0/10 codefiles reviewed, 2/5 ado wit searched, 1/]

## Discovered Artifacts & Related Files
* AT[Reference Number (e.g., 001)] [relative/path/to/file (identified from referenced artifacts, discovered in artifacts, conversation, codebase)] - [one of, Not Started|In-Progress|Complete] - [Processing|Related|N/A]

## Discovered ADO Work Items
* ADO-[ADO Work Item ID (identified from mcp_ado_search_workitem, discovered in artifacts, conversation) (e.g., 1023)] - [one of, Not Started|In-Progress|Complete] - [Processing|Related|N/A]

## Work Items
### **WI[Reference Number]** - [WorkItemType (e.g., User Story)] - [one of, In-Progress|Complete]
* [WI[Reference Number] - Work Item Section](./artifact-analysis.md)
* Working Search Keywords: [Working Keywords (e.g., "the keyword OR another keyword")]
* Related ADO Work Items: [Related work items when identified include similarity (e.g., ADO-1023 (0.5), ADO-102 (0.7), ADO-103(0.8))]
* Suggested Action: [one of, Create|Update]

[Collected & Discovered Information]

[Possible Work Item Field Values (Refer to Work Item Fields)]

## Doc Analysis - artifact-analysis.md
### [relative/path/to/referenced/doc.ext]
* WI[Reference Number] - [WI[Reference Number] - Work Item Section](./artifact-analysis.md): [Summary of what was done (e.g., New section made)]
### [relative/path/to/another/referenced/doc.ext]
* WI[Reference Number] - [WI[Reference Number] - Work Item Section](./artifact-analysis.md): [Summary of what was done (e.g., Section was updated)]

## ADO Work Items
### ADO-[ADO Work Item ID]

[All content from mcp_ado_wit_get_work_item]
````
<!-- </template-planning-log-md> -->

#### handoff.md
Purpose: Stable, concise execution handoff. Required sections:
1. Source Information (artifacts, project, repository, area path, iteration path)
2. Execution Parameters (work-items.md relative path, markdown style reference to each work item in work-items.md, wit title, wit description)
3. Summary (Totals + Action counts + Type counts)
4. Next Steps (simple ordered list)

Template:
<!-- <template-handoff-md> -->
```markdown
# Work Item Handoff
* **Project**: <Project Name>
* **Repository**: <repo-name>
* **Area Path**: <Optional Area>
* **Iteration Path**: <Optional Iteration>
* **Source Artifacts**:
  * work-items.md (authoritative plan)
  * planning-log.md (state log)
  * artifact-analysis.md (analysis)

## Execution Parameters
* Plan File: ./work-items.md
* Items:
  * WI002 (Update) – System.Id 1071 – Update existing user story for functionality A
  * WI003 (Create) – New user story for functionality C

## Summary
* Total Items: 2
* Actions: { create: 1, update: 1, review: 0 }
* Types: { User Story: 2 }

## Next Steps
1. Validate similarity scores for WI003 against latest search results <= 24h old
2. Execute updates / creations in ADO (record resulting IDs in work-items.md)
3. Refresh planning-log.md relationships section
```
<!-- </template-handoff-md> -->

## Work Item Fields

**Relative Work Item Type Fields:**
* Core: "System.Id", "System.WorkItemType", "System.Title", "System.State", "System.Reason", "System.Parent", "System.AreaPath", "System.IterationPath", "System.TeamProject", "System.Description", "System.AssignedTo", "System.CreatedBy", "System.CreatedDate", "System.ChangedBy", "System.ChangedDate", "System.CommentCount"
* Board: "System.BoardColumn", "System.BoardColumnDone", "System.BoardLane"
* Classification / Tags: "System.Tags"
* Common Extensions: "Microsoft.VSTS.Common.AcceptanceCriteria", "Microsoft.VSTS.TCM.ReproSteps", "Microsoft.VSTS.Common.Priority", "Microsoft.VSTS.Common.StackRank", "Microsoft.VSTS.Common.ValueArea", "Microsoft.VSTS.Common.BusinessValue", "Microsoft.VSTS.Common.Risk", "Microsoft.VSTS.Common.TimeCriticality", "Microsoft.VSTS.Common.Severity"
* Estimation & Scheduling: "Microsoft.VSTS.Scheduling.StoryPoints", "Microsoft.VSTS.Scheduling.OriginalEstimate", "Microsoft.VSTS.Scheduling.RemainingWork", "Microsoft.VSTS.Scheduling.CompletedWork", "Microsoft.VSTS.Scheduling.Effort"

**Available Types:**
| Type | Available | Key Fields |
|------|-----------|------------|
| Epic | ✅ | System.Title, System.Description, System.AreaPath, System.IterationPath, Microsoft.VSTS.Common.BusinessValue, Microsoft.VSTS.Common.ValueArea, Microsoft.VSTS.Common.Priority, Microsoft.VSTS.Scheduling.Effort |
| Feature | ✅ | System.Title, System.Description, System.AreaPath, System.IterationPath, Microsoft.VSTS.Common.ValueArea, Microsoft.VSTS.Common.BusinessValue, Microsoft.VSTS.Common.Priority |
| User Story | ✅ | System.Title, System.Description, Microsoft.VSTS.Common.AcceptanceCriteria, Microsoft.VSTS.Scheduling.StoryPoints, Microsoft.VSTS.Common.Priority, Microsoft.VSTS.Common.ValueArea |

Rules:
* Feature requires Epic parent.
* User Story requires Feature parent.

## Search Keyword & Search Text Protocol

Goal: Deterministic, resumable discovery of existing work items.

<!-- <search-keyword-protocol> -->
Steps:
1. Maintain ACTIVE KEYWORD GROUPS: ordered list, each group = 1–4 specific terms (multi‑word allowed) joined by OR.
2. Compose `searchText`:
  * Single group → `(term1 OR "multi word")`
  * Multiple groups → `(group1) AND (group2)` etc.
3. Execute search (page size suggested: 50). For every related result ID:
  * Fetch full work item immediately and update planning-log.md.
  * Compute similarity (semantic intent focus, not token count).
  * Assign action via matrix.

Similarity Computation Guidance:
* Use combined semantic representation of (title + description + acceptance).
* Boost for aligned outcome/goal verbs; penalize scope or persona mismatch.
* Store raw float, round to 2 decimals for `similarity` field.
<!-- </search-keyword-protocol> -->

<!-- <similarity-decision-matrix> -->
| Similarity | Action | Interpretation |
|------------|--------|----------------|
| ≥ 0.70 | update | Strong alignment with existing item intent |
| 0.50–0.69 | review | Potential alignment; needs manual confirmation |
| < 0.50 | create | No sufficiently aligned existing item |
<!-- </similarity-decision-matrix> -->


## Routine State Persistence & Summarization Protocol

<!-- <state-persistence-protocol> -->
Must maintain planning-log.md routinely by keeping it up to date as information is discovered.
Must add and update work items in work-items.md as information is discovered.
Must add and update planning-log.md for each new artifact, keyword group, Azure DevOps work item, etc.

### Required Pre-Summarization
Summarization must also include the following (or else you will likely cause breaking changes):
* Full paths to all working files with a summary describing each file and its purpose
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
  * Use the `list_dir` tool under the `.copilot-tracking/workitems/<artifact-type>/<artifact-normalized-name>` working folder
  * Use the `read_file` tool to read back in all of the planning-log.md to build back context

2. **Context Reconstruction User Update**:
  Let the user know that you are working on rebuilding your context:

  ```markdown
  ## Resuming After Context Summarization

  I notice our conversation history was summarized. Let me rebuild context:

  📋 **[Analyzing Title]**: [Analyze planning-log.md and current work item content]

  To ensure continuity, I'll do the following:
  * [List protocol that you plan to follow next]

  Would you like me to proceed with this approach?
  ```
<!-- </state-persistence-protocol> -->
