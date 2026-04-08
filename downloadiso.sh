#!/bin/bash
set -euo pipefail

VERSION="${1:-13}"

find_iso_name() {
    local url="$1" pattern="$2"
    local page iso_name
    page=$(curl -sL "$url/") || { echo "Fehler: Seite $url nicht erreichbar" >&2; return 1; }
    iso_name=$(echo "$page" | grep -oP "$pattern" | head -n1) || true
    echo "$iso_name"
}

case "$VERSION" in
    13)
        BASE_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd"
        ISO_NAME=$(find_iso_name "$BASE_URL" "debian-13\.[0-9]+\.[0-9]+-amd64-netinst\.iso")
        if [ -z "$ISO_NAME" ]; then
            echo "Fehler: Konnte Debian 13 ISO nicht finden." >&2
            exit 1
        fi
        # Vollversion extrahieren (z.B. 13.4.0)
        FULL_VERSION=$(echo "$ISO_NAME" | grep -oP "13\.[0-9]+\.[0-9]+")
        OUTFILE="debian-${FULL_VERSION}-netinst.iso"
        URL="${BASE_URL}/${ISO_NAME}"
        ;;
    testing)
        BASE_URL="https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd"
        ISO_NAME="debian-testing-amd64-netinst.iso"
        OUTFILE="debian-testing-$(date +%Y%m%d)-netinst.iso"
        URL="${BASE_URL}/${ISO_NAME}"
        ;;
    *)
        echo "Unterstuetzte Versionen: 13, testing" >&2
        exit 1
        ;;
esac

if [ -f "$OUTFILE" ]; then
    echo "$OUTFILE existiert bereits." >&2
    echo "$OUTFILE"
    exit 0
fi

echo "Lade $URL herunter..." >&2
curl -fL "$URL" --output "$OUTFILE"
echo "Gespeichert als $OUTFILE" >&2

# Dateiname auf stdout fuer autoPreseed.sh
echo "$OUTFILE"
