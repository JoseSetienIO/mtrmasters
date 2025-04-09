# Attempt to get the path of the currently executing script
$currentScriptPath = $MyInvocation.MyCommand.Path
if (-not $currentScriptPath) {
    $currentScriptPath = Get-Location  # Fallback
}

if (-not $currentScriptPath) {
    Write-Error "Unable to determine the current script path."
    exit 1
}

# Define the path to copy the script
$scriptCopyPath = "C:\MTRSoftware\script-Nureva.txt"

# Create the destination folder if it doesn't exist
if (-Not (Test-Path -Path "C:\MTRSoftware")) {
    New-Item -ItemType Directory -Path "C:\MTRSoftware" -Force
}

# Copy the script instead of modifying its contents
Copy-Item -Path $currentScriptPath -Destination $scriptCopyPath -Force

# Define the download URL and corresponding executable
$app = @{
    Url = "https://xxxx.blob.core.windows.net/xxxxx/NurevaConsoleClient-Enterprise-3.1.282832.msi"
    FileName = "NurevaConsoleClient-Enterprise-3.1.282832.msi"
    InstallCommand = "/qn /norestart"
}

# Define the destination folder and log file paths
$destinationFolder = "C:\MTRSoftware"
$logFile = Join-Path -Path $destinationFolder -ChildPath "installation_log.txt"
$errorLogFile = Join-Path -Path $destinationFolder -ChildPath "error_log.txt"

# Ensure log files exist before writing logs
if (-Not (Test-Path $logFile)) {
    New-Item -ItemType File -Path $logFile -Force | Out-Null
}
if (-Not (Test-Path $errorLogFile)) {
    New-Item -ItemType File -Path $errorLogFile -Force | Out-Null
}

# Function to write log messages
function Write-Log {
    param (
        [string]$message,
        [string]$logType = "info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$logType] $message"

    if ($logType -eq "error") {
        Add-Content -Path $errorLogFile -Value $logMessage
    } else {
        Add-Content -Path $logFile -Value $logMessage
    }

    # Verbose logging to console
    Write-Verbose $logMessage
}

# Function to download a file
function Download-File {
    param (
        [string]$url,
        [string]$destinationPath
    )
    
    if (Test-Path -Path $destinationPath) {
        Write-Log -message "File $destinationPath already exists. Skipping download."
    } else {
        try {
            Invoke-WebRequest -Uri $url -OutFile $destinationPath -ErrorAction Stop
            Write-Log -message "Downloaded $url to $destinationPath"
        } catch {
            Write-Log -message "Failed to download $url to $destinationPath. Error: $_" -logType "error"
            exit 1
        }
    }
}

# Function to install software quietly
function Install-Software {
    param (
        [string]$filePath,
        [string]$installArgs
    )

    try {
        # Ensure the MSI file exists before running the installation
        if (-Not (Test-Path -Path $filePath)) {
            Write-Log -message "Installation file not found: $filePath" -logType "error"
            exit 1
        }

        Write-Log -message "Executing installation command: msiexec.exe /i `"$filePath`" $installArgs"
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$filePath`" $installArgs" -Wait -PassThru

        # Check for installation failure
        if ($process.ExitCode -ne 0) {
            Write-Log -message "Installation failed with exit code: $($process.ExitCode)" -logType "error"
            exit 1
        }

        Write-Log -message "Successfully installed: $filePath"
    } catch {
        Write-Log -message "Failed to install $filePath. Error: $_" -logType "error"
        exit 1
    }
}

# Process the app
$url = $app.Url
$fileName = $app.FileName
$destinationPath = Join-Path -Path $destinationFolder -ChildPath $fileName
$installCommand = $app.InstallCommand

# Download the file
Download-File -url $url -destinationPath $destinationPath

# Install the software quietly
Install-Software -filePath $destinationPath -installArgs $installCommand