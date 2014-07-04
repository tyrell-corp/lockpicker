#!/bin/sh -e

await() {
    until "$1" devices | grep -Eqx "$serial	(device|recovery|fastboot)"; do sleep 1; done
}

setbootloader() {
    adb -s "$serial" shell \
    "test -e $part && busybox printf '\\x$1' | ${2+su -c \"} busybox dd bs=1 count=1 seek=$pos of=$part ${2+\"}"
}


if test $# != 2; then
    echo Usage: "$0" device-serial-number path/to/custom/recovery.img
    exit 1
fi
  serial=$1
recovery=$2

echo Waiting for adb access to device "$serial"...
await adb

echo
echo Getting device model...
device=$(adb -s "$serial" shell 'getprop ro.product.device' | tr -d '\015')
case "$device" in
    # From https://code.google.com/p/boot-unlocker-gnex

    maguro|toro|toroplus) # Galaxy Nexus
            part=/dev/block/platform/omap/omap_hsmmc.0/by-name/param
             pos=124
          locked=01
        unlocked=00
    ;;

    mako|hammerhead) # Nexus 4, 5
            part=/dev/block/platform/msm_sdcc.1/by-name/misc
             pos=16400
          locked=00
        unlocked=01
    ;;

    flo|deb) # Nexus 7 (2013)
            part=/dev/block/platform/msm_sdcc.1/by-name/aboot
             pos=5241856
          locked=00
        unlocked=02
    ;;

    manta) # Nexus 10
            part=/dev/block/platform/dw_mmc.0/by-name/param
             pos=548
          locked=00
        unlocked=01
    ;;

    *)
        echo Unsupported model: "$device"
        exit 1
    ;;
esac
echo Supported model: "$device"

echo
echo Unlocking bootloader...
setbootloader "$unlocked" su

echo
echo Starting bootloader...
adb -s "$serial" reboot-bootloader

echo
echo Waiting for bootloader fastboot...
await fastboot

echo
echo Sending recovery "$recovery"...
fastboot -s "$serial" boot "$recovery"

echo
echo Waiting for recovery adb...
await adb

echo
echo Locking bootloader...
setbootloader "$locked"

echo
echo Done.
