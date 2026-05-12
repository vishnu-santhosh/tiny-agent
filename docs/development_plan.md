# Current Strategic Position

At this point, three major architectural streams are emerging:

1. **Inference Runtime Layer**

   * Minimal C wrapper around Vertex AI
   * Network/runtime abstractions
   * Token streaming
   * Authentication/session management

2. **Tiny-Agent Runtime (URP-based)**

   * PTY orchestration
   * BashAct execution paradigm
   * Agent-shell interaction model
   * Runtime primitive implementation

3. **Embedded Linux Integration**

   * Yocto meta-layer
   * PID2 execution model
   * System boot/runtime orchestration
   * Agent-native Linux distribution

These are not independent projects.
They form a stack.

---

# Most Important Realization

You do NOT need all layers fully complete before progress becomes meaningful.

The most dangerous trap now is over-designing the final architecture before validating the runtime interaction primitives.

The immediate goal should be:

> Validate the BashAct + PTY runtime primitive as early as possible.

Why?

Because the PTY interaction model is the true foundation of tiny-agent.
If this primitive becomes elegant, resilient, and portable:

* everything above it becomes simpler,
* everything below it becomes infrastructure.

The shell becomes the agent's body.

---

# Recommended Priority Order

## Phase 1 — BashAct Runtime Exploration (Highest Priority)

## Objective

Discover the correct runtime primitive for:

LLM ↔ PTY ↔ Linux process interaction.

This is the architectural heart of tiny-agent.

---

# Why This Comes First

The following unknowns are still unresolved:

* How should PTY output be chunked?
* What becomes the synchronization primitive?
* How should command completion be detected?
* How do we distinguish prompts from command output?
* Should the agent operate synchronously or event-driven?
* What should be the failure semantics?
* How should interactive programs behave?
* How should streaming outputs be routed?
* How should cancellation/interruption work?
* What becomes the canonical agent loop?

These answers will shape:

* URP design
* Tiny-agent APIs
* Runtime scheduling
* Meta-layer structure
* LLM interaction format

Without this exploration, later abstractions risk becoming incorrect.

---

# Immediate Deliverables for BashAct Exploration

## 1. Minimal PTY Harness

Create the smallest possible runtime:

```text
LLM stdin/stdout
      ↓
Tiny runtime loop
      ↓
PTY master
      ↓
/bin/sh or /bin/bash
```

No abstractions.
No framework.
No orchestration.

Just:

* forkpty()
* shell spawn
* read/write loop
* prompt detection
* output streaming

Goal:
Observe behavior.

---

## 2. Define Runtime Semantics

Document:

### Input Semantics

* How commands are sent
* Line discipline
* Multi-line commands
* Control characters
* EOF handling

### Output Semantics

* Streaming vs buffered
* ANSI escape handling
* Prompt identification
* Interactive mode behavior
* stderr/stdout treatment

### Synchronization Semantics

* When is a command “complete”?
* Prompt detection?
* Timeout?
* Exit code retrieval?

---

## 3. Define Failure Model

You need a formal model for:

* hanging commands
* broken PTYs
* zombie processes
* terminal corruption
* shell state divergence
* accidental interactive locks

This becomes critical later.

---

## 4. Experiment with Real Agent Loops

Do not immediately use Vertex AI.

Initially:

* hardcode command sequences,
* replay scripts,
* manually simulate agent outputs.

Reason:
You want to isolate PTY runtime behavior from LLM variability.

Only after the PTY primitive stabilizes should LLMs be introduced.

---

# Phase 2 — Minimal Vertex AI C Runtime

This should happen in parallel, but with narrower scope.

Goal:
Build a small, dependency-minimized inference runtime.

NOT a framework.
NOT an SDK replacement.

Just enough functionality to:

* authenticate,
* send prompts,
* stream responses,
* return tokens.

---

# Recommended Technical Direction

## Core Libraries

