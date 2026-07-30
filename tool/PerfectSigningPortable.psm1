Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:BackupFormat = "perfect-private-signing"
$script:BackupVersion = 1
$script:KdfIterations = 600000
$script:MaximumPackageBytes = 67108864
$script:MaximumIdentityFileBytes = 33554432
$script:Aad = [Text.Encoding]::UTF8.GetBytes(
  "Perfect! private signing backup|v1|PBKDF2-HMAC-SHA256|AES-256-GCM"
)
$script:RequiredFiles = @(
  "perfect-private.jks",
  "Perfect-private.pfx",
  "Perfect-private.cer",
  "perfect-private-android.cer",
  "signing-manifest.json"
)

if ($null -eq ("PerfectSigningRsaValidator" -as [type])) {
  Add-Type -TypeDefinition @"
using System;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

public static class PerfectSigningRsaValidator
{
    public static void AssertUsable(byte[] pkcs8, byte[] certificateBytes)
    {
        using RSA privateKey = RSA.Create();
        privateKey.ImportPkcs8PrivateKey(pkcs8, out int bytesRead);
        if (bytesRead != pkcs8.Length)
        {
            throw new CryptographicException(
                "The Android PKCS#8 key has trailing data."
            );
        }

#pragma warning disable SYSLIB0057
        using X509Certificate2 certificate = new(certificateBytes);
#pragma warning restore SYSLIB0057
        using RSA publicKey = certificate.GetRSAPublicKey()
            ?? throw new CryptographicException(
                "The Android certificate has no RSA public key."
            );

        RSAParameters privatePublic = privateKey.ExportParameters(false);
        RSAParameters certificatePublic = publicKey.ExportParameters(false);
        if (!CryptographicOperations.FixedTimeEquals(
                privatePublic.Modulus!,
                certificatePublic.Modulus!
            ) ||
            !CryptographicOperations.FixedTimeEquals(
                privatePublic.Exponent!,
                certificatePublic.Exponent!
            ))
        {
            throw new CryptographicException(
                "The Android private key does not match its certificate."
            );
        }

        byte[] probe = RandomNumberGenerator.GetBytes(32);
        byte[] signature = privateKey.SignData(
            probe,
            HashAlgorithmName.SHA256,
            RSASignaturePadding.Pkcs1
        );
        try
        {
            if (!publicKey.VerifyData(
                probe,
                signature,
                HashAlgorithmName.SHA256,
                RSASignaturePadding.Pkcs1
            ))
            {
                throw new CryptographicException(
                    "The Android private key failed its signing probe."
                );
            }
        }
        finally
        {
            CryptographicOperations.ZeroMemory(probe);
            CryptographicOperations.ZeroMemory(signature);
        }
    }
}
"@
}

function Assert-WindowsHost {
  if ($PSVersionTable.PSEdition -ne "Core" -or
      $PSVersionTable.PSVersion -lt [Version]"7.4") {
    throw "Perfect signing portability requires PowerShell 7.4 or newer."
  }
  if (-not $IsWindows) {
    throw "Perfect signing portability requires Windows DPAPI and NTFS ACLs."
  }
}

function Clear-Bytes([byte[]]$Bytes) {
  if ($null -ne $Bytes) {
    [Array]::Clear($Bytes, 0, $Bytes.Length)
  }
}

function ConvertFrom-RecoverySecureString(
  [Security.SecureString]$SecureValue
) {
  if ($null -eq $SecureValue) {
    throw "A recovery passphrase is required."
  }
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
  $characters = $null
  try {
    $length = [Runtime.InteropServices.Marshal]::ReadInt32($pointer, -4) / 2
    if ($length -lt 16) {
      throw "The recovery passphrase must contain at least 16 characters."
    }
    $characters = [char[]]::new($length)
    for ($index = 0; $index -lt $length; $index++) {
      $characters[$index] = [char][Runtime.InteropServices.Marshal]::ReadInt16(
        $pointer,
        $index * 2
      )
    }
    return [Text.Encoding]::UTF8.GetBytes($characters)
  } finally {
    if ($null -ne $characters) {
      [Array]::Clear($characters, 0, $characters.Length)
    }
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
  }
}

function ConvertFrom-DpapiSecret([string]$ProtectedValue) {
  $secureValue = ConvertTo-SecureString $ProtectedValue
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    $secureValue.Dispose()
  }
}

function Protect-WithCurrentUserDpapi([string]$PlainValue) {
  $secureValue = ConvertTo-SecureString $PlainValue -AsPlainText -Force
  try {
    return ConvertFrom-SecureString $secureValue
  } finally {
    $secureValue.Dispose()
  }
}

function Set-RestrictedAcl([string]$Path, [bool]$IsDirectory) {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
  $arguments = if ($IsDirectory) {
    @($Path, "/inheritance:r", "/grant:r", "${identity}:(OI)(CI)F")
  } else {
    @($Path, "/inheritance:r", "/grant:r", "${identity}:F")
  }
  & icacls @arguments | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to restrict access to $Path."
  }
}

