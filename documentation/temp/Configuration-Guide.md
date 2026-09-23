# Ethos-U and ML model application setup

This guide explains how to configure Ethos-U application for an arbitrary target
and an arbitrary ML model.

## 1. Examine the target memory system

Find physical memory that the NPU can access.

Determine the memory type, is it:

- Read-Only (Flash/MRAM), Read/Write (SRAM/DRAM)

Note the size of accessible memory so that the memory requirements can be evaluated
after Vela compiles the ML model.

Other factors to consider:

- Check how the NPU can access that memory, for
  - U55/U65: which memory can be accessed via `AXI0` or `AXI1`
  - U85: which memory can be accessed via `AXI_SRAM` or `AXI_EXT`
- Security: secure/non-secure attribution and NPU access permission
- CPU cacheability: are explicit clean/invalidate operations required
- Performance: does the memory performance make sense for intended use

## 2. Examine configuration file for Vela

Use existing configuration (provided by device vendor) or create your own.
Existing configuration may be modified if it does not meet requirements.

### Examine system configuration for Vela

Listed System_Config is a model of physical memories. Vela understands types:

- `Sram`, `OnChipFlash`, `OffChipFlash`, and `Dram`

This are only names used to model the performance of different physical memory types.

Select System_Config that models physical memories you want to use.

### Examine memory mode configuration for Vela

Select appropriate Memory_Mode:

```ini
[Memory_Mode.<memory_mode-name>]
const_mem_area=<Axi0-or-Axi1>
arena_mem_area=<Axi0-or-Axi1>
cache_mem_area=<Axi0-or-Axi1>
arena_cache_size=<bytes>
```

> NOTE
>
> - `const_mem_area=Axi0` tells Vela to allocate constants to the logical Axi0 memory area
> and model them according to axi0_port from System_Config.
> - `arena_mem_area=Axi0` tells Vela to allocate working tensors to the logical Axi0 memory area
> and model them according to axi0_port from System_Config.
> - `cache_mem_area=Axi0` tells Vela to allocate optional fast scratch memory to the logical Axi0 memory
> are and model it according to axi0_port from System_Config.
> - `arena_cache_size` is the size of cache buffer passed to the Ethos-U initialization function

## 4. Compile the model for selected NPU and Vela configuration

Set the Ethos-U type, MAC count, system configuration, and memory mode in CMSIS solution:

```yml
mlops:
  npu:
    type: <Ethos-U55-or-Ethos-U65-or-Ethos-U85>
    macs: <implemented-MAC-count>
  vela:
    system: <system_config-name>
    memory: <memory_mode-name>
```

Regenerated `*.cbuild-mlops.yml` shall reflect the selected configuration.

Recompile the model.

For the example in the Ethos-U pack:

```sh
python script/model-converter.py <solution>.cbuild-mlops.yml
```

Check Vela summary and confirm:

- the accelerator and MAC count match the hardware;
- the expected system configuration and memory mode were selected;
- SRAM and external-memory use fit the available physical regions; and
- the expected operators were delegated to the NPU.

Vela summary also lists memory consumption.

## 5. Configure memory routing

- `NPU_QCONFIG` routes command stream (read-only)
- `NPU_REGIONCFG_0` routes the constants (read-only)
- `NPU_REGIONCFG_1` routes arena tensors (read/write)
- `NPU_REGIONCFG_2` routes optional cache (read/write)

Use defines and value selectors to route the access to the physical memory:

```yml
define:
  - NPU_QCONFIG: <selector-for-command-stream>
  - NPU_REGIONCFG_0: <selector-for-constants>
  - NPU_REGIONCFG_1: <selector-for-arena>
  - NPU_REGIONCFG_2: <selector-for-fast-cache>
```

Selector value are explained below, depending on Ethos-U type.

### Ethos-U55 and Ethos-U65

For Ethos-U55/U65 selector values choose both the AXI port and an AXI limit/counter profile:

| Selector | NPU path | Profile      |
|----------|----------|--------------|
| `0`      | `AXI0`   | `AXI_LIMIT0` |
| `1`      | `AXI0`   | `AXI_LIMIT1` |
| `2`      | `AXI1`   | `AXI_LIMIT2` |
| `3`      | `AXI1`   | `AXI_LIMIT3` |

Different profiles are used so a platform can independently tune the bus traffic. For example,
command-stream and constant-data traffic use different profile due to potential performance tuning.

### Ethos-U85

For U85, selector value is an index into `NPU_MEM_ATTR_n`:

| Selector | NPU path   | Memory attributes |
|----------|------------|-------------------|
| `0`      | `AXI_SRAM` | `NPU_MEM_ATTR_0`  |
| `1`      | `AXI_SRAM` | `NPU_MEM_ATTR_1`  |
| `2`      | `AXI_EXT`  | `NPU_MEM_ATTR_2`  |
| `3`      | `AXI_EXT`  | `NPU_MEM_ATTR_3`  |

## 6. Configure memory placement via linker script

Each relevant Ethos-U defined memory section shall be placed into physical memory modeled by System_Config.

| Linker section | NPU access |
|----------------|------------|
| `ethos_model`  | read-only  |
| `ethos_arena`  | read/write |
| `ethos_cache`  | read/write |
