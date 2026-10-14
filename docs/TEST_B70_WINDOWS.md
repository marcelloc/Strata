# Native Windows validation report

Base: Strata 0.1.44.1 (`296b59d2`), with the native Windows SYCL changes.
Hardware/software: Intel Arc Pro B70, Windows 10 x64, 80 GB system RAM,
Visual Studio 2022, oneAPI 2026.1.1, Level Zero SDK 1.32.0; JIT compilation.

The full SYCL build with parity targets completed. Seven GPU tests passed:
sampler, rope, quantize_act, elementwise, bf16_gemv, kv_q8 and prefill_gdn.
The positioned-file host test was previously exercised with concurrent reads,
partial EOF and offsets above 4 GiB; that source did not change in the upgrade.

The native API served IQ3_XXS with MTP, a 131072-token context, INT8 KV and
32768 resident KV tokens. A 127009-token prompt recovered all three requested
targets. SSE streaming and a subsequent arithmetic request also succeeded.
Six short comparison requests returned identical text before and after the
0.1.41 to 0.1.44.1 upgrade. These runs are functional evidence, not a controlled
performance benchmark. Server unload completed with exit code zero.

Still unvalidated: Linux SYCL regression build, Windows 11, multiple GPUs,
256K context and extended soak testing. A standalone engine shutdown failure
seen on the earlier 0.1.41 port has not been rechecked on 0.1.44.1. Server unload
success does not establish that the standalone failure is fixed.

No changes to the shared CUDA/HIP engine are included. Linux default behavior
has not been established as byte-identical by execution. Keep this contribution
in draft until the affected backend validation is complete.
