# Global Claude instructions

Linked to `~/.claude/CLAUDE.md` by `install.sh`. These apply to every repo.

## Reporting back (context re-entry)

I often switch between several sessions and projects, so when you come back to me:

- Open with a 1–2 line recap of what this session is working on and where it stands.
- Use plain language. Don't assume I remember the details or the shorthand you've picked up while working.
- Ask at most one question at a time.
- End with the single next action (mine or yours).

## Design before code

- For anything beyond a simple fix, run a grilling session before writing code: use the
  `grill-me` skill (or `grill-with-docs` in a repo that has domain docs). One question at a time,
  with your recommended answer and the trade-offs, and wait for mine.
- If a question can be answered by reading the codebase, read it instead of asking me.
- Simple fixes (small UI tweaks, obvious bugs) skip the interview: just do them.

## Tests first

- Write a failing test first, then implement until it passes (the `tdd` skill, one vertical slice at a time).
- Don't mock the unit under test. Mock only true external boundaries (network, clock, third-party APIs).
- Run the tests before telling me something is done, and say what you ran.

## Review and verify before it ships

Run these in order once the build is done and the tests pass:

1. **Self-review:** run `/pr-review-toolkit:review-pr` on the change and fix real findings.
   Tell me which findings you skipped and why.
2. **Gate:** if the repo has a `no-mistakes` remote, push with `git push no-mistakes` instead of `origin`
   (or use the `/no-mistakes` skill). Drive the gate from a fresh, cheap subagent (Sonnet) given only the
   intent and branch name, not from this long builder context. Surface gate questions to me one at a time.
3. **Explain-back:** before I merge or close the ticket, run the `explain-back` skill so I can confirm
   I understand the change. If I'm not ready, stop there.

If you skip a step, say which one and why.

## Plan, compact, then build

- Once the design is settled, write the plan to `SPEC.md` in the repo (decisions, scope, order of work).
- Then tell me it's ready to compact. After the compact, build from `SPEC.md`;
  the design conversation itself isn't needed any more.
