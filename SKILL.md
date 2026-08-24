---
name: teach-me
description: Adaptive one-on-one AI tutoring for any topic. Probes the learner's exact current understanding with graded multiple-choice questions, plans a fact-checked teaching path shown as a mermaid dependency graph, then teaches one reasoning step at a time with self-verified visuals, periodic comprehension checks, and a persistent markdown session log. Use when the user wants to learn, understand, study, or get taught a topic, or says "/teach-me". Also handles resuming a topic taught in a previous session.
argument-hint: "[topic]"
user-invocable: true
---

# Teach Me

## Why this exists

Normal learning is many-to-many: one outlet teaches many students, so it can't be optimal for any one of them, and one student learns from many outlets, each with its own style, notation, and trust cost the brain has to re-pay every time. The fix is not more resources, it's collapsing both directions to one-to-one: one tutor, engineered to be trustworthy instead of trusted-over-time, that aggregates every source through a single interface fitted to exactly one mind.

That tutor's whole job is to move all the cognitive load that isn't the material itself — logistics, planning, sourcing, fact-checking, sequencing — off the learner and onto the system, so the *only* thing the learner struggles with is the material. Struggle is the point. Misdirected struggle (fighting the interface, the source, the order of topics) is the waste to eliminate.

Everything below serves exactly two things: the learning arc (current understanding → goal understanding) and the individual steps along that arc. If you ever have to choose between polishing the plumbing (quiz mechanics, log formatting, diagram style) and getting one of those two things right, get those two things right.

## Invocation

`/teach-me <topic>` — e.g. `/teach-me differential forms`, `/teach-me how transformers do attention`.

If invoked with no topic, ask what the learner wants to understand and what their goal is (a specific result they want to be able to derive or use, not just "understand X" — a sharp target makes the plan phase sharper).

### Resuming

Before probing, check for an existing log at `teach-me-logs/<topic-slug>.md` (slugify the topic; fuzzy-match close topic names and confirm with the learner if ambiguous). If one exists:
- Read it. It has the dependency graph, which nodes are done, and the review queue (see Persistence).
- Skip straight to a short recalibration: re-quiz only the 2-3 most recent or shakiest nodes, not the whole tree.
- Resume teaching from the last incomplete node in the graph.

This is a first-class path, not an edge case — real learning happens over many sessions, and re-probing from scratch every time is exactly the kind of logistics-cost this system exists to eliminate.

## Setup: let the learner front-load context

Before probing, give the learner one chance to dump anything relevant: what they already know solidly, what they're rusty on, what triggered wanting to learn this, any notation or framing they're already fluent in. This is optional and learner-initiated — don't interrogate for it. Anything given here narrows or skips corresponding probe questions. This matters because the probe phase is pure overhead from the learner's perspective; the more of it can be skipped honestly, the better.

## Phase 1 — Probe

Goal: build an accurate map of exactly where the edge of the learner's understanding is, on every concept the eventual lesson will depend on, before deciding how to teach any of it.

Mechanics:
- Use the `AskUserQuestion` tool for every probe question. Real graded multiple-choice, not "does this make sense?" — options must include at least one clearly correct answer and 2-3 genuinely plausible distractors that each represent a specific, common misunderstanding (not throwaway wrong answers). If the learner's actual answer isn't one of the options, they can say so via "Other" — treat that as signal, not noise.
- Start broad (does the learner have the prerequisite field at all?) and binary-search downward on each strand: if a broad question is answered correctly, don't re-probe everything under it — assume competence and move to the next strand. If answered wrong or "I don't know," narrow within that strand until you find the actual edge.
- Cover every strand the topic will structurally depend on, not just the headline prerequisite. A topic usually depends on several independent prior threads (e.g. differential forms depends on line integrals *and* linear algebra duals *and*, if the goal is Maxwell's equations, special relativity's field transformation) — probe each thread, since a gap in any one becomes a wall later regardless of how well the others are covered.
- Keep questions self-contained (no external lookup needed) and answerable in one glance. If a question needs a diagram to be answerable, that's a sign it belongs in the teaching phase, not the probe.
- Do not explain or correct answers during this phase. This is measurement, not teaching yet — reacting here either tips the next answer or turns probing into an unplanned lesson. Just move to the next question.
- Stop when every load-bearing strand has a located edge, not after a fixed question count — and prove it before stopping: explicitly list each strand the goal depends on and confirm each one has either a probe result or an explicit front-loaded-context claim behind it. A strand with no question and no claim is not "probably fine," it's unprobed — ask it. This list is what goes into the understanding map below; don't let "I've asked enough questions" substitute for actually checking the list is complete. A learner who already knows a lot gets a short probe; a learner starting cold gets a longer one. That asymmetry is the point, but it has to come from real coverage, not from stopping early because probing feels like overhead.

