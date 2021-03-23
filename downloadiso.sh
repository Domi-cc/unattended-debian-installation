#!/bin/bash

isoname=$(curl -s https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/ | egrep -io "(debian-[0-9]{2}\.[0-9]\.[0-9]-amd64-netinst\.iso)" | head -n 1)


url="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/$isoname"

# -L for follow redirects
curl -L $url --output debian.iso



