# Define the device name to detect
$deviceName = "Jabra PanaCast"
$requiredVersion = "6.21.01701"

# Function to check for the device
function Check-USBDevice {
    # Query to find the device in the system
    $devices = Get-WmiObject -Query "SELECT * FROM Win32_PnPEntity WHERE Caption LIKE '%$deviceName%'"
    
    # Check if the device is found
    if ($devices) {
        Write-Output "$deviceName is plugged in."

        # Check if any installed application has the target version
        $installedApps = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
        $installedApps += Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue

        $matchingApp = $installedApps | Where-Object { $_.DisplayVersion -eq $requiredVersion }

        if ($matchingApp) {
            Write-Output "Application with DisplayVersion $requiredVersion is installed."
            exit 0
        } else {
            Write-Output "No application with DisplayVersion $requiredVersion is installed."
            exit 1
        }
    } 
    else {
        Write-Output "$deviceName is not plugged in."
        exit 0
    }
}

# Call the function
Check-USBDevice
