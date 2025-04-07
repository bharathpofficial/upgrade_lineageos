#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

# Variables
DOWNLOAD_DIR="$HOME/Downloads/mobile_flashing"
OG_BOOT_DIR="$DOWNLOAD_DIR/og_boot"
MODIFIED_BOOT_DIR="$DOWNLOAD_DIR/modified_boot"

# Functions
rollback() {
    echo -e "An error occurred. Rolling back changes..."
    exit 1
}

trap rollback ERR  # Trigger rollback on any error

# Step 1: Ensure necessary directories exist
echo -e "\nStep 1: Creating necessary directories..."
mkdir -p "$MODIFIED_BOOT_DIR"

# Step 2: Handle multiple LineageOS packages
echo -e "\nStep 2: Finding LineageOS package..."
LINEAGE_PACKAGES=($(ls "$DOWNLOAD_DIR" | grep "lineage-22.1-[0-9]\{8\}-nightly-miatoll-signed.zip"))
if [[ ${#LINEAGE_PACKAGES[@]} -eq 0 ]]; then
    echo -e "Error: No LineageOS packages found in $DOWNLOAD_DIR."
    exit 1
elif [[ ${#LINEAGE_PACKAGES[@]} -gt 1 ]]; then
    echo -e "Multiple LineageOS packages found:"
    for i in "${!LINEAGE_PACKAGES[@]}"; do
        PACKAGE_NAME=${LINEAGE_PACKAGES[$i]}
        DATE_PART=$(echo -e "$PACKAGE_NAME" | grep -oE "[0-9]{8}")
        echo -e "$i) lineage-22.1-\033[92m$DATE_PART\033[0m-nightly-miatoll-signed.zip"
    done
    read -p "Select the package to use (enter the number): " PACKAGE_INDEX
    LINEAGE_PACKAGE="${LINEAGE_PACKAGES[$PACKAGE_INDEX]}"
else
    LINEAGE_PACKAGE="${LINEAGE_PACKAGES[0]}"
fi

DATE_PART=$(echo -e "$LINEAGE_PACKAGE" | grep -oE "[0-9]{8}")
echo -e "Selected package: lineage-22.1-\033[92m$DATE_PART\033[0m-nightly-miatoll-signed.zip"

MODIFIED_PACKAGE="modified-$LINEAGE_PACKAGE"

# Step 3: Download boot.img from the mobile device
echo -e "\nStep 3: Downloading boot.img from the mobile device..."
BOOT_IMG="/sdcard/Download/boot.img"
if ! adb shell test -f "$BOOT_IMG"; then
    echo -e "Error: boot.img not found on the device."
    exit 1
fi

echo -e "Copying boot.img to $OG_BOOT_DIR..."
adb pull -p "$BOOT_IMG" "$OG_BOOT_DIR"
echo -e "boot.img copied to $OG_BOOT_DIR"

# Step 4: Manual approval for Magisk patching
echo
echo -e "#############################################"
echo -e "# Step 4: Patching boot.img with Magisk     #"
echo -e "#############################################"
echo
echo -e "Please open Magisk on your device and patch the boot image."
read -p "Press Enter when you have completed the patching..."

echo
echo -e "Waiting for the patched boot image to appear in /sdcard/Download..."
while true; do
    MAGISK_PATCHED_IMGS=($(adb shell ls "/sdcard/Download" | grep "magisk_patched-"))
    if [[ ${#MAGISK_PATCHED_IMGS[@]} -gt 0 ]]; then
        break
    fi
    echo -n "."
    sleep 1
done

echo
echo -e "Patched boot images found:"
for i in "${!MAGISK_PATCHED_IMGS[@]}"; do
    echo -e "$i) ${MAGISK_PATCHED_IMGS[$i]}"
done

read -p "Select the patched boot image to use (enter the number): " PATCHED_INDEX
if (( PATCHED_INDEX < 0 || PATCHED_INDEX >= ${#MAGISK_PATCHED_IMGS[@]} )); then
    echo
    echo -e "Invalid selection. Exiting..."
    exit 1
fi

SELECTED_PATCHED_IMG="${MAGISK_PATCHED_IMGS[$PATCHED_INDEX]}"
echo
echo -e "Selected patched boot image: $SELECTED_PATCHED_IMG"

echo
echo -e "Pulling it to $MODIFIED_BOOT_DIR..."
if ! adb pull -p "/sdcard/Download/$SELECTED_PATCHED_IMG" "$MODIFIED_BOOT_DIR/boot.img"; then
    echo -e "Error: Failed to pull the patched boot image."
    exit 1
fi
echo -e "Patched boot image successfully pulled to $MODIFIED_BOOT_DIR."

# Step 5: Extract LineageOS update package and replace boot.img
echo -e "\nStep 5: Extracting LineageOS update package..."
EXTRACT_DIR="$DOWNLOAD_DIR/extracted_lineageos"
mkdir -p "$EXTRACT_DIR"
unzip -o "$DOWNLOAD_DIR/$LINEAGE_PACKAGE" -d "$EXTRACT_DIR"
echo -e "Replacing default boot.img with the modified one..."
cp "$MODIFIED_BOOT_DIR/boot.img" "$EXTRACT_DIR/boot.img"
echo -e "boot.img replaced in extracted package"

# Step 6: Repackage the modified LineageOS update package
echo -e "\nStep 6: Repackaging the modified LineageOS update package..."
cd "$EXTRACT_DIR"
zip -r9 "../$MODIFIED_PACKAGE" *
cd -
echo -e "Modified package created: $MODIFIED_PACKAGE"

# Step 7: Verify the modified package exists
echo -e "Step 7: Verifying the modified package exists..."
if [[ ! -f "$DOWNLOAD_DIR/$MODIFIED_PACKAGE" ]]; then
    echo -e "Error: Failed to create the modified LineageOS package."
    exit 1
fi
echo -e "Modified package verified"

# Step 8: Reboot into sideload mode and apply the update
echo -e "\nStep 8: Rebooting into sideload mode..."

if adb devices | grep -q "sideload"; then
    echo -e "Device is already in sideload mode."
else
    adb reboot sideload || { echo -e "Error: Failed to reboot into sideload mode."; exit 1; }
    echo -e "Waiting for the device to enter sideload mode..."
    while ! adb devices | grep -q "sideload"; do
        sleep 1
    done
    echo -e "Device in sideload mode"
fi

echo -e "Applying the update..."
adb sideload "$DOWNLOAD_DIR/$MODIFIED_PACKAGE" || { echo -e "Error: Sideloading failed."; exit 1; }

# Step 9: Verify flashing completion and reboot system
echo -e "Step 9: Verifying flashing completion..."
if adb devices | grep -q "sideload"; then
    echo -e "Flashing completed successfully!"
else
    echo -e "Warning: Unable to confirm flashing success. Please check your device manually."
fi

echo -e "system will be rebooted in 5 seconds..."

sleep 5  # Wait for a few seconds to ensure the device is ready

echo -e "\nRebooting back to the system..."
adb reboot || { echo -e "Error: Failed to reboot into the system."; exit 1; }

# Step 10: Clean up extracted directory
echo -e "\nStep 10: Cleaning up extracted LineageOS directory..."
if [[ -d "$EXTRACT_DIR" ]]; then
    rm -rf "$EXTRACT_DIR"
    echo -e "Extracted directory $EXTRACT_DIR removed successfully."
else
    echo -e "No extracted directory found to clean up."
fi

echo -e "\n\nUpgrade completed successfully!"

