# Integration {#mainpage}

This section contains integration documentation and workflows.

See also:

- [General](../general/index.html)
- [Drivers](../drivers/index.html)


## Introduction

The Vela configuration, linker script, MPU or SAU setup, and Ethos-U driver build
configuration must describe the same memory system. Vela uses this information to
generate a model for the selected memory mode, while the runtime software and
driver must make the corresponding buffers visible to the NPU at run time.

## Vela system configuration names

The memory block names used in the `System_Config` sections of `vela.ini`, such
as `Sram`, `OnChipFlash`, `OffChipFlash`, and `Dram`, are Vela memory type names.
The names themselves do not carry platform-specific meaning. They could have
been named `MemBlock0` and `MemBlock1`; what matters to Vela are the performance
values associated with each name:

- `*_clock_scale`
- `*_burst_length`
- `*_read_latency`
- `*_write_latency`
- optional outstanding read and write limits, when supported by the target

For example, an SRAM/MRAM system configuration can use:

```ini
axi0_port=Sram
axi1_port=OffChipFlash
```

In this case the physical memory behind `axi1_port` may be MRAM, even though the
Vela memory type name is `OffChipFlash`. This is appropriate when the MRAM is
used like a read-only, higher-latency memory for model constants.

An SRAM/DRAM system configuration can instead use:

```ini
axi0_port=Sram
axi1_port=Dram
```

Here the `Dram` name is selected because the memory behind `axi1_port` behaves
like a read-write, higher-latency memory. In both examples, the important part is
that the performance values attached to `Sram`, `OffChipFlash`, or `Dram`
describe the memory behavior well enough for Vela to make placement decisions.

These values form a compiler cost model. They are accurate enough for Vela to
make code generation and memory placement decisions, but they are not a
replacement for benchmarking the final network on the real system when accurate
performance numbers are required.

The `axi0_port` and `axi1_port` names match the two AXI ports used by Ethos-U55
and Ethos-U65. The names identify NPU access paths, not specific physical
memories. In a typical platform integration, `Axi0` is tuned for lower-latency
memories, often internal memories such as SRAM or TCM, and `Axi1` is tuned for
higher-latency memories, often external memories such as Flash or DRAM. For
Ethos-U85 the `axi0` and `axi1` names are less descriptive; it is better to think
in terms of low-latency and higher-latency access paths.

The `cache_mem_area` attribute is present in all `Memory_Mode` sections, but it
does not always imply a separate NPU-only cache memory. It is used as a dedicated
NPU cache area only when the memory mode maps `cache_mem_area` to a different
AXI access path from `arena_mem_area`, as in a dedicated-SRAM configuration. In
SRAM-only or shared-SRAM configurations, `cache_mem_area` maps to the same AXI
access path as `arena_mem_area`. That does not prove it is the same physical
memory, but it does mean there is no separate NPU-only cache section to allocate.

## Vela memory modes and memory areas

The `Memory_Mode` section of `vela.ini` selects how the Vela memory areas are
mapped onto the two AXI areas. The names `Sram_Only`, `Shared_Sram`, and
`Dedicated_Sram` are used in the official Vela documentation, so keeping those
names makes the configuration easier to relate to the Vela documentation when
they match the intended mapping. A platform can still define additional names
when a more specific label is useful. What matters for integration is the mapping
described by the `const_mem_area`, `arena_mem_area`, and `cache_mem_area`
attributes.

A configuration where all three areas use the low-latency path is typically named
`Sram_Only`:

```ini
[Memory_Mode.Sram_Only]
const_mem_area=Axi0
arena_mem_area=Axi0
cache_mem_area=Axi0
```

A configuration where model constants are placed in a read-only higher-latency
memory, while activations use the low-latency path, is typically named
`Shared_Sram`:

```ini
[Memory_Mode.Shared_Sram]
const_mem_area=Axi1
arena_mem_area=Axi0
cache_mem_area=Axi0
```