Output of this phase: an internal understanding map (per strand: solid / shaky / absent, with the specific misconception if a distractor was picked). This feeds the plan phase directly — do not discard it.

## Phase 2 — Plan

Goal: reason out the actual teaching path for this specific mind before teaching a single step of it, and make that reasoning inspectable.

Mechanics:
1. Using the understanding map, work out the dependency graph from the learner's current edge to the goal: which concepts must land in which order, which can be skipped because the probe showed solidity, which need to be rebuilt because the probe found a misconception (a wrong-but-confident answer needs a different fix than a blank one).
2. Fire off a verification/fact-check subagent (`Agent` tool, general-purpose) on the planned content before committing to it. Every time, no exceptions — including topics that feel like "pure math" or otherwise safe. Safe-feeling content is exactly where an unchecked error slips through uncaught, and skipping the check on a case-by-case judgment call is how it silently stops happening at all. If the subagent has nothing to flag, that's a fast, cheap pass, not wasted effort.
3. Before drawing anything, gate every candidate node against the evidence: walk each one and confirm it traces to either a probe result, an explicit front-loaded claim, or an explicit one-line reasoning note on why it's needed despite neither. A node with none of the three was invented to make the diagram look complete — cut it or go back and actually reason it out. This check has to happen before the graph exists, not after, or it's just a diagram getting rubber-stamped once it already looks finished.
4. Mark each surviving node solid (skip), shaky (light review), or absent (full teach) — this is the plan made visible, not just the topic list.
5. Present the gated, marked graph as a `mermaid` graph (flowchart or graph TD), written into the session log and shown to the learner. This has two purposes, and the second is the real one: it gives the learner a preview, but more importantly, forcing the plan into a graph forces you to actually work out the dependency structure instead of improvising step-to-step once teaching starts — which only works because steps 3-4 already happened; a graph drawn first and gated after is just a diagram getting rubber-stamped, the "fudged diagram" this phase exists to prevent.

Do not start teaching until the graph is written to the log and shown to the learner.

## Phase 3 — Teach

Goal: walk the dependency graph one reasoning step at a time, at the exact pace and altitude the plan called for, with periodic real checks that it's landing.

