# Integration {#mainpage}

This chapter explains how to integrate a compiled ML model consistently into a
Cortex-M and Ethos-U target system.

## Integration workflow

Complete the steps in order because later steps depend on earlier decisions and
measurements. Each step ends with a concrete deliverable:

1. **Select the device and DFP.** Choose the microcontroller device and its Device
   Family Pack from [www.keil.arm.com/pack](https://www.keil.arm.com/pack).
   CMSIS-Toolbox records the selected packs in the project metadata.
2. **Select the build context.** Use CMSIS-Toolbox to select the device and
   resolve the `vela.ini`, linker, and driver resources referenced by the DFP
   description. The project metadata records the `vela.ini` configuration file used
   by the build. Deliverable: the resolved
   [MLOps information](https://open-cmsis-pack.github.io/cmsis-toolbox/build-overview/#mlops-information).
3. **Select the workload.** Define the quantized ML model, CPU fallback policy,
   and latency and throughput goals. Deliverable: a versioned input ML model and
   acceptance criteria.
4. **Compile with the device configuration.** Use the accelerator, system
   configuration, and memory mode supplied by the DFP. Deliverable: the
   optimized model, compiler reports, and resolved `vela.ini` configuration.
5. **Establish the memory floor.** Run a size-optimized compile and inspect its
   allocation report. Deliverable: the minimum model-controlled allocation.
6. **Set a system budget.** Account for the ML inference runtime, stacks, heaps,
   application data, alignment, and a safety margin. Deliverable: the maximum ML
   model budget for each physical memory region.
7. **Generate candidates.** Run performance compiles across the feasible memory
   budgets. Deliverable: the generated models and their compiler reports.
8. **Build and verify placement.** Use the linker and driver configuration from
   the same DFP and review the resulting application allocations. Deliverable:
   the resolved vendor memory map with the application placement.
9. **Complete application integration.** Add any application-specific RTOS,
   power, timeout, cache, and fault handling. Deliverable: the completed
   application hooks.
10. **Validate and tune.** Verify correctness, actual allocation, cycle counts,
   bandwidth, latency, and concurrency. Deliverable: a measured release
   configuration.

A change to a memory mode, linker section, cache attribute, or driver region
value requires reviewing the other descriptions of that memory region.

## General integration guidance

- Keep the `vela.ini` `System_Config`, selected `Memory_Mode`, linker sections,
  MPU/SAU attributes, and driver build definitions consistent.
- Use `arena_cache_size` as the compiler allocation constraint. In
  shared-SRAM mappings, it constrains the `arena_mem_area`, so the application
  arena, often a statically allocated C array, must not be smaller than this
  value. In dedicated-cache mappings, it constrains the `cache_mem_area`; model
  constants and activations can then grow up to the limits of the memories where
  the linker places them.
- Place model constants, activations, and any dedicated cache section in memory
  regions that match the memory-area mapping selected in `vela.ini`. If the
  linker uses three physical memories, benchmark representative ML models to
  confirm that the selected `System_Config` section models the system suitably.
- Override the driver weak hooks when the default integration assumptions do not
  match the platform, especially for data cache maintenance, address remapping,
  and RTOS synchronization.
- Ensure the NPU completion interrupt is eventually serviced. Very low jitter is
  usually not required for inference workloads, but completion handling must not
  be postponed indefinitely.
- During bring-up, use timeouts, fault reporting, and a minimal known-good model
  before moving to full application graphs.

### Keep records

It is good practice to document the hand-off boundary between model, platform, and application
engineers. This also gives automated tools enough context to check consistency.
CMSIS-Toolbox already records the selected packs and `vela.ini` configuration
file in the project metadata; do not duplicate that information. Record the
remaining application-specific information:

- Input ML model hash or version and Vela version;
- Accelerator configuration, system configuration, memory mode, optimization
  strategy, and effective arena-cache size;
- Physical placement of the command stream and every generated base region;
- Linker symbols or sections and their reserved sizes;
- MPU/SAU and CPU cache attributes;
- `NPU_QCONFIG`, all used `NPU_REGIONCFG_x` values, and any non-default AXI or
  memory-attribute settings;
- Implemented cache, address-remap, interrupt, RTOS, power, and fault hooks;
- Actual compiler-reported allocation, link-map use, and measured target-system performance.

## Introduction

The `vela.ini` configuration, linker script, MPU or SAU setup, and Ethos-U
driver build configuration must describe the same memory system. The Vela
compiler uses this information to generate an ML model for the selected memory
mode, while the ML inference runtime and driver must make the corresponding
buffers visible to the NPU at run time.

For a microcontroller device, the silicon vendor should define and validate these
settings in a DFP, with the device-specific resources referenced by its DFP
description. Application developers normally select the pack and consume the resolved
settings through CMSIS-Toolbox. The detailed configuration sections below are
retained for silicon vendors, pack authors, troubleshooting, and manual
integration when a suitable DFP is unavailable.

## Creating or extending a Device Family Pack

A silicon vendor or pack maintainer should include the device-specific
`vela.ini` configuration file, matching linker scripts, and Ethos-U driver
configuration in the DFP and reference them from the DFP description. The pack should expose the
applicable parameters through the CMSIS-Toolbox build context and MLOps
information so that an application build does not need to locate or reconcile
these files manually.

Validate every supported pack configuration as one unit: the `System_Config`
and `Memory_Mode` sections in `vela.ini`, linker placement, MPU/SAU and cache
attributes,
driver region settings, interrupt wiring, and physical device memory system must
agree. Version these artifacts together. The
[Alif Ensemble DFP](https://github.com/alifsemi/alif_ensemble-cmsis-dfp) is an
example of device-specific files referenced by a DFP description.

If the selected DFP does not provide the required `vela.ini` or linker information,
use the manual procedure in the following sections and obtain the missing device
parameters from the silicon vendor. Record locally supplied files with the
build, and report the missing pack support to the vendor.

## `vela.ini` system configuration names

The memory block names used in the `System_Config` sections of `vela.ini`, such
as `Sram`, `OnChipFlash`, `OffChipFlash`, and `Dram`, are memory type names used
by `vela.ini`. A memory type describes a class of memory and gives that memory a
name and attaches performance parameters to it. For example, `Sram`,
`OffChipFlash`, and `Dram` are memory types:

```ini
[System_Config.Example]
axi0_port=Sram
axi1_port=Dram
Sram_clock_scale=1.0
Sram_read_latency=32
Dram_clock_scale=0.25
Dram_read_latency=500
```

In this example, the configuration has two aliases, `Axi0` and `Axi1`. `Axi0` resolves to the
`Sram` memory type, and `Axi1` resolves to the `Dram` memory type. The names have
compiler meaning, but they do not by themselves name physical memories in the
SoC.

The `axi0_port` and `axi1_port` keys define logical aliases in `vela.ini`. They should
be read as labels used by `vela.ini` to connect a memory mode to memory types,
not as physical memory names or direct references to real hardware ports. A
memory mode is a separate `vela.ini` section that chooses which alias is used for
each kind of model storage: constants, the feature-map arena, and any cache or
staging area. For example:

```ini
[Memory_Mode.Shared_Sram]
const_mem_area=Axi1
arena_mem_area=Axi0
cache_mem_area=Axi0
```

Together with the system config above, this means that constants use the `Dram`
memory type, while the feature-map arena and cache or staging area use the
`Sram` memory type. The aliases describe the compiler's memory-placement model. The
hardware access path is selected later by the ML inference runtime and driver configuration
when the generated model is executed.

The stock memory type names are also the safest names for custom configurations:

- `Sram`
- `Dram`
- `OnChipFlash`
- `OffChipFlash`

These names follow `vela.ini` conventions and avoid parser naming pitfalls. The
Vela compiler splits memory parameter keys at the first underscore, so a
custom memory name such as `My_Sram` in `My_Sram_clock_scale` is parsed as
memory `My` with an unrecognized parameter name.

Model storage means the categories of data that the Vela compiler must place in
memory, such
as ML model constants, neural network activations, scratch tensors, and optional cache or
staging data. What matters to the compiler are the memory type selected for each kind of
model storage and the performance values associated with that type:

- `*_clock_scale`
- `*_burst_length`
- `*_read_latency`
- `*_write_latency`
- optional outstanding read and write limits, when supported by the target

For example, an SRAM/MRAM system configuration can use the `Axi0` alias for
`Sram` and `Axi1` for `OffChipFlash`:

```ini
axi0_port=Sram
axi1_port=OffChipFlash
```

In this case the physical memory behind `axi1_port` may be MRAM, even though the
memory type name in `vela.ini` is `OffChipFlash`. This is appropriate when the
MRAM is
used like a read-only, higher-latency memory for model constants.

An SRAM/DRAM system configuration can instead map the `Axi1` alias to `Dram`:

```ini
axi0_port=Sram
axi1_port=Dram
```

Here the `Dram` name is selected because the memory behaves like a read-write,
higher-latency memory. In both examples, the important part is that the memory
roles and the performance values attached to `Sram`, `OffChipFlash`, or `Dram`
describe the memory behavior well enough for the Vela compiler to make
scheduling, buffering,
and placement decisions.

These values form a compiler cost model. They are not only used for reports:
memory bandwidth, latency, burst length, and outstanding transaction limits can
change schedule selection, weight buffering, staging, DMA insertion, allocation
sizes, and therefore the generated command stream. `core_clock` is different; it
is mostly used for reporting and conversion of cycle counts to time. None of
these values are a replacement for benchmarking the final ML model on the real
system when accurate performance numbers are required.

In a typical platform integration, the `Axi0` alias is used for lower-latency
memory, often internal memory such as SRAM or TCM, and `Axi1` is used for
higher-latency memory, often external Flash, MRAM, or DRAM. The selected
`Memory_Mode` then chooses which alias is used for constants, the feature-map
arena, and any cache or staging area.

### `vela.ini` configuration constraints

Custom `vela.ini` files should preserve these naming conventions:

- Use `[System_Config.<name>]` and `[Memory_Mode.<name>]` section prefixes.
- Use `axi0_port` and `axi1_port` in system configs, and `Axi0` and `Axi1` in
  memory modes.
- Avoid underscores in custom memory type names.
- Put inherited sections before inheriting sections.
- Start custom U55 system configuration names with `Ethos_U55`. The Vela
  compiler uses that
  prefix to select the U55 AXI bandwidth width when translating memory
  performance values.

## `vela.ini` memory modes and memory areas

The `Memory_Mode` section of `vela.ini` selects how the compiler memory areas are
mapped onto the `Axi0` and `Axi1` aliases. The aliases are resolved to memory
types by the selected `System_Config`.

The Vela compiler then uses storage roles. A compiler storage role is the compiler's
name for what a tensor or buffer is used for after the memory mode has been
resolved. Examples are read-only storage for constants and weights, feature-map
storage for activations and scratch tensors, and staging storage for fast
temporary copies. These names may be visible in verbose compiler output or compiler
dumps:

| Memory mode attribute | Compiler storage role | Typical contents | Typical generated region |
| --- | --- | --- | --- |
| `const_mem_area` | read-only or permanent storage | constants, encoded weights, scales, and other read-only tensor data | region 0, weight tensor |
| `arena_mem_area` | feature-map or scratch arena storage | ML model input, output, intermediate activations, and scratch tensors | region 1, scratch tensor |
| `cache_mem_area` | staging or fast scratch storage | temporary fast copies used for caching, staging, or spilling | region 2, scratch-fast tensor when spilling is enabled |

The staging or fast scratch role is temporary storage used by the compiler for
data that benefits from being moved through faster memory. It is separate from
the main feature-map arena only when `cache_mem_area` resolves to a different
memory type from `arena_mem_area`.

The names `Sram_Only`, `Shared_Sram`, and `Dedicated_Sram` are used in the
official Vela documentation, so keeping those names makes the configuration
easier to relate to the Vela documentation when they match the intended mapping.
A platform can still define additional names when a more specific label is
useful. What matters for integration is the mapping described by the
`const_mem_area`, `arena_mem_area`, and `cache_mem_area` attributes.

A configuration where all three areas use the memory selected by `Axi0` is
typically named `Sram_Only`:

```ini
[Memory_Mode.Sram_Only]
const_mem_area=Axi0
arena_mem_area=Axi0
cache_mem_area=Axi0
```

A configuration where model constants are placed in the memory selected by
`Axi1`, while activations use the memory selected by `Axi0`, is typically named
`Shared_Sram`:

```ini
[Memory_Mode.Shared_Sram]
const_mem_area=Axi1
arena_mem_area=Axi0
cache_mem_area=Axi0
```

A configuration where constants and activations use the memory selected by
`Axi1`, while staging or cache storage uses the memory selected by `Axi0`, is
typically named `Dedicated_Sram`:

```ini
[Memory_Mode.Dedicated_Sram]
const_mem_area=Axi1
arena_mem_area=Axi1
cache_mem_area=Axi0
```

Another platform may use a different label for the same mapping. For example,
`Dtcm_Cache` can make it explicit that the cache memory is DTCM rather than
ordinary SRAM:

```ini
[Memory_Mode.Dtcm_Cache]
const_mem_area=Axi1
arena_mem_area=Axi1
cache_mem_area=Axi0
```

Conceptually, the two logical aliases in `vela.ini` can still target three run-time memory
purposes:

| Compiler memory area | Linker section purpose | Access |
| --- | --- | --- |
| `const_mem_area` | model coefficients and other read-mostly model data | read-only is preferred, but read-write memory can be used if the platform requires it |
| `arena_mem_area` | neural network activations, including ML model input and output tensors | read-write |
| `cache_mem_area` | staging or fast scratch area for dedicated SRAM configurations | read-write |

The `cache_mem_area` attribute is present in all `Memory_Mode` sections, but it
does not always imply a separate NPU-only cache memory. It becomes a distinct
staging or scratch-fast memory only when the memory mode maps `cache_mem_area` to
a different alias from `arena_mem_area`, as in a dedicated-SRAM configuration.
In SRAM-only or shared-SRAM configurations, `cache_mem_area` maps to the same
alias as `arena_mem_area`, so the scratch-fast role is folded into the normal
scratch region and there is no separate NPU-only cache section to allocate.

### Spilling

Spilling is the Vela compiler's use of a separate fast staging memory for data
whose main storage is in another memory, for example DRAM. When spilling is
enabled, the compiler
can insert DMA transfers that move selected weights or feature-map data into the
fast memory before an NPU operation uses it. This can improve performance, but
it can also change tensor placement, scheduling, memory allocation sizes, and
the generated command stream.

The compiler's spilling machinery uses this separate staging memory when the
resolved
cache or staging memory differs from the resolved feature-map arena memory.
Spilling uses the scratch-fast region in the generated command stream.

### Arena cache size {#integration_arena_cache_size}

A `Memory_Mode` section can also define `arena_cache_size`, for example:

```ini
arena_cache_size=393216
```

The meaning of `arena_cache_size` depends on the memory-area mapping, not on the
name of the memory mode. It is the scheduler's available fast-memory budget:

- If `arena_mem_area` and `cache_mem_area` map to the same logical alias, as
  in the `Sram_Only` and `Shared_Sram` examples above, `arena_cache_size` sizes
  the `arena_mem_area` and acts as the SRAM arena target.
- If `arena_mem_area` and `cache_mem_area` map to different logical aliases, as
  in the `Dedicated_Sram` and `Dtcm_Cache` examples above, `arena_cache_size`
  sizes the separate fast staging or cache memory, not the full arena memory.

The Vela compiler also supports related command-line options:

```text
vela network.tflite --optimise Size
vela network.tflite --optimise Performance --arena-cache-size 2097152
```

`--optimise Size` minimizes SRAM usage and does not use the arena cache memory
area size. `--optimise Performance` maximizes performance and uses the arena
cache memory area size when it is specified. The `--arena-cache-size` option sets
the arena cache size in bytes and overrides the `arena_cache_size` value from
`vela.ini`. If neither value is specified, the compiler uses a size equal to the
maximum
address supported by the selected Ethos-U target.

Ethos-U55 treats the real hardware AXI1 interface as read-only. Other Ethos-U
implementations do not necessarily have that constraint, so do not infer a
global read-only rule from the `Axi1` alias in `vela.ini` alone. The compiler
contains
generic spilling machinery, but `Dedicated_Sram` is not a practical Ethos-U55
execution model when it requires the writable feature-map arena to be backed by
the real U55 AXI1 side.

## Generated command-stream regions

After the Vela compiler resolves the selected system configuration and memory
mode, the generated
command stream uses NPU regions, also called base pointer indices. It does not
use the strings `Axi0` or `Axi1`. Those aliases have already been resolved into
compiler storage roles before this point.

For the common Cortex-M embedded flow, the application-facing regions are:

| Region | Compiler storage role | Driver base pointer |
| --- | --- | --- |
| 0 | read-only tensors, constants, encoded weights | weight tensor |
| 1 | feature-map arena and scratch tensors | scratch tensor |
| 2 | fast staging or cache tensors, when spilling is enabled | scratch-fast tensor |

Generated commands such as `NPU_SET_IFM_REGION`, `NPU_SET_OFM_REGION`,
`NPU_SET_WEIGHT_REGION`, `NPU_SET_SCALE_REGION`, `NPU_SET_DMA0_SRC_REGION`, and
`NPU_SET_DMA0_DST_REGION` carry region numbers and offsets. The runtime and
driver supply the base addresses and memory attributes for those regions.

Verbose compiler dumps can also show internal region names that are not ordinary
application-provided buffers. `Mem2Mem` is one of these names. The Vela compiler
uses it for
internal DMA or LUT handling, not for the application weight, scratch, or
scratch-fast buffers. Spilling uses the scratch-fast region, not `Mem2Mem`.

COP1 and COP2 are driver-action output formats produced by the Vela compiler.
The common Cortex-M
embedded flow uses the usual application-facing base pointers for weights,
scratch, and optionally scratch-fast storage. COP2 is required by the compiler for
flows that use separated input and output regions; it is a command-stream or
driver-action format that a compatible ML inference runtime flow must consume.

The Vela compiler can emit separated input and output regions when
`--separate-io-regions`
is used. That belongs to COP2/raw or separated-IO flows, not the normal Cortex-M
COP1-style flow that passes the usual weight, scratch, and optional scratch-fast
buffers. If the generated stream uses additional base pointer regions,
configure the corresponding driver region definitions from the actual generated
ML model and ML inference runtime flow.

## Linker script relationship

Even when a selected `System_Config` section in `vela.ini` names only two memory
aliases, the Vela compiler works with three logical storage roles: constants,
arena, and
staging or cache.
The linker script should therefore expose three corresponding sections so the
application can place each generated ML model artifact or run-time buffer
deliberately:

| Linker section | Compiler memory area | Sram_Only example | Shared_Sram example | Dedicated_Sram example |
| --- | --- | --- | --- | --- |
| `ethosu_arena` | `arena_mem_area` | low-latency memory | low-latency memory shared with Cortex-M software | DRAM |
| `ethosu_const` | `const_mem_area` | low-latency memory | external Flash or DRAM | external Flash or DRAM |
| `ethosu_cache` | `cache_mem_area` | not used separately | not used separately | dedicated SRAM or DTCM |

The memory names in the table are examples. A dedicated-cache configuration can
therefore use three different physical memories: external Flash for model
constants, DRAM for activations, and dedicated SRAM or DTCM for staging or
cache storage.
For SRAM-only and shared-SRAM configurations, the dedicated cache section is not
used and can be ignored.

Select a `System_Config` section in `vela.ini` that corresponds to the memory
placement used by the linker script. When the linker placement uses only two
physical memories, this mapping is usually direct because the selected
`System_Config` section
also describes two memory types and their performance parameters. When the linker
placement uses three physical memories, as in the dedicated-cache example above,
the selected `System_Config` section cannot fully describe all three memory
performances. In that case, use the system configuration that best matches the
intended ML model placement, then benchmark representative ML models to decide which
configuration generates the best model for the real memory system.

The exact section names are platform-defined. The important point is that the
linker placement, MPU/SAU attributes, cache maintenance policy, and memory-area
mapping selected in `vela.ini` agree. When `arena_mem_area` and
`cache_mem_area` map to the same resolved
memory type, there is no separate dedicated cache section to allocate. When they
map to different resolved memory types, the cache section should be placed in
the low-latency memory that is reserved for the NPU, for example a dedicated
SRAM or DTCM region. Dedicated SRAM cache is not a practical Ethos-U55 mode
because the writable arena cannot be placed behind the real U55 read-only AXI1
side.

## Driver weak hooks

The driver provides weak functions that a platform can override when the default
implementation is not sufficient. These hooks are part of the integration layer:
they connect the generic driver to the cache, address map, and synchronization
policy of the target system.

For data cache maintenance, the driver exposes \ref ethosu_flush_dcache
"ethosu_flush_dcache()" and \ref ethosu_invalidate_dcache
"ethosu_invalidate_dcache()". The default implementations are no-ops. Override
them when the Cortex-M data cache is enabled and the NPU accesses memory that may
also be cached by the CPU. It is advised to clean and invalidate.

- \ref ethosu_flush_dcache "ethosu_flush_dcache()" prepares CPU-written data for
  NPU access. It is used before inference so the NPU sees the command stream,
  constants, and input or activation data that may still be dirty in the CPU
  cache.
- \ref ethosu_invalidate_dcache "ethosu_invalidate_dcache()" prepares
  NPU-written data for CPU access. It is used after inference so the CPU does not
  read stale cache lines for output or activation buffers updated by the NPU. It is advised to clean and invalidate.

Cache management policy is platform-specific, but these rules are useful during
integration:

- Invalidating a cache range without first cleaning dirty lines can lose data
  that has only been written to the CPU cache. Use invalidate-only operations
  only when the platform can guarantee that the range has no dirty CPU-owned
  data.
- Cleaning by address can be slower for large model buffers, but cleaning the
  full data cache can disturb unrelated software by evicting or writing back data
  outside the inference buffers.
- If a cache hook is asked to operate on a non-cacheable region, such as TCM or a
  memory region configured as device/non-cacheable, it should do nothing for that
  range except any required ordering barrier.

The driver also exposes \ref ethosu_address_remap "ethosu_address_remap()" and
\ref ethosu_config_select "ethosu_config_select()" for address and
region-configuration handling.

- \ref ethosu_address_remap "ethosu_address_remap()" converts the address used
  by Cortex-M software into the address that must be programmed into the NPU when
  both agents see the same memory through different address windows. This is
  common when linker sections are placed in TCM for the CPU while the NPU reaches
  that storage through an AXI alias.
- \ref ethosu_config_select "ethosu_config_select()" selects the NPU memory
  region attributes for a command stream or base pointer. The default build-time
  definitions are enough for many systems; override this hook when the region
  selection depends on the address or memory placement.

For bare-metal systems, the default synchronization hooks may be sufficient if
only one execution context submits work to the driver. For RTOS-based systems, or
for integrations where multiple contexts may use the driver, override the mutex
and semaphore hooks to use the operating system primitives:
\ref ethosu_mutex_create "ethosu_mutex_create()",
\ref ethosu_mutex_destroy "ethosu_mutex_destroy()",
\ref ethosu_mutex_lock "ethosu_mutex_lock()",
\ref ethosu_mutex_unlock "ethosu_mutex_unlock()",
\ref ethosu_semaphore_create "ethosu_semaphore_create()",
\ref ethosu_semaphore_destroy "ethosu_semaphore_destroy()",
\ref ethosu_semaphore_take "ethosu_semaphore_take()", and
\ref ethosu_semaphore_give "ethosu_semaphore_give()".

These hooks are separate from the memory placement model, but they are commonly
implemented in the same platform integration layer as cache maintenance and
address remapping. The Driver API documentation provides the detailed function
prototypes and calling contract.

## Driver build configuration

The current Ethos-U driver build selects one NPU memory configuration at build
time. A single binary cannot switch between different memory-area mappings unless
the project builds separate variants or adds a platform-specific selection
mechanism.

With CMSIS Toolbox, select the required mode by providing the driver compile
definitions in the relevant build context, layer, or target configuration. The
values used for `NPU_QCONFIG` and `NPU_REGIONCFG_x` tell the driver which NPU
access path to use for the command stream and for each base pointer region:

| Driver define | Used for | Compiler memory area in the examples below |
| --- | --- | --- |
| `NPU_QCONFIG` | command stream | usually placed with model constants |
| `NPU_REGIONCFG_0` | base pointer region 0 | `const_mem_area` |
| `NPU_REGIONCFG_1` | base pointer region 1 | `arena_mem_area` |
| `NPU_REGIONCFG_2` | base pointer region 2 | `cache_mem_area`, when the generated model uses scratch-fast storage |

Additional `NPU_REGIONCFG_3` to `NPU_REGIONCFG_7` definitions exist for command
streams that use more base pointer regions. In normal Cortex-M COP1-style
outputs these are usually not additional application buffers. The Vela compiler
can use
regions 3 and 4 for separated input and output tensors when
`--separate-io-regions` is enabled, while the special `Mem2Mem` use of region 3
is for internal DMA/LUT handling. Configure extra regions only when the generated
model and ML inference runtime flow use them.

For the default driver configuration, the practical mapping is:

| Value | Ethos-U55/U65 meaning | Ethos-U85 meaning with the default `NPU_MEM_ATTR_0` to `NPU_MEM_ATTR_3` |
| --- | --- | --- |
| `0` or `1` | use AXI0 | use AXI_SRAM |
| `2` or `3` | use AXI1 | use AXI_EXT |

This lets the same region values give the same intended behavior across
Ethos-U55, Ethos-U65, and Ethos-U85: use `0` or `1` for base pointer regions
whose compiler storage role resolved through the `Axi0` alias, and use `2` or
`3` for base pointer regions whose role resolved through the `Axi1` alias.

The value does not name a physical memory by itself. It selects the NPU access
path and the attributes programmed for that path. The platform integration must
still ensure that the linker placement, MPU/SAU attributes, cache policy, and
driver AXI limit settings match the real SRAM, Flash, MRAM, DRAM, or TCM behind
the selected region configuration.

For example, a shared-SRAM memory mode may place the command stream and
constants in the memory selected by `Axi1`, and activations in the memory
selected by `Axi0`:

```ini
[Memory_Mode.Shared_Sram]
const_mem_area=Axi1
arena_mem_area=Axi0
cache_mem_area=Axi0
```

If the driver configuration maps `2` or `3` to the memory selected by `Axi1` and
`0` or `1` to the memory selected by `Axi0`, the corresponding build definitions
can be:

```yaml
defines:
  - NPU_QCONFIG: 2
  - NPU_REGIONCFG_0: 3
  - NPU_REGIONCFG_1: 0
  - NPU_REGIONCFG_2: 1
```

For a dedicated-SRAM memory mode, where supported, activations may move to the
memory selected by `Axi1` while the staging or cache region remains in the
memory selected by `Axi0`:

```ini
[Memory_Mode.Dedicated_Sram]
const_mem_area=Axi1
arena_mem_area=Axi1
cache_mem_area=Axi0
```

The build definitions then follow that placement:

```yaml
defines:
  - NPU_QCONFIG: 2
  - NPU_REGIONCFG_0: 3
  - NPU_REGIONCFG_1: 2
  - NPU_REGIONCFG_2: 1
```

For an SRAM-only memory mode, all generated regions can use the memory selected
by `Axi0`:

```ini
[Memory_Mode.Sram_Only]
const_mem_area=Axi0
arena_mem_area=Axi0
cache_mem_area=Axi0
```

```yaml
defines:
  - NPU_QCONFIG: 0
  - NPU_REGIONCFG_0: 1
  - NPU_REGIONCFG_1: 0
  - NPU_REGIONCFG_2: 1
```

The distinction between `0` and `1`, or between `2` and `3`, is target and
system specific. On Ethos-U55 and Ethos-U65 the value is the REGIONCFG encoding
and selects one of the AXI limit entries: `0` and `1` use the AXI0-side limit
settings, while `2` and `3` use the AXI1-side limit settings. On Ethos-U85 the
value is a MEM_ATTR index; the driver defaults make MEM_ATTR0 and MEM_ATTR1 use
AXI_SRAM, and MEM_ATTR2 and MEM_ATTR3 use AXI_EXT. Change `NPU_MEM_ATTR_0` to
`NPU_MEM_ATTR_3` only when the platform needs different U85 memory attributes.

The AXI limit values are separate platform-tuning settings. Simplified,
`AXI_LIMIT0` and `AXI_LIMIT1` on Ethos-U55 and Ethos-U65 correspond to the
AXI0-side configuration, while `AXI_LIMIT2` and `AXI_LIMIT3` correspond to the
AXI1-side configuration. On Ethos-U85 the equivalent limit settings are grouped
as AXI_SRAM and AXI_EXT. The exact outstanding transaction and burst settings
depend on the SoC interconnect and memory system.

Keep these definitions synchronized with the `Memory_Mode` used to compile the
model with the Vela compiler and with the linker sections used by the
application. The driver
must ultimately program region attributes that match the memory used for the
command stream and each model base pointer. If the meaning of a numeric value is
not clear for the selected Ethos-U target, use the target integration guide,
hardware register description, or a platform-provided configuration as the source
of truth before benchmarking or releasing the build.

## Determine the memory budget

Memory sizing is an iterative system exercise, not a single number from a Vela
compiler report.

### Establish the model-controlled floor

Compile the exact ML model for the exact Ethos-U target configuration using the
size strategy:

```console
vela network.tflite \
  --config target-vela.ini \
  --accelerator-config ethos-u55-256 \
  --system-config System_Name \
  --memory-mode Shared_Sram \
  --optimise Size \
  --verbose-allocation \
  --output-dir out/vela-size
```

Record each reported memory area, not only total SRAM. This is the Vela
compiler's practical
memory-minimized schedule for that model, compiler version, accelerator, and
configuration; it is not a proof of a global mathematical minimum.

### Convert the floor into a system budget

For every physical memory, account for all consumers:

```text
required memory = generated model data
                + ML inference runtime overhead
                + application static data
                + stacks and heaps
                + alignment and section padding
                + measured safety margin
```

Use the linker map and run-time high-water measurements to verify the non-model
terms. The activation buffer or tensor arena reserved by the application must
be at least the actual generated requirement, including framework alignment and
metadata overhead. A Vela compiler allocation report alone is not a complete
firmware
memory budget.

### Sweep feasible performance budgets

Give the Vela compiler the memory remaining after the system reservation and
compile several
performance candidates:

```console
vela network.tflite \
  --config target-vela.ini \
  --accelerator-config ethos-u55-256 \
  --system-config System_Name \
  --memory-mode Shared_Sram \
  --optimise Performance \
  --arena-cache-size BUDGET_BYTES \
  --verbose-allocation \
  --output-dir out/vela-performance
```

`--arena-cache-size` overrides the value in `vela.ini`. Its target area depends
on the selected memory-mode mapping, as explained in
\ref integration_arena_cache_size "Arena cache size".
Treat it as an optimization target: if the compiler reports that the target was
exceeded, use the reported actual allocation. Select a candidate only after its
linked image fits and its correctness and performance have been measured on the
target.

The compact loop is:

```text
size compile -> reserve the whole system -> performance budget sweep
     -> inspect actual allocation -> link -> run -> measure -> select
```

