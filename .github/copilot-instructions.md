---
description: 'Comprehensive coding guidelines and instructions'
---

# General Instructions

Items in **HIGHEST PRIORITY** sections from attached instructions files override any conflicting guidance.

## **HIGHEST PRIORITY**

**Breaking changes:** Do not add backward-compatibility layers or legacy support unless explicitly requested. Breaking changes are acceptable.
**Artifacts:** Do not create or modify tests, scripts, or one-off markdown docs unless explicitly requested.
**Comment policy:** Never include thought processes, step-by-step reasoning, or narrative comments in code.
  - Keep comments brief and factual; describe **behavior/intent, invariants, edge cases**.
  - Remove or update comments that contradict the current behavior. Do not restate obvious functionality.
**Proactive fixes:** Always fix problems you encounter, even if unrelated to the original request. Prefer root-cause, constructive fixes over symptom-only patches.
