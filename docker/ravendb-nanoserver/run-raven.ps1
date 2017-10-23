function CheckLastExitCode {
    param ([int[]]$SuccessCodes = @(0), [scriptblock]$CleanupScript = $null)

    if ($SuccessCodes -notcontains $LastExitCode) {
        if ($CleanupScript) {
            "Executing cleanup script: $CleanupScript"
            &$CleanupScript
        }
        $msg = @"
EXE RETURNED EXIT CODE $LastExitCode
CALLSTACK:$(Get-PSCallStack | Out-String)
"@
        throw $msg
    }
}

$ErrorActionPreference = 'Stop'

$command = './Raven.Server.exe'
$commandArgs = @( '--non-interactive', '--log-to-console' )

$serverUrlScheme = if ([string]::IsNullOrEmpty($env:CERTIFICATE_PATH)) { "http" } else { "https" }

if ([string]::IsNullOrEmpty($env:CUSTOM_CONFIG_FILE) -eq $False) {
    $commandArgs += "--config-path"
    $commandArgs += "`"$($env:CUSTOM_CONFIG_FILE)`""
}

$commandArgs += "--ServerUrl=$($serverUrlScheme)://0.0.0.0:8080"
$commandArgs += "--ServerUrl.Tcp=tcp://0.0.0.0:38888"
$commandArgs += "--DataDir=`"$($env:DATA_DIR)`""

if ([string]::IsNullOrEmpty($env:UNSECURED_ACCESS_ALLOWED) -eq $False) {
    $commandArgs += "--Security.UnsecuredAccessAllowed=$($env:UNSECURED_ACCESS_ALLOWED)"
}

if ([string]::IsNullOrEmpty($env:PUBLIC_SERVER_URL) -eq $False) {
    $commandArgs += "--PublicServerUrl=$($env:PUBLIC_SERVER_URL)"
}

if ([string]::IsNullOrEmpty($env:PUBLIC_TCP_SERVER_URL) -eq $False) {
    $commandArgs += "--PublicServerUrl.Tcp=$($env:PUBLIC_TCP_SERVER_URL)"
}

if ([string]::IsNullOrEmpty($env:LOGS_MODE) -eq $False) {
    $commandArgs += "--Logs.Mode=$($env:LOGS_MODE)"
}

if ([string]::IsNullOrEmpty($env:CERTIFICATE_PATH) -eq $False) {
    $certificatePath = $env:CERTIFICATE_PATH;
    $commandArgs += "--Security.Certificate.Path=`"$certificatePath`""
}

if (([string]::IsNullOrEmpty($env:CERTIFICATE_PASSWORD) -eq $False) -and ([string]::IsNullOrEmpty($env:CERTIFICATE_PASSWORD_FILE) -eq $False)) {
    throw "CERTIFICATE_PASSWORD and CERTIFICATE_PASSWORD_FILE were both specified. Please use only one of those environment variables to configure your certificate's password.";
}

$certificatePassword = $null
if ([string]::IsNullOrEmpty($env:CERTIFICATE_PASSWORD) -eq $False) {
    $certificatePassword = "$env:CERTIFICATE_PASSWORD";
}

if ([string]::IsNullOrEmpty($env:CERTIFICATE_PASSWORD_FILE) -eq $False) {
    $certificatePassword = $(Get-Content "$env:CERTIFICATE_PASSWORD_FILE").Trim();
}

if ([string]::IsNullOrEmpty($certificatePassword) -eq $False) {
    $commandArgs += "--Security.Certificate.Password=`"$certificatePassword`""
}

$commandDesc = "Starting RavenDB server: $command $commandArgs" 
if ([string]::IsNullOrEmpty($certificatePassword) -eq $False) {
    $commandDesc = $commandDesc -replace "$certificatePassword", "********"
}

write-host $commandDesc

Invoke-Expression -Command "$command $commandArgs"
