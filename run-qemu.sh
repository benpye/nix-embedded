#/bin/sh

SCRIPT=$(readlink "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

qemu-system-aarch64 \
    -vga none -nographic \
    -cpu host -machine virt,highmem=off -accel hvf \
    -kernel $SCRIPTPATH/result/kernel/*/Image -append "root=/dev/vda" \
    -drive if=virtio,readonly,format=raw,file=$SCRIPTPATH/result/squashfs.img \
    -device qemu-xhci -device usb-audio