function Get-Sha256Hex([byte[]]$Bytes) {
  $hash = [Security.Cryptography.SHA256]::HashData($Bytes)
  try {
    return [Convert]::ToHexString($hash)
  } finally {
    Clear-Bytes $hash
  }
}

function Test-FixedTimeHex([string]$Expected, [string]$Actual) {
  if ([string]::IsNullOrWhiteSpace($Expected) -or
      [string]::IsNullOrWhiteSpace($Actual)) {
    return $false
  }
  $left = $null
  $right = $null
  try {
    $left = [Convert]::FromHexString($Expected)
    $right = [Convert]::FromHexString($Actual)
    return [Security.Cryptography.CryptographicOperations]::FixedTimeEquals(
      $left,
      $right
    )
  } catch {
    return $false
  } finally {
    Clear-Bytes $left
    Clear-Bytes $right
  }
}

function Read-Int32BigEndian([IO.BinaryReader]$Reader) {
  $bytes = $Reader.ReadBytes(4)
  if ($bytes.Length -ne 4) {
    throw "The JKS is truncated."
  }
  if ([BitConverter]::IsLittleEndian) {
    [Array]::Reverse($bytes)
  }
  return [BitConverter]::ToInt32($bytes, 0)
}

function Read-UInt32BigEndian([IO.BinaryReader]$Reader) {
  $bytes = $Reader.ReadBytes(4)
  if ($bytes.Length -ne 4) {
    throw "The JKS is truncated."
  }
  if ([BitConverter]::IsLittleEndian) {
    [Array]::Reverse($bytes)
  }
  return [BitConverter]::ToUInt32($bytes, 0)
}

function Read-Int64BigEndian([IO.BinaryReader]$Reader) {
  $bytes = $Reader.ReadBytes(8)
  if ($bytes.Length -ne 8) {
    throw "The JKS is truncated."
  }
  if ([BitConverter]::IsLittleEndian) {
    [Array]::Reverse($bytes)
  }
  return [BitConverter]::ToInt64($bytes, 0)
}

function Read-JavaUtf([IO.BinaryReader]$Reader) {
  $lengthBytes = $Reader.ReadBytes(2)
  if ($lengthBytes.Length -ne 2) {
    throw "The JKS is truncated."
  }
  $length = ($lengthBytes[0] -shl 8) -bor $lengthBytes[1]
  $bytes = $Reader.ReadBytes($length)
  if ($bytes.Length -ne $length) {
    throw "The JKS is truncated."
  }
  return [Text.Encoding]::UTF8.GetString($bytes)
}

function Assert-RsaPrivateKeyMatchesCertificate(
  [byte[]]$Pkcs8Bytes,
  [byte[]]$CertificateBytes
) {
  try {
    [PerfectSigningRsaValidator]::AssertUsable(
      $Pkcs8Bytes,
      $CertificateBytes
    )
  } catch [Security.Cryptography.CryptographicException] {
    throw "The Android private key is malformed, mismatched, or unusable."
  }
}

function New-RestoreDestinationStream([string]$Path) {
  return [IO.File]::Open(
    $Path,
    [IO.FileMode]::CreateNew,
    [IO.FileAccess]::Write,
    [IO.FileShare]::None
  )
}

function Unprotect-JksPrivateKey(
  [byte[]]$ProtectedKeyInfo,
  [string]$KeyPassword,
  [byte[]]$CertificateBytes
) {
  $asnReader = [System.Formats.Asn1.AsnReader]::new(
    [ReadOnlyMemory[byte]]::new($ProtectedKeyInfo),
    [System.Formats.Asn1.AsnEncodingRules]::DER
  )
  $encryptedPrivateKeyInfo = $asnReader.ReadSequence()
  $algorithm = $encryptedPrivateKeyInfo.ReadSequence()
  $algorithmOid = $algorithm.ReadObjectIdentifier()
  while ($algorithm.HasData) {
    $null = $algorithm.ReadEncodedValue()
  }
  if ($algorithmOid -cne "1.3.6.1.4.1.42.2.17.1.1") {
    throw "The Android JKS uses an unsupported key-protection algorithm."
  }
  $encrypted = $encryptedPrivateKeyInfo.ReadOctetString()
  $encryptedPrivateKeyInfo.ThrowIfNotEmpty()
  $asnReader.ThrowIfNotEmpty()
  if ($encrypted.Length -le 40) {
    throw "The Android JKS private-key envelope is invalid."
  }

  $passwordBytes = [Text.Encoding]::BigEndianUnicode.GetBytes($KeyPassword)
  $salt = [byte[]]::new(20)
  [Buffer]::BlockCopy($encrypted, 0, $salt, 0, 20)
  $privateKeyLength = $encrypted.Length - 40
  $plaintextKey = [byte[]]::new($privateKeyLength)
  $digestSeed = $salt
  $digest = $null
  $digestInput = $null
  $checksumInput = $null
  $computedChecksum = $null
  $storedChecksum = [byte[]]::new(20)
  try {
    for ($offset = 0; $offset -lt $privateKeyLength; $offset += 20) {
      $digestInput = [byte[]]::new(
        $passwordBytes.Length + $digestSeed.Length
      )
      [Buffer]::BlockCopy(
        $passwordBytes,
        0,
        $digestInput,
        0,
        $passwordBytes.Length
      )
      [Buffer]::BlockCopy(
        $digestSeed,
        0,
        $digestInput,
        $passwordBytes.Length,
        $digestSeed.Length
      )
      $digest = [Security.Cryptography.SHA1]::HashData($digestInput)
      $chunkLength = [Math]::Min(20, $privateKeyLength - $offset)
      for ($chunkOffset = 0; $chunkOffset -lt $chunkLength; $chunkOffset++) {
        $plaintextKey[$offset + $chunkOffset] =
          $encrypted[20 + $offset + $chunkOffset] -bxor $digest[$chunkOffset]
      }
      if (-not [Object]::ReferenceEquals($digestSeed, $salt)) {
        Clear-Bytes $digestSeed
      }
      $digestSeed = $digest
      $digest = $null
      Clear-Bytes $digestInput
      $digestInput = $null
    }

    $checksumInput = [byte[]]::new(
      $passwordBytes.Length + $plaintextKey.Length
    )
    [Buffer]::BlockCopy(
      $passwordBytes,
      0,
      $checksumInput,
      0,
      $passwordBytes.Length
    )
    [Buffer]::BlockCopy(
      $plaintextKey,
      0,
      $checksumInput,
      $passwordBytes.Length,
      $plaintextKey.Length
    )
    $computedChecksum = [Security.Cryptography.SHA1]::HashData($checksumInput)
    [Buffer]::BlockCopy(
      $encrypted,
      20 + $privateKeyLength,
      $storedChecksum,
      0,
      20
    )
    if (-not [Security.Cryptography.CryptographicOperations]::FixedTimeEquals(
      $computedChecksum,
      $storedChecksum
    )) {
      throw "The Android private-key password is invalid."
    }
    Assert-RsaPrivateKeyMatchesCertificate $plaintextKey $CertificateBytes
  } finally {
    Clear-Bytes $passwordBytes
    Clear-Bytes $salt
    if ($null -ne $digestSeed -and
        -not [Object]::ReferenceEquals($digestSeed, $salt)) {
      Clear-Bytes $digestSeed
    }
    Clear-Bytes $digest
    Clear-Bytes $digestInput
    Clear-Bytes $checksumInput
    Clear-Bytes $computedChecksum
    Clear-Bytes $storedChecksum
    Clear-Bytes $plaintextKey
    Clear-Bytes $encrypted
  }
}

