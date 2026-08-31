# Agent RULE — MATHOS RECOVERY PROTOCOL

## 1. Canonical local location
Folder name:
`Agent recovery`

Expected location at the Mathos project root:
`<MATHOS_PROJECT_ROOT>\Agent recovery\`

This recovery folder is LOCAL-ONLY operational state. Do not upload it to Google Drive or expose internal agent workflow unless M1 explicitly authorizes it.

Required files — exactly these six notes:
- Agent1.md
- Agent2.md
- Agent3.md
- Agent4.md
- Agent5.md
- Agent RULE.md

## 2. Mandatory rule — update on EVERY prompt
Every Agent1–Agent5 MUST do this immediately whenever it receives a new prompt from M1:

1. Read `Agent RULE.md`.
2. Read its own `AgentN.md`.
3. BEFORE starting implementation, update its own note with:
   - TASK_ID/title;
   - exact goal;
   - scope and prohibited scope;
   - dependencies;
   - worktree/branch/current HEAD;
   - acceptance gates;
   - current status;
   - a new Recent Prompt Log entry.
4. Perform the task.
5. BEFORE sending a REPORT, update the same note again with:
   - files changed;
   - key findings/decisions;
   - tests and exact counts;
   - blockers/escalations;
   - current/final full HEAD;
   - worktree status;
   - next action;
   - enough handoff context for another agent to continue.

No prompt is considered fully received until the recovery note has been updated.
No report is considered ready until the recovery note reflects the report state.

## 3. Ownership
- Agent1 writes ONLY Agent1.md.
- Agent2 writes ONLY Agent2.md.
- Agent3 writes ONLY Agent3.md.
- Agent4 writes ONLY Agent4.md.
- Agent5 writes ONLY Agent5.md.
- Agents must not rewrite another agent's recovery note.
- `Agent RULE.md` may be changed only by explicit M1 instruction.

## 4. Recovery quality requirement
Each AgentN.md must be sufficient for this scenario:

> Chat history is lost. M1 uploads only the six recovery notes to a new ChatGPT session, or gives them to another agent. The new reader must know the active task, current code lineage, scope, decisions, blockers, test evidence, and exact next action without guessing.

Therefore NEVER write vague entries such as:
- "same as before"
- "continue old task"
- "see chat"
- "already discussed"

Write explicit state instead.

## 5. Git safety
Always record the FULL Git commit SHA, not a shortened hash, when a commit exists.
Record:
- worktree path;
- branch;
- start HEAD;
- current/final HEAD;
- canonical base when relevant;
- clean/dirty status.

Do not claim PASS if the note does not contain the evidence needed to recover that decision.

## 6. Status vocabulary
Prefer explicit states:
- PROMPT_RECEIVED
- IN_PROGRESS
- READY_FOR_REVIEW
- PASS / CLOSED
- FIX_REQUIRED
- BLOCKED
- WAITING_ON_DEPENDENCY
- WAITING_ON_M1

Do not turn waiting/blocking states into PASS.

## 7. Handoff / cross-agent recovery
If M1 asks another agent to continue a task:
- the receiving agent first reads Agent RULE.md;
- reads the source agent's note;
- copies only the context needed into its own note;
- records that the task was inherited and from whom;
- does not modify the source agent's note.

## 8. Keep it current, not huge
The recovery note is a state ledger, not a raw chat transcript.
Keep current authoritative facts plus a compact Recent Prompt Log.
If old details are superseded, summarize them rather than allowing the note to become unusably large.
Never delete facts still required to understand an accepted HEAD, unresolved blocker, or architectural decision.

## 9. M1 standard footer
From now on, every M1 prompt to Agent1–Agent5 should include this operational instruction:

`RECOVERY RULE: Before starting this prompt, read <MATHOS_PROJECT_ROOT>\Agent recovery\Agent RULE.md and your own AgentN.md, then update your AgentN.md with this prompt, current branch/worktree/full HEAD, scope, gates, and status. Before returning your REPORT, update AgentN.md again with results, tests, blockers, final full HEAD, and next action. This is mandatory.`

## 10. Privacy
This folder exists specifically to recover internal M1/agent state locally.
Do not place it in shared/public deliverables, Google Drive handoffs, presentation assets, or external documentation unless M1 explicitly instructs otherwise.
