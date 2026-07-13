# Vela {#mainpage}

Arm Vela is a ahead-of-time neural-network compiler for the
[Ethos-U55](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u55),
[Ethos-U65](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u65), and
[Ethos-U85](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u85) NPUs.
It converts a quantized TensorFlow Lite
(`.tflite`) or TOSA (`.tosa`) network into command streams and encoded constant
data for a selected Ethos-U configuration.

This page describes Vela 5.1.0.
Run `vela --version` and consult the matching release documentation when using a
different version.

## Feature overview

Vela performs the offline, target-specific part of an Ethos-U deployment:

- Reads quantized TFLite/LiteRT and TOSA networks. Activations and weights must
  be quantized for Ethos-U acceleration.
- Detects operations supported by the selected NPU. In TFLite networks,
  unsupported regions remain CPU operations; TOSA compilation has no CPU
  fallback.
- Rewrites, decomposes, packs, and fuses graph operations into Ethos-U work.
- Selects execution schedules and block configurations for the target MAC
  configuration.
- Compresses weights and uses cascading, striping, buffering, and tensor reuse
  to reduce storage and runtime-memory demand.
- Allocates tensors among the constant, arena, and cache memory areas described
  by the selected system configuration and memory mode.
- Optimizes either for performance or for minimum peak SRAM use.
- Generates an optimized TFLite model or raw command-stream data.
- Reports operator placement, estimated cycles, bandwidth, and memory use.

The normal deployment flow is:

```text
quantized model -> Vela + target/memory description -> optimized model
                                                       |
                                                       v
                                      runtime + Ethos-U driver -> NPU
```

