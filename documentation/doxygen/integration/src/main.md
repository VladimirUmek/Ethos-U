# Integration {#mainpage}

This section contains integration documentation and workflows.

See also:

- [General](../general/index.html)
- [Drivers](../drivers/index.html)


## Vela, linker, and driver memory configuration

The Vela configuration, linker script, MPU or SAU setup, and Ethos-U driver build
configuration must describe the same memory system. Vela uses this information to
generate a model for the selected memory mode, while the runtime software and
driver must make the corresponding buffers visible to the NPU at run time.

### Vela system configuration names

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

These values form a compiler cost model. They are accurate enough for Vela to
make code generation and memory placement decisions, but they are not a
replacement for benchmarking the final network on the real system when accurate
performance numbers are required.

The `axi0_port` and `axi1_port` names match the two AXI ports used by Ethos-U55
and Ethos-U65. For Ethos-U85 the names are less descriptive, because the
integration is better understood as an SRAM-like low-latency access path and an
external or higher-latency access path. A platform may choose clearer local names
for its own configuration, but the selected Vela memory mode still has to map the
three Vela memory areas onto the memory paths available to the NPU.

### Vela memory modes and memory areas

The `Memory_Mode` section of `vela.ini` selects how the two Vela AXI areas are
used. In practice the common choices are:

- `Sram_Only`: constants, activations, and cache all use the SRAM-like memory.
- `Shared_Sram`: constants use the non-SRAM memory and activations/cache use
  shared SRAM.
- `Dedicated_Sram`: constants and activations use the non-SRAM memory, while the
  cache uses SRAM dedicated to the NPU.

The names can be extended by a platform partner if clearer product-specific names
are useful. Conceptually, the two AXI selections can still target three runtime
memory purposes:

| Vela memory area | Linker section purpose | Access |
| --- | --- | --- |
| `const_mem_area` | model coefficients and other read-mostly model data | read-only is preferred, but read-write memory can be used if the platform requires it |
| `arena_mem_area` | network activations, including input and output tensors | read-write |
| `cache_mem_area` | NPU cache or scratch area for dedicated SRAM configurations | read-write |

Ethos-U55 treats the AXI1 path as read-only. Other Ethos-U implementations do not
necessarily have that constraint, so do not infer a global read-only rule from
the `Axi1` name alone.

### Linker script relationship

Even when a selected `System_Config` section in `vela.ini` names only two memory
ports, Vela works with three logical memory areas: constants, arena, and cache.
The linker script should therefore expose three corresponding sections so the
application can place each generated model artifact or runtime buffer
deliberately:

```text
ethosu_const    -> model coefficients / const_mem_area
ethosu_arena    -> activation arena / arena_mem_area
ethosu_cache    -> dedicated NPU cache / cache_mem_area
```

The exact section names are platform-defined. The important point is that the
linker placement, MPU/SAU attributes, cache maintenance policy, and Vela memory
mode agree. For `Sram_Only` and `Shared_Sram`, the cache section may be placed in
the same physical SRAM as the arena. For `Dedicated_Sram`, the cache section
should be placed in the SRAM that is reserved for the NPU, for example an
Ethos-U85 dedicated SRAM configuration. Dedicated SRAM cache is not supported on
Ethos-U55.

### Driver weak hooks

The driver provides weak functions that a platform can override when the default
implementation is not sufficient. These hooks are part of the integration layer:
they connect the generic driver to the cache, address map, and synchronization
policy of the target system.

For data cache maintenance, the driver exposes:

```c
void ethosu_flush_dcache(const uint64_t *base_addr,
                         const size_t *base_addr_size,
                         int num_base_addr);

void ethosu_invalidate_dcache(const uint64_t *base_addr,
                              const size_t *base_addr_size,
                              int num_base_addr);
```

The default implementations are no-ops. Override them when the Cortex-M data
cache is enabled and the NPU accesses memory that may also be cached by the CPU.
The flush hook is called before inference for the command stream and base
addresses. The invalidate hook is called after inference so CPU reads observe
data written by the NPU. A platform implementation may skip cache maintenance
for memory regions that are configured as non-cacheable, and apply clean or
invalidate operations only to cached regions. The addresses passed to these hooks
must follow the cache-line alignment requirements of the CPU.

The driver also exposes address and region-configuration hooks:

```c
uint64_t ethosu_address_remap(uint64_t address, int index);
unsigned int ethosu_config_select(uint64_t address, int index);
```

`ethosu_address_remap` is used when the Cortex-M and Ethos-U do not see the same
physical memory at the same address. This can happen when a linker section is
placed in a memory such as TCM for the CPU, but the NPU reaches the same storage
through a different AXI address window. The driver calls the remap hook for the
command stream with `index == -1` and for each base pointer with `index >= 0`
before programming the NPU registers.

`ethosu_config_select` selects the NPU region configuration for the remapped
address. The default implementation returns the build-time `NPU_QCONFIG` value
for the command stream and `NPU_REGIONCFG_n` for base pointer `n`. Override it
only if the platform needs to choose a region configuration dynamically from the
address or from the base pointer index.

For RTOS-based integrations, the mutex and semaphore weak hooks can also be
overridden to use the operating system primitives:

```c
void *ethosu_mutex_create(void);
void ethosu_mutex_destroy(void *mutex);
int ethosu_mutex_lock(void *mutex);
int ethosu_mutex_unlock(void *mutex);

void *ethosu_semaphore_create(void);
void ethosu_semaphore_destroy(void *sem);
int ethosu_semaphore_take(void *sem, uint64_t timeout);
int ethosu_semaphore_give(void *sem);
```

These hooks are separate from the memory placement model, but they are commonly
implemented in the same platform integration layer as cache maintenance and
address remapping.

### Driver build configuration

The current Ethos-U driver build selects one NPU memory configuration at build
time. A single binary cannot switch between `Sram_Only`, `Shared_Sram`, and
`Dedicated_Sram` unless the project builds separate variants or adds a
platform-specific selection mechanism.

With CMSIS Toolbox, select the required mode by providing the driver compile
definitions in the relevant build context, layer, or target configuration. For
example:

```yaml
# Dedicated_Sram
defines:
  - NPU_QCONFIG=3       # AXI1=M1
  - NPU_REGIONCFG_0=3   # AXI1=M1
  - NPU_REGIONCFG_1=3   # AXI1=M1
```

```yaml
# Shared_Sram
defines:
  - NPU_QCONFIG=3       # AXI1=M1
  - NPU_REGIONCFG_0=3   # AXI1=M1
  - NPU_REGIONCFG_1=0   # AXI0=M0
```

```yaml
# Sram_Only
defines:
  - NPU_QCONFIG=0       # AXI0=M0
  - NPU_REGIONCFG_0=0   # AXI0=M0
  - NPU_REGIONCFG_1=0   # AXI0=M0
```

Keep these definitions synchronized with the `Memory_Mode` used to compile the
model with Vela and with the linker sections used by the application. If any one
of those three descriptions changes, the other two should be reviewed before
benchmarking or releasing the build.

## General integration guidance

- Keep Ethos-U-visible memory regions explicit in linker scripts and MPU/SAU policy.
- Reserve enough SRAM for intermediate activations, command stream data, and any
  dedicated cache area required by the selected Vela memory mode.
- Ensure interrupt priority configuration avoids starvation of NPU completion signaling.
- Add timeout and recovery paths for fault handling during bring-up.
- Validate with a minimal known-good model before integrating full application graphs.
