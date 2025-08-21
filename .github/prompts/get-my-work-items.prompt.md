---
mode: 'agent'
description: 'Retrieve ordered @Me work items using ADO tools and persist raw JSON'
---

# Get My Work Items (Ordered, Raw Export)

You WILL retrieve a prioritized list of work items assigned to the current user using ONLY the Azure DevOps tools. You WILL rely on a saved managed query for ordering (no local sorting). You WILL persist a raw JSON artifact under `.copilot-tracking/workitems/`.

## Inputs
- ${input:project:edge-ai}: Azure DevOps project name or ID
- ${input:queryPath}: Optional path to the saved managed query. If omitted, you WILL fallback to `wit_my_work_items`.
- ${input:top:10}: Max items to return
- ${input:types:Bug, User Story, Task}: Comma-separated WorkItemTypes to include (case-insensitive). Default filters to Bug, User Story, and Task.
- ${input:states:Active, New}: Comma-separated System.State values to include (case-insensitive). Default filters to Active and New.
- ${input:fields}: Explicit fields to fetch when hydrating (default list provided below)

## Default Fields
```json
["System.Id","System.WorkItemType","System.Title","System.State","System.Parent","System.Tags","Microsoft.VSTS.Common.StackRank","Microsoft.VSTS.Common.Priority","System.AssignedTo","System.ChangedDate","System.Description","Microsoft.VSTS.Common.AcceptanceCriteria"]
```

## Required Behavior
1. Determine Source of IDs
   - If `${input:queryPath}` is provided:
     - Use `wit_get_query` with `expand = Wiql` to locate and validate `${input:queryPath}` within `${input:project}`.
     - The saved query SHOULD include filters for `Assigned To = @Me` AND `Work Item Type IN (${input:types})`, and order by `Priority ASC, StackRank ASC` to minimize client-side filtering.
     - If the query is missing, you MUST ask the user to create it (Assigned To = @Me, Work Item Type IN (${input:types}), ORDER BY Priority asc, StackRank asc). Do NOT fallback to local sorting; you MAY offer the `wit_my_work_items` fallback with unordered results and client-side type filtering.
   - If `${input:queryPath}` is NOT provided:
     - Use `wit_my_work_items` with `type = assignedtome`, `top = max(${input:top}, 50)`, `includeCompleted = false` to retrieve the IDs. Note: this does NOT apply server-side ordering beyond the predefined behavior; you MUST NOT apply client-side sorting.

2. Collect IDs
   - If using a saved query, use `wit_get_query_results_by_id` with `top = ${input:top}` to retrieve ordered work item IDs.
   - If using `wit_my_work_items`, extract IDs from the predefined query results payload.
   - If no results, you MUST create an empty artifact (see Persist step) and finish.

3. Hydrate Details
   - Use `wit_get_work_items_batch_by_ids` with `${input:fields}` or default fields.
   - Identity fields MUST remain as returned by the tool (already normalized to `Name <email>` when available).

3b. Fetch Comments (Default)
   - For each work item ID, use `wit_list_work_item_comments` to retrieve comments.
   - You SHOULD include at least the latest 10 comments (or all when few), capturing: `id`, `text` (or rendered), `createdBy` (display name), and `publishedDate/createdDate`.

3c. Filter by WorkItemType
  - Parse `${input:types}` into a set of type names by splitting on commas, trimming whitespace, and matching case-insensitively.
  - From the hydrated `items`, KEEP ONLY those where `fields["System.WorkItemType"]` is in the set.
  - Preserve the original order (stable filter). Recompute `idsOrdered` to include only IDs of the filtered items in the same order.

3d. Filter by State and Cap to Top
  - Parse `${input:states}` into a set by splitting on commas, trimming whitespace, and matching case-insensitively.
  - KEEP ONLY items where `fields["System.State"]` is in the set.
  - Preserve the original order (stable filter).
  - Cap the working set to at most `${input:top}` items by taking the first N of the filtered list. Recompute `idsOrdered` to reflect the capped list.

  - Fallback Path Ordering: When using `wit_my_work_items`, perform steps 3c and 3d immediately after hydration (Step 3) and BEFORE comments/enrichment (Step 3b). Persist the capped set first, then continue with comments and any additional enrichment for ONLY the capped items.

4. Persist Raw JSON
   - Compute `date = YYYYMMDD` (UTC preferred). Ensure folder `.copilot-tracking/workitems/` exists.
   - Write to `.copilot-tracking/workitems/${date}-assigned-to-me.raw.json` with structure:
     ```json
     {
       "project": "${input:project}",
       "queryPath": "${input:queryPath}",
       "timestamp": "<ISO8601>",
       "top": 0,
       "idsOrdered": [],
       "items": [
         {
           "id": 0,
           "fields": {},
           "comments": [
             { "id": 0, "text": "", "createdBy": "", "createdDate": "" }
           ]
         }
       ]
     }
     ```
   - You MUST overwrite if the file already exists for the same date.

5. Output
   - Report a concise summary: total items, first 5 IDs, output file path.

## Edge Cases
- Missing query with ${input:queryPath} provided: ask user to create it; you MAY offer the `wit_my_work_items` fallback (unordered). Do NOT perform client-side sorting.
- No ${input:queryPath}: use `wit_my_work_items` and proceed with unordered IDs; clearly state that ordering is not guaranteed.
- Empty results: still write a valid raw file with `[]` for `idsOrdered` and `items`.
- API errors: report the tool error content verbatim and stop.
- Invalid or empty `${input:types}`: default to `Bug, User Story, Task`. Treat matching as case-insensitive and trim whitespace.
- Invalid or empty `${input:states}`: default to `Active, New`. Treat matching as case-insensitive and trim whitespace.