A configuration where constants and activations use the higher-latency path,
while the NPU cache uses a low-latency memory reserved for the NPU, is typically
named `Dedicated_Sram`:

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

Conceptually, the two AXI selections can still target three runtime memory
purposes:

| Vela memory area | Linker section purpose | Access |
| --- | --- | --- |
| `const_mem_area` | model coefficients and other read-mostly model data | read-only is preferred, but read-write memory can be used if the platform requires it |
| `arena_mem_area` | network activations, including input and output tensors | read-write |
| `cache_mem_area` | NPU cache or scratch area for dedicated SRAM configurations | read-write |

### Arena cache size

A `Memory_Mode` section can also define `arena_cache_size`, for example:

```ini
arena_cache_size=393216
```

The meaning of `arena_cache_size` depends on the memory-area mapping, not on the
name of the memory mode:

- If `arena_mem_area` and `cache_mem_area` map to the same AXI access path, as
  in the `Sram_Only` and `Shared_Sram` examples above, `arena_cache_size` sizes
  the `arena_mem_area`.
- If `arena_mem_area` and `cache_mem_area` map to different AXI access paths, as
  in the `Dedicated_Sram` and `Dtcm_Cache` examples above, `arena_cache_size`
  sizes the `cache_mem_area`.

Vela also supports related command-line options:

```text
vela network.tflite --optimise Size
vela network.tflite --optimise Performance --arena-cache-size 2097152
```

`--optimise Size` minimizes SRAM usage and does not use the arena cache memory
area size. `--optimise Performance` maximizes performance and uses the arena
cache memory area size when it is specified. The `--arena-cache-size` option sets
the arena cache size in bytes and overrides the `arena_cache_size` value from
`vela.ini`. If neither value is specified, Vela uses a size equal to the maximum
address supported by the selected Ethos-U target.

Ethos-U55 treats the AXI1 path as read-only. Other Ethos-U implementations do not
necessarily have that constraint, so do not infer a global read-only rule from
the `Axi1` name alone.

## Linker script relationship

Even when a selected `System_Config` section in `vela.ini` names only two memory
ports, Vela works with three logical memory areas: constants, arena, and cache.
The linker script should therefore expose three corresponding sections so the
application can place each generated model artifact or runtime buffer
deliberately:

| Linker section | Vela memory area | Sram_Only example | Shared_Sram example | Dedicated_Sram example |
| --- | --- | --- | --- | --- |
| `ethosu_arena` | `arena_mem_area` | low-latency memory | low-latency memory shared with Cortex-M software | DRAM |
| `ethosu_const` | `const_mem_area` | low-latency memory | external Flash or DRAM | external Flash or DRAM |
| `ethosu_cache` | `cache_mem_area` | not used | not used | dedicated SRAM or DTCM |

The memory names in the table are examples. A dedicated-cache configuration can
therefore use three different physical memories: external Flash for model
constants, DRAM for activations, and dedicated SRAM or DTCM for the NPU cache.
For SRAM-only and shared-SRAM configurations, the dedicated cache section is not
used and can be ignored.

Select a `System_Config` section in `vela.ini` that corresponds to the memory
placement used by the linker script. When the linker placement uses only two
physical memories, this mapping is usually direct because the Vela system section
also describes two memory types and their performance parameters. When the linker
placement uses three physical memories, as in the dedicated-cache example above,
the selected Vela system section cannot fully describe all three memory
performances. In that case, use the system configuration that best matches the
intended model placement, then benchmark representative networks to decide which
configuration generates the best model for the real memory system.

The exact section names are platform-defined. The important point is that the
linker placement, MPU/SAU attributes, cache maintenance policy, and Vela memory
mode agree. When `arena_mem_area` and `cache_mem_area` map to the same AXI access
path, there is no separate dedicated cache section to allocate. When they map to
different AXI access paths, the cache section should be placed in the low-latency
memory that is reserved for the NPU, for example a dedicated SRAM or DTCM region.
Dedicated SRAM cache is not supported on Ethos-U55.

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

