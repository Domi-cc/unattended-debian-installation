# Unattended Debian installation via Preseed-Datei für den Debianinstaller

Mit diesem Verfahren wird ein Debian ISO erstellt, welches nahezu unattended installiert. Auf Wunsch kann auch das Root-PW und ein Hostname hinterlegt werden, um die Installation komplett zu automatisieren. 

Eine Preseed-Datei zum einbinden an eine Debian-Netinstaller-Iso liegt mit bei.

## Was wird automatisiert?

**Bestätigungsanfragen werden automatisch beantwortet**

1. American english ist die ausgewählte Sprache.
2. Deutschland ist ausgewähltes Land und das Tastaturlayout ist deutsch.
3. Der Downloadserver wird auf deb.debian.org gesetzt.
4. Die System-Uhr wird auf UTC gesetzt.
5. Partitionierung ist so gesetzt, dass die erste gefunde Festplatte genommen wird und eine alle Daten in 1 Partition gesetzt werden
6. Es wird das Standardpaket ohne Grafikoberfläche und das ssh-plugin installiert.
7. Bootloader wird auf der ersten gefundenen Festplatte installiert.
8. Umfragedaten werden nicht gesendet

**Es müssen noch selber ein Root-Passwort gesetzt und ein Domain-und Servername angegeben werden**

**Fehlermeldung mount unmount am Anfang der installation ignorieren!?**

## Erstellung einer Iso-Datei mit Preseed mit einem Linux-Terminal

**Hinweis:** Diese Datei wurde auf einem *amd64* System auf Basis einer *netinstall cd Stand 10.2.0* geschrieben
und es besteht keine Garantie, dass sie bei Änderungen funktioniert.

1. Von [debian.org](https://www.debian.org/CD/http-ftp/index.de.html#stable) die gewünschte Iso-Datei herunterladen.
2. *preseed.cfg* im selben Verzeichnis speichern.
3. Einen leeren Ordner im Verzeichnis erstellen. Dieser heißt zu Referenzzwecken *isofiles*.
4. Mit `bsdtar -C isofiles -xf NAMEDERISODATEI.iso` den Inhalt der Isodatei in den Ordner übertragen.
5. Die preseed Datei an die *initrd* anhängen. (Schreibrechte geben > entpacken > anhängen > packen > Schreibrechte nehmen)
```
chmod +w -R isofiles/install.amd/
gunzip isofiles/install.amd/initrd.gz
echo preseed.cfg | cpio -H newc -o -A -F isofiles/install.amd/initrd
gzip isofiles/install.amd/initrd
chmod -w -R isofiles/install.amd/
```
6. Die *md5sum.txt* aktualisieren
```
cd isofiles
chmod +w md5sum.txt
md5sum `find -follow -type f` > md5sum.txt
chmod -w md5sum.txt
cd ..
```
(Ignore warning: File system loop detected)

7. Den Ordner *isofiles* wieder in eine bootbare Iso-Datei umwandeln.
```
genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
            -no-emul-boot -boot-load-size 4 -boot-info-table \
            -o WUNSCHNAME.iso isofiles
```
8. Fertig

