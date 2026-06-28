---
name: comprehensive-code-review
description: >-
  Comprehensive code review across three lenses — correctness/bugs, security, and
  simplification/readability — producing a severity-ranked report (Critical/High/Medium/Low)
  with file:line references and concrete fixes. Use this whenever the user wants code reviewed,
  audited, or quality-checked: reviewing a diff or PR, looking for bugs before merging or
  committing, auditing a file or module, or verifying a change is safe to ship — even if they
  don't say the word "review" explicitly. Also use when a code-review subagent needs a
  consistent review methodology to follow.
---

# Comprehensive Code Review

Review code the way a thoughtful senior engineer would: find the problems that actually
matter, explain _why_ each one matters, and propose a concrete fix. The goal is a report the
author can act on directly — not a vague list of nitpicks, and not a wall of false positives
that erodes trust.

## When you're invoked

You may be asked to review one of several things. Figure out the scope first:

- **A diff / changes** — review only what changed (plus enough surrounding context to judge it).
  Get the diff with `git diff`, `git diff --staged`, or `git diff <base>...HEAD`.
- **Specific files** — review the named files in full.
- **A whole project** — sweep the codebase; prioritize entry points, shared utilities, and
  anything handling untrusted input.

If the scope is ambiguous, default to reviewing the current uncommitted changes
(`git diff HEAD`), and state that assumption at the top of your report.

## The three lenses

Look at the code through each lens in turn. They catch different classes of problems, so don't
collapse them — a security hole and a readability smell deserve different scrutiny.

### 1. Correctness & bugs

The question: _will this do the wrong thing for some realistic input or sequence of events?_

- Logic errors, off-by-one, inverted conditions, wrong operator.
- Unhandled edge cases: empty input, null/undefined, zero, negative numbers, very large input,
  duplicate keys, missing keys.
- Error handling: failures swallowed silently, errors that leave state half-updated, promises
  not awaited, exceptions that escape and crash the flow.
- Async/concurrency: race conditions, read-modify-write that isn't atomic, missing `await`,
  unhandled rejections, state mutated from two places.
- Resource issues: leaks (listeners, connections, file handles), unbounded growth.
- Contract mismatches: a function called with the wrong shape, an API used against its
  documented behavior, off-by-one in array indexing.

### 2. Security

The question: _can an untrusted actor make this misbehave, leak data, or exceed their privileges?_

- Injection: SQL, command, HTML/XSS, template injection. Is user input ever concatenated into
  a query, a shell command, or `innerHTML`?
- AuthZ/AuthN: missing access checks, trusting client-supplied identity, privilege escalation.
  For systems with row-level security or policies, check that mutations can't be forged
  client-side.
- Secrets: hardcoded keys/passwords/tokens that are actually sensitive. (Note: some keys are
  _designed_ to be public — e.g. a Supabase anon key or a publishable API key. Don't flag those
  as leaks; the real risk there is whether the _access policies_ behind them are correct.)
- Data exposure: more data returned than needed, sensitive data logged, verbose errors leaking
  internals.
- Input validation: unvalidated/unsanitized input crossing a trust boundary.

### 3. Simplification & readability

The question: _could the next person understand and safely change this in less time?_

- Duplication that should be factored out; or premature abstraction that should be inlined.
- Dead code, unused variables, unreachable branches.
- Naming that misleads or obscures intent.
- Overly clever one-liners where a plain version would be clearer.
- Functions/files doing too much — a signal the boundaries are wrong.
- Reinventing something the codebase or standard library already provides.

Be careful here: readability is the lens most prone to noise. Only raise a simplification point
if it genuinely reduces bugs or cognitive load — not just to match a personal style.

## Severity rubric

Rank every finding so the author knows what to fix first. Use this rubric consistently:

- **Critical** — security vulnerability, data loss/corruption, or a bug that breaks a core flow
  for normal use. Must fix before shipping.
- **High** — a real bug that triggers on a plausible (if not the most common) path, or a
  security weakness with meaningful impact. Should fix before shipping.
- **Medium** — a bug on an edge case, missing error handling, or a maintainability problem that
  will bite later. Fix soon.
- **Low** — minor readability/style/cleanup. Nice to fix; safe to defer.

When unsure between two levels, pick the lower one and say why — over-escalating trains the
reader to ignore you.

## Output format

ALWAYS structure the report exactly like this:

```
# Code Review: <what was reviewed>

**Scope:** <files / diff range reviewed>
**Summary:** <1-3 sentences: overall health and the single most important thing to address>

## Critical
### <short title>
- **Where:** `path/to/file.ext:42`
- **Problem:** <what's wrong and the why — the impact>
- **Fix:** <concrete suggestion; a short code snippet if it helps>

## High
（same structure; omit the section entirely if empty）

## Medium
（same）

## Low
（same）

## What looks good
<1-3 bullets on things done well — brief, genuine, skip if nothing stands out>
```

Rules for the report:

- If a severity section has no findings, **omit the section header entirely** rather than writing
  "None". A short report is a feature.
- Every finding needs a `file:line` (or `file:function` if line is unstable). A finding the
  author can't locate is useless.
- Lead each finding with impact, not mechanism. "Two users voting at once can lose a vote
  (race condition)" beats "read-modify-write pattern detected."
- If you found nothing worth raising, say so plainly: "No issues found above Low severity." Don't
  manufacture findings to look thorough.

## Process

1. Determine scope (diff / files / project). State it.
2. Read the code. For a diff, read enough surrounding code to judge correctness — don't review
   a hunk in isolation.
3. Pass through each lens (correctness → security → simplification).
4. For each candidate finding, sanity-check it before writing it down: re-read the relevant
   code and confirm it's real. **A false positive costs more than a missed nit** — it makes the
   author distrust the whole report.
5. Assign severity with the rubric.
6. Write the report in the exact format above.

## Principles

- **Verify before you claim.** If you assert a bug, you should be able to describe the exact
  input or sequence that triggers it. If you can't, downgrade it to a question or drop it.
- **Cite location.** Always `file:line`.
- **Explain the why.** The author learns from the reasoning, not the verdict.
- **Propose a fix.** Even a one-line sketch. Reviews that only criticize are half-done.
- **Respect intent.** Don't propose unrelated rewrites or impose style preferences as if they
  were defects. Stay focused on what makes the code more correct, safer, or clearer.
