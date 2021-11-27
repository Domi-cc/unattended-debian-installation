#!/bin/bash

#TODO: change script to use die constants instead hardcoded values

FILEOUT=debian-unattended.iso
FILEIN=debian.cfg

if [ -f "$FILEOUT" ]; then
    echo "$FILEOUT already exists."
    exit 1;
fi

# Skript zur automatischen Erstellung der preseeded Iso mit debian

./downloadiso.sh

mkdir tempOrdnerPreseed
bsdtar -C tempOrdnerPreseed -xf debian.iso
# preseed anhängen
chmod +w -R tempOrdnerPreseed/install.amd/
gunzip tempOrdnerPreseed/install.amd/initrd.gz
echo preseed.cfg | cpio -H newc -o -A -F tempOrdnerPreseed/install.amd/initrd
gzip tempOrdnerPreseed/install.amd/initrd
chmod -w -R tempOrdnerPreseed/install.amd/
# md5sum fix
cd tempOrdnerPreseed
chmod +w md5sum.txt
md5sum `find -follow -type f` > md5sum.txt
chmod -w md5sum.txt
cd ..
# Neue Iso erstellen; hat bei mir nicht ohne root Rechte funktioniert
sudo genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
            -no-emul-boot -boot-load-size 4 -boot-info-table \
            -o debian-unattended.iso tempOrdnerPreseed
# Aufräumen
chmod +w -R tempOrdnerPreseed/
rm -r tempOrdnerPreseed