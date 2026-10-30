[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [uri]$PagesBaseUrl,

    [string]$PagesWorktreePath = (Join-Path $env:TEMP 'dnd_cuecard_app-gh-pages')
)

$ErrorActionPreference = 'Stop'

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [Parameter(Mandatory = $true)]
        [string[]]$CommandArgs
    )

    & $Command @CommandArgs
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed with exit code $LASTEXITCODE."
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$gitRoot = & git -C $repoRoot rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0) {
    throw "Unable to locate the source Git repository: $repoRoot"
}
$gitRoot = ($gitRoot | Select-Object -First 1).Trim()
$releaseRoot = [System.IO.Path]::GetFullPath($PagesWorktreePath)

if ([string]::Equals($repoRoot.TrimEnd('\'), $releaseRoot.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'PagesWorktreePath must be separate from the source working tree.'
}

if ($PagesBaseUrl.Scheme -ne 'https' -or $PagesBaseUrl.Query -or $PagesBaseUrl.Fragment) {
    throw 'PagesBaseUrl must be an HTTPS URL without a query or fragment.'
}

$branch = & git -C $repoRoot branch --list gh-pages
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to check for the local gh-pages branch.'
}
if (-not $branch) {
    throw 'The local gh-pages branch is missing. Fetch it from origin before publishing.'
}

$worktreeRoot = $null
if (Test-Path -LiteralPath $releaseRoot) {
    $worktreeRoot = & git -C $releaseRoot rev-parse --show-toplevel
    if ($LASTEXITCODE -ne 0) {
        throw "PagesWorktreePath exists but is not a Git worktree: $releaseRoot"
    }
}

if (-not $worktreeRoot) {
    & git -C $repoRoot worktree add $releaseRoot gh-pages
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create a gh-pages worktree at $releaseRoot."
    }
}
else {
    $worktreeRoot = ($worktreeRoot | Select-Object -First 1).Trim()
    $normalizedWorktreeRoot = $worktreeRoot.Replace('/', '\').TrimEnd('\')
    $normalizedReleaseRoot = $releaseRoot.Replace('/', '\').TrimEnd('\')
    if (-not [string]::Equals($normalizedWorktreeRoot, $normalizedReleaseRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Git reports a different worktree root than PagesWorktreePath: $worktreeRoot"
    }

    $worktreeGitRoot = & git -C $releaseRoot rev-parse --git-common-dir
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to verify the Git repository for PagesWorktreePath: $releaseRoot"
    }
    $worktreeGitRoot = ($worktreeGitRoot | Select-Object -First 1).Trim()
    if (-not [System.IO.Path]::IsPathRooted($worktreeGitRoot)) {
        $worktreeGitRoot = [System.IO.Path]::GetFullPath((Join-Path $releaseRoot $worktreeGitRoot))
    }
    $worktreeGitRoot = (Resolve-Path $worktreeGitRoot).Path
    $sourceGitCommonDir = & git -C $repoRoot rev-parse --git-common-dir
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to verify the source Git repository: $repoRoot"
    }
    $sourceGitCommonDir = ($sourceGitCommonDir | Select-Object -First 1).Trim()
    if (-not [System.IO.Path]::IsPathRooted($sourceGitCommonDir)) {
        $sourceGitCommonDir = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $sourceGitCommonDir))
    }
    $sourceGitCommonDir = (Resolve-Path $sourceGitCommonDir).Path
    $normalizedWorktreeGitRoot = $worktreeGitRoot.Replace('/', '\').TrimEnd('\')
    $normalizedSourceGitCommonDir = $sourceGitCommonDir.Replace('/', '\').TrimEnd('\')
    if (-not [string]::Equals($normalizedWorktreeGitRoot, $normalizedSourceGitCommonDir, [StringComparison]::OrdinalIgnoreCase)) {
        throw "PagesWorktreePath belongs to a different Git repository: $releaseRoot"
    }

    $worktreeBranch = & git -C $releaseRoot branch --show-current
    if ($LASTEXITCODE -ne 0 -or $worktreeBranch.Trim() -ne 'gh-pages') {
        throw 'PagesWorktreePath must be checked out to the gh-pages branch.'
    }
}

$releaseStatus = @(& git -C $releaseRoot status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to check the release repository status.'
}
if ($releaseStatus.Count -gt 0) {
    throw 'The release repository must have a clean working tree before publishing.'
}

$pubspec = Get-Content (Join-Path $repoRoot 'pubspec.yaml') -Raw
$nameMatch = [regex]::Match($pubspec, '(?m)^name:\s*([A-Za-z0-9_]+)\s*$')
$identityMatch = [regex]::Match($pubspec, '(?m)^\s+identity_name:\s*([A-Za-z0-9.-]+)\s*$')
$versionMatch = [regex]::Match($pubspec, '(?m)^\s+msix_version:\s*["'']?([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)')
if (-not $nameMatch.Success -or -not $identityMatch.Success -or -not $versionMatch.Success) {
    throw 'Could not read the app name, MSIX identity, or four-part version from pubspec.yaml.'
}

$appName = $nameMatch.Groups[1].Value
$identityName = $identityMatch.Groups[1].Value
$version = $versionMatch.Groups[1].Value
$previousInstallerPath = Join-Path $releaseRoot "$appName.appinstaller"
if (Test-Path -LiteralPath $previousInstallerPath) {
    [xml]$previousInstaller = Get-Content -LiteralPath $previousInstallerPath -Raw
    $previousVersion = [version]$previousInstaller.DocumentElement.GetAttribute('Version')
    if ([version]$version -le $previousVersion) {
        throw "MSIX version $version must be higher than the published version $previousVersion. Bump msix_version in pubspec.yaml."
    }
}

$certificatePath = Join-Path $repoRoot 'certificates\CERTIFICATE.pfx'
$publicCertificatePath = Join-Path $repoRoot 'certificates\certificate.crt'
if (-not (Test-Path -LiteralPath $certificatePath -PathType Leaf)) {
    throw "Signing certificate not found: $certificatePath"
}
if (-not (Test-Path -LiteralPath $publicCertificatePath -PathType Leaf)) {
    throw "Public certificate not found: $publicCertificatePath"
}

$securePassword = Read-Host 'Enter the MSIX signing certificate password' -AsSecureString
if ($securePassword.Length -eq 0) {
    throw 'The certificate password cannot be empty.'
}
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try {
    $certificatePassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    $pfxCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $certificatePath,
        $certificatePassword,
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet
    )
    $publicCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $publicCertificatePath
    )
    if ($pfxCertificate.Thumbprint -ne $publicCertificate.Thumbprint) {
        throw 'certificate.crt does not match the signing certificate in CERTIFICATE.pfx.'
    }

    $publishArguments = @(
        'run',
        'msix:publish',
        "--certificate-password=$certificatePassword",
        "--publish-folder-path=$releaseRoot"
    )
    Push-Location $repoRoot
    try {
        Invoke-CheckedCommand -Command 'dart' -CommandArgs $publishArguments
    }
    finally {
        Pop-Location
    }
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    $certificatePassword = $null
    $securePassword.Dispose()
}

