# lockpicker

Unlocks your Android bootloader (without wiping user data),  
then boots into a transient custom/open/insecure recovery,  
then relocks the bootloader from inside that recovery.

Can also flash a new bootloader version,  
or help you install a ROM via the transient recovery,  
or merely unlock the bootloader.

You need adb root access and fastboot access from the host running this
script to the device.

(Nexus 4, 5, 7 (2013), 10, or Galaxy Nexus)


## What's the point?

You've installed a custom Android ROM and encrypted your device, but now
the unlocked bootloader and open recovery can be used by physical attackers
to _quickly_ infect your system with malware or copy your encrypted data.

To mitigate the threat, you flash stock recovery from a factory image at
https://developers.google.com/android/nexus/images and then relock the
bootloader. But you'll still want to boot a custom recovery when it's time
to upgrade your ROM or to make a backup:

    $ ./lockpicker.sh
    Usage: ./lockpicker.sh -s serial-number [-b new-bootloader.img] [-r transient-recovery.img [sideload.zip...]]

    $ time ./lockpicker.sh -s xxxxxxxx -r openrecovery-twrp-2.7.1.1-flo.img
    -> Waiting for adb access to device xxxxxxxx...
    -> Getting device model...
    -> Supported model: flo
    -> Unlocking bootloader...
    1+0 records in
    1+0 records out
    1 bytes (1B) copied, 0.011231 seconds, 89B/s
    -> Starting bootloader...
    -> Waiting for bootloader fastboot...
    -> Sending transient recovery openrecovery-twrp-2.7.1.1-flo.img...
    downloading 'boot.img'...
    OKAY [  0.354s]
    booting...
    OKAY [  0.026s]
    finished. total time: 0.380s
    -> Waiting for recovery adb...
    -> Locking bootloader...
    1+0 records in
    1+0 records out
    1 bytes (1B) copied, 0.005493 seconds, 182B/s
    -> Done.

    real    0m14.076s
    user    0m0.031s
    sys     0m0.068s
