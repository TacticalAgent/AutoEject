#!/bin/bash

# === Confirm Uninstall ===
response=$(osascript -e 'tell application "System Events" to display dialog "Are you sure you want to uninstall Auto-Eject and remove all related files?" buttons {"Cancel", "Uninstall"} default button "Uninstall"')

if [[ "$response" == *"Cancel"* ]]; then
  exit 0
fi

# === Stop SleepWatcher ===
brew services stop sleepwatcher

# === Uninstall SleepWatcher ===
brew uninstall sleepwatcher

# === Remove .sleep script & log ===
rm -f ~/.sleep
rm -f ~/sleepwatcher.log

# === Confirmation Message ===
osascript -e 'tell application "System Events" to display dialog "Uninstallation complete. Auto-Eject has been fully removed.\n\nMade by TacticalAgent" buttons {"OK"} default button "OK"'
