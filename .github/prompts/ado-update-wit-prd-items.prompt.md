---
mode: "agent"
description: "Execute Azure DevOps work item operations based on planning artifacts from PRD analysis. Process handoff documents to create, update, and link work items with comprehensive validation and error handling."
---

# PRD Work Items Executor (Full Execution with Validation)

You WILL execute Azure DevOps work item operations based on planning artifacts from PRD analysis using ONLY the provided Azure DevOps tools. This prompt processes handoff documents from the `prd-to-wit-enhanced` chatmode to create, update, and link work items in Azure DevOps. It handles the actual execution phase after analysis and planning are complete.

## Inputs

- ${input:handoffFile}: Path to handoff markdown file, provided or inferred from attachment or prompt (REQUIRED)
- ${input:project}: Override ADO project name (Optional - will use project from handoff metadata if not provided)
- ${input:areaPath}: Override area path (Optional - will use areaPath from handoff metadata if not provided)
- ${input:iterationPath}: Override iteration path (Optional - will use iterationPath from handoff metadata if not provided)
- ${input:dryRun:false}: Preview operations without executing (Boolean, default: false)

## Phases (Overview)

Update the task list with the following:

0. Validate Handoff Document
1. Parse Work Items and Relationships
2. Process Work Items by Hierarchy
3. Handle Work Item Actions (Create/Update/Skip)
4. Establish Relationships
5. Generate Execution Report

**Communication Protocol:**

- Planning type phases outputs: "Review handoff.md in `.copilot-tracking/workitems/[prd-name]/`"
- Execution type phases confirms: "Processed [N] work items from handoff.md, [X] created, [Y] updated, [Z] failed"

## Expected Handoff Document Structure

<!-- <handoff-json-schema> -->
```json
{
  "metadata": {
    "sourceFile": "docs/prd.md",
    "project": "MyProject",
    "generatedAt": "2025-08-24T10:30:00Z",
    "areaPath": "MyProject\\Features",
    "iterationPath": "MyProject\\Sprint 1",
    "analysisMode": "planning-only"
  },
  "workItems": [
    {
      "id": "WI001",
      "level": 1,
      "type": "Epic",
      "title": "Customer Onboarding Experience",
      "description": "...",
      "parentId": null,
      "action": "create|update|skip",
      "existingMatch": {
        "id": 1234,
        "confidence": 0.85,
        "reason": "Strong title and description match"
      },
      "acceptance": [],
      "tags": ["onboarding", "epic"],
      "customFields": {
        "Priority": 2,
        "BusinessValue": 100
      },
      "searchTerms": ["customer", "onboarding", "experience"]
    }
  ],
  "relationships": [
    {
      "parentId": "WI001",
      "childId": "WI002",
      "linkType": "Parent"
    }
  ],
  "summary": {
    "totalItems": 15,
    "actions": {
      "create": 12,
      "update": 2,
      "skip": 1
    },
    "types": {
      "Epic": 3,
      "Feature": 8,
      "User Story": 4
    }
  }
}
```
<!-- </handoff-json-schema> -->

## Work Item Type Fields

**Relative Work Item Type Fields:**
- "System.Id", "System.WorkItemType", "System.Title", "System.State", "System.Tags", "System.CreatedDate", "System.ChangedDate", "System.Reason", "System.Parent", "System.AreaPath", "System.IterationPath", "System.TeamProject", "System.Tags", "System.Description", "System.AssignedTo", "System.CreatedBy", "System.CreatedDate", "System.ChangedBy", "System.ChangedDate", "System.CommentCount", "System.BoardColumn", "System.BoardColumnDone", "System.BoardLane"
- "Microsoft.VSTS.Common.AcceptanceCriteria", "Microsoft.VSTS.TCM.ReproSteps", "Microsoft.VSTS.Common.Priority", "Microsoft.VSTS.Common.StackRank", "Microsoft.VSTS.Common.ValueArea", "Microsoft.VSTS.Common.BusinessValue", "Microsoft.VSTS.Common.Risk", "Microsoft.VSTS.Common.TimeCriticality", "Microsoft.VSTS.Scheduling.StoryPoints", "Microsoft.VSTS.Scheduling.OriginalEstimate", "Microsoft.VSTS.Scheduling.RemainingWork", "Microsoft.VSTS.Scheduling.CompletedWork", "Microsoft.VSTS.Common.Severity"

