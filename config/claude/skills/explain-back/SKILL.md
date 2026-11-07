---
name: explain-back
description: Check that I actually understand a change before we move on. Use when I say "explain-back", "quiz me on this", "check my understanding", or before marking a feature, ticket or PR as done.
---

# Explain-back check

The goal is to confirm I understand what was built and why, not to test trivia.

1. In one or two lines, say which change you are quizzing me on (branch, PR or files).
2. Ask 3 questions, **one at a time**, and wait for my answer before the next:
   - **Why:** why was it done this way instead of the obvious alternative?
   - **How:** walk through what happens at runtime for one concrete input or user action.
   - **Risk:** what would break, or what test would fail, if a specific line or decision were changed?
   Base every question on the actual diff and the decisions made in this session. No multiple choice.
3. After each answer, say plainly whether it's right, partly right or wrong, and fill the gap in 2–3 sentences.
   Point to the file and line if it helps.
4. At the end, give a one-line verdict:
   - **Ready:** all three answered correctly or close.
   - **Not yet:** list the concept(s) I should review, and offer a 2-minute explanation of each.
5. If I'm not ready, don't merge, push through the gate, or close the ticket unless I explicitly say to go ahead anyway.
