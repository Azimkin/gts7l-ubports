#!/bin/bash
# Windows host (Git Bash): hand the tablet over to WSL so heimdall/adb there see it.
#
#   tools/wsl-usb.sh            wait for Download Mode (04e8:685d) and attach it
#   tools/wsl-usb.sh any        attach whatever Samsung device is plugged in
#   tools/wsl-usb.sh detach     give it back to Windows
#
# One-time setup (elevated):
#   winget install dorssel.usbipd-win
#   usbipd policy add --effect Allow --operation AutoBind --hardware-id 04e8:685d
# Keep a WSL distro running meanwhile (e.g. `wsl -- sleep infinity` in another
# terminal): usbipd refuses to attach when no WSL 2 distribution is up.
#
# Then run heimdall inside WSL as root:
#   wsl -u root -- ~/bin/heimdall ...
# Download Mode re-enumerates after every reboot, so attach again each time.
set -euo pipefail

USBIPD="${USBIPD:-/c/Program Files/usbipd-win/usbipd.exe}"
WANT="04e8:685d"
[ "${1:-}" = "any" ] && WANT="04e8:"

busid() { "$USBIPD" list | awk -v w="$WANT" '$2 ~ "^"w {print $1; exit}'; }

if [ "${1:-}" = "detach" ]; then
    b="$(WANT=04e8: busid || true)"
    [ -n "$b" ] && "$USBIPD" detach --busid "$b"
    exit 0
fi

echo "waiting for $WANT ..."
for _ in $(seq 120); do
    b="$(busid || true)"
    [ -n "$b" ] && break
    sleep 1
done
[ -n "${b:-}" ] || { echo "device $WANT not found"; exit 1; }

"$USBIPD" attach --wsl --busid "$b"
echo "attached busid $b to WSL"
