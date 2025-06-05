# AutoEject
Auto-eject your external drives before sleep, reduces the annoying macOS ejection warnings without paying for bloated apps. Free, simple, and effective for most users :D

# How to get it:

Go to Releases

Download the recent v1.2 AutoEjectInstaller-v1.2.dmg

Follow the prompts to set it up

# Notes:
You’ll be guided to allow Terminal Full Disk Access (required for encrypted drives)

You’ll also need to give SleepWatcher Full Disk Access:
Go to **System Settings → Privacy & Security → Full Disk Access, and make sure SleepWatcher is also enabled in the list.**

Both are one-time setups





**This tool uses force unmounting to ensure your selected drives are cleanly ejected before sleep**, even if Finder or background processes are holding onto them.


While macOS does its best to flush data safely, **ejecting during active file transfers always carries a risk of interruption**, to avoid potential data loss or incomplete copies, **please make sure file transfers to your external drives are finished before your Mac goes to sleep.**