$installerPath = Join-Path $releaseRoot "$appName.appinstaller"
$versionedPackageName = "${appName}_${version}.msix"
$versionedPackagePath = Join-Path $releaseRoot "versions\$versionedPackageName"
if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    throw "MSIX publish did not create the app installer: $installerPath"
}
if (-not (Test-Path -LiteralPath $versionedPackagePath -PathType Leaf)) {
    throw "MSIX publish did not create the versioned package: $versionedPackagePath"
}

[xml]$installer = Get-Content -LiteralPath $installerPath -Raw
$mainPackage = $installer.SelectSingleNode("//*[local-name()='MainPackage']")
if ($null -eq $mainPackage) {
    throw 'Generated .appinstaller has no MainPackage element.'
}
if ($mainPackage.GetAttribute('Name') -ne $identityName) {
    throw 'The generated package identity does not match identity_name in pubspec.yaml.'
}
if ($mainPackage.GetAttribute('Publisher') -ne $pfxCertificate.Subject) {
    throw 'The generated package Publisher does not match the signing certificate subject.'
}
if ($mainPackage.GetAttribute('Version') -ne $version) {
    throw 'The generated package version does not match msix_version in pubspec.yaml.'
}

$baseUrl = $PagesBaseUrl.AbsoluteUri.TrimEnd('/')
$installerUrl = "$baseUrl/$([uri]::EscapeDataString("$appName.appinstaller"))"
$packageUrl = "$baseUrl/versions/$([uri]::EscapeDataString($versionedPackageName))"
$installer.DocumentElement.SetAttribute('Uri', $installerUrl)
$mainPackage.SetAttribute('Uri', $packageUrl)
$installer.Save($installerPath)

Copy-Item -LiteralPath $publicCertificatePath -Destination (Join-Path $releaseRoot 'certificate.crt') -Force
$setupScript = @'
$ErrorActionPreference = 'Stop'
$certificatePath = Join-Path $PSScriptRoot 'certificate.crt'
$appInstallerPath = Join-Path $PSScriptRoot '__APP_NAME__.appinstaller'

if (-not (Test-Path -LiteralPath $certificatePath -PathType Leaf)) {
    throw "Certificate not found: $certificatePath"
}
if (-not (Test-Path -LiteralPath $appInstallerPath -PathType Leaf)) {
    throw "App installer not found: $appInstallerPath"
}

$trustedPeople = 'Cert:\CurrentUser\TrustedPeople'
if (-not (Test-Path $trustedPeople)) {
    New-Item -Path $trustedPeople -Force | Out-Null
}
Import-Certificate -FilePath $certificatePath -CertStoreLocation $trustedPeople | Out-Null
Start-Process -FilePath $appInstallerPath
'@.Replace('__APP_NAME__', $appName)
Set-Content -LiteralPath (Join-Path $releaseRoot 'install.ps1') -Value $setupScript -Encoding UTF8

Write-Host "Release files prepared in $releaseRoot"
Write-Host "App Installer: $installerUrl"
Write-Host "MSIX package:  $packageUrl"
Write-Host 'Review the files, then commit and push the gh-pages worktree to deploy them with GitHub Pages.'
Write-Host "  git -C `"$releaseRoot`" add ."
Write-Host "  git -C `"$releaseRoot`" commit -m `"Release $version`""
Write-Host "  git -C `"$releaseRoot`" push origin gh-pages"
