param(
    [ValidateSet("all", "api")]
    [string]$Suite = "all"
)

$ErrorActionPreference = "Stop"

$testRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $testRoot
try {
    switch ($Suite) {
        "api" { node automated/api-tests.mjs }
        default { node automated/run-all.mjs }
    }
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        exit $exitCode
    }
}
finally {
    Pop-Location
}
