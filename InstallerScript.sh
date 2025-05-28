#!/bin/bash

# === Made by TacticalAgent ===
osascript -e 'tell application "System Events" to display dialog "Welcome to Auto-Eject Installer\n\nMade by TacticalAgent\n\nThis tool auto-ejects your drives on sleep and auto-remounts on wake (including encrypted drives)." buttons {"Continue"} default button "Continue"'

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

# === Ask if any drive is encrypted ===
encryptedList=$(osascript <<EOD
try
    display dialog "If any drives are ENCRYPTED, enter their names again here (comma-separated).\n\nIf none are encrypted, leave blank." default answer "" buttons {"OK"} default button "OK"
    return text returned of result
on error
    return ""
end try
EOD
)

# === Install Homebrew (if missing) ===
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# === Load Homebrew into PATH ===
eval "$(${HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew shellenv)"

# === Install SleepWatcher & Restart Service ===
brew install sleepwatcher
brew services restart sleepwatcher
brew services list | grep sleepwatcher >> ~/sleepwatcher.log

# === Create the .sleep script ===
echo "#!/bin/bash" > ~/.sleep
echo "echo \"Running sleep script at \$(date)\" >> ~/sleepwatcher.log" >> ~/.sleep
echo "tmutil stopbackup >> ~/sleepwatcher.log 2>&1" >> ~/.sleep

IFS=',' read -ra drives <<< "$driveList"
for drive in "${drives[@]}"; do
  cleanDrive=$(echo "$drive" | xargs)
  echo "diskutil unmount force /Volumes/$cleanDrive >> ~/sleepwatcher.log 2>&1" >> ~/.sleep
done

echo "sleep 10" >> ~/.sleep
chmod +x ~/.sleep

# === Handle encrypted drive passwords (store securely in Keychain) ===
IFS=',' read -ra encryptedDrives <<< "$encryptedList"
for encDrive in "${encryptedDrives[@]}"; do
  cleanEncDrive=$(echo "$encDrive" | xargs)
  encPass=$(osascript -e "Tell application \"System Events\" to display dialog \"Enter password for encrypted drive \" & quoted form of \"$cleanEncDrive\" & \" (stored securely in Keychain):\" default answer \"\" with hidden answer" -e 'text returned of result')
  security add-generic-password -a "$USER" -s "AutoEject_$cleanEncDrive" -w "$encPass"
done

# === Create the corrected .wakeup script ===
echo "#!/bin/bash" > ~/.wakeup
echo "echo \"Running wakeup script at \$(date)\" >> ~/sleepwatcher.log" >> ~/.wakeup

for drive in "${drives[@]}"; do
  cleanDrive=$(echo "$drive" | xargs)
  echo "echo \"Searching for disk identifier for $cleanDrive\" >> ~/sleepwatcher.log" >> ~/.wakeup
  echo "diskID=\$(diskutil info \"$cleanDrive\" | awk -F': ' '/Device Node/{print \$2}' | xargs)" >> ~/.wakeup
  echo "if [[ -n \"\$diskID\" ]]; then" >> ~/.wakeup
  echo "  isEncrypted=false" >> ~/.wakeup
  for encDrive in "${encryptedDrives[@]}"; do
    cleanEnc=$(echo "$encDrive" | xargs)
    echo "  if [[ \"$cleanDrive\" == \"$cleanEnc\" ]]; then isEncrypted=true; fi" >> ~/.wakeup
  done
  echo "  if \$isEncrypted; then" >> ~/.wakeup
  echo "    echo \"Attempting to unlock $cleanDrive (ID: \$diskID)\" >> ~/sleepwatcher.log" >> ~/.wakeup
  echo "    pass=\$(security find-generic-password -a \"$USER\" -s \"AutoEject_$cleanDrive\" -w)" >> ~/.wakeup
  echo "    diskutil apfs unlockVolume \"\$diskID\" -passphrase \"\$pass\" >> ~/sleepwatcher.log 2>&1" >> ~/.wakeup
  echo "  fi" >> ~/.wakeup
  echo "  echo \"Attempting to mount $cleanDrive (ID: \$diskID)\" >> ~/sleepwatcher.log" >> ~/.wakeup
  echo "  diskutil mount \"\$diskID\" >> ~/sleepwatcher.log 2>&1" >> ~/.wakeup
  echo "else" >> ~/.wakeup
  echo "  echo \"Failed to find disk /Volumes/$cleanDrive\" >> ~/sleepwatcher.log" >> ~/.wakeup
  echo "fi" >> ~/.wakeup
done

chmod +x ~/.wakeup

# === Final popup ===
osascript -e 'tell application "System Events" to display dialog "Setup complete! Your drives (including encrypted drives) will auto-eject on sleep and auto-remount on wake. Enjoy!!\n\nMade by TacticalAgent" buttons {"OK"} default button "OK"'

# === Helpful Notes ===
osascript -e 'tell application "System Events" to display dialog "Note:\nIf you still see the \"Disk Not Ejected Properly\" warning occasionally, don’t worry — your script is still working.\n\nTo verify:\n1. Open Terminal\n2. Run: cat ~/sleepwatcher.log\n3. You’ll see timestamps showing drives were cleanly unmounted and remounted/unlocked.\n\nThis warning is cosmetic only (not data loss).\n\n- TacticalAgent" buttons {"Got it!"} default button "Got it!"'

# === Important Sandbox Note ===
osascript -e 'tell application "System Events" to display dialog "⚠️ IMPORTANT (Encrypted Drives Only):\n\nmacOS restricts script access to unlock encrypted volumes unless Terminal has Full Disk Access.\n\nPlease do this one-time setup:\n\n1. Open System Settings\n2. Privacy & Security → Full Disk Access\n3. Click (+) and add Terminal\n4. Fully quit & reopen Terminal\n\nThis ensures encrypted drives auto-unlock properly.\n\n- TacticalAgent" buttons {"Understood"} default button "Understood"'

# === Important: Enable SleepWatcher in Login Items ===
osascript -e 'tell application "System Events" to display dialog "⚠️ IMPORTANT (Final Step):\n\nTo ensure AutoEject works after every sleep/wake, you must enable SleepWatcher in background apps:\n\n1. Open System Settings\n2. Go to General → Login Items\n3. Under Allow in Background, toggle ON for sleepwatcher\n\nThis only needs to be done once!\n\n- TacticalAgent" buttons {"Understood"} default button "Understood"'