| Driver define | Used for | Vela memory area in the examples below |
| --- | --- | --- |
| `NPU_QCONFIG` | command stream | usually placed with model constants |
| `NPU_REGIONCFG_0` | base pointer region 0 | `const_mem_area` |
| `NPU_REGIONCFG_1` | base pointer region 1 | `arena_mem_area` |
| `NPU_REGIONCFG_2` | base pointer region 2 | `cache_mem_area` |

Additional `NPU_REGIONCFG_3` to `NPU_REGIONCFG_7` definitions exist for command
streams that use more base pointer regions. Configure them with the same rule if
they are used by the generated model.

For the default driver configuration, the practical mapping is:

| Value | Ethos-U55/U65 meaning | Ethos-U85 meaning with the default `NPU_MEM_ATTR_0` to `NPU_MEM_ATTR_3` |
| --- | --- | --- |
| `0` or `1` | use AXI0 | use AXI_SRAM |
| `2` or `3` | use AXI1 | use AXI_EXT |

This lets the same region values give the same intended behavior across
Ethos-U55, Ethos-U65, and Ethos-U85: use `0` or `1` for regions that Vela placed
on `Axi0`, and use `2` or `3` for regions that Vela placed on `Axi1`.

The value does not name a physical memory by itself. It selects the NPU access
path and the attributes programmed for that path. The platform integration must
still ensure that the linker placement, MPU/SAU attributes, cache policy, and
driver AXI limit settings match the real SRAM, Flash, MRAM, DRAM, or TCM behind
that path.

For example, a shared-SRAM memory mode may place the command stream and
constants on the higher-latency path, and activations on the low-latency path:

```ini
[Memory_Mode.Shared_Sram]
const_mem_area=Axi1
arena_mem_area=Axi0
cache_mem_area=Axi0
```

The corresponding build definitions can therefore use `2` or `3` for the
command stream and constants, and `0` or `1` for activations:

```yaml
defines:
  - NPU_QCONFIG: 2
  - NPU_REGIONCFG_0: 3
  - NPU_REGIONCFG_1: 0
  - NPU_REGIONCFG_2: 1
```

For a dedicated-SRAM memory mode, where supported, activations may move to the
higher-latency path while the cache region remains on the low-latency path:

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

For an SRAM-only memory mode, all regions can use the low-latency path:

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
model with Vela and with the linker sections used by the application. The driver
must ultimately program region attributes that match the memory used for the
command stream and each model base pointer. If the meaning of a numeric value is
not clear for the selected Ethos-U target, use the target integration guide,
hardware register description, or a platform-provided configuration as the source
of truth before benchmarking or releasing the build.

## General integration guidance

- Keep the `vela.ini` `System_Config`, selected `Memory_Mode`, linker sections,
  MPU/SAU attributes, and driver build definitions consistent.
- Use `arena_cache_size` as the Vela-defined allocation constraint. In
  shared-SRAM mappings, it constrains the `arena_mem_area`, so the application
  arena, often a statically allocated C array, must not be smaller than this
  value. In dedicated-cache mappings, it constrains the `cache_mem_area`; model
  constants and activations can then grow up to the limits of the memories where
  the linker places them.
- Place model constants, activations, and any dedicated cache section in memory
  regions that match the selected Vela memory-area mapping. If the linker uses
  three physical memories, benchmark representative networks to confirm the best
  Vela system configuration.
- Override the driver weak hooks when the default integration assumptions do not
  match the platform, especially for data cache maintenance, address remapping,
  and RTOS synchronization.
- Ensure the NPU completion interrupt is eventually serviced. Very low jitter is
  usually not required for inference workloads, but completion handling must not
  be postponed indefinitely.
- During bring-up, use timeouts, fault reporting, and a minimal known-good model
  before moving to full application graphs.
