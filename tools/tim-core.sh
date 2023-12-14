ui_print " " "Installer template v1.01 by timjosten" " "
umount_all
mount_all
mount -o rw,remount /system_root

uninstall=0
case $(basename "$ZIPFILE") in
  *uninstall*)
    ui_print "Uninstalling..." " "
    rm -rf $home/system/tmp
    mv $home/system/add $home/system/tmp
    mv $home/system/delete $home/system/add
    mv $home/system/tmp $home/system/delete
    uninstall=1
    ;;
esac

ui_print "Deleting files..."
delete=""
dir=$home/system/delete/
for file in `find $dir -type f | sed 's|^'$dir'||g'`; do
  rm "/system_root/system/$file" && ui_print "Delete $file... ok" || ui_print "Delete $file... failed"
  delete="$delete $file"
done

ui_print "Extracting files..."
add=""
dir=$home/system/add/
for file in `find $dir -type f | sed 's|^'$dir'||g'`; do
  mkdir -p $(dirname "/system_root/system/$file")
  cp -Tp "$dir$file" "/system_root/system/$file" && ui_print "Extract $file... ok" || abort "Cannot extract file $file"
  add="$add $file"
done

if [ "$(file_getprop anykernel.sh do.addond)" == 1 ]; then
  file=$(file_getprop anykernel.sh addond.name).sh
  if [ "$uninstall" == 1 ]; then
    ui_print "Deleting addon.d script..."
    rm "/system_root/system/addon.d/$file" && ui_print "Delete $file... ok" || ui_print "Delete $file... failed"
  else
    ui_print "Generating addon.d script..."
    tee "/system_root/system/addon.d/$file" <<EOF >/dev/null && ui_print "Generate $file... ok" || abort "Cannot generate file $file"
#!/sbin/sh
#
# ADDOND_VERSION=2
#
# /system/addon.d/$file
# $(file_getprop anykernel.sh kernel.string)
#

. /tmp/backuptool.functions

# determine parent output fd and ui_print method
FD=1
# update-binary|updater <RECOVERY_API_VERSION> <OUTFD> <ZIPFILE>
OUTFD=\$(ps | grep -v 'grep' | grep -oE 'update(.*) 3 [0-9]+' | cut -d" " -f3)
[ -z \$OUTFD ] && OUTFD=\$(ps -Af | grep -v 'grep' | grep -oE 'update(.*) 3 [0-9]+' | cut -d" " -f3)
# update_engine_sideload --payload=file://<ZIPFILE> --offset=<OFFSET> --headers=<HEADERS> --status_fd=<OUTFD>
[ -z \$OUTFD ] && OUTFD=\$(ps | grep -v 'grep' | grep -oE 'status_fd=[0-9]+' | cut -d= -f2)
[ -z \$OUTFD ] && OUTFD=\$(ps -Af | grep -v 'grep' | grep -oE 'status_fd=[0-9]+' | cut -d= -f2)
if [ -z \$OUTFD ]; then
  ui_print() { echo \$1; }
else
  ui_print() { echo -e "ui_print \$1\nui_print" >>"/proc/self/fd/\$OUTFD"; }
fi

delete_list() {
cat <<'HEREDOC'$([ -z "$delete" ] || echo; for file in $delete; do echo $file; done)
HEREDOC
}
add_list() {
cat <<'HEREDOC'$([ -z "$add" ] || echo; for file in $add; do echo $file; done)
HEREDOC
}

case \$1 in
  backup)
    ui_print '- Backing up $(file_getprop anykernel.sh kernel.string)'
    add_list | while read FILE; do
      backup_file "\$S/\$FILE"
    done
    ;;
  restore)
    ui_print '- Restoring $(file_getprop anykernel.sh kernel.string)'
    delete_list | while read FILE; do
      rm -f "\$S/\$FILE"
    done
    add_list | while read FILE; do
      [ -f "\$C/\$S/\$FILE" ] && restore_file "\$S/\$FILE"
    done
    ;;
esac
EOF
  fi
fi

umount_all
exit 0
