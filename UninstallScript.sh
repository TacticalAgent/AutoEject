#!/bin/bash

# === Confirm Uninstall ===
buttonClicked=$(osascript <<EOD
try
    display dialog "Are you sure you want to uninstall Auto-Eject and remove all related files?" buttons {"Cancel", "Uninstall"} default button "Uninstall"
    return button returned of result
on error
    return "Cancel"
end try
EOD
)

if [[ "$buttonClicked" == "Cancel" ]]; then
  osascript -e 'tell application "System Events" to display dialog "Uninstall cancelled. No changes were made." buttons {"OK"} default button "OK"'
  exit 0
fi

# === Stop SleepWatcher ===
brew services stop sleepwatcher

# === Uninstall SleepWatcher ===
brew uninstall sleepwatcher

# === Remove .sleep script & log ===
rm -f ~/.sleep
rm -f ~/sleepwatcher.log

# === Remove AutoEject-related Keychain entries ===
while IFS= read -r item; do
  security delete-generic-password -a "$USER" -s "$item" &>/dev/null
done < <(security find-generic-password -a "$USER" -g 2>&1 | grep "AutoEject_" | awk -F'"' '/"AutoEject_/{print $2}')

# === Confirmation Message ===
osascript -e 'tell application "System Events" to display dialog "Uninstallation complete. Auto-Eject has been fully removed.\n\nMade by TacticalAgent" buttons {"OK"} default button "OK"'
