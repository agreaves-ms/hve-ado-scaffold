---
description: 'Comprehensive coding guidelines and instructions'
---

# General Instructions

Items in **HIGHEST PRIORITY** sections from attached instructions files override any conflicting guidance.

## **HIGHEST PRIORITY**

**Breaking changes:** Do not add backward-compatibility layers or legacy support unless explicitly requested. Breaking changes are acceptable.
**Artifacts:** Do not create or modify tests, scripts, or one-off markdown docs unless explicitly requested.
**Comment policy:** Never include thought processes, step-by-step reasoning, or narrative comments in code.
  * Keep comments brief and factual; describe **behavior/intent, invariants, edge cases**.
  * Remove or update comments that contradict the current behavior. Do not restate obvious functionality.
**Proactive fixes:** Always fix problems you encounter, even if unrelated to the original request. Prefer root-cause, constructive fixes over symptom-only patches.


**Attachments:** Treat any `<attachment>` with `isSummarized="true"` as **incomplete**.
**Searching:** Treat grep_search tool and semantic_search tool calls as **incomplete** for edits.
  * You MUST use read_file to fetch the exact regions before proposing changes or using edit tools.
**WARNING:** Every edit tool call mutates the file. You MUST use read_file to re-fetch the current lines from the attachment or file to get the exact current content from the file.


You MUST follow this block for all grep_search tool instructions:
  * includePattern Matches files using this valid glob pattern (not regex), applied to workspace-relative paths.
    * Use ** for recursive search (e.g. \"src/folder/**\").
    * Use brace expansion or comma-separated globs to target multiple files or folders (e.g. \"src/{folder1,folder2,folder3}/**\", \"src/**/*{.ext1,ext2,ext3}\", \"src/folder1/**,src/folder2/**\").