function Get-JksIdentity(
  [byte[]]$JksBytes,
  [string]$StorePassword,
  [string]$KeyPassword,
  [string]$ExpectedAlias
) {
  if ($JksBytes.Length -lt 32) {
    throw "The Android JKS is too small."
  }

  $contentLength = $JksBytes.Length - 20
  $passwordBytes = [Text.Encoding]::BigEndianUnicode.GetBytes($StorePassword)
  $phraseBytes = [Text.Encoding]::ASCII.GetBytes("Mighty Aphrodite")
  $digestInput = [byte[]]::new(
    $passwordBytes.Length + $phraseBytes.Length + $contentLength
  )
  $computedDigest = $null
  $storedDigest = $null
  try {
    [Buffer]::BlockCopy(
      $passwordBytes,
      0,
      $digestInput,
      0,
      $passwordBytes.Length
    )
    [Buffer]::BlockCopy(
      $phraseBytes,
      0,
      $digestInput,
      $passwordBytes.Length,
      $phraseBytes.Length
    )
    [Buffer]::BlockCopy(
      $JksBytes,
      0,
      $digestInput,
      $passwordBytes.Length + $phraseBytes.Length,
      $contentLength
    )
    $computedDigest = [Security.Cryptography.SHA1]::HashData($digestInput)
    $storedDigest = [byte[]]::new(20)
    [Buffer]::BlockCopy($JksBytes, $contentLength, $storedDigest, 0, 20)
    if (-not [Security.Cryptography.CryptographicOperations]::FixedTimeEquals(
      $computedDigest,
      $storedDigest
    )) {
      throw "The Android JKS password or integrity digest is invalid."
    }
  } finally {
    Clear-Bytes $passwordBytes
    Clear-Bytes $phraseBytes
    Clear-Bytes $digestInput
    Clear-Bytes $computedDigest
    if ($null -ne $storedDigest) {
      Clear-Bytes $storedDigest
    }
  }

  $stream = [IO.MemoryStream]::new($JksBytes, 0, $contentLength, $false)
  $reader = [IO.BinaryReader]::new($stream)
  $matchedCertificate = $null
  $matchedProtectedKey = $null
  try {
    $magic = Read-UInt32BigEndian $reader
    if ($magic -ne [Convert]::ToUInt32("FEEDFEED", 16)) {
      throw "The Android signing file is not a JKS."
    }
    $version = Read-Int32BigEndian $reader
    if ($version -notin @(1, 2)) {
      throw "Unsupported JKS version $version."
    }
    $entryCount = Read-Int32BigEndian $reader
    if ($entryCount -lt 1 -or $entryCount -gt 128) {
      throw "The Android JKS entry count is invalid."
    }

    for ($entryIndex = 0; $entryIndex -lt $entryCount; $entryIndex++) {
      $tag = Read-Int32BigEndian $reader
      $alias = Read-JavaUtf $reader
      $null = Read-Int64BigEndian $reader
      if ($tag -eq 1) {
        $keyLength = Read-Int32BigEndian $reader
        if ($keyLength -lt 1) {
          throw "The Android JKS private-key entry is invalid."
        }
        $keyBytes = $reader.ReadBytes($keyLength)
        if ($keyBytes.Length -ne $keyLength) {
          throw "The Android JKS private-key entry is truncated."
        }
        $chainCount = Read-Int32BigEndian $reader
        if ($alias -ceq $ExpectedAlias -and $chainCount -lt 1) {
          Clear-Bytes $keyBytes
          throw "The pinned Android private-key entry has no certificate."
        }
        for ($chainIndex = 0; $chainIndex -lt $chainCount; $chainIndex++) {
          if ($version -eq 2) {
            $null = Read-JavaUtf $reader
          }
          $certificateLength = Read-Int32BigEndian $reader
          $certificateBytes = $reader.ReadBytes($certificateLength)
          if ($certificateBytes.Length -ne $certificateLength) {
            throw "The Android JKS certificate is truncated."
          }
          if ($alias -ceq $ExpectedAlias -and $chainIndex -eq 0) {
            $matchedCertificate = $certificateBytes
          }
        }
        if ($alias -ceq $ExpectedAlias) {
          $matchedProtectedKey = $keyBytes
        } else {
          Clear-Bytes $keyBytes
        }
      } elseif ($tag -eq 2) {
        if ($version -eq 2) {
          $null = Read-JavaUtf $reader
        }
        $certificateLength = Read-Int32BigEndian $reader
        $certificateBytes = $reader.ReadBytes($certificateLength)
        if ($certificateBytes.Length -ne $certificateLength) {
          throw "The Android JKS certificate is truncated."
        }
        Clear-Bytes $certificateBytes
      } else {
        throw "The Android JKS contains an unsupported entry."
      }
    }
    if ($null -eq $matchedCertificate -or $null -eq $matchedProtectedKey) {
      throw "The pinned Android alias is not a private-key entry in the JKS."
    }
    Unprotect-JksPrivateKey `
      $matchedProtectedKey `
      $KeyPassword `
      $matchedCertificate
    return @{
      alias = $ExpectedAlias
      certificate_sha256 = Get-Sha256Hex $matchedCertificate
    }
  } finally {
    Clear-Bytes $matchedProtectedKey
    $reader.Dispose()
    $stream.Dispose()
  }
}

function Get-PfxIdentity([byte[]]$PfxBytes, [string]$Password) {
  $collection =
    [Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()
  $flags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::
    EphemeralKeySet
  try {
    $collection.Import($PfxBytes, $Password, $flags)
    $certificate = @($collection | Where-Object { $_.HasPrivateKey })[0]
    if ($null -eq $certificate) {
      throw "The Windows PFX does not contain a private key."
    }
    return @{
      subject = $certificate.Subject
      thumbprint = $certificate.Thumbprint.ToUpperInvariant()
      raw_certificate_sha256 = Get-Sha256Hex $certificate.RawData
    }
  } finally {
    foreach ($certificateToDispose in $collection) {
      $certificateToDispose.Dispose()
    }
  }
}

function Get-SigningPayloadFromRoot([string]$SigningRoot) {
  $resolvedRoot = (Resolve-Path -LiteralPath $SigningRoot).Path
  $protectedPath = Join-Path $resolvedRoot "protected-secrets.json"
  if (-not (Test-Path -LiteralPath $protectedPath -PathType Leaf)) {
    throw "The signing root has no protected-secrets.json."
  }
  foreach ($fileName in $script:RequiredFiles) {
    $filePath = Join-Path $resolvedRoot $fileName
    if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
      throw "The signing root is missing $fileName."
    }
    if ((Get-Item -LiteralPath $filePath).Length -gt
        $script:MaximumIdentityFileBytes) {
      throw "The signing identity file $fileName exceeds the safe size limit."
    }
  }

  $protected = Get-Content -Raw -LiteralPath $protectedPath |
    ConvertFrom-Json
  $manifestPath = Join-Path $resolvedRoot "signing-manifest.json"
  $manifest = Get-Content -Raw -LiteralPath $manifestPath |
    ConvertFrom-Json
  $storePassword = ConvertFrom-DpapiSecret $protected.android_store_password
  $keyPassword = ConvertFrom-DpapiSecret $protected.android_key_password
  $pfxPassword = ConvertFrom-DpapiSecret $protected.windows_pfx_password
  $fileBytesByName = $null
  try {
    if ($protected.android_alias -cne $manifest.android_alias) {
      throw "The protected Android alias does not match the signing manifest."
    }
    $files = @()
    $fileBytesByName = @{}
    foreach ($fileName in $script:RequiredFiles) {
      $bytes = [IO.File]::ReadAllBytes((Join-Path $resolvedRoot $fileName))
      $fileBytesByName[$fileName] = $bytes
      $files += @{
        name = $fileName
        sha256 = Get-Sha256Hex $bytes
        content = [Convert]::ToBase64String($bytes)
      }
    }

    $androidKeystoreHash = Get-Sha256Hex `
      $fileBytesByName["perfect-private.jks"]
    if (-not (Test-FixedTimeHex `
      $manifest.android_keystore_sha256 `
      $androidKeystoreHash)) {
      throw "The Android JKS hash does not match the signing manifest."
    }
    $windowsPfxHash = Get-Sha256Hex $fileBytesByName["Perfect-private.pfx"]
    if (-not (Test-FixedTimeHex `
      $manifest.windows_pfx_sha256 `
      $windowsPfxHash)) {
      throw "The Windows PFX hash does not match the signing manifest."
    }

    $jksIdentity = Get-JksIdentity `
      $fileBytesByName["perfect-private.jks"] `
      $storePassword `
      $keyPassword `
      $manifest.android_alias
    $androidCertificateHash = Get-Sha256Hex `
      $fileBytesByName["perfect-private-android.cer"]
    if (-not (Test-FixedTimeHex `
      $manifest.android_certificate_sha256 `
      $androidCertificateHash) -or
      -not (Test-FixedTimeHex `
        $jksIdentity.certificate_sha256 `
        $androidCertificateHash)) {
      throw "The Android certificate fingerprint is not pinned consistently."
    }

    $pfxIdentity = Get-PfxIdentity `
      $fileBytesByName["Perfect-private.pfx"] `
      $pfxPassword
    $publicWindowsCertificate =
      [Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $fileBytesByName["Perfect-private.cer"]
      )
    try {
      if ($pfxIdentity.thumbprint -cne
        $publicWindowsCertificate.Thumbprint.ToUpperInvariant() -or
        $pfxIdentity.thumbprint -cne
        ([string]$manifest.windows_certificate_thumbprint).ToUpperInvariant() -or
        $pfxIdentity.subject -cne $manifest.windows_certificate_subject) {
        throw "The Windows certificate identity does not match the manifest."
      }
    } finally {
      $publicWindowsCertificate.Dispose()
    }

    return @{
      format = $script:BackupFormat
      version = $script:BackupVersion
      created_at = (Get-Date).ToUniversalTime().ToString("o")
      identity = @{
        android_alias = $manifest.android_alias
        android_certificate_sha256 =
          ([string]$manifest.android_certificate_sha256).ToUpperInvariant()
        android_keystore_sha256 =
          ([string]$manifest.android_keystore_sha256).ToUpperInvariant()
        windows_certificate_subject = $manifest.windows_certificate_subject
        windows_certificate_thumbprint =
          ([string]$manifest.windows_certificate_thumbprint).ToUpperInvariant()
        windows_pfx_sha256 =
          ([string]$manifest.windows_pfx_sha256).ToUpperInvariant()
      }
      files = $files
      secrets = @{
        android_alias = $protected.android_alias
        android_store_password = $storePassword
        android_key_password = $keyPassword
        windows_pfx_password = $pfxPassword
      }
    }
  } finally {
    $storePassword = $null
    $keyPassword = $null
    $pfxPassword = $null
    if ($null -ne $fileBytesByName) {
      foreach ($bytesToClear in $fileBytesByName.Values) {
        Clear-Bytes $bytesToClear
      }
    }
  }
}

function ConvertTo-ValidatedSigningPayload([byte[]]$Plaintext) {
  $payloadJson = [Text.Encoding]::UTF8.GetString($Plaintext)
  $payload = $payloadJson | ConvertFrom-Json
  if ($payload.format -cne $script:BackupFormat -or
      [int]$payload.version -ne $script:BackupVersion) {
    throw "The decrypted signing payload has an unsupported format."
  }

  $fileBytesByName = @{}
  foreach ($file in $payload.files) {
    $name = [string]$file.name
    if ($name -notin $script:RequiredFiles -or
        $fileBytesByName.ContainsKey($name)) {
      throw "The signing payload contains an unexpected or duplicate file."
    }
    $bytes = [Convert]::FromBase64String([string]$file.content)
    if (-not (Test-FixedTimeHex ([string]$file.sha256) (Get-Sha256Hex $bytes))) {
      Clear-Bytes $bytes
      throw "A signing payload file failed its embedded hash."
    }
    $fileBytesByName[$name] = $bytes
  }
  foreach ($requiredFile in $script:RequiredFiles) {
    if (-not $fileBytesByName.ContainsKey($requiredFile)) {
      throw "The signing payload is missing $requiredFile."
    }
  }

  $manifestJson = [Text.Encoding]::UTF8.GetString(
    $fileBytesByName["signing-manifest.json"]
  )
  $manifest = $manifestJson | ConvertFrom-Json
  $identity = $payload.identity
  if ($payload.secrets.android_alias -cne $identity.android_alias -or
      $manifest.android_alias -cne $identity.android_alias) {
    throw "The Android alias is not pinned consistently."
  }
  if (-not (Test-FixedTimeHex `
      $identity.android_keystore_sha256 `
      (Get-Sha256Hex $fileBytesByName["perfect-private.jks"])) -or
      -not (Test-FixedTimeHex `
        $manifest.android_keystore_sha256 `
        $identity.android_keystore_sha256)) {
    throw "The Android JKS identity hash is inconsistent."
  }
  if (-not (Test-FixedTimeHex `
      $identity.windows_pfx_sha256 `
      (Get-Sha256Hex $fileBytesByName["Perfect-private.pfx"])) -or
      -not (Test-FixedTimeHex `
        $manifest.windows_pfx_sha256 `
        $identity.windows_pfx_sha256)) {
    throw "The Windows PFX identity hash is inconsistent."
  }

  $jksIdentity = Get-JksIdentity `
    $fileBytesByName["perfect-private.jks"] `
    $payload.secrets.android_store_password `
    $payload.secrets.android_key_password `
    $identity.android_alias
  $androidCertificateHash = Get-Sha256Hex `
    $fileBytesByName["perfect-private-android.cer"]
  if (-not (Test-FixedTimeHex `
      $jksIdentity.certificate_sha256 `
      $androidCertificateHash) -or
      -not (Test-FixedTimeHex `
        $identity.android_certificate_sha256 `
        $androidCertificateHash) -or
      -not (Test-FixedTimeHex `
        $manifest.android_certificate_sha256 `
        $androidCertificateHash)) {
    throw "The Android signing certificate fingerprint is inconsistent."
  }

  $pfxIdentity = Get-PfxIdentity `
    $fileBytesByName["Perfect-private.pfx"] `
    $payload.secrets.windows_pfx_password
  $publicWindowsCertificate =
    [Security.Cryptography.X509Certificates.X509Certificate2]::new(
      $fileBytesByName["Perfect-private.cer"]
    )
  try {
    $publicThumbprint =
      $publicWindowsCertificate.Thumbprint.ToUpperInvariant()
    if ($pfxIdentity.thumbprint -cne $publicThumbprint -or
        $pfxIdentity.thumbprint -cne
        ([string]$identity.windows_certificate_thumbprint).ToUpperInvariant() -or
        $pfxIdentity.thumbprint -cne
        ([string]$manifest.windows_certificate_thumbprint).ToUpperInvariant() -or
        $pfxIdentity.subject -cne $identity.windows_certificate_subject -or
        $pfxIdentity.subject -cne $manifest.windows_certificate_subject) {
      throw "The Windows signing certificate identity is inconsistent."
    }
  } finally {
    $publicWindowsCertificate.Dispose()
  }

  return @{
    payload = $payload
    files = $fileBytesByName
  }
}

function Backup-PerfectSigningIdentity {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$SigningRoot,
    [Parameter(Mandatory)]
    [string]$OutputPath,
    [Parameter(Mandatory)]
    [Security.SecureString]$Passphrase
  )

  Assert-WindowsHost
  if (Test-Path -LiteralPath $OutputPath) {
    throw "The backup destination already exists; overwrite is not allowed."
  }
  $parent = Split-Path -Parent $OutputPath
  if ([string]::IsNullOrWhiteSpace($parent)) {
    $parent = (Get-Location).Path
  }
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    throw "The backup destination directory does not exist."
  }

  $passphraseBytes = ConvertFrom-RecoverySecureString $Passphrase
  $payload = $null
  $plaintext = $null
  $salt = [byte[]]::new(32)
  $nonce = [byte[]]::new(12)
  $key = [byte[]]::new(32)
  $ciphertext = $null
  $tag = [byte[]]::new(16)
  $partialPath = "$OutputPath.partial.$([Guid]::NewGuid().ToString('N'))"
  try {
    $payload = Get-SigningPayloadFromRoot $SigningRoot
    $plaintext = [Text.Encoding]::UTF8.GetBytes(
      ($payload | ConvertTo-Json -Depth 8 -Compress)
    )
    [Security.Cryptography.RandomNumberGenerator]::Fill($salt)
    [Security.Cryptography.RandomNumberGenerator]::Fill($nonce)
    $derivedKey = $null
    $deriver = [Security.Cryptography.Rfc2898DeriveBytes]::new(
      $passphraseBytes,
      $salt,
      $script:KdfIterations,
      [Security.Cryptography.HashAlgorithmName]::SHA256
    )
    try {
      $derivedKey = $deriver.GetBytes(32)
      [Buffer]::BlockCopy($derivedKey, 0, $key, 0, 32)
    } finally {
      Clear-Bytes $derivedKey
      $deriver.Dispose()
    }
    $ciphertext = [byte[]]::new($plaintext.Length)
    $aes = [Security.Cryptography.AesGcm]::new($key, 16)
    try {
      $aes.Encrypt($nonce, $plaintext, $ciphertext, $tag, $script:Aad)
    } finally {
      $aes.Dispose()
    }

    $envelope = @{
      format = $script:BackupFormat
      version = $script:BackupVersion
      kdf = @{
        name = "PBKDF2-HMAC-SHA256"
        iterations = $script:KdfIterations
        salt = [Convert]::ToBase64String($salt)
      }
      cipher = @{
        name = "AES-256-GCM"
        nonce = [Convert]::ToBase64String($nonce)
        tag = [Convert]::ToBase64String($tag)
      }
      ciphertext = [Convert]::ToBase64String($ciphertext)
    } | ConvertTo-Json -Depth 5 -Compress

    $stream = [IO.File]::Open(
      $partialPath,
      [IO.FileMode]::CreateNew,
      [IO.FileAccess]::Write,
      [IO.FileShare]::None
    )
    try {
      $writer = [IO.StreamWriter]::new(
        $stream,
        [Text.UTF8Encoding]::new($false)
      )
      try {
        $writer.Write($envelope)
        $writer.Flush()
        $stream.Flush($true)
      } finally {
        $writer.Dispose()
      }
    } finally {
      $stream.Dispose()
    }
    Set-RestrictedAcl $partialPath $false
    [IO.File]::Move($partialPath, $OutputPath)
    return [pscustomobject]@{
      Format = $script:BackupFormat
      Version = $script:BackupVersion
      Path = [IO.Path]::GetFullPath($OutputPath)
      Sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $OutputPath).Hash
    }
  } finally {
    Clear-Bytes $passphraseBytes
    Clear-Bytes $plaintext
    Clear-Bytes $salt
    Clear-Bytes $nonce
    Clear-Bytes $key
    Clear-Bytes $ciphertext
    Clear-Bytes $tag
    $payload = $null
    if (Test-Path -LiteralPath $partialPath) {
      Remove-Item -LiteralPath $partialPath -Force
    }
  }
}

