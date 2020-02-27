#!/system/bin/sh

# Variables
LOCATION="storage/emulated/0"

# TODO: Check if a device is connected with adb devices

# Create directories if they don't already exist
adb shell mkdir -p $LOCATION/scripts/fun-run-3

# Push the script to phone
adb push funrun-ai.sh $LOCATION/scripts/fun-run-3

# Run script. Comment line if you don't want to run the script after pushing
adb shell sh $LOCATION/scripts/fun-run-3/afk-daily.sh