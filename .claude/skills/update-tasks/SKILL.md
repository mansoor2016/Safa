---
name: update-tasks
description: "Review and update the project TASKS.md file. Audits completed work, compacts the completed section, and ensures the task list accurately reflects project state."
allowed-tools: Bash, Glob, Grep, Read, Edit
user-invocable: true
---

# Update Tasks Skill

Review the project task list, audit what's been completed, compact the completed section, and update task statuses. Optimized for agent parsibility.

## Arguments

Optional:
- First argument: path to the tasks file (e.g. `/update-tasks .docs/TASKS.md`)
- If no argument provided, search for the file automatically

## Workflow

### Step 1: Find the tasks file

If a path argument was provided, use it (relative to project root). Otherwise:
```
Search for TASKS.md in these locations (in order):
1. .docs/TASKS.md
2. docs/TASKS.md
3. TASKS.md
```
Read the file. If not found, report an error and stop.

### Step 2: Audit recent completed work

Gather evidence of what's been done recently:

1. **Read recent git history** (last 20 commits):
   ```bash
   git log --oneline -20
   ```

2. **Read the current TASKS.md** to understand existing state.

3. **Cross-reference** git commits against open tasks (`[ ]`) to identify tasks that are now complete but not yet checked off.

### Step 3: Update the file

Apply these changes using the Edit tool:

#### a) Check off newly completed tasks
- Change `- [ ]` to `- [x]` for any task that git history confirms is done.
- If a task is partially done, leave it as `[ ]` but add a note like `(partial — X done, Y remaining)`.

#### b) Compact the Completed section
The `## Completed` section is a single dense paragraph. Append any newly completed phase tasks to it as short comma-separated phrases. Follow the existing style: no bullet points, no line breaks within the paragraph, just flowing text with commas and periods.

When appending, use this pattern:
- Feature name + key detail in parentheses if needed
- Example: `Dua favourites (quick access + heart toggle), in-app review prompt (exponential backoff).`

Remove checked-off items (`- [x]`) from the phase sections after appending their summary to the Completed paragraph. This keeps the phase sections short — only open tasks remain.

#### c) Update the timestamp
Change the `*Last Updated:` line at the bottom to today's date and a brief note of what changed.

### Step 4: Show a summary

After editing, output a concise summary:

```
## Tasks Updated

**Newly completed:** (list items moved to completed, or "None")
**Still open:** (count of remaining [ ] items per phase)
**Next priority:** (first unchecked item in highest-priority phase)

Updated: .docs/TASKS.md
```

## Rules

1. NEVER delete or modify open tasks (`[ ]`) unless you have git evidence they're done
2. NEVER rewrite the Completed paragraph from scratch — only append to it
3. NEVER change task ordering within phases
4. Keep the Completed paragraph as a single dense block — no bullet points, no blank lines within it
5. Preserve the phase structure (headers, "Why" explanations)
6. If unsure whether a task is complete, leave it as `[ ]`
7. Manual/device testing tasks (marked with `*(manual ...)*`) should only be checked off if explicitly told to — git commits can't prove manual verification
