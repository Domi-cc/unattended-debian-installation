# Unattended Debian Installation via Preseed

Erstellt bootbare Debian-ISOs die vollautomatisch installieren — ohne Benutzerinteraktion.

## Features

- Unterstuetzt Debian 13 und Testing (via Parameter)
- Vollstaendig unattended (kein User-Input noetig)
- Root-Passwort: `unattended`
- Hostname: `deb-YYYYMMDD-HHMM` (automatisch generiert bei Installation)
- IP via DHCP
- SSH-Server aktiviert (Root-Login mit Passwort)
- LVM-Partitionierung auf der ersten erkannten Festplatte
- UEFI + BIOS hybrid Boot (wenn moeglich)

## Voraussetzungen

```bash
apt install libarchive-tools cpio xorriso isolinux genisoimage curl
```

Fallback auf `genisoimage` (nur BIOS) wenn kein UEFI-Image im ISO vorhanden.

## Nutzung

```bash
# Debian 13 (Standard)
./autoPreseed.sh 13

# Debian Testing (weekly build)
./autoPreseed.sh testing

# Nur ISO herunterladen
./downloadiso.sh 13
```

Die erstellte ISO-Datei heisst `debian-<version>-unattended.iso`.

## Was wird automatisiert?

1. Sprache: American English, Land: Deutschland, Tastatur: deutsch
2. Netzwerk: DHCP auf dem ersten Interface
3. Mirror: deb.debian.org
4. Partitionierung: LVM auf der ersten erkannten Festplatte, alles in einer Partition
5. Zeitzone: Europe/Berlin (UTC)
6. Pakete: standard + ssh-server, openssh-server, vim, htop, curl, wget
7. Bootloader: GRUB auf der Boot-Festplatte
8. Root-SSH mit Passwort aktiviert
9. Kein normaler Benutzer angelegt (nur root)