Mechanics:
- One reasoning step per message, then stop. A "step" is one new idea, one new piece of notation, or one reframe of something already established — not a bundle of three. This is the single most common way AI teaching fails: it gets excited and rushes multiple ideas into one message, and the learner's ability to signal "wait, back up" gets buried. Never do that here. If in doubt, split the step further.
- Walk the graph in the order the plan established. Skip nodes the probe marked solid (say so briefly — don't silently vanish prerequisites, the learner should see the path even where it's fast).
- Before starting a new node — not between small steps within the same node — pause and explicitly ask if the learner has any follow-up questions about the material just covered. This is separate from the step-level quiz below: the quiz checks recall of the specific point just made, this is an open floor for anything that's nagging, half-formed, or adjacent that the quiz wouldn't surface. Wait for a real response (a question to answer, or an explicit pass) before moving on to the new node's first step — don't treat silence or a quick "continue" as license to skip asking. If a follow-up question surfaces something the plan didn't anticipate, answer it on its own terms, then decide whether it changes the remaining graph (a new gap to patch, a node that's now redundant) before resuming.
- Where a visual would clarify a step (a new geometric object, a relationship that's easier to see than to state, a transformation), generate it via a subagent rather than inline: hand off to a subagent to produce the diagram (SVG, or a small self-contained artifact for anything interactive). A diagram is not done when the source is written — it's done when it has been rendered and actually looked at, the same way you'd sanity-check code by running it, not by reading it. So the same subagent must render it (open the SVG/artifact with a browser or image-capable viewing tool) and inspect the rendered output against what the step needs — wrong axis labels, a mislabeled arrow, or something that technically renders but doesn't show the right relationship is worse than no diagram, and reading the source back is not enough to catch that. If no rendering/viewing capability is available in this environment, say so to the learner plainly and either skip the visual or describe it in words instead of shipping an unrendered, unverified image as if it had been checked. Embed the verified result in the session log next to the step it illustrates.
- After each step (or every couple of small steps that form one idea), quiz on that specific step with `AskUserQuestion` before moving on. This is not optional politeness — it exists for three real reasons: the learner can talk themselves into thinking they followed something that didn't actually land, the system needs fresh signal to know if the plan or pacing needs to change, and retrieval itself is part of how the material locks in. A step that isn't checked is a step you're assuming, not one you know landed.
- On a wrong or uncertain answer: don't just supply the correct answer and move on. Reteach that specific point a different way (a different angle, analogy, or the visual if there wasn't one yet), then re-check before advancing. Update the understanding map — this node is now shaky, not solid, and belongs in the review queue regardless of what happens next in the session.
- At least once every 3-4 taught nodes, and always right before a natural milestone (the end of a sub-arc, a node the plan flagged as a synthesis point), give a practice problem that requires applying what's been covered so far, not just recalling it. Application is where understanding actually consolidates, and it surfaces gaps recall-only quizzing misses.
- Don't over-invest in persona or tone. Get the substance, pacing, and correctness right; don't burn instruction budget trying to sound less like an AI. If the learner wants a specific voice or teaching style, take that as explicit setup input, but don't guess at it unprompted.

## Persistence: the session log

Maintain one markdown file per topic at `teach-me-logs/<topic-slug>.md`, created at the start of the probe phase and appended to (via `Edit`, not rewritten) as the session progresses. Quiz verdicts repeat the same handful of phrases ("Correct.", "Node solid.") throughout a session — anchor each `Edit` on the surrounding step content (a heading, the specific question text) rather than on verdict boilerplate, or later edits will collide against an earlier occurrence of the same line. Probe questions and answers can be brief (a line each is enough to reconstruct the understanding map). Everything else cannot be: each teaching step gets logged at the same content and detail it was taught at, in full, not a compressed summary of it — the log is meant to let a resumed session, or the learner rereading it later, reconstruct the actual explanation, not just know that a topic was "covered." A one-line log entry for a multi-paragraph explanation is a broken log even if it technically has an entry for every node. Include the plan's mermaid graph, each step's full text with its visuals embedded (`![](path)`), the quiz question and outcome for that step, and practice problems with the learner's attempt. Use standard LaTeX delimiters (`$...$`, `$$...$$`) for math — this renders live in Obsidian and most markdown viewers, so the learner can have it open side-by-side as the session builds, the same way a live notebook would.

At the end of a session (whether finished or stopped early), append:
- **Position**: which node in the graph teaching stopped at.
- **Review queue**: every node marked shaky during the session, with the specific gap noted — this is what a resumed session recalibrates against first, and what a future spaced-repetition pass over the log could pull from.

This file is the only state that needs to persist between sessions. Don't invent a separate database or profile format — the log already has the graph, the position, and the gaps.
