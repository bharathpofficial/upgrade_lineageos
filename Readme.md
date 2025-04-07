# LineageOS Upgrade Automation Script

This script automates the process of upgrading a device running LineageOS 22.1 Nightly builds. It simplifies the steps required to patch the `boot.img` with Magisk, modify the LineageOS update package, and sideload the update to the device.

---

## Features

1. **Automatic Detection of LineageOS Packages**:
   - The script scans the specified directory for LineageOS update packages and allows the user to select one if multiple packages are found.

2. **Magisk Boot Image Patching**:
   - Downloads the `boot.img` from the device.
   - Waits for the user to patch the `boot.img` using Magisk on the device.
   - Pulls the patched `boot.img` back to the local system.

3. **Package Modification**:
   - Replaces the default `boot.img` in the LineageOS update package with the Magisk-patched `boot.img`.
   - Repackages the modified update package.

4. **Automated Sideloading**:
   - Reboots the device into sideload mode and applies the modified update package.

5. **Cleanup**:
   - Removes temporary files and directories after the process is completed.

---

## Prerequisites

1. **ADB (Android Debug Bridge)**:
   - Ensure `adb` is installed and accessible from the terminal.

2. **Device Setup**:
   - USB Debugging must be enabled on the device.
   - The device must be connected via USB and recognized by `adb`.

3. **LineageOS Update Package**:
   - Place the LineageOS update package (e.g., `lineage-22.1-YYYYMMDD-nightly-miatoll-signed.zip`) in the directory:
     ```
     ~/Downloads/mobile_flashing/
     ```

4. **Magisk Manager**:
   - Magisk Manager must be installed on the device to patch the `boot.img`.

---

## Directory Structure

| Directory                          | Description                                                                 |
|------------------------------------|-----------------------------------------------------------------------------|
| `~/Downloads/mobile_flashing/`     | Base directory for all files related to the upgrade process.                |
| `og_boot/`                         | Stores the original `boot.img` downloaded from the device.                  |
| `modified_boot/`                   | Stores the Magisk-patched `boot.img`.                                       |
| `extracted_lineageos/`             | Temporary directory for extracting the LineageOS update package.            |
| `lineage-22.1-YYYYMMDD-nightly-miatoll-signed.zip` | Original LineageOS update package.                              |
| `modified-lineage-22.1-YYYYMMDD-nightly-miatoll-signed.zip` | Modified LineageOS update package with patched `boot.img`. |

---

## Workflow

### Steps Automated by the Script

1. **Download the Original Boot Image**:
   - The script pulls the `boot.img` from the device located at:
     ```
     /sdcard/Download/boot.img
     ```
   - The `boot.img` is saved to:
     ```
     ~/Downloads/mobile_flashing/og_boot/
     ```

2. **Patch the Boot Image with Magisk**:
   - The user patches the `boot.img` manually using the Magisk Manager app on the device.
   - The patched boot image (e.g., `magisk_patched-XXXX.img`) is saved to:
     ```
     /sdcard/Download/
     ```

3. **Copy the Patched Boot Image to the Local System**:
   - The patched boot image is pulled from the device and saved to:
     ```
     ~/Downloads/mobile_flashing/modified_boot/
     ```

4. **Extract the LineageOS Update Package**:
   - The LineageOS update package is extracted to:
     ```
     ~/Downloads/mobile_flashing/extracted_lineageos/
     ```

5. **Replace the Default Boot Image**:
   - The default `boot.img` in the extracted LineageOS package is replaced with the Magisk-patched `boot.img`.

6. **Repackage the Modified LineageOS Update Package**:
   - The modified package is zipped and saved as:
     ```
     ~/Downloads/mobile_flashing/modified-lineage-22.1-YYYYMMDD-nightly-miatoll-signed.zip
     ```

7. **Reboot into Sideload Mode**:
   - The script checks if the device is already in sideload mode. If not, it reboots the device into sideload mode using:
     ```
     adb reboot sideload
     ```

8. **Apply the Update**:
   - The modified LineageOS package is sideloaded to the device using:
     ```
     adb sideload ~/Downloads/mobile_flashing/modified-lineage-22.1-YYYYMMDD-nightly-miatoll-signed.zip
     ```

9. **Reboot Back to the System**:
   - After a successful flash, the device is rebooted back to the system using:
     ```
     adb reboot
     ```

10. **Clean Up Temporary Files**:
    - The extracted LineageOS directory (`~/Downloads/mobile_flashing/extracted_lineageos/`) is removed to keep the workspace clean.

---

## Usage

1. Place the LineageOS update package in the `~/Downloads/mobile_flashing/` directory.
2. Run the script:
   ```bash
   upgrade_lineageos.sh
   ```
3. When asked to patch manually open magisk manager app and patch the boot.img, How to get boot.img separately you ask, I got you, visit the `https://download.lineageos.org/devices/miatoll/builds`  grab the latest release's boot.img.
