# Integration {#mainpage}

This section is reserved for integration documentation and workflows.

See also:

- [General](../../general/html/index.html)
- [Drivers](../../drivers/html/index.html)


## General integration guidance

- Keep Ethos-U-visible memory regions explicit in linker scripts and MPU/SAU policy.
- Reserve enough SRAM for intermediate activations and command stream data.
- Ensure interrupt priority configuration avoids starvation of NPU completion signaling.
- Add timeout and recovery paths for fault handling during bring-up.
- Validate with a minimal known-good model before integrating full application graphs.
