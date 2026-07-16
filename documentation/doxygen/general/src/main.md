# General {#mainpage}

Chapter content:

- This chapter explains the top-level architecture and deployment flow for ML models to Cortex-M/Ethos-U based system.
- [Vela](../vela/index.html) explains how to compile, inspect, or troubleshoot a ML model for Ethos-U.
- [Drivers](../drivers/index.html) contains details about the Ethos-U related drivers.
- [Integration](../integration/index.html) details the overall system design with information about memory, linker, cache, RTOS, and build configuration.

## Target audiences and device packs

In this documentation, a **microcontroller device** is a device that combines a
Cortex-M processor with an integrated Ethos-U NPU. The documentation serves both
embedded application developers using these devices and silicon vendors or
platform maintainers who provide support for them.

The term **Vela compiler** refers to the model-compilation tool. The term
**`vela.ini` configuration** refers to its target-system and memory configuration
file. System configurations and memory modes are named sections within that
file.

A CMSIS Device Family Pack (DFP) can simplify integration by including or
referencing device-specific resources such as the `vela.ini` configuration
file, linker scripts, and software components. Device packs are available from
[www.keil.arm.com/pack](https://www.keil.arm.com/pack). CMSIS-Toolbox resolves
these resources for the selected device and build context and exposes the
relevant parameters through its
[MLOps information](https://open-cmsis-pack.github.io/cmsis-toolbox/build-overview/#mlops-information).
The [Alif Ensemble DFP](https://github.com/alifsemi/alif_ensemble-cmsis-dfp)
is an example of this pack structure.

When a vendor-qualified DFP is available, application developers can use it to
obtain validated device-specific files. Silicon vendors and pack maintainers
are responsible for supplying and validating those files. If a suitable DFP is
unavailable, the same information in this documentation supports manual
integration.

## System overview

An Ethos-U NPU is a memory-mapped accelerator controlled by Cortex-M software.
The Vela compiler performs target-specific compilation before deployment. At
run time, the ML inference runtime locates the generated Ethos-U custom operator and asks the driver to
execute its command stream using the model's memory-region base addresses.

```text
quantized model
      |
      v
Vela compiler + DFP-provided target and memory description
      |
      v
optimized model: metadata + constants + Ethos-U command stream
      |
      v
application / ML inference runtime -> Ethos-U driver -> NPU
      ^                                      |
      +---------- input and output memory ---+
```

The Vela compiler decides which supported operations run on the NPU and how
their tensors are scheduled and placed. Unsupported TensorFlow Lite operations can remain CPU
operations. At run time, the CPU provides the command stream and region base
addresses; the NPU fetches constants and input data, performs the encoded tensor
operations, writes intermediate and output tensors, and signals completion.

For command-line options and compiler diagnostics, see
[Vela](../vela/index.html). For invocation and interrupt contracts, see
[Drivers](../drivers/index.html).

## Coordinating the device configuration

A microcontroller device has a fixed Cortex-M, Ethos-U, interconnect, and memory
integration. The software descriptions used to build an application must match
that finished device:

1. The device description identifies the processor, Ethos-U configuration, and
   available memory regions.
2. The `vela.ini` configuration models the device's memory performance and
   defines its supported memory modes.
3. The linker and MPU/SAU configuration places code and data in the device's
   physical memory regions with suitable CPU attributes.
4. The driver configuration assigns the command stream and model regions to the
   matching NPU memory-access paths and attributes.

A DFP can provide these related descriptions, and CMSIS-Toolbox can resolve
them for the selected device and build context. They are not independent
choices. The full mapping, examples, and
consistency checklist are in [Integration](../integration/index.html). The
meaning and syntax of `vela.ini` are in [Vela](../vela/index.html).

## Memory modes at a glance

A memory mode in `vela.ini` describes where the different classes of ML model
data are stored. The following diagram provides a conceptual comparison of the three
commonly used memory modes.

![Comparison of Ethos-U memory modes](./images/memory-modes.png "Ethos-U memory modes")

### SRAM-only mode

All ML model data is stored in SRAM. Constants and writable tensor data remain
separate logical areas, but both use the same physical memory type. This mode is
simple and can provide low access latency, but the complete compiled ML model
and its tensor arena must fit in the available SRAM.

### Shared-SRAM mode

The writable tensor arena is stored in SRAM shared with the Cortex-M application.
The arena contains ML model input and output tensors, intermediate activations,
and scratch tensors. Read-only constants, such as encoded weights and scales,
are stored in another memory such as Flash, MRAM, or DRAM. This arrangement
preserves SRAM for data that changes during inference.

### Dedicated-SRAM mode

Constants and the main writable tensor arena are stored outside the dedicated
SRAM, commonly in external or higher-capacity memory. The SRAM is reserved as a
fast staging area for the NPU. The Vela compiler can move selected data through
this area to reduce the performance cost of accessing the main storage. This behavior is
also called spilling.

These names describe logical placement patterns, not fixed physical memory
devices or NPU bus connections. The exact meaning comes from the selected
system configuration and memory-area mapping in `vela.ini`. See
[Vela](../vela/index.html) for configuration syntax and
[Integration](../integration/index.html) for the corresponding linker sections,
MPU/SAU attributes, cache policy, and driver region configuration. In
particular, the meaning of `arena_cache_size` depends on whether the arena and
fast staging area map to the same memory.

## Deployment lifecycle

1. Select the device, its DFP, and specify the CMSIS-Toolbox build context.
2. Select a quantized ML model and ML inference runtime, then resolve the
   `vela.ini`, linker, and driver configuration supplied by the pack.
3. Compile for size to establish the model-controlled memory floor.
4. Reserve ML inference runtime and application memory, then compile
   performance candidates
   using the remaining budget.
5. Place model artifacts and buffers with the linker and configure the driver
   to match the same memory mapping.
6. Implement target hooks for interrupts, cache maintenance, address remapping,
   and RTOS synchronization as needed.
7. Validate correctness with a small known-good ML model, then measure the
   production ML model on hardware and tune from evidence.

The detailed procedure and required evidence are in
[Integration](../integration/index.html). Vela compiler estimates are useful for
comparison but do not replace measurements on the target.

## Key terms

This manual uses:

- **ML model** or **neural network model** for the compiled machine-learning workload.
- **ML inference runtime** means the software framework that interprets model metadata, prepares tensors, and invokes the Ethos-U driver.
- **Target system** means the complete Cortex-M-based hardware and firmware platform.
- **Ethos-U target** means the selected NPU architecture and MAC configuration.

| Term | Meaning | More information |
| --- | --- | --- |
| command stream | NPU instructions generated by the Vela compiler and embedded in or emitted with the compiled model | [Drivers](../drivers/index.html) |
| constant area | read-mostly model data such as encoded weights and scales | [Integration](../integration/index.html) |
| arena | input, output, intermediate activation, and scratch storage | [Integration](../integration/index.html) |
| fast staging/cache area | optional fast temporary storage used for spilling | [Integration](../integration/index.html) |
| system configuration | performance model for the target memory system defined in `vela.ini` | [Vela](../vela/index.html) |
| memory mode | mapping of model storage roles to memory aliases defined in `vela.ini` | [Vela](../vela/index.html) |

## Related resources

- [Ethos-U55](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u55),
  [Ethos-U65](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u65), and
  [Ethos-U85](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u85)
- [Vela source and release documentation](https://gitlab.arm.com/artificial-intelligence/ethos-u/ethos-u-vela)
- [CMSIS-NN](https://www.keil.arm.com/packs/cmsis-nn-arm/overview/)
- [ExecuTorch Arm examples](https://github.com/pytorch/executorch/tree/main/examples/arm)
- [Arm Fixed Virtual Platforms](https://www.arm.com/products/development-tools/simulation/fixed-virtual-platforms)
