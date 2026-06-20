---
name: strict-code-reviewer
description: Performs rigorous code reviews and quality assurance checks before code is merged. Ensures compliance with brand guidelines, security standards, and architectural patterns. Use when the user asks to "review my work", "check for bugs", or "audit this file".
---

# Code Review & Quality Assurance

## When to use this skill
- Before merging any feature or fix.
- When the user asks for a "sanity check" or "code review".
- To validate compliance with `brand-identity` and `test-driven-development`.
- **Trigger:** "Review this", "Is this code good?", "Audit file X".

## Workflow: The Review Cycle

### Phase 0: Fresh Build Verification (البديهيات — قبل أي ريفيو)
Before reviewing ANY code, perform a clean environment check:
- [ ] **Kill & Restart**: Kill all node processes and start fresh (`taskkill /F /IM node.exe`, then `npm run dev`).
- [ ] **Clean Build**: Run `npm run build`. **Zero errors and zero warnings** required. If it fails, the review is automatically **BLOCKED**.
- [ ] **Browser Console**: Open the browser DevTools console. Check for runtime errors, hydration mismatches, or failed API calls.
- [ ] **TypeScript/ESLint**: Run `npx tsc --noEmit` and check for type errors. Run `npx eslint .` if configured.

> [!CAUTION]
> If Phase 0 fails, **STOP the review immediately**. Fix the build first. Do not review broken code.

### Phase 1: The Actual Review
1.  **Read Context**: Analyze the modified files and their related tests.
2.  **Verify Execution**: Run the code/tests yourself. *If you can't run it, you can't review it.*
3.  **Checklist Audit**: Systematically check against the criteria below.
4.  **Report Generation**: Create a review summary (Pass/Fail with blocking issues).

## Review Criteria (The Checklist)

### 1. Functional Integrity (The Iron Law)
- [ ] **Does it work?** Run the code. Do not guess.
- [ ] **Are requirements met?** Compare against the original task/design doc.
- [ ] **Are tests passing?** Run `npm test` or equivalent. Zero failures allowed.

### 2. Code Quality & Standards
- [ ] **Readability**: Is the code self-explanatory? Are variables named clearly?
- [ ] **DRY (Don't Repeat Yourself)**: Is there duplicated logic?
- [ ] **Type Safety**: Are there `any` types or `@ts-ignore`? (Strictly forbidden unless justified).
- [ ] **Error Handling**: Are errors caught and handled (not just logged)? See `handling-errors`.

### 3. Architecture & Security
- [ ] **Separation of Concerns**: Is business logic mixed with UI?
- [ ] **Security**: Are inputs validated? Are secrets hardcoded? (Immediate Fail).
- [ ] **Performance**: Any O(n^2) loops or unnecessary re-renders?

### 4. Brand Alignment (If UI)
- [ ] **Design Tokens**: Are we using `design-tokens.json` values?
- [ ] **Tech Stack**: Are we using the approved stack (e.g., Tailwind, Shadcn)?

## Output Template
Produce a report in this format:

```markdown
# Code Review Report: [File/Feature Name]

## 🚨 Status: [APPROVED / REQUEST CHANGES]

### 🛑 Critical Blocks (Must Fix)
- [ ] **Security**: Found hardcoded API key in `config.ts`.
- [ ] **Bug**: `calculateTotal()` returns NaN for empty inputs.

### ⚠️ Major Issues (Should Fix)
- [ ] **Architecture**: Logic in `UserCard.tsx` should move to a hook.
- [ ] **Tests**: Missing test case for error state.

### ℹ️ Minor Suggestions (Nice to Have)
- [ ] **Style**: Rename `d` to `data` for clarity.

## Verification Evidence
[Paste terminal output showing test results or execution proof]
```

## Instructions
- **Be Ruthless but Polite**: Your job is to catch bugs, not to be nice. A strict review saves hours of debugging later.
- **Evidence Required**: Never pass a review without seeing the code run successfully.
