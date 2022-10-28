#!/usr/bin/bash

case $1 in
  '--help'|'-h')
	  echo "Usage:       mkukimg.sh <opt:val>"
	  echo "Description: Makes an Unified Kernel Image"
    echo "Options:
  kernel=the kernel image
  initrd=the init{rd,ramfs} image
  stub=the EFI stub
  ukimg=the resulting ukimg"
    exit 1;;
esac

if [[ $USER != root ]]; then
	echo "[ !! ] Need to be root"
	exit 1
fi

function try_opts {
  for opt in $@; do
    opt_key="${opt%%:*}"

    if [[ $opt_key = $opt ]]; then
      echo "[ !! ] Wrong option: \`$opt'"
      exit 1
    else
      opt_val="${opt##*:}"
    fi

    case $opt_key in
      'kernel')
        KERNEL=$opt_val;;
      'initrd')
        INITRD=$opt_val;;
      'stub')
        STUB=$opt_val;;
      'ukimg')
        UKIMG=$opt_val;;
    esac
  done
}

function try_defaults {
  [[ -z $KERNEL ]] && KERNEL=/boot/vmlinuz-linux
  [[ -z $INITRD ]] && INITRD=/boot/initramfs-linux.img
  [[ -z $STUB ]]   && STUB=/usr/lib/systemd/boot/efi/linuxx64.efi.stub
  [[ -z $UKIMG ]]  && UKIMG=/boot/EFI/BOOT/BOOTX64.EFI
  CMDLINE=/etc/kernel/cmdline
}

try_opts $@
try_defaults

## begin offsets ##
echo "[ .. ] Computing offsets"
stub_line=$(objdump -h "$STUB"  | awk '/\.sdmagic/')
stub_size=0x$(echo "$stub_line" | awk '{print $3}')
stub_offs=0x$(echo "$stub_line" | awk '{print $4}')

cmdline_offs=$((stub_size  + stub_offs))
linux_offs=$((cmdline_offs + $(stat -c%s "$CMDLINE")))
initrd_offs=$((linux_offs  + $(stat -c%s "$KERNEL")))
## end offsets ##

echo "[ .. ] Copying the modified object"
objcopy \
    --add-section .cmdline="$CMDLINE" \
    --change-section-vma .cmdline=$(printf 0x%x $cmdline_offs) \
    --add-section .linux="$KERNEL" \
    --change-section-vma .linux=$(printf 0x%x $linux_offs) \
    --add-section .initrd="$INITRD" \
    --change-section-vma .initrd=$(printf 0x%x $initrd_offs) \
    "$STUB" "$UKIMG" && \
echo "[ OK ] Done"
