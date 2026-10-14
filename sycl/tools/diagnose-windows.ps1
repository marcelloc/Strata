[CmdletBinding()]
param([string]$BuildDir = 'build-sycl-windows', [string]$OutputFile = 'sycl-diagnostic.json')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if (-not [IO.Path]::IsPathRooted($BuildDir)) { $BuildDir = Join-Path $repo $BuildDir }
# Deliberately exclude machine/user names, environment dumps, serial numbers,
# process lists, model paths and prompts. No driver installation or settings edits.
$report = [ordered]@{
    timestamp_utc = [DateTime]::UtcNow.ToString('o')
    os_version = [Environment]::OSVersion.VersionString
    process_x64 = [Environment]::Is64BitProcess
    commit = 'unavailable'
    dirty = $null
    tools = [ordered]@{}
    sycl_devices = @()
    diagnostic = @()
    diagnostic_exit = $null
}
if (Get-Command git -ErrorAction SilentlyContinue) {
    $report.commit = (& git -C $repo rev-parse HEAD) -join ''
    $report.dirty = [bool](& git -C $repo status --porcelain)
}
foreach ($tool in @('icx', 'cmake', 'ninja')) {
    if (Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue) {
        $version = & $tool --version
        $report.tools[$tool] = @($version)[0]
    } else { $report.tools[$tool] = 'not found' }
}
if (Get-Command sycl-ls -CommandType Application -ErrorAction SilentlyContinue) {
    $report.sycl_devices = @(& sycl-ls)
    $report.tools['sycl-ls_exit'] = $LASTEXITCODE
} else { $report.tools['sycl-ls'] = 'not found' }
$probe = Join-Path $BuildDir 'strata-sycl-diagnostic.exe'
if (Test-Path -LiteralPath $probe) {
    # Only stdout is saved. Driver exceptions on stderr may contain local paths.
    $report.diagnostic = @(& $probe)
    $report.diagnostic_exit = $LASTEXITCODE
} else { $report.diagnostic = @('Build strata-sycl-diagnostic first.') }
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputFile -Encoding UTF8
Write-Host "Diagnostic saved to $OutputFile. An absent GPU is expected before the B70 arrives."
if ($null -eq $report.diagnostic_exit -or $report.diagnostic_exit -ne 0) { exit 2 }
