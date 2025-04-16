# Define the download URL and corresponding install command
$apps = @(
    @{
        Url = "https://xxxx.blob.core.windows.net/JabraDirectSetup-v6.21.1701.exe"
        FileName = "JabraDirectSetup_v6.21.01701.exe"
        InstallCommand = "/S /quiet /norestart"
    }
)

# Define the destination folder and log file paths
$destinationFolder = "C:\MTRSoftware"
$logFile = Join-Path -Path $destinationFolder -ChildPath "installation_log.txt"
$errorLogFile = Join-Path -Path $destinationFolder -ChildPath "error_log.txt"

# Create the destination folder if it doesn't exist
if (-Not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder -Force
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
            Invoke-WebRequest -Uri $url -OutFile $destinationPath
            Write-Log -message "Downloaded $url to $destinationPath"
        } catch {
            Write-Log -message "Failed to download $url to $destinationPath. Error: $_" -logType "error"
        }
    }
}

# Function to install software silently and hidden
function Install-Software {
    param (
        [string]$installerPath,
        [string]$installCommand
    )

    try {
        $command = "$installerPath $installCommand"
        Write-Log -message "Executing installation command: $command"
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $installerPath
        $startInfo.Arguments = $installCommand
        $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $startInfo.CreateNoWindow = $true
        $process = [System.Diagnostics.Process]::Start($startInfo)
        $process.WaitForExit()
        Write-Log -message "Successfully executed: $command"
    } catch {
        Write-Log -message "Failed to execute: $command. Error: $_" -logType "error"
    }
}

# Process each app
foreach ($app in $apps) {
    $url = $app.Url
    $fileName = $app.FileName
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $fileName
    $installCommand = $app.InstallCommand

    # Download the file
    Download-File -url $url -destinationPath $destinationPath

    # Install the software silently and hidden
    Install-Software -installerPath $destinationPath -installCommand $installCommand
}

# Copy the script itself to the specified path
$scriptCopyPath = "C:\MTRSoftware\script.txt"
Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $scriptCopyPath -Force