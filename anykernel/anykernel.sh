### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Mix 4 (odin) 5.4.302 ReSukiSU + OIS post-init fix
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=odin
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;
} # end attributes

# boot shell variables
block=boot;
is_slot_device=1;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot;
write_boot;
## end boot install

## vendor kernel modules install
# The camera driver (camera.ko) lives in /vendor/lib/modules and is loaded by
# vendor_init long before any systemless overlay exists, so it is written to
# the vendor partition directly. Existing files are overwritten in place with
# cat so their SELinux context and ownership are preserved.
install_vendor_modules() {
  local src cnt miss m base;
  src=$home/vendor_modules;
  [ -d "$src" ] || return 0;

  ui_print " ";
  ui_print "Installing vendor kernel modules...";

  if ! mount | grep -q " /vendor "; then
    mount -o ro -t auto /vendor 2>/dev/null;
  fi;
  if ! mount | grep -q " /vendor "; then
    ui_print "  ! /vendor could not be mounted";
    ui_print "  ! kernel flashed, modules NOT updated";
    return 0;
  fi;

  mount -o rw,remount /vendor 2>/dev/null;
  if [ ! -w /vendor/lib/modules ]; then
    ui_print "  ! /vendor is read-only, modules NOT updated";
    mount -o ro,remount /vendor 2>/dev/null;
    return 0;
  fi;

  cnt=0; miss=0;
  for m in $src/*.ko; do
    base=$(basename $m);
    if [ -f /vendor/lib/modules/$base ]; then
      cat $m > /vendor/lib/modules/$base && cnt=$((cnt + 1));
    else
      miss=$((miss + 1));
    fi;
  done;

  ui_print "  replaced $cnt modules in /vendor/lib/modules";
  [ $miss -gt 0 ] && ui_print "  skipped $miss modules with no counterpart on device";

  sync;
  mount -o ro,remount /vendor 2>/dev/null;
}

install_vendor_modules;
## end vendor kernel modules install
