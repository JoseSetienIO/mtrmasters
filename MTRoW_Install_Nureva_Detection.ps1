# Define the required product version
$targetVersion = [Version]"3.1.282832"

# Define registry path and key for Nureva Console Client
$registryPath = "HKLM:\SOFTWARE\Nureva Console client"
$registryKey = "Version"

# Define the device name to detect
$deviceName = "Nureva Audio"

# Function to check if the Nureva Audio device is plugged in
function Check-USBDevice {
    $devices = Get-WmiObject -Query "SELECT * FROM Win32_SoundDevice WHERE Caption LIKE '%$deviceName%'"
    return $devices
}

# Function to get the installed version from the registry
function Get-NurevaVersion {
    if (Test-Path $registryPath) {
        $installedVersion = (Get-ItemProperty -Path $registryPath -Name $registryKey -ErrorAction SilentlyContinue).Version
        if ($installedVersion) {
            return [Version]$installedVersion
        }
    }
    return $null
}

# Check for the device
$device = Check-USBDevice

if ($device) {
    Write-Output "$deviceName is plugged in."

    # Get the installed version of Nureva Console Client
    $installedVersion = Get-NurevaVersion

    # Check if the software is installed and up to date
    if ($installedVersion -eq $null) {
        Write-Output "Nureva Console Client is not installed."
        exit 1  # Trigger remediation
    } elseif ($installedVersion -ge $targetVersion) {
        Write-Output "Nureva Console Client is up to date (Version: $installedVersion)."
        exit 0  # No action needed
    } else {
        Write-Output "Nureva Console Client is outdated. Installed: $installedVersion, Required: $targetVersion."
        exit 1  # Trigger remediation
    }
} else {
    Write-Output "$deviceName is not plugged in."
    exit 0  # Do nothing if device is not present
}