# Ethos-U integration documentation ToDo

This document tracks the work required to turn the current integration guidance
into a reproducible and verified developer journey. Items in this file are
planning tasks, not yet validated product guidance.

## Desired outcome

A developer can start with a quantized ML model, build and run it on a concrete
Ethos-U device, verify the memory configuration, measure it with the NPU PMU,
tune one configuration parameter, and repeat the same flow with Zephyr.

## Work packages

### 1. Create a reproducible Alif Ensemble E8 reference application (P0)

**Why:** The Integration chapter uses an Alif E7 configuration as an example,
but the repository does not contain a corresponding hardware application that
can be built, inspected, and tested. A maintained E8 reference repository would
provide the concrete source of truth for the complete integration flow.

**Repository:** `arm-examples/CMSIS-Ethos-Integration`

**Deliverables:**

- A public repository or self-contained example targeting one explicitly named
  E8 device, board, Cortex-M core, Ethos-U instance, and MAC configuration.
- Document the minimum requirements, but keep the default setup compatible with
  current CMSIS-Toolbox, Vela, compiler, DFP, and board support releases rather
  than pinning the example to one known-good combination.
- The CMSIS solution, board layer, device-specific `vela.ini`, linker
  configuration, driver settings, model conversion step, and run/debug setup.
- At least one SRAM/Flash or SRAM/MRAM placement verified through the Vela
  report, linker map, and successful inference on hardware.
- Known-good input and output data and an automated pass/fail result.
- A documented license and redistribution approach for vendor files that
  cannot be committed directly.

**Acceptance criteria:** A clean checkout can be built by following the README,
the model can be regenerated, and the application passes on the named E8 board.
The recorded Vela configuration, linker placement, and `NPU_REGIONCFG_x`
settings describe the same physical memories.

### 2. Verify and correct the Zephyr integration flow (P0)

**Why:** The Zephyr chapter documents a plausible setup, but guidance should not
be presented as a working flow until its commands, configuration, and runtime
behavior have been reproduced.

**Deliverables:**

- Use `arm-examples/CMSIS-Ethos-Integration` as the initial basis for the
  Zephyr exploration so that the hardware configuration, model, test data, and
  expected output can be shared with the CMSIS solution flow where practical.
- A validation matrix containing the tested Zephyr revision, SDK/toolchain,
  TensorFlow Lite Micro revision, board or FVP, NPU variant, and Vela version.
- A clean-workspace test of module fetching, devicetree, Kconfig, model
  compilation, build, execution, and expected output.
- Verification of interrupt delivery, tensor and fast-memory placement, cache
  handling, and the `arm,ethos-u` devicetree properties used by the example.
- Corrections to the Zephyr chapter based on the observed workflow.
- Preferably, an automated FVP smoke test that detects future regressions.

**Acceptance criteria:** Every published command has been executed from a clean
environment and produces the documented result. Hardware-specific statements
are either verified on hardware or clearly labelled as assumptions.

### 3. Add a complete custom-model integration example (P1)

**Why:** The documentation explains where to replace model files, but it does
not demonstrate the complete change from an external quantized model to a
running application. This leaves model metadata, tensor handling, generated C
data, arena sizing, and result validation implicit.

**Deliverables:**

