# Native Windows SYCL build (experimental)

This manual path was exercised on Windows 10 x64 with an Intel Arc Pro B70,
Visual Studio 2022, Intel oneAPI 2026.1.1 and Level Zero SDK 1.32.0.
The Windows setup wizard is not implemented by this change.

Install the Visual Studio C++ x64 build tools, Intel oneAPI DPC++ compiler and
oneMKL development files, CMake, Ninja, Git and the Level Zero SDK. Activate
the Visual Studio x64 and oneAPI environments before starting PowerShell.
Use a current Intel graphics driver compatible with your GPU.

From the repository root:

```powershell
./sycl/tools/build-windows.ps1 -Parity `
  -LevelZeroInclude C:/SDK/level-zero/include `
  -LevelZeroLibrary C:/SDK/level-zero/lib/ze_loader.lib
$env:ONEAPI_DEVICE_SELECTOR = 'level_zero:gpu'
./build-sycl-windows/strata-sycl-diagnostic.exe
./sycl/tools/diagnose-windows.ps1
```

Adjust SDK paths to your installation. The build uses JIT unless `-Aot` is
explicitly supplied. The compiler runtime, oneMKL and Level Zero loader must
be available on PATH at runtime. Models and runtimes are not bundled.

The implementation supplies MSVC-compatible compiler options, Windows pinned
memory support and positioned file reads, plus a device capability diagnostic.
Parity test identifiers avoid Windows SDK macro collisions.

See [TEST_B70_WINDOWS.md](TEST_B70_WINDOWS.md) for measured coverage and gaps.
