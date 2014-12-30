#!/bin/sh -e

await() {
    until "$1" devices | grep -Fqx "$serial	$2"; do sleep 1; done
}

adb_hell() {
    # https://code.google.com/p/android/issues/detail?id=3254

    out=$(adb -s "$serial" shell "$1; echo \$?" | tr -d '\015')
    printf %s "$out" | sed \$d
    return "${out##*[!0-9]}"
}

setbootloader() {
    adb_hell \
    "test -e $part && busybox printf '\\x$1' | ${2+su -c \"} busybox dd bs=1 count=1 seek=$pos of=$part ${2+\"}"
}

usage() {
    echo "Usage: $0 -s serial-number [-b new-bootloader.img] [-r transient-recovery.img [sideload.zip...]]"
    exit 1
}

log() {
    echo "-> $1"
}


unset serial bootloader recovery
while getopts s:b:r: opt; do
    case "$opt" in
        s)     serial=$OPTARG ;;
        b) bootloader=$OPTARG ;;
        r)   recovery=$OPTARG ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
if test -z "$serial" -o -z "$recovery" -a $# != 0; then
    usage
fi

log "Waiting for adb access to device $serial..."
await adb device

log "Getting device model..."
model=$(adb_hell 'getprop ro.product.device')
case "$model" in
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
        log "Unsupported model: $model"
        exit 1
    ;;
esac
log "Supported model: $model"

log "Unlocking bootloader..."
setbootloader "$unlocked" su

if test -n "$bootloader" -o -n "$recovery"; then
    log "Starting bootloader..."
    adb -s "$serial" reboot-bootloader

    log "Waiting for bootloader fastboot..."
    await fastboot fastboot

    if test -n "$bootloader"; then
        log "Flashing bootloader $bootloader..."
        fastboot -s "$serial" flash bootloader "$bootloader"

        log "Restarting bootloader..."
        fastboot -s "$serial" reboot-bootloader

        log "Waiting for bootloader fastboot..."
        await fastboot fastboot

        if test -z "$recovery"; then
            log "Locking bootloader..."
            fastboot -s "$serial" oem lock

            log "Rebooting device..."
            fastboot -s "$serial" reboot
        fi
    fi

    if test -n "$recovery"; then
        log "Sending transient recovery $recovery..."
        fastboot -s "$serial" boot "$recovery"

        log "Waiting for recovery adb..."
        await adb recovery

        log "Locking bootloader..."
        setbootloader "$locked"

        for sideload; do
            log "Waiting for you to select sideload installation on the device..."
            await adb sideload

            log "Sending sideload package $sideload..."
            adb -s "$serial" sideload "$sideload"

            log "Waiting for recovery adb..."
            await adb recovery
        done
    fi
fi

log "Done."
