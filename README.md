# Building Sailfish OS for the Nokia 8000 4G

**WARNING**: Sailfish OS is currently **not usable** on feature phones like the Nokia 8000 4G without
a proper user interface. This port is just a proof of concept.

This port is based on the <https://github.com/msm8916-mainline/linux> kernel, so some hardware features
are not supported yet.

Keypad, display and WiFi are known to work. Modem support requires changes to ofono and audio is not
enabled in the kernel yet. The camera is currently not supported at all.

## Prerequisites
The build script requires the [Sailfish OS Platform SDK](https://docs.sailfishos.org/Tools/Platform_SDK/Installation/).

Two SDK targets need to be set up before running this script, a device-specific target and a native target.

Here is an example for Sailfish OS 4.6.0.11:

```
sdk-assistant tooling create SailfishOS-4.6.0 https://releases.sailfishos.org/sdk/targets/Sailfish_OS-4.6.0.11-Sailfish_SDK_Tooling-i486.tar.7z
sdk-assistant target create nokia-sparkler-armv7hl https://releases.sailfishos.org/sdk/targets/Sailfish_OS-4.6.0.11-Sailfish_SDK_Target-armv7hl.tar.7z
sdk-assistant target create native https://releases.sailfishos.org/sdk/targets/Sailfish_OS-4.6.0.11-Sailfish_SDK_Target-i486.tar.7z
```

## Building

After setting up the SDK and cloning this repository, one can simply run `./build.sh all` inside the SDK
to build the image.

The build is divided into the following stages:
1. `community-adaptation`: Building the community-adaptation package
2. `mw`: Building various middleware packages (see `DEFAULT_MW` in config-sparkler.sh)
3. `configs`: Building the device configuration package
4. `kernel`: Building the kernel
5. `bootimg`: Building the kernel/initramfs boot image
6. `image`: Building the final image

The build script allows specifying stages on the command line (e.g., `./build.sh configs` or `./build.sh configs image`).
For building the middleware, it is also possible to specify individual package names (e.g., `./build.sh rmtfs`).


## Flashing

A zip file containing the final image can be found in the `out` directory if the build is successful.

### lk2nd installation
Before flashing, [lk2nd](https://github.com/msm8916-mainline/lk2nd) for MSM8909 (version 17.0 or later) must be
installed on the device. A prebuilt image can be found [here](https://github.com/msm8916-mainline/lk2nd/releases/download/17.0/lk2nd-msm8909.img).

The lk2nd image should be flashed to the `boot` partition, either with `dd` from a rooted stock OS or using the
EDL loader provided at <https://edl.bananahackers.net/>. It is highly recommended to make backups of the stock OS
first!

### Flashing with lk2nd
Once lk2nd is installed, it should show a menu when the device is booted. If it doesn't, try booting the device
with the `#` key held down.

lk2nd provides a fastboot interface, which can now be used to flash Sailfish OS (after unpacking the zip file):

```
fastboot flash boot boot.img
fastboot flash system fimage.img001
fastboot flash userdata sailfish.img001
fastboot flash recovery recovery.img
```

### Booting to recovery mode
Recovery mode only works when booted from lk2nd. There are two easy ways to do this:

- holding down the `*` key **just before** the lk2nd version text appears on the screen
- live-booting the recovery image with `fastboot boot recovery.img`
