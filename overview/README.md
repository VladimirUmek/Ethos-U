# Overview

The **Arm CMSIS Ethos-U pack** provides the low-level driver for Arm [Ethos-U55](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u55),
  [Ethos-U65](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u65), and
  [Ethos-U85](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u85) neural processing units (NPUs). The driver connects an
ML inference runtime to the NPU and supports initialization, neural-network
command-stream execution, interrupt handling, and performance monitoring.

Before deployment, the [Vela compiler](https://arm-software.github.io/CMSIS-Ethos-U/main/vela/index.html)
optimizes a quantized ML model for the selected Ethos-U target. At runtime, the
Cortex-M application and ML inference runtime use this pack's driver to submit
the compiled command stream and model memory regions to the NPU.

## Memory modes

Ethos-U systems can place model constants, the tensor arena, and temporary data
in different memories. Vela uses the selected memory mode and the target's
memory-performance configuration to optimize data movement and execution.

![Comparison of Ethos-U memory modes](./memory-modes.png)

- **SRAM-only mode** keeps both constants and the tensor arena in SRAM for low
  access latency, but the complete model and arena must fit there.
- **Shared-SRAM mode** keeps the tensor arena in SRAM while read-only constants
  reside in Flash, MRAM, or DRAM, reducing SRAM usage.
- **Dedicated-SRAM mode** places constants and the tensor arena in larger memory
  and uses SRAM as a fast staging area for selected data.

See the [General documentation](https://arm-software.github.io/CMSIS-Ethos-U/main/general/index.html)
for memory-mode concepts and the [Integration documentation](https://arm-software.github.io/CMSIS-Ethos-U/main/integration/index.html)
for linker placement, memory attributes, cache policy, and driver configuration.

## Integration and tutorial

The [Integration guide](https://arm-software.github.io/CMSIS-Ethos-U/main/integration/index.html)
describes the end-to-end workflow for creating an ML application for selected
target hardware. It covers selecting the device configuration, creating a CMSIS
solution project, compiling the model with Vela, placing the generated model
regions in physical memory, configuring the driver, and validating the complete
system.

The [tutorial](https://arm-software.github.io/CMSIS-Ethos-U/main/integration/index.html#tutorial)
uses Keil Studio for VS Code to start from an example that matches the target's
Ethos-U NPU. It shows how to obtain the resolved MLOps and Vela settings,
generate an NPU-optimized model, build the application, and extend the solution
with a board layer and configuration for the physical target.

## Examples

The pack includes three `Hello-Ethos-U` CMSIS solution examples. Select the
example that matches the NPU in the target hardware:

| Pack example | NPU | Initial target configuration |
|---|---|---|
| `Hello-Ethos-U55` | Ethos-U55 | V2M-MPS3-SSE-300 FVP |
| `Hello-Ethos-U65` | Ethos-U65 | V2M-MPS3-SSE-300 FVP |
| `Hello-Ethos-U85` | Ethos-U85 | SSE-320 FVP |

The examples provide an application project, board and ML model layers,
quantized models, Vela configuration, and self-checking test sources.
The FVP configuration supports initial validation; use the tutorial to
add the selected physical target hardware.

## Features

- Generic core-driver components for Arm Ethos-U55, Ethos-U65, and Ethos-U85.
- Synchronous and asynchronous command-stream execution.
- Interrupt handling and performance monitoring unit (PMU) support.
- Configuration headers for each supported NPU family.
- Platform hooks for cache maintenance, address translation, locking, and
  logging.
- Guidance for Vela configuration, driver use, system integration, and Zephyr.

## Links

- [Documentation](https://arm-software.github.io/CMSIS-Ethos-U/main/index.html)
- [Zephyr](https://arm-software.github.io/CMSIS-Ethos-U/main/zephyr/index.html)
- [Repository](https://github.com/Arm-Software/CMSIS-Ethos-U)
- [Issues](https://github.com/Arm-Software/CMSIS-Ethos-U/issues)
