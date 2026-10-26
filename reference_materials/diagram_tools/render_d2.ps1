param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$d2 = Join-Path $repoRoot ".tools\d2\d2-v0.9.0\bin\d2.exe"

if (-not (Test-Path -LiteralPath $d2)) {
    throw "D2 not found at $d2. See reference_materials/diagram_tools/README.md."
}

$input = (Resolve-Path -LiteralPath $InputPath).Path
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $output = [System.IO.Path]::ChangeExtension($input, ".svg")
} else {
    $output = [System.IO.Path]::GetFullPath($OutputPath)
}

& $d2 --layout=elk --scale=1 $input $output
if ($LASTEXITCODE -ne 0) {
    throw "D2 rendering failed with exit code $LASTEXITCODE."
}

Write-Output $output
