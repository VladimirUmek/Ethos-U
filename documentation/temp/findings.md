# This is a list of observations

## Vela Error Reporting

There is a lot of noise in error outputs. Maybe there is way to remove the `Traceback` output and make it optional with a --debug option or so.

The relevant message is at the very end:
ethosu.vela.errors.ConfigOptionError: 'Error: Invalid configuration of arena_mem_area=OffChipFlash (must be Sram or Dram)'

```
C:\w\Test-Project\Hello-Ethos-U>vela Model\hello_world\hello_world_int8.tflite --accelerator-config ethos-u55-256 --system-config Ethos_U55_High_End_Embedded --memory-mode Dedicated_Sram_512KB --verbose-config
Warning: No configuration file specified. Using a default of ['c:\\users\\reikei01\\appdata\\roaming\\python\\python313\\site-packages\\ethosu\\config_files\\Arm\\vela.ini']. Compilation may be invalid or non-optimal.
Traceback (most recent call last):
  File "<frozen runpy>", line 198, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File "C:\Users\reikei01\AppData\Roaming\python\python313\scripts\vela.exe\__main__.py", line 5, in <module>
    sys.exit(main())
             ~~~~^^
  File "c:\users\reikei01\appdata\roaming\python\python313\site-packages\ethosu\vela\vela.py", line 1219, in main
    arch = architecture_features.ArchitectureFeatures(
        vela_config_files=config_files,
    ...<5 lines>...
        arena_cache_size=args.arena_cache_size,
    )
  File "c:\users\reikei01\appdata\roaming\python\python313\site-packages\ethosu\vela\architecture_features.py", line 298, in __init__
    self._get_vela_config(vela_config_files, verbose_config, arena_cache_size)
    ~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "c:\users\reikei01\appdata\roaming\python\python313\site-packages\ethosu\vela\architecture_features.py", line 728, in _get_vela_config
    raise ConfigOptionError("arena_mem_area", self._mem_port_mapping(self.arena_mem_area).name, "Sram or Dram")
ethosu.vela.errors.ConfigOptionError: 'Error: Invalid configuration of arena_mem_area=OffChipFlash (must be Sram or Dram)'
```

## Default vela.ini file

Does not contain a config that enables spilling (cache) with Ethos-U55. I believe that cache is effectively impossible as Ethos-U55 AXI1 port is read-only.  If this is the case, we should mention this.

## Usage of **Dedicated-SRAM mode on Cortex-M**

A common Cortex-M system can have three relevant memory areas:

- on-chip SRAM reserved as a fast NPU cache;
- memory-mapped off-chip QSPI flash, which holds constants and is read-only
  during inference; and
- off-chip RAM, which holds the writable arena.

The reference `Dedicated_Sram` mode cannot represent this topology. It assigns
both `const_mem_area` and `arena_mem_area` to `Axi1`, while assigning
`cache_mem_area` to `Axi0`:

```ini
[Memory_Mode.Dedicated_Sram]
const_mem_area=Axi1
arena_mem_area=Axi1
cache_mem_area=Axi0
```

If `Axi1` maps to `OffChipFlash`, Vela rejects the configuration because the
arena must be writable. If `Axi1` maps to `Dram`, compilation succeeds, but Vela
models both constants and the arena in DRAM instead of modeling constants in
QSPI flash. Consequently, constants in flash, the arena in off-chip RAM, and a
cache in on-chip SRAM cannot be represented at the same time.

The terminology in the report adds another problem. The configuration and
documentation use `const_mem_area`, `arena_mem_area`, and `cache_mem_area`, but
the summary CSV uses `weights_storage_area` and `feature_map_storage_area`. It
has no corresponding cache-storage field and reports memory usage only as totals
for each physical memory type. For example, when constants and the arena are in
DRAM, `dram_memory_used` combines both. `total_npu_encoded_weights` covers only
encoded weights and cannot be used to derive either the complete constant region
or the arena size.

This is more than a naming inconsistency. A user cannot describe the common
three-memory topology or obtain separate const, arena, and cache requirements
from the report. Vela either needs distinct mappings and report fields for these
areas, or the limitation and the correspondence between the two terminologies
must be documented clearly.

## max read/writes settings

This are driver settings.

AXI_LIMITx_MAX_OUTSTANDING_READS`, and `AXI_LIMITx_MAX_OUTSTANDING_WRITES`

vela.ini uses similar settings. I assume that vela generated code will not use more then specified in the vela.ini file. 
As a user, do I need to care about the driver settings?