For TFLite output, supported regions become Ethos-U custom operators containing
the NPU command stream and related data. Unsupported TFLite operators remain in
the model for CPU execution, commonly using TensorFlow Lite Micro reference or
[CMSIS-NN](https://www.keil.arm.com/packs/cmsis-nn-arm/overview/) kernels.
Always review compiler warnings and `--show-cpu-operations`;
a successful compilation does not imply that every operation runs on the NPU.

Vela's cycle and bandwidth figures are cost-model estimates intended to guide
compiler decisions and compare like-for-like builds. Validate final performance
on an FPGA or target silicon; an
[Arm Fixed Virtual Platform (FVP)](https://www.arm.com/products/development-tools/simulation/fixed-virtual-platforms)
can provide approximate behavior.

## Installation

Vela runs on Linux, macOS, and Windows. The released package requires Python
3.10 or newer:

```console
python -m pip install ethos-u-vela
vela --version
```

### Update an existing installation

Plain `pip install` considers an already installed version satisfactory and
does not necessarily install a newer release. Request an upgrade explicitly:

```console
python -m pip install --upgrade ethos-u-vela
python -m pip show ethos-u-vela
vela --version
```

If PyPI reports a newer package but `vela --version` still shows the old
version, the `pip` command and the `vela` executable usually belong to different
Python environments. Locate both and compare them:

```console
python -c "import sys; print(sys.executable)"
python -m pip --version
python -m pip show ethos-u-vela
```

On Windows use `where vela`; on Linux or macOS use `command -v vela`. Activate
the intended virtual environment, remove the stale executable from `PATH`, or
upgrade through the Python interpreter associated with that executable. A clean
reinstallation in the selected environment is the final fallback:

```console
python -m pip install --upgrade --force-reinstall ethos-u-vela
vela --version
```

Use `py -m pip ...` instead of `python -m pip ...` on Windows when the Python
launcher is how the intended interpreter is selected. Avoid `pip` without
`python -m`: it is easier for that command to address a different environment.

PyPI supplies wheels for supported host combinations. If no matching wheel is
available, `pip` builds from source and requires Python development headers,
CMake, a C99 compiler, and a C++17 compiler. The package depends on FlatBuffers
and NumPy 1.23 or newer.

## Basic invocation

```console
vela [OPTIONS] NETWORK
```

Only the input network and accelerator configuration are needed for a basic
build:

```console
vela --accelerator-config ethos-u55-128 my_network.tflite
```

For meaningful scheduling and performance estimates, also select a platform
configuration, memory mode, and optimization strategy:

```console
vela my_network.tflite \
  --accelerator-config ethos-u55-128 \
  --config Arm/vela.ini \
  --system-config Ethos_U55_High_End_Embedded \
  --memory-mode Shared_Sram \
  --optimise Performance
```

Options can precede or follow `NETWORK`. Use `vela --help` for the exact options
provided by the installed version.

## Invocation parameters

### Input, output, and discovery

| Parameter | Purpose |
|---|---|
| `NETWORK` | Required `.tflite` or `.tosa` input path. |
| `-h`, `--help` | Show command help and exit. |
| `--version` | Show the installed Vela version and exit. |
| `--api-version` | Show the deprecated external-API version. Planned for removal. |
| `--supported-ops-report` | Write `SUPPORTED_OPS.md` for TFLite operator constraints and exit. |
| `--list-config-files` | List packaged Vela configuration files and exit. |
| `--list-configs FILE` | List system configurations and memory modes in a `vela.ini` file and exit. |
| `--output-dir DIR` | Output directory; default `output`. |
| `--output-format {tflite,raw}` | Select the output format; default `tflite`. Raw output is an `.npz` archive and requires complete NPU placement. |
| `--enable-debug-db` | Write a network debug database into the output directory. |
| `--config FILE` | Read a ConfigParser-format `vela.ini` file. May be supplied more than once; later files can extend or override earlier definitions. |
| `--timing` | Report time spent in compiler stages. |
| `--force-symmetric-int-weights` | Force signed integer weight zero-points to zero. |

Raw output holds command streams, weight data, and tensor quantization metadata
for Ethos-U regions. It omits CPU regions and therefore is not a general
TFLite-to-TOSA conversion format.

### Target and scheduling

| Parameter | Purpose and values |
|---|---|
| `--accelerator-config TARGET` | Select the hardware: `ethos-u55-{32,64,128,256}`, `ethos-u65-{256,512}`, or `ethos-u85-{128,256,512,1024,2048}`. The suffix is the MACs-per-cycle configuration. |
| `--system-config NAME` | Select `[System_Config.NAME]` from the configuration files. The internal default provides functional defaults, but a platform-specific definition gives useful scheduling estimates. |
| `--memory-mode NAME` | Select `[Memory_Mode.NAME]`, which maps constants, arena, and cache to the system's memory areas. |
| `--tensor-allocator {LinearAlloc,Greedy,HillClimb}` | Choose tensor allocation; default `HillClimb`. |
| `--max-block-dependency {0,1,2,3}` | Limit dependency distance between NPU kernel operations; default `3`. Smaller values can improve interrupt latency at a possible performance cost. |
| `--optimise {Performance,Size}` | `Performance` is the default and minimizes inference time; `Size` minimizes peak SRAM and ignores the arena-cache size. |
| `--arena-cache-size BYTES` | Override the selected memory mode's cache capacity for `Performance` optimization. This is a byte count, not KiB. |
| `--cpu-tensor-alignment BYTES` | Alignment for CPU tensors, including custom-operator inputs and outputs; default `16`. Keep it consistent with the runtime allocation. |
| `--recursion-limit COUNT` | Python recursion limit used during compilation; default `1000`. |
| `--hillclimb-max-iterations COUNT` | Maximum HillClimb allocator iterations; default `99999`. |
| `--cop-format {COP1,COP2}` | Select custom-operator payload metadata format; default `COP1`. |
| `--separate-io-regions` | Place custom-operator inputs and outputs into separate logical regions. Requires `--cop-format COP2`. |
| `--ignore-ops OP[,OP...]` | Force named TFLite builtin operator types, such as `ADD,ARGMAX`, onto the CPU. Repeatable, Regor-only, and ignored for TOSA. |

### Reporting and diagnostics

| Parameter | Purpose |
|---|---|
| `--show-cpu-operations` | List TFLite operations that were not placed on the NPU. |
| `--show-subgraph-io-summary` | Summarize every subgraph and its inputs and outputs. |
| `--verbose-all` | Enable all verbose reports. This can be very large. |
| `--verbose-config` | Show resolved system and memory configuration. |
| `--verbose-graph` | Trace graph rewrites. |
| `--verbose-quantization` | Show quantization processing. |
| `--verbose-packing` | Show operation/pass packing. |
| `--verbose-performance` | Show detailed performance estimates. |
| `--verbose-tensor-purpose` | Show tensor-purpose assignment. |
| `--verbose-tensor-format` | Show tensor-format assignment. |
| `--verbose-schedule` | Show the selected schedule. |
| `--verbose-allocation` | Show tensor allocation. |
| `--verbose-high-level-command-stream` | Print the high-level command stream. |
| `--verbose-register-command-stream` | Print the register command stream. |
| `--verbose-operators` | List operators. |
| `--verbose-weights` | Show weight information. |
| `--verbose-cycle-estimate` | Show cycle-estimation details. |
| `--verbose-progress` | Show compilation progress. |

The source also exposes experimental and debug switches such as
`--experimental-softmax-int16-neg-exp-range`, `--debug-force-legacy-core`,
`--debug-force-regor`, `--disable-chaining`, `--disable-fwd`, `--disable-cascading`,
and `--disable-buffering`. They are useful for compiler development and
regression isolation, but are not recommended as production tuning controls.
Their names and behavior can change between releases.

## Accelerator and memory configuration

The accelerator target, system configuration, and memory mode describe
different things:

| Setting | Describes |
|---|---|
| `--accelerator-config` | NPU architecture and MAC configuration. The generated command stream is target-specific. |
| `--system-config` | Core clock, AXI port mapping, memory clock ratios, burst lengths, latencies, and outstanding transactions used by the cost model. |
| `--memory-mode` | Placement of constant, arena, and cache memory areas on the AXI-connected memories. |

The package provides the reference file `Arm/vela.ini`. Discover the installed
configuration files and definitions with:

```console
vela --list-config-files
vela --list-configs Arm/vela.ini
```

Typical packaged system configurations include:

- Ethos-U55: `Ethos_U55_Deep_Embedded`,
  `Ethos_U55_High_End_Embedded`.
- Ethos-U65: `Ethos_U65_Embedded`, `Ethos_U65_Mid_End`,
  `Ethos_U65_High_End`, `Ethos_U65_Client_Server`.
- Ethos-U85: `Ethos_U85_SYS_Flash_Low`, `Ethos_U85_SYS_Flash_High`,
  `Ethos_U85_SYS_DRAM_Low`, `Ethos_U85_SYS_DRAM_Mid`,
  `Ethos_U85_SYS_DRAM_High`.

### Memory modes

| Mode | Constants | Arena | Fast cache | Typical use |
|---|---|---|---|---|
| `Sram_Only` | AXI0/SRAM | AXI0/SRAM | AXI0/SRAM | Everything fits in SRAM. |
| `Shared_Sram` | AXI1/Flash or DRAM | AXI0/SRAM | AXI0/SRAM | SRAM is shared with software; constants remain in slower memory. |
| `Dedicated_Sram` | AXI1/DRAM | AXI1/DRAM | AXI0/SRAM | Dedicated SRAM is a cache for an arena in writable external memory. |

Packaged variants such as `Dedicated_Sram_256KB`, `_384KB`, `_512KB`, and
`_1024KB` inherit `Dedicated_Sram` and set `arena_cache_size`.

The names `Axi0` and `Axi1` are logical Vela ports. Their physical memory types
come from the selected system configuration. The `vela.ini` file, SoC interconnect,
linker placement, MPU/SAU attributes, cache policy, driver region indices, and
runtime tensor arena must agree. Vela cannot validate the complete firmware
memory map.

## `vela.ini` reference

`vela.ini` uses Python ConfigParser syntax and is case-sensitive for section
names, keys, and values. It contains two section types:

```ini
[System_Config.ConfigurationName]
; NPU clock, AXI mapping, and memory performance

[Memory_Mode.ModeName]
; compiler memory-area placement
```

`ConfigurationName` and `ModeName` must not contain spaces. A file can define
multiple sections of either type; select them with `--system-config` and
`--memory-mode`. Every property is technically optional, but an omitted
property receives an internal value equivalent to `1`, not the corresponding
property from a packaged reference configuration. Define every property that
affects the target system.

Any section can contain `inherit=Part.Name` to inherit another section. The
child's values override the parent. Inheritance cannot be recursive.

### System configuration parameters

The system configuration maps Vela's two logical AXI interfaces to memory
types and supplies the performance model. Parameters for a memory type are
needed only when `axi0_port` or `axi1_port` selects that type.

| Parameter | Type or values | Description |
|---|---|---|
| `core_clock` | Float, Hz | Ethos-U core frequency. Scientific notation such as `500e6` is accepted. |
| `axi0_port` | `Sram`, `Dram`, `OnChipFlash`, `OffChipFlash` | Memory type connected to Vela's AXI0 interface. |
| `axi1_port` | Same as `axi0_port` | Memory type connected to Vela's AXI1 interface. |
| `<Memory>_clock_scale` | Float, `0.0` to `1.0` | Memory clock/bandwidth scale relative to `core_clock`. `<Memory>` is `Sram`, `Dram`, `OnChipFlash`, or `OffChipFlash`. |
| `<Memory>_ports_used` | Integer | Number of ports used for that memory. Documented for SRAM, DRAM, and off-chip Flash. |
| `<Memory>_burst_length` | Integer, bytes | Minimum efficient transfer burst. |
| `<Memory>_read_latency` | Integer, cycles | Read latency used by the cost model. |
| `<Memory>_write_latency` | Integer, cycles | Write latency used by the cost model. Use `0` for a read-only memory when appropriate. |
| `<Memory>_max_reads` | Integer | Maximum outstanding reads. |
| `<Memory>_max_writes` | Integer | Maximum outstanding writes. Use `0` for a read-only memory when appropriate. |

The current option reference explicitly lists the full metric set for `Sram`,
`Dram`, and `OffChipFlash`, and `OnChipFlash_clock_scale` for on-chip Flash.
Use `--verbose-config` with the installed Vela version to inspect the resolved
properties supported by that version.

### Memory mode parameters

| Parameter | Type or values | Description |
|---|---|---|
| `const_mem_area` | `Axi0` or `Axi1` | Location for read-only constants, including weights, scales, biases, and constant tensors. |
| `arena_mem_area` | `Axi0` or `Axi1` | Location for read/write feature maps, intermediate tensors, and internal buffers. |
| `cache_mem_area` | `Axi0` or `Axi1` | Fast memory used as a dedicated cache when the selected mode requires one. |
| `arena_cache_size` | Integer, bytes | Available arena size in SRAM-only/shared-SRAM modes, or cache size in dedicated-SRAM mode. The CLI `--arena-cache-size` overrides it for `Performance` optimization. |
| `inherit` | `Part.Name` | Parent section whose parameters are inherited. Child values take precedence. |

The memory-area mapping must match the Ethos-U driver, runtime tensor arena,
linker script, and physical memory system. These options guide compilation; they
do not configure the hardware.

### Complete `vela.ini` example

```ini
; Ethos-U55 at 500 MHz with SRAM on AXI0 and read-only Flash on AXI1
[System_Config.My_Ethos_U55_System]
core_clock=500e6
axi0_port=Sram
axi1_port=OffChipFlash

Sram_clock_scale=1.0
Sram_ports_used=1
Sram_burst_length=32
Sram_read_latency=32
Sram_write_latency=32
Sram_max_reads=4
Sram_max_writes=4

OffChipFlash_clock_scale=0.125
OffChipFlash_ports_used=1
OffChipFlash_burst_length=128
OffChipFlash_read_latency=64
OffChipFlash_write_latency=0
OffChipFlash_max_reads=2
OffChipFlash_max_writes=0

; Constants remain in Flash; the tensor arena occupies shared SRAM
[Memory_Mode.My_Shared_Sram]
const_mem_area=Axi1
arena_mem_area=Axi0
cache_mem_area=Axi0
arena_cache_size=262144

; Derived mode with a smaller 128 KiB arena budget
[Memory_Mode.My_Shared_Sram_128KB]
inherit=Memory_Mode.My_Shared_Sram
arena_cache_size=131072
```

Invoke it with:

```console
vela model.tflite --config vela.ini \
  --accelerator-config ethos-u55-128 \
  --system-config My_Ethos_U55_System \
  --memory-mode My_Shared_Sram
```

Print the effective values while validating a new configuration:

```console
vela model.tflite --config vela.ini \
  --system-config My_Ethos_U55_System \
  --memory-mode My_Shared_Sram \
  --verbose-config
```

## Examples

### Compile for an Ethos-U55 reference system

```console
vela person_detect.tflite \
  --accelerator-config ethos-u55-128 \
  --config Arm/vela.ini \
  --system-config Ethos_U55_High_End_Embedded \
  --memory-mode Shared_Sram \
  --optimise Performance \
  --show-cpu-operations
```

The default output directory contains `person_detect_vela.tflite` and reporting
artifacts. Use the optimized model, not the original input, in the Ethos-U
runtime application.

### Minimize peak SRAM

```console
vela keyword_spotting.tflite \
  --accelerator-config ethos-u55-64 \
  --optimise Size
```

`Size` scheduling favors tensor reuse and cascading. It can reread more weights
and reduce throughput, so measure both memory and performance.

### Set a performance-scheduler SRAM budget

```console
vela person_detect.tflite \
  --accelerator-config ethos-u55-128 \
  --optimise Performance \
  --arena-cache-size 61440
```

This supplies a 60 KiB cache budget. Reducing it may increase AXI1 traffic as
weights or feature-map data are reread. The reported `Total SRAM used` covers
the model's NPU-visible tensors and working buffers, not the RTOS, stacks,
application allocations, CPU kernels, or other firmware state.

### Compile TOSA for Ethos-U85 raw output

```console
vela my_network.tosa \
  --config Arm/vela.ini \
  --accelerator-config ethos-u85-256 \
  --system-config Ethos_U85_SYS_DRAM_High \
  --memory-mode Dedicated_Sram_384KB \
  --output-format raw
```

The resulting `.npz` contains the NPU command streams, constants, and
quantization metadata needed by an integration that consumes raw Vela output.

### Inspect placement and compiler decisions

```console
vela model.tflite \
  --accelerator-config ethos-u85-512 \
  --show-cpu-operations \
  --show-subgraph-io-summary \
  --verbose-config \
  --verbose-performance \
  --enable-debug-db
```

Start with focused reports. `--verbose-all` can produce impractically large
logs for real networks.

### Embed an optimized TFLite model in firmware

On hosts that provide `xxd`, convert the Vela output to a C array:

```console
xxd -i output/my_network_vela.tflite my_network_model.h
```

Place the generated data in the linker region that matches the Vela memory
configuration. Ensure the runtime registers the Ethos-U custom operator and
uses an Ethos-U driver compatible with the compiled command stream.

## ExecuTorch Arm example flow

ExecuTorch's `examples/arm` directory demonstrates an integrated PyTorch-to-
Ethos-U workflow. Its setup script installs the Arm toolchain, TOSA tools,
Ethos-U Vela, and
[Corstone](https://www.arm.com/products/silicon-ip-subsystems) FVPs. The AOT Arm
backend exports and quantizes a
PyTorch model, lowers supported partitions through TOSA and Vela, and packages
the result in an ExecuTorch `.pte`/`.bpte` program. In this flow Vela is called
by the backend; users normally run the example helper rather than invoke Vela
on a `.pte` file.

From an ExecuTorch checkout on Linux:

```console
./examples/arm/setup.sh --i-agree-to-the-contained-eula
source examples/arm/arm-scratch/setup_path.sh
./examples/arm/run.sh \
  --model_name=examples/arm/example_modules/add.py \
  --target=ethos-u85-128
```

The helper runs the AOT compiler, builds the matching runtime, and starts the
target simulator unless build-only mode is selected. Other examples include an
Ethos-U minimal notebook, quantizer tutorial, pruning example, image
classification application, and Zephyr/[CMSIS](https://www.keil.arm.com/packs/cmsis-arm/overview/)
project templates. Treat the
ExecuTorch branch and Vela version as a tested toolchain: backend-generated
Vela options can evolve independently from the standalone CLI examples above.

## Troubleshooting

| Symptom | Check |
|---|---|
| Most operations run on the CPU | Confirm integer quantization, inspect `--show-cpu-operations`, and generate `--supported-ops-report` to check every operator constraint. |
| Compilation succeeds but estimates look unrealistic | Use a platform-specific `System_Config`; verify clocks, AXI mappings, latency, bandwidth, and memory mode. Compare only builds with the same configuration. |
| Runtime allocation fails | Check Vela's peak-memory report and add firmware overhead. Align linker regions and the tensor arena with `cpu_tensor_alignment` and the chosen memory mode. |
| Performance degrades after reducing SRAM | A smaller cache can cause more AXI1 reads. Inspect the performance CSV/report and hardware PMU counters. |
| A wheel is unavailable | Install Python development headers, CMake, and C99/C++17 build tools, or use a supported host/Python combination. |
| Output does not run on the target | Recompile for the exact Ethos-U architecture/MAC configuration and keep Vela, driver, linker, and memory-region configuration consistent. |
