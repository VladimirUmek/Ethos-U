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

## max read/writes settings

This are driver settings.

AXI_LIMITx_MAX_OUTSTANDING_READS`, and `AXI_LIMITx_MAX_OUTSTANDING_WRITES`

vela.ini uses similar settings. I assume that vela generated code will not use more then specified in the vela.ini file. 
As a user, do I need to care about the driver settings?

