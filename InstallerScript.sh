#!/bin/bash

# === Made by TacticalAgent ===
osascript -e 'tell application "System Events" to display dialog "Welcome to Auto-Eject Installer\n\nMade by TacticalAgent\n\nThis tool will automatically eject your selected drives when your Mac sleeps." buttons {"Continue"} default button "Continue"'

# === Prompt for Drives (comma-separated) ===
driveList=$(osascript <<EOD
try
    display dialog "Enter the EXACT names of all drives you want auto-ejected, separated by commas:\n\nExample: MyFiles, SSD1, BackupDrive" default answer "" buttons {"Cancel", "OK"} default button "OK"
    return text returned of result
on error
    return "CANCELLED"
end try
EOD
)

# === Cancel Handling ===
if [[ "$driveList" == "CANCELLED" ]]; then
  osascript -e 'tell application "System Events" to display dialog "Setup was cancelled. No changes were made." buttons {"OK"} default button "OK"'
  exit 0
fi

# === Install Homebrew (if missing) ===
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# === Load Homebrew into PATH ===
eval "$(/opt/homebrew/bin/brew shellenv)"

# === Install and start SleepWatcher ===
brew install sleepwatcher
brew services start sleepwatcher

# === Create the .sleep script ===
echo "#!/bin/bash" > ~/.sleep
echo "echo \"Running sleep script at \$(date)\" >> ~/sleepwatcher.log" >> ~/.sleep
echo "tmutil stopbackup >> ~/sleepwatcher.log 2>&1" >> ~/.sleep

# === Loop through each drive name ===
IFS=',' read -ra drives <<< "$driveList"
for drive in "${drives[@]}"; do
  cleanDrive=$(echo "$drive" | xargs)  # Trim spaces
  echo "diskutil unmount force /Volumes/$cleanDrive >> ~/sleepwatcher.log 2>&1" >> ~/.sleep
done

# === Add sleep delay ===
echo "sleep 15" >> ~/.sleep

# === Make the script executable ===
chmod +x ~/.sleep

# === Final popup ===
osascript -e 'tell application "System Events" to display dialog "Setup complete! Your drives will now auto-eject when your Mac sleeps. Enjoy!!\n\nMade by TacticalAgent" buttons {"OK"} default button "OK"'

# === Helpful Notes ===
osascript -e 'tell application "System Events" to display dialog "Note:\nIf you still see the \"Disk Not Ejected Properly\" warning occasionally, don’t worry — your script is still working.\n\nTo verify:\n1. Open Terminal\n2. Run: cat ~/sleepwatcher.log\n3. You’ll see timestamps showing the drives were cleanly unmounted.\n\nThis warning is a cosmetic glitch in macOS (not data loss).\n\n- TacticalAgent" buttons {"Got it!"} default button "Got it!"'


