$ErrorActionPreference = 'Stop'
$certificatePath = Join-Path $PSScriptRoot 'certificate.crt'
$appInstallerPath = Join-Path $PSScriptRoot 'dnd_cuecard_app.appinstaller'

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
