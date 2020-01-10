#!bin/bash

# Skript zur automatischen Erstellung der preseeded Iso mit debian 10.2.0
# Downloads und Verzeichnis anlegen
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.2.0-amd64-netinst.iso
wget https://raw.githubusercontent.com/Domi-cc/unattended-debian-installation/master/preseed.cfg
mkdir tempOrdnerPreseed
bsdtar -C tempOrdnerPreseed -xf debian-10.2.0-amd64-netinst.iso
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
            -o Preseed-10.2.0-debianInstaller.iso tempOrdnerPreseed
# Aufräumen
chmod +w -R tempOrdnerPreseed/
rm -r tempOrdnerPreseed
rm preseed.cfg debian-10.2.0-amd64-netinst.iso
