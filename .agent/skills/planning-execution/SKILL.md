---
name: planning-execution
description: Generates detailed, step-by-step implementation plans and enforces strict execution order. Prevents skipping steps or multitasking without completion.
---

# Implementation Planning & Strict Enforcement

## When to use this skill
- After a Design Document has been approved.
- To CREATE a new roadmap.
- To **EXECUTE** an existing roadmap step-by-step.
- **Trigger:** "Plan this", "Start building", "What's next?", "Execute Step X".

## Workflow

### 1. Plan Creation (If no plan exists)
- [ ] **Read Design**: Load `docs/designs/...`.
- [ ] **Atomic Tasks**: Break work into 15-min tasks.
- [ ] **Write Plan**: Save to `docs/plans/YYYY-MM-DD-[topic].md`.

### 2. Strict Execution (The "Enforcer" Mode)

#### Step 0: Environment Readiness (البديهيات — قبل أي شغل)
Before starting ANY implementation step, verify these basics:
- [ ] **Dev Server Running?** Check that `npm run dev` is active. If not, start it.
- [ ] **Clean State?** If switching branches or pulling changes, run `npm install` first.
- [ ] **After Each Step**: Run `npm run build` to catch TypeScript/bundling errors immediately. **Never** move to the next step if the build is broken.
- [ ] **After Major Changes**: Restart the dev server (kill node processes, re-run `npm run dev`). Major changes include: modifying configs, adding/removing dependencies, changing file structure.
- [ ] **Browser Check**: After UI changes, verify in the browser that nothing looks broken.

#### Execution Flow
When the user says "Next" or "Do it":
1.  **Read the Plan**: Open the current plan file.
2.  **Identify Next Step**: Find the *first* unchecked box `[ ]`.
    - *If user asks to skip:* REFUSE politely unless explicit override given.
    - *If user asks for something else:* Remind them of the current step.
3.  **Execute**: Perform the code edits/commands for THAT step only.
4.  **Build Check**: Run `npm run build`. If it fails, fix immediately.
5.  **Verify & Mark**:
    - If successful, **edit the plan file** to mark it `[x]`.
    - If failed, **do not mark**. Fix it first.
6.  **Report**: "Step X Complete. Next is Step Y: [Description]. Proceed?"

## Instructions

### 1. The "Blind Engineer" Persona
Write steps for a junior dev with zero context.
- **Bad:** "Fix the bug."
- **Good:** "In `api.ts`, change line 50 to `return true`."

### 2. One Step at a Time
- **NEVER** execute multiple phases at once.
- **NEVER** mark a step as done unless you have verified it (e.g., file created, build passed).

### 3. Plan Document Template
```markdown
# Implementation Plan - [Topic]

## Phase 1: Setup
- [x] Step 1: Install dependencies
- [ ] Step 2: Create utility file `utils/helper.ts`  <-- CURRENT FOCUS

## Phase 2: Core Logic
- [ ] Step 3: Implement class `User`
```

## Output
- **Creation:** "Plan created at [path]. Ready for Step 1?"
- **Execution:** "Step [N] Done. Plan updated. Ready for Step [N+1]?"
