# General {#mainpage}

This documentation is structured into following chapters:

Chapter                                                    | Description
:----------------------------------------------------------|:--------------------
[General](index.html)                                      | Overview and general information.
[Vela](../vela/index.html)                                 | Vela compiler features, configuration, and usage.
[Drivers](../drivers/index.html)                   | Driver interfaces and usage.
[Integration](../integration/index.html)           | Integration notes and workflows.

This chapter provides an overview and general information for integrating an Ethos-U NPU into a Cortex-M processor-based system.

## Overview

The [Ethos-U NPU](https://www.arm.com/product-filter?families=ethos%20npus) series are integrated as a tightly coupled acceleration subsystem that is controlled by the Cortex-M processor. In a typical deployment, the firmware running on the Cortex-M prepares input and output tensors in memory, configures and starts the NPU through the driver API, and handles completion or error events.

From a software point of view, the integration requires:

- Ethos-U NPU driver configuration and low-level hardware access.
- Memory layout for model weights, activations, scratch buffers, and tensor arena.
- Interrupt and mailbox/event handling.
- Optional RTOS scheduling and synchronization around inference jobs.

## Typical System Architecture

At a high level, the Cortex-M application code uses an inference runtime interface to call into the Ethos-U driver layer. The driver interacts with platform-specific hardware blocks such as interrupt controllers, memory protection units, and optional mailbox or shared-memory transport used for multi-core or secure/non-secure split designs.

Integration decisions are often platform specific, but these are some core patters:

1. Initialize clocks, resets, and memory regions required by Ethos-U.
2. Initialize platform services (timers, interrupt controller, optional mailbox).
3. Initialize the Ethos-U driver and inference runtime layer.
4. Load or reference ML model data and provide buffers for the inference runtime.
5. Submit inference jobs and wait for completion events.
6. Validate outputs and monitor performance counters.

## Vela Overview

[Vela](https://pypi.org/project/ethos-u-vela/) is the compiler for Ethos-U. It takes a quantized neural network model and generates output optimized for a specific Ethos-U target and memory configuration. In a typical workflow, Vela:

- Identifies operations that can run on Ethos-U.
- Applies graph and memory optimizations for the selected target.
- Produces model artifacts and metadata consumed by the runtime and driver.

Because graph and memory optimizations depend on platform settings, the Vela configuration should match the system integration, especially for memory layout and selected memory mode. A device-specific `vela.ini` file captures these platform settings includes also other system parameters such as clock speed.

**Note:**

- Even without a device-specific `vela.ini` file, the Vela compiler delivers functional correct models, just not optimized for the target hardware.

## Memory Modes

Memory modes balance different system trade-offs such as speed and memory availability. Some target systems have enough tightly-coupled SRAM for all tensors and constants, while others must place constants in other memory (Flash or DRAM) and keep only latency-critical data in SRAM. Depending on the selected memory mode, the Vela compiler maps the following memory types to the available memory.

ToDo: verify memory terminology (is SRAM tightly coupled, is other memory correct)

Typically, there are three memory modes available as shown in the following diagram.

![Memory Modes](./images/memory-modes.png "Memory Modes")

**SRAM Only Mode**:

- Ethos-U only uses SRAM.
- Vela uses two separate regions in SRAM for `const_mem_area` and `arena_mem_area`.
- `arena_cache_size` defines the maximum size of `arena_mem_area`.
- `arena_mem_area` contains network input, output, and intermediate tensors, including the Ethos-U scratch tensor working buffers.

**Shared SRAM Mode**:

- Ethos-U uses SRAM for `arena_mem_area` and also has access to other memory types (Flash or DRAM) used for `const_mem_area`.
- `arena_cache_size` defines the maximum size of `arena_mem_area`.
- `arena_mem_area` contains all network input, output, and intermediate tensors, including the Ethos-U scratch tensor working buffers.

**Dedicated SRAM Mode:**

- Ethos-U uses SRAM for `cache_mem_area` (SRAM is entirely dedicated to the NPU) and also has access to other memory types (Flash or DRAM).
- Vela uses two separate regions in these other memory types: `const_mem_area` and `arena_mem_area`.
- `arena_cache_size` defines the maximum size of `cache_mem_area`.
- `arena_mem_area` contains all network input, output, and intermediate tensors, including the Ethos-U scratch tensor working buffers.

**Important:**

The Vela settings, system configuration and memory allocation via linker scripts must be consistent. This is the responsibility software architect as there is no tool support for consistency checking.

## Related Arm products

- [Arm Ethos-U55](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u55)
- [Arm Ethos-U65](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u65)
- [Arm Ethos-U85](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u85)
- [CMSIS-NN software pack](https://www.keil.arm.com/packs/cmsis-nn-arm/overview/)
- [CMSIS software pack](https://www.keil.arm.com/packs/cmsis-arm/overview/)
- [Arm Cortex-M55](https://www.arm.com/products/silicon-ip-cpu/cortex-m/cortex-m55)
- [Arm Corstone-300](https://www.arm.com/products/silicon-ip-subsystems/corstone-300)
- [Arm Corstone-320](https://www.arm.com/products/silicon-ip-subsystems/corstone-320)
- [Arm Fixed Virtual Platforms](https://www.arm.com/products/development-tools/simulation/fixed-virtual-platforms)

## Vela and ExecuTorch resources

- [ethos-u-vela on PyPI](https://pypi.org/project/ethos-u-vela/)
- [Vela source and release documentation](https://gitlab.arm.com/artificial-intelligence/ethos-u/ethos-u-vela)
- [Vela CLI options](https://gitlab.arm.com/artificial-intelligence/ethos-u/ethos-u-vela/-/blob/5.1.0/OPTIONS.md)
- [Supported operator constraints](https://gitlab.arm.com/artificial-intelligence/ethos-u/ethos-u-vela/-/blob/5.1.0/SUPPORTED_OPS.md)
- [Performance estimation reference](https://gitlab.arm.com/artificial-intelligence/ethos-u/ethos-u-vela/-/blob/5.1.0/PERFORMANCE.md)
- [ExecuTorch examples](https://github.com/pytorch/executorch/tree/main/examples)
- [ExecuTorch Arm examples](https://github.com/pytorch/executorch/tree/main/examples/arm)