- Use the model that runs on Ethos-U85 from the
  [Alif dual-NPU vision Learning Path](https://learn.arm.com/learning-paths/embedded-and-microcontrollers/alif-dual-npu-vision/),
  subject to confirming its license, redistribution terms, source artifact,
  and reproducible conversion steps. It differs meaningfully from the existing
  `hello_world` and `tiny_cnn` models and connects the example to a realistic
  vision use case.
- Document model input/output shapes, data types, quantization parameters, and
  representative preprocessing and postprocessing.
- Add the model to an `ML-Model` layer and update the MLOps model selection.
- Regenerate the Vela model and embedded C array from the original `.tflite`
  file rather than committing unexplained generated artifacts.
- Show how to read the Vela report, adjust the tensor arena, place the model and
  arena, and validate output against a known-good reference.
- Exercise and explain the case in which one or more operations remain on the
  CPU, or explicitly select a model for which all operations are delegated.

**Acceptance criteria:** A developer can replace the supplied model using only
the documented steps and obtain a deterministic pass/fail result on FVP and on
the E8 reference target.

### 4. Create a PMU-driven performance-tuning walkthrough (P1)

**Why:** The Driver chapter already documents the PMU API and includes a basic
counter example. What is missing is a measured tuning exercise that connects a
performance question to event selection, a configuration change, and a verified
result.

**Deliverables:**

- Define one tuning question, for example whether arena-cache size or memory
  placement is causing external-memory stalls.
- Explain which PMU events answer that question for the selected Ethos-U
  variant, including counter availability, start/stop behavior, overflow, and
  repeatability considerations.
- Add working application code that captures cycle, active/idle, stall, and
  relevant AXI traffic or latency events for a single inference.
- Record a baseline over multiple runs, change exactly one Vela or driver
  parameter, regenerate the model where required, and repeat the measurement.
- Compare Vela estimates, PMU observations, and wall-clock measurements without
  treating the Vela performance model as a cycle-accurate prediction.
- Explain how to distinguish compute-bound, memory-bound, and CPU/runtime
  overhead from the collected evidence.

**Acceptance criteria:** The example produces repeatable measurements on the E8
target and demonstrates a justified tuning decision, including a case where a
change does not improve the result or has a memory/performance tradeoff.

### 5. Continuously test the integration example (P1)

**Why:** `arm-examples/CMSIS-Ethos-Integration` is both a user example and an
integration test for the development tools, software packs, model-conversion
flow, and runtime components required by Ethos-U. The objective is to preserve
upward compatibility as these dependencies evolve, not to freeze the example
to one known-good version set.

**Deliverables:**

- Add CI to the example repository that obtains current compatible tool and
  pack releases, regenerates the model, builds the application, and runs the
  automated FVP test where available.
- Run the compatibility workflow for pull requests and periodically on a
  schedule so that newly released development tools and software packs are
  exercised even when the example has not changed.
- Test the normal latest-version path and, where useful, a documented minimum
  supported configuration. Do not pin the normal user flow merely to keep CI
  green; investigate and report compatibility failures.
- Record the versions resolved during each CI run as diagnostic metadata. This
  is evidence of what was tested, not a requirement for users to install those
  exact versions.
- Distinguish failures in the example from regressions or compatibility changes
  in CMSIS-Toolbox, Vela, DFPs, software packs, compiler, and runtime software.
- Validate documentation links and runnable command snippets that are shipped
  with the example.
- Add a periodic hardware test when suitable E8 hardware and CI infrastructure
  are available; until then, clearly distinguish FVP-tested and hardware-tested
  results.

**Acceptance criteria:** A clean CI environment builds and tests the example
against current dependencies without editing version pins. Scheduled runs make
compatibility regressions visible and retain the resolved dependency versions
and test results needed to reproduce the failure.

### 6. Validate failure diagnosis and recovery on a real target (P2)

**Why:** The Integration and Driver chapters contain bring-up and timeout
guidance, but developers also need confidence that the recommended diagnostic
signals can be collected before recovery changes the NPU state.

**Deliverables:**

- Intentionally exercise at least an invalid memory route, a missing or blocked
  interrupt, and an inference timeout.
- Record the expected driver log, `STATUS`, and `QREAD` observations.
- Demonstrate fault capture followed by `ethosu_soft_reset()` and a successful
  known-good inference.
- Convert only confirmed, reusable observations into troubleshooting guidance.

**Acceptance criteria:** Each diagnostic branch is reproduced on FVP or
hardware, with the validation environment stated explicitly.

## Recommended execution order

1. Define the E8 target and the minimum requirements without pinning the normal
   example flow to specific tool and pack versions.
2. Create the E8 reference application and its automated functional test.
3. Integrate a different ML model to prove the model-replacement workflow.
4. Add PMU capture to the same application and perform the tuning experiment.
5. Verify the Zephyr flow, reusing the model and expected output where practical.
6. Run the example CI against current dependencies and add scheduled
   compatibility testing and automated FVP coverage.
7. Validate the failure-diagnosis scenarios and publish confirmed findings.

Keeping the E8 application, custom model, and PMU experiment in one reference
project reduces duplicated setup and makes the later tasks produce cumulative,
testable improvements. Zephyr should reuse the same model and validation data,
but remain a separate build so that CMSIS solution and Zephyr-specific issues
are easy to isolate.

## Potential future gaps

- TrustZone secure/non-secure deployment example.
- Non-coherent cache and CPU/NPU address-remapping example.
- RTOS concurrency and multiple inference requests.
- Multi-NPU or multi-variant deployment.
- Power-management integration and measurement.
