[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$PackagePath,
  [string]$SigningRoot = (Join-Path $env:USERPROFILE ".perfect-signing"),
  [switch]$AllowExistingEmptyTarget
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Import-Module (
  Join-Path $PSScriptRoot "PerfectSigningPortable.psm1"
) -Force

$passphrase = Read-Host "Recovery passphrase" -AsSecureString
try {
  Restore-PerfectSigningIdentity `
    -PackagePath $PackagePath `
    -SigningRoot $SigningRoot `
    -Passphrase $passphrase `
    -AllowExistingEmptyTarget:$AllowExistingEmptyTarget
} finally {
  $passphrase.Dispose()
}
