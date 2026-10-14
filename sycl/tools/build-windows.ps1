[CmdletBinding()]
param(
    [string]$BuildDir = 'build-sycl-windows',
    [string]$GgmlDir = '',
    [string]$LevelZeroInclude = '',
    [string]$LevelZeroLibrary = '',
    [ValidatePattern('^[a-zA-Z0-9_-]*$')][string]$Aot = '',
    [ValidateRange(1, 256)][int]$Jobs = 4,
    [switch]$Parity,
    [switch]$ConfigureOnly
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitProcess) {
    throw 'Use a 64-bit Windows PowerShell in an Intel oneAPI + Visual Studio x64 environment.'
}
$missing = @('icx', 'cl', 'link', 'cmake', 'ninja', 'git') | Where-Object {
    -not (Get-Command $_ -CommandType Application -ErrorAction SilentlyContinue)
}
if ($missing) {
    throw "Missing tools: $($missing -join ', '). Open Intel oneAPI command prompt for VS x64, then start powershell. See docs/BUILD_WINDOWS_SYCL.md. Nothing was installed."
}
if ($env:VSCMD_ARG_TGT_ARCH -and $env:VSCMD_ARG_TGT_ARCH -ne 'x64') {
    throw 'Visual Studio targets a non-x64 architecture. Open its x64 tools environment.'
}
if (-not $env:MKLROOT -or -not (Test-Path (Join-Path $env:MKLROOT 'include/oneapi/mkl.hpp'))) {
    throw 'oneMKL development files not found. Activate the oneAPI environment (MKLROOT).'
}
& icx --version
if ($LASTEXITCODE -ne 0) { throw 'icx --version failed.' }
& cmake --version
if ($LASTEXITCODE -ne 0) { throw 'cmake --version failed.' }
if ($Aot) {
    if (-not (Get-Command ocloc -CommandType Application -ErrorAction SilentlyContinue)) {
        throw 'AOT requires ocloc. Start with JIT (omit -Aot).'
    }
    & ocloc ids $Aot
    if ($LASTEXITCODE -ne 0) { throw "ocloc does not accept target '$Aot'; use JIT." }
}
if (-not [IO.Path]::IsPathRooted($BuildDir)) { $BuildDir = Join-Path $repo $BuildDir }
$configure = @('-S', (Join-Path $repo 'sycl'), '-B', $BuildDir, '-G', 'Ninja',
    '-DCMAKE_C_COMPILER=icx', '-DCMAKE_CXX_COMPILER=icx', '-DCMAKE_BUILD_TYPE=Release',
    "-DSTRATA_SYCL_AOT=$Aot", "-DSTRATA_SYCL_PARITY=$($Parity.IsPresent.ToString().ToUpperInvariant())")
if ($GgmlDir) { $configure += "-DSTRATA_GGML_DIR=$((Resolve-Path $GgmlDir).Path)" }
if ($LevelZeroInclude) { $configure += "-DSTRATA_ZE_INCLUDE_DIR=$((Resolve-Path $LevelZeroInclude).Path)" }
if ($LevelZeroLibrary) { $configure += "-DSTRATA_ZE_LOADER=$((Resolve-Path $LevelZeroLibrary).Path)" }
& cmake @configure
if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed; inspect its compiler/link probe logs.' }
if (-not $ConfigureOnly) {
    $build = @('--build', $BuildDir, '--parallel', "$Jobs")
    if (-not $Parity) { $build += @('--target', 'strata', 'strata-sycl-diagnostic') }
    & cmake @build
    if ($LASTEXITCODE -ne 0) { throw 'SYCL build failed. No GPU tests were run.' }
}
Write-Host 'Completed. GPU validation is a separate step: docs/TEST_B70_WINDOWS.md.'