Prefer:

* libcurl → HTTP transport
* jansson/cJSON → JSON parsing
* OpenSSL → TLS/auth support

Avoid heavy abstractions.

---

# Minimal Interface Goal

```c
int llm_init(...);
int llm_generate(...);
int llm_stream(...);
void llm_shutdown(...);
```

Streaming support matters.

Your runtime architecture is inherently streaming-oriented.

---

# Most Important Design Constraint

The inference module must remain:

* stateless where possible,
* swappable,
* runtime-agnostic.

Tiny-agent should not become Vertex-AI-specific.

Instead:

```text
URP Runtime
    ↓
Inference Adapter
    ↓
Vertex AI / Local Model / Other Backend
```

This separation is critical.

---

# Phase 3 — Define URP Properly

Once the PTY primitive is validated:

Design the actual URP.

At this point you will finally understand:

* what the scheduler should do,
* what state must be preserved,
* how event propagation should work,
* whether synchronous loops are sufficient,
* what abstraction boundaries are natural.

Right now those answers are still speculative.

---

# Suggested URP Architecture Direction

Potential structure:

```text
+-------------------+
| LLM Adapter       |
+-------------------+
          ↓
+-------------------+
| Agent Loop        |
+-------------------+
          ↓
+-------------------+
| URP Runtime       |
| - PTY             |
| - Event Loop      |
| - Process Mgmt    |
| - Stream Routing  |
+-------------------+
          ↓
+-------------------+
| Linux             |
+-------------------+
```

But avoid freezing architecture too early.

---

# Phase 4 — Yocto Meta-Layer Integration

Only after the runtime primitive stabilizes.

Because PID2 design depends heavily on:

* supervision model,
* process lifecycle semantics,
* failure handling,
* logging strategy,
* runtime isolation.

---

# PID2 Insight

Making tiny-agent PID2 is a profound architectural choice.

That effectively makes it:

* the first userspace intelligence layer,
* an orchestrator sitting directly above init,
* part of the operating environment itself.

This is not “an app running on Linux.”

It is:

> Linux evolving into an agent-native runtime substrate.

---

# Recommended Parallel Execution Strategy

## Primary Focus (70%)

## BashAct + PTY Runtime Exploration

Daily work:

* PTY experiments
* shell interaction semantics
* synchronization logic
* runtime primitives
* event loop behavior

This is the highest architectural uncertainty.

---

## Secondary Focus (30%)

## Vertex AI Minimal C Runtime

Daily work:

* authentication flow
* streaming transport
* request serialization
* response parser
* lightweight abstraction layer

This can mature independently.

---

# What NOT To Do Yet

Avoid:

* premature multi-agent orchestration
* complex planning systems
* memory architectures
* high-level frameworks
* plugin systems
* elaborate URP APIs
* distributed execution
* elaborate state machines

First validate:

> Can an LLM reliably inhabit a PTY-driven shell environment through a tiny runtime primitive?

Everything else depends on that.

---

# Suggested Immediate Milestone Sequence

## Milestone 1

Minimal PTY shell bridge in C.

---

## Milestone 2

Reliable prompt detection + command completion.

---

## Milestone 3

Streaming output routing.

---

## Milestone 4

Interactive process handling.

---

## Milestone 5

Minimal Vertex AI streaming inference.

---

## Milestone 6

Connect inference engine to PTY runtime.

---

## Milestone 7

Run autonomous shell tasks.

---

## Milestone 8

Package runtime inside Yocto image.

---

## Milestone 9

Promote runtime into PID2 execution model.

---

# Final Recommendation

Your instinct to pursue BashAct exploration first is correct.

The PTY interaction model is the deepest unknown.

The Vertex AI runtime is important,
but it is ultimately infrastructure.

The true invention opportunity lies in:

> discovering the correct primitive for embodied agent interaction with Unix.

That primitive is likely to shape everything else that follows.
