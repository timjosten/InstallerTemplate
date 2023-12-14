### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Patch name and version goes here
do.addond=1
addond.name=70-uniquepatchname
do.devicecheck=0
device.name1=begonia
do.cleanup=1
do.cleanuponabort=0
'; } # end properties


### AnyKernel install
# boot shell variables
block=boot;
no_block_display=1;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;
. tools/tim-core.sh;