function Restore-PerfectSigningIdentity {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$PackagePath,
    [Parameter(Mandatory)]
    [string]$SigningRoot,
    [Parameter(Mandatory)]
    [Security.SecureString]$Passphrase,
    [switch]$AllowExistingEmptyTarget
  )

  Assert-WindowsHost
  $resolvedPackage = (Resolve-Path -LiteralPath $PackagePath).Path
  if ((Get-Item -LiteralPath $resolvedPackage).Length -gt
      $script:MaximumPackageBytes) {
    throw "The signing backup exceeds the safe size limit."
  }
  $targetExists = Test-Path -LiteralPath $SigningRoot
  if ($targetExists) {
    if (-not $AllowExistingEmptyTarget) {
      throw "The signing target already exists. Use a new path."
    }
    if (-not (Test-Path -LiteralPath $SigningRoot -PathType Container) -or
        @(Get-ChildItem -Force -LiteralPath $SigningRoot).Count -ne 0) {
      throw "The signing target must be an explicitly allowed empty directory."
    }
  }

  $envelope = Get-Content -Raw -LiteralPath $resolvedPackage |
    ConvertFrom-Json
  if ($envelope.format -cne $script:BackupFormat -or
      [int]$envelope.version -ne $script:BackupVersion -or
      $envelope.kdf.name -cne "PBKDF2-HMAC-SHA256" -or
      $envelope.cipher.name -cne "AES-256-GCM") {
    throw "The backup envelope is unsupported."
  }
  $iterations = [int]$envelope.kdf.iterations
  if ($iterations -lt $script:KdfIterations -or $iterations -gt 5000000) {
    throw "The backup KDF work factor is outside the accepted range."
  }

  $passphraseBytes = ConvertFrom-RecoverySecureString $Passphrase
  $salt = [Convert]::FromBase64String([string]$envelope.kdf.salt)
  $nonce = [Convert]::FromBase64String([string]$envelope.cipher.nonce)
  $tag = [Convert]::FromBase64String([string]$envelope.cipher.tag)
  $ciphertext = [Convert]::FromBase64String([string]$envelope.ciphertext)
  if ($salt.Length -ne 32 -or $nonce.Length -ne 12 -or $tag.Length -ne 16) {
    throw "The backup envelope cryptographic parameters are invalid."
  }
  $key = [byte[]]::new(32)
  $plaintext = [byte[]]::new($ciphertext.Length)
  $validated = $null
  $createdTarget = $false
  $createdFiles = [Collections.Generic.List[string]]::new()
  $originalTargetSddl = if ($targetExists) {
    (Get-Acl -LiteralPath $SigningRoot).GetSecurityDescriptorSddlForm(
      [Security.AccessControl.AccessControlSections]::Access
    )
  } else {
    $null
  }
  try {
    $derivedKey = $null
    $deriver = [Security.Cryptography.Rfc2898DeriveBytes]::new(
      $passphraseBytes,
      $salt,
      $iterations,
      [Security.Cryptography.HashAlgorithmName]::SHA256
    )
    try {
      $derivedKey = $deriver.GetBytes(32)
      [Buffer]::BlockCopy($derivedKey, 0, $key, 0, 32)
    } finally {
      Clear-Bytes $derivedKey
      $deriver.Dispose()
    }
    $aes = [Security.Cryptography.AesGcm]::new($key, 16)
    try {
      $aes.Decrypt($nonce, $ciphertext, $tag, $plaintext, $script:Aad)
    } catch [Security.Cryptography.AuthenticationTagMismatchException] {
      throw "The recovery passphrase is wrong or the backup was modified."
    } finally {
      $aes.Dispose()
    }
    $validated = ConvertTo-ValidatedSigningPayload $plaintext

    if (-not $targetExists) {
      $null = [IO.Directory]::CreateDirectory($SigningRoot)
      $createdTarget = $true
    }
    Set-RestrictedAcl $SigningRoot $true
    foreach ($fileName in $script:RequiredFiles) {
      $destination = Join-Path $SigningRoot $fileName
      $stream = New-RestoreDestinationStream $destination
      $createdFiles.Add($destination)
      try {
        $bytes = $validated.files[$fileName]
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
      } finally {
        $stream.Dispose()
      }
    }

    $protectedSecrets = @{
      version = 1
      android_alias = $validated.payload.secrets.android_alias
      android_store_password = Protect-WithCurrentUserDpapi `
        $validated.payload.secrets.android_store_password
      android_key_password = Protect-WithCurrentUserDpapi `
        $validated.payload.secrets.android_key_password
      windows_pfx_password = Protect-WithCurrentUserDpapi `
        $validated.payload.secrets.windows_pfx_password
    } | ConvertTo-Json
    $protectedPath = Join-Path $SigningRoot "protected-secrets.json"
    $protectedStream = New-RestoreDestinationStream $protectedPath
    $createdFiles.Add($protectedPath)
    try {
      $protectedWriter = [IO.StreamWriter]::new(
        $protectedStream,
        [Text.UTF8Encoding]::new($false)
      )
      try {
        $protectedWriter.Write($protectedSecrets)
        $protectedWriter.Flush()
        $protectedStream.Flush($true)
      } finally {
        $protectedWriter.Dispose()
      }
    } finally {
      $protectedStream.Dispose()
    }
    Set-RestrictedAcl $SigningRoot $true
    return [pscustomobject]@{
      Format = $script:BackupFormat
      Version = $script:BackupVersion
      SigningRoot = [IO.Path]::GetFullPath($SigningRoot)
      AndroidAlias = $validated.payload.identity.android_alias
      AndroidCertificateSha256 =
        $validated.payload.identity.android_certificate_sha256
      WindowsCertificateThumbprint =
        $validated.payload.identity.windows_certificate_thumbprint
    }
  } catch {
    foreach ($createdFile in $createdFiles) {
      if (Test-Path -LiteralPath $createdFile -PathType Leaf) {
        Remove-Item -LiteralPath $createdFile -Force
      }
    }
    if ($createdTarget -and
        (Test-Path -LiteralPath $SigningRoot -PathType Container) -and
        @(Get-ChildItem -Force -LiteralPath $SigningRoot).Count -eq 0) {
      Remove-Item -LiteralPath $SigningRoot -Force
    } elseif ($targetExists -and
        (Test-Path -LiteralPath $SigningRoot -PathType Container) -and
        $null -ne $originalTargetSddl) {
      $originalAcl =
        [Security.AccessControl.DirectorySecurity]::new()
      $originalAcl.SetSecurityDescriptorSddlForm(
        $originalTargetSddl,
        [Security.AccessControl.AccessControlSections]::Access
      )
      [IO.FileSystemAclExtensions]::SetAccessControl(
        [IO.DirectoryInfo]::new($SigningRoot),
        $originalAcl
      )
    }
    throw
  } finally {
    Clear-Bytes $passphraseBytes
    Clear-Bytes $salt
    Clear-Bytes $nonce
    Clear-Bytes $tag
    Clear-Bytes $ciphertext
    Clear-Bytes $key
    Clear-Bytes $plaintext
    if ($null -ne $validated) {
      foreach ($bytesToClear in $validated.files.Values) {
        Clear-Bytes $bytesToClear
      }
    }
  }
}

Export-ModuleMember -Function @(
  "Backup-PerfectSigningIdentity",
  "Restore-PerfectSigningIdentity"
)
