# Global Claude instructions

Linked to `~/.claude/CLAUDE.md` by `install.sh`. These apply to every repo.

## Reporting back (context re-entry)

I often switch between several sessions and projects, so when you come back to me:

- Open with a 1–2 line recap of what this session is working on and where it stands.
- Use plain language. Don't assume I remember the details or the shorthand you've picked up while working.
- Ask at most one question at a time.
- End with the single next action (mine or yours).

## Design before code

- For anything beyond a simple fix, interview me about the design before writing code.
  Ask one question at a time, offer options with trade-offs, and wait for my answer.
- Simple fixes (small UI tweaks, obvious bugs) skip the interview: just do them.

## Tests first

- Write a failing test first, then implement until it passes.
- Don't mock the unit under test. Mock only true external boundaries (network, clock, third-party APIs).
- Run the tests before telling me something is done, and say what you ran.

## Plan, compact, then build

- Once the design is settled, write the plan to `SPEC.md` in the repo (decisions, scope, order of work).
- Then tell me it's ready to compact. After the compact, build from `SPEC.md`;
  the design conversation itself isn't needed any more.
