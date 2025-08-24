# PRD Work Items Executor

Execute Azure DevOps work item operations based on planning artifacts from PRD analysis.

## Purpose

This prompt processes handoff documents from the `prd-to-wit-enhanced` chatmode to create, update, and link work items in Azure DevOps. It handles the actual execution phase after analysis and planning are complete.

## Required Inputs

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| handoffFile | string | Path to handoff markdown file | ".copilot-tracking/workitems/customer-onboarding-prd/handoff.md" |
| project | string (optional) | Override ADO project name | "MyProject" |
| areaPath | string (optional) | Override area path | "MyProject\\Features" |
| iterationPath | string (optional) | Override iteration | "MyProject\\Sprint 1" |
| dryRun | boolean (optional) | Preview operations without executing | false |

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

## Execution Workflow

### Step 1: Validate Handoff Document

```markdown
## Processing Handoff Instructions
- Reading handoff.md file
- Locating work-items.json file
- Validating execution parameters
- Checking ADO project connectivity
```

**Actions:**

- Read handoff.md file from provided path
- Extract execution parameters (project, area path, iteration)
- Locate and read work-items.json file in same directory
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

### Step 2: Process Work Items by Hierarchy

```markdown
## Creating Work Items
- Processing Epics (Level 1)
- Processing Features (Level 2)
- Processing User Stories (Level 3)
- Establishing relationships
```

**Execution Order:**

1. **Create Epics** - Process all Epic-level items using `wit_create_work_item`
2. **Create Features** - Process Feature-level items using `wit_add_child_work_items`
3. **Create User Stories** - Process Story-level items using `wit_add_child_work_items`
4. **Update Existing** - Modify matched items using `wit_update_work_items_batch`
5. **Create Additional Links** - Establish cross-hierarchy relationships using `wit_work_items_link`

**Processing Rules:**

- Process items in hierarchy order (Epics → Features → Stories)
- Maximum 20 work items per batch operation
- Log each operation result with work item ID mapping
- Update handoff document with created work item IDs

### Step 3: Handle Work Item Actions

**Create Actions:**

```markdown
## Creating New Work Items: [count]
- Epic: [epic-count] items
- Feature: [feature-count] items
- User Story: [story-count] items
```

**Update Actions:**

```markdown
## Updating Existing Work Items: [count]
- Updating descriptions and acceptance criteria
- Adding tags and custom field values
- Preserving existing relationships
```

**Skip Actions:**

```markdown
## Skipping Work Items: [count]
- Items marked for manual review
- Low confidence matches requiring user decision
```

### Step 4: Establish Relationships

```markdown
## Creating Work Item Relationships
- Parent-child links: [count]
- Related links: [count]
- Cross-epic dependencies: [count]
```

**Link Processing:**

- Use `wit_work_items_link` for all relationship creation
- Map temporary IDs to actual Azure DevOps work item IDs
- Batch relationship operations (max 50 links per call)
- Verify link creation success and log failures

### Step 5: Generate Execution Report

```markdown
## Work Item Creation Summary

### Successfully Created
| Type | Count | ADO IDs | Temp IDs |
|------|-------|---------|----------|
| Epic | 3 | 5001-5003 | WI001-WI003 |
| Feature | 8 | 5004-5011 | WI004-WI011 |
| User Story | 4 | 5012-5015 | WI012-WI015 |

### Successfully Updated
| ADO ID | Type | Title | Changes Applied |
|--------|------|-------|-----------------|
| 1234 | Feature | User Registration | Description, Tags, Custom Fields |

### Failed Operations
| Temp ID | Type | Title | Error | Retry Status |
|---------|------|-------|-------|--------------|
| WI016 | Story | Login Flow | Required field missing | Manual review needed |

### Created Relationships
- 12 Parent-child links established
- 3 Related links created
- 0 failed relationship operations

### Next Steps
1. Review created work items: [ADO query link]
2. Assign work items to team members
3. Estimate effort for stories
4. Plan sprint assignments
```

## Field Mapping and Creation

<!-- <field-mapping-execution> -->
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
<!-- </field-mapping-execution> -->

## Error Handling and Recovery

<!-- <error-handling-execution> -->
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
<!-- </error-handling-execution> -->

## Batch Processing Rules

<!-- <batch-processing-rules> -->
**Creation Batching:**

- Epics: Create individually to ensure proper parent context
- Features: Batch by parent Epic (max 20 per Epic)
- User Stories: Batch by parent Feature (max 20 per Feature)
- Use `wit_create_work_item` for top-level, `wit_add_child_work_items` for children

**Update Batching:**

- Group updates by work item type
- Maximum 50 work items per `wit_update_work_items_batch` call
- Process updates after all creations complete

**Link Batching:**

- Group by link type (Parent, Related, etc.)
- Maximum 50 links per `wit_work_items_link` call
- Process links after all work items exist

**Rate Limiting:**

- 2-second delay between large batch operations
- 5-second delay after any API error
- Maximum 3 retries per failed operation
<!-- </batch-processing-rules> -->

## Output Artifacts

**Generated Files:**

- **Execution Log:** `.copilot-tracking/execution/YYYYMMDD-execution-log.md`
- **ID Mapping:** `.copilot-tracking/execution/YYYYMMDD-id-mapping.json`
- **Error Report:** `.copilot-tracking/execution/YYYYMMDD-errors.json`

**ID Mapping Structure:**

```json
{
  "mappings": [
    {
      "tempId": "WI001",
      "adoId": 5001,
      "type": "Epic",
      "title": "Customer Onboarding Experience",
      "url": "https://dev.azure.com/org/project/_workitems/edit/5001"
    }
  ],
  "statistics": {
    "created": 15,
    "updated": 2,
    "failed": 1,
    "totalProcessed": 18
  }
}
```

## Success Criteria

A successful execution includes:

- **High Creation Rate:** >90% of planned items created successfully
- **Accurate Relationships:** All parent-child links established correctly
- **Data Integrity:** Field values applied as specified in handoff document
- **Traceability:** Complete mapping from temporary IDs to ADO work item IDs
- **Error Handling:** Clear documentation of any failures with remediation steps
- **Audit Trail:** Comprehensive log of all operations for review and debugging

## Integration with Planning Chatmode

**Handoff Requirements:**

- Planning chatmode must generate `handoff.md` with execution parameters
- Supporting `work-items.json` must contain compliant structure
- All temporary IDs must be unique and consistent
- Work item actions must be clearly specified (create/update/skip)
- Relationships must reference valid temporary IDs
- Directory structure: `.copilot-tracking/workitems/[prd-name]/`

**Communication Protocol:**

- Planning phase outputs: "Review handoff.md in `.copilot-tracking/workitems/[prd-name]/`"
- Execution phase confirms: "Processed [N] work items from handoff.md, [X] created, [Y] updated, [Z] failed"
- Both phases maintain audit trail in same directory structure
- Execution results logged to `execution-log.md` in handoff directory