**Available Types:**
| Type | Available | Key Fields |
|------|-----------|------------|
| Epic | ✅ | System.Title, System.Description, System.AreaPath, System.IterationPath, Microsoft.VSTS.Common.BusinessValue, Microsoft.VSTS.Common.ValueArea, Microsoft.VSTS.Common.Priority, Microsoft.VSTS.Scheduling.Effort |
| Feature | ✅ | System.Title, System.Description, System.AreaPath, System.IterationPath, Microsoft.VSTS.Common.ValueArea, Microsoft.VSTS.Common.BusinessValue, Microsoft.VSTS.Common.Priority |
| User Story | ✅ | System.Title, System.Description, Microsoft.VSTS.Common.AcceptanceCriteria, Microsoft.VSTS.Scheduling.StoryPoints, Microsoft.VSTS.Common.Priority, Microsoft.VSTS.Common.ValueArea |

## Detailed Required Behavior

### 0. Validate Handoff Document

You must first validate the handoff document structure and dependencies:

- Read handoff.md file from `${input:handoffFile}` path
- Extract execution parameters (project, area path, iteration)
- Locate and read work-items.json file in same directory as handoff.md
- Validate all required fields are present
- Verify project accessibility and permissions
- Check work item types exist in target project

**Validation Rules:**

- Handoff.md must contain execution parameters section
- work-items.json must exist in same directory as handoff.md
- All work items must have: id, type, title, action
- Parent references must exist within the document
- Area path and iteration path must be valid
- Custom fields must match work item type schema

### 1. Parse Work Items and Relationships

Parse the work-items.json structure and build execution plan:

- Extract all work items with their hierarchy levels
- Map parent-child relationships from relationships array
- Identify work items marked for create/update/skip actions
- Validate all temporary IDs are unique and consistent
- Build execution order based on hierarchy (Epics → Features → Stories)

### 2. Process Work Items by Hierarchy

Process work items in hierarchical order with proper dependency management:

**Execution Order:**

1. **Create Epics** - Process all Epic-level items using `mcp_ado_wit_create_work_item`
2. **Create Features** - Process Feature-level items using `mcp_ado_wit_add_child_work_items`
3. **Create User Stories** - Process Story-level items using `mcp_ado_wit_add_child_work_items`
4. **Update Existing** - Modify matched items using `mcp_ado_wit_update_work_items_batch`
5. **Create Additional Links** - Establish cross-hierarchy relationships using `mcp_ado_wit_work_items_link`

**Processing Rules:**

- Process items in hierarchy order (Epics → Features → Stories)
- Maximum 20 work items per batch operation
- Log each operation result with work item ID mapping
- Update ID mapping file with created work item IDs

### 3. Handle Work Item Actions (Create/Update/Skip)

Execute the specified actions for each work item based on the handoff document:

**Create Actions:**

- Use `mcp_ado_wit_create_work_item` for Epic-level items (top-level hierarchy)
- Use `mcp_ado_wit_add_child_work_items` for Features and User Stories
- Apply all field mappings as specified in handoff document
- **Must** use `mcp_ado_wit_update_work_items_batch` after `mcp_ado_wit_create_work_item` or `mcp_ado_wit_add_child_work_items` calls to apply remaining fields (refer to Work Item Type Fields section)
- Log creation results and update ID mapping immediately

**Update Actions:**

- Use `mcp_ado_wit_update_work_items_batch` for items with existing matches
- Only update fields that have changed from existing work item
- Preserve existing relationships unless explicitly overridden
- Log update results with before/after field comparisons

**Skip Actions:**

- Document items marked for manual review in execution log
- Include reason for skipping (low confidence, manual review required, etc.)
- Provide specific remediation steps for each skipped item

### 4. Establish Relationships

Create all parent-child and related links after work items are created:

**Link Processing:**

- Use `mcp_ado_wit_work_items_link` for all relationship creation
- Map temporary IDs to actual Azure DevOps work item IDs
- Batch relationship operations (max 50 links per call)
- Verify link creation success and log failures

**Relationship Types:**

- Parent-child links between hierarchy levels
- Related links for cross-epic dependencies
- Custom relationship types as specified in handoff document

### 5. Generate Execution Report

Produce comprehensive reporting artifacts and summary information:

**Report Components:**

- Success/failure counts by operation type
- Complete ID mapping from temporary to ADO IDs
- Error details with remediation steps
- Next steps for manual review items
- ADO query links for created work items

## Edge Cases & Rules

- If handoff document is missing or invalid, surface error and stop processing
- If work-items.json is malformed, attempt to continue with handoff.md data only
- NEVER create work items without proper hierarchy validation
- If parent work item creation fails, queue children for retry after parent resolution
- Preserve existing work item data when updating; only modify specified fields

## Field Mapping and Creation Rules

You must follow these mandatory field mapping rules for all work item operations:

**Required Field Handling:**

- **Title:** Use from handoff document (already processed)
- **Description:** Convert markdown to HTML for work item
- **Work Item Type:** Use type from handoff document
- **Area Path:** Use from parameters or handoff metadata
- **Iteration Path:** Use from parameters or handoff metadata
- **State:** Set to "New" for created items

**Custom Field Processing:**

- **Priority:** Map to work item Priority field (1-4 scale)
- **Business Value:** Map to Business Value field if available
- **Story Points:** Leave blank for estimation during planning
- **Tags:** Apply tags array from handoff document
- **Acceptance Criteria:** Format as structured list in Description or dedicated field

**Update Field Handling:**

- Only update fields that have changed from existing work item
- Preserve existing relationships unless explicitly overridden
- Maintain work item history and audit trail
- Apply incremental updates to avoid overwriting manual changes

## Error Handling and Recovery Rules

Handle all error scenarios with specific recovery actions:

**Creation Failures:**

- **Required field missing:** Log error, skip item, continue processing
- **Permission denied:** Log for manual creation, provide details
- **Duplicate detection:** Check if acceptable duplicate or abort
- **Type not available:** Use fallback type or defer to user

**Update Failures:**

- **Work item not found:** Log error, treat as creation candidate
- **Concurrent modification:** Retry once with fresh data
- **Field validation error:** Log specifics, continue with valid fields
- **Permission denied:** Log for manual update

**Relationship Failures:**

- **Parent not found:** Queue for retry after parent creation
- **Invalid link type:** Log error, suggest manual creation
- **Circular dependency:** Detect and break cycle with warning

**Recovery Actions:**

- Retry failed operations once with 3-second delay
- Continue processing remaining items after individual failures
- Generate comprehensive error log for manual resolution
- Provide specific remediation steps for each error type

## Batch Processing Rules

Optimize API calls and reduce processing time with proper batching:

**Creation Batching:**

- Epics: Create individually to ensure proper parent context
- Features: Batch by parent Epic (max 20 per Epic)
- User Stories: Batch by parent Feature (max 20 per Feature)
- Use `mcp_ado_wit_create_work_item` for top-level, `mcp_ado_wit_add_child_work_items` for children

**Update Batching:**

- Group updates by work item type
- Maximum 50 work items per `mcp_ado_wit_update_work_items_batch` call
- Process updates after all creations complete

**Link Batching:**

- Group by link type (Parent, Related, etc.)
- Maximum 50 links per `mcp_ado_wit_work_items_link` call
- Process links after all work items exist

**Rate Limiting:**

- 2-second delay between large batch operations
- 5-second delay after any API error
- Maximum 3 retries per failed operation

## Completion Summary Requirements

When done, provide a comprehensive summary including:

- Count of work items processed (created/updated/skipped/failed)
- Path to execution log file
- Path to ID mapping JSON file
- Path to error report file (if any errors occurred)
- Success rate percentage
- The markdown summary table with all processed work items
- Next steps for manual review items
- ADO query links for created work items

## Compliance Checklist (Self-Evaluate Before Responding)

<!-- <important-compliance-checklist> -->
- [ ] Handoff document validated and parsed successfully
- [ ] Work items processed in proper hierarchy order
- [ ] All specified field mappings applied correctly
- [ ] Batch processing rules followed for optimal performance
- [ ] Error handling implemented with retry logic
- [ ] ID mapping maintained throughout execution
- [ ] Execution log generated with comprehensive details
- [ ] Recovery instructions provided for failed operations
- [ ] Rate limiting respected to avoid API throttling
- [ ] All output artifacts created in specified locations
- [ ] Summary table includes all required columns and formatting
- [ ] Completion summary provides actionable next steps
<!-- </important-compliance-checklist> -->

---

Proceed with work item execution by following all phases in order
