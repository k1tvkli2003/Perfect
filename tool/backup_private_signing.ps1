[CmdletBinding()]
param(
  [string]$SigningRoot = (Join-Path $env:USERPROFILE ".perfect-signing"),
  [Parameter(Mandatory)]
  [string]$OutputPath
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Import-Module (
  Join-Path $PSScriptRoot "PerfectSigningPortable.psm1"
) -Force

function Test-SecureStringEqual(
  [Security.SecureString]$Left,
  [Security.SecureString]$Right
) {
  if ($Left.Length -ne $Right.Length) {
    return $false
  }
  $leftPointer =
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Left)
  $rightPointer =
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Right)
  try {
    $difference = 0
    for ($index = 0; $index -lt $Left.Length; $index++) {
      $difference = $difference -bor (
        [Runtime.InteropServices.Marshal]::ReadInt16(
          $leftPointer,
          $index * 2
        ) -bxor
        [Runtime.InteropServices.Marshal]::ReadInt16(
          $rightPointer,
          $index * 2
        )
      )
    }
    return $difference -eq 0
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($leftPointer)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($rightPointer)
  }
}

$passphrase = Read-Host `
  "Recovery passphrase (at least 16 characters)" `
  -AsSecureString
$confirmation = Read-Host "Confirm recovery passphrase" -AsSecureString
try {
  if (-not (Test-SecureStringEqual $passphrase $confirmation)) {
    throw "Recovery passphrases do not match."
  }
  Backup-PerfectSigningIdentity `
    -SigningRoot $SigningRoot `
    -OutputPath $OutputPath `
    -Passphrase $passphrase
} finally {
  $passphrase.Dispose()
  $confirmation.Dispose()
}
