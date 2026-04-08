#!/bin/bash
set -euo pipefail

REQUIRED_CMDS=(bsdtar cpio gzip curl xorriso genisoimage)
MISSING=()
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING+=("$cmd")
    fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Fehlende Tools: ${MISSING[*]}"
    echo "Installieren mit: apt install libarchive-tools cpio xorriso isolinux genisoimage curl"
    exit 1
fi
if [ ! -f /usr/lib/ISOLINUX/isohdpfx.bin ]; then
    echo "Fehlt: /usr/lib/ISOLINUX/isohdpfx.bin"
    echo "Installieren mit: apt install isolinux"
    exit 1
fi

if [ -z "${1:-}" ]; then
    echo "Welche Debian-Version?"
    echo "  1) Debian 13 (stable)"
    echo "  2) Debian testing"
    read -rp "Auswahl [1]: " choice
    case "${choice:-1}" in
        1) VERSION="13" ;;
        2) VERSION="testing" ;;
        *) echo "Ungueltige Auswahl."; exit 1 ;;
    esac
else
    VERSION="$1"
fi
TMPDIR="tmpPreseed_$$"
cleanup() { [ -d "$TMPDIR" ] && chmod +w -R "$TMPDIR/" && rm -rf "$TMPDIR"; }
trap cleanup EXIT

# ISO herunterladen, Dateiname kommt via stdout
FILEIN=$(./downloadiso.sh "$VERSION")
FILEOUT="${FILEIN%-netinst.iso}-unattended.iso"

if [ ! -f "$FILEIN" ]; then
    echo "Fehler: $FILEIN nicht gefunden."
    exit 1
fi

if [ -f "$FILEOUT" ]; then
    echo "$FILEOUT existiert bereits."
    exit 1
fi

# ISO entpacken
mkdir "$TMPDIR"
bsdtar -C "$TMPDIR" -xf "$FILEIN"

# Boot-Config: sofort in Text-Installer mit auto-Modus booten
# Kein Menue, kein Countdown, keine Speech synthesis, kein grafischer Installer
# BIOS (isolinux)
chmod +w -R "$TMPDIR/isolinux/" 2>/dev/null || true
BOOT_PARAMS="priority=critical locale=en_US.UTF-8 keymap=de vga=788"
cat > "$TMPDIR/isolinux/isolinux.cfg" <<ISOLINUX
default install
timeout 1
label install
	kernel /install.amd/vmlinuz
	append ${BOOT_PARAMS} initrd=/install.amd/initrd.gz --- quiet
ISOLINUX
# Alle anderen Boot-Eintraege neutralisieren (Speech synthesis, GTK, etc.)
for cfg in spkgtk.cfg spk.cfg gtk.cfg txt.cfg menu.cfg; do
    : > "$TMPDIR/isolinux/$cfg"
done
# UEFI (grub)
if [ -d "$TMPDIR/boot/grub" ]; then
    chmod +w -R "$TMPDIR/boot/grub/"
    cat > "$TMPDIR/boot/grub/grub.cfg" <<GRUB
set timeout=0
set default=0
set gfxpayload=keep
insmod all_video
menuentry 'Install' {
    linux /install.amd/vmlinuz ${BOOT_PARAMS} --- quiet
    initrd /install.amd/initrd.gz
}
GRUB
fi

# Preseed in initrd einbetten
chmod +w -R "$TMPDIR/install.amd/"
gunzip "$TMPDIR/install.amd/initrd.gz"
echo preseed.cfg | cpio -H newc -o -A -F "$TMPDIR/install.amd/initrd"
gzip "$TMPDIR/install.amd/initrd"
chmod -w -R "$TMPDIR/install.amd/"

# md5sum aktualisieren
cd "$TMPDIR"
chmod +w md5sum.txt
# -follow erzeugt "File system loop detected" bei Debian-ISOs (Symlink-Loop) — ist harmlos
{ find . -follow -type f ! -name md5sum.txt -print0 2>/dev/null || true; } | xargs -0 md5sum > md5sum.txt.new
mv md5sum.txt.new md5sum.txt
chmod -w md5sum.txt
cd ..

# ISO erstellen
if [ -f "$TMPDIR/boot/grub/efi.img" ]; then
    # UEFI + BIOS hybrid
    xorriso -as mkisofs \
        -o "$FILEOUT" \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
        -c isolinux/boot.cat \
        -b isolinux/isolinux.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot -isohybrid-gpt-basdat \
        "$TMPDIR"
else
    # Nur BIOS (Fallback)
    genisoimage -r -J \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -o "$FILEOUT" "$TMPDIR"
fi

echo "Erstellt: $FILEOUT"
