# EG25 NixOS mode switching

The installed commands reproduce the upstream Mac/UTM workflow locally on
NixOS:

| Command | Result |
| --- | --- |
| `eg25-set-imei.sh` | Validate, write, persistently verify, and synchronize a new modem IMEI |
| `eg25-status.sh` | Show the connected modem, QMI/ECM interface, IP, and VoHive state |
| `eg25-to-mac.sh` | Stop VoHive, set `usbnet=1`, and connect the ECM interface through NetworkManager |
| `eg25-to-ipad.sh` | Validate ECM on NixOS, then hand the modem off to a USB-C iPad |
| `eg25-to-vohive.sh` | Disconnect ECM, set `usbnet=0`, wait for QMI, and start VoHive |

`eg25-to-mac.sh` keeps the upstream command name for compatibility. On this
machine it means "NixOS internet mode"; there is no Mac, UTM, USB passthrough,
or SSH hop.

Changing `usbnet` restarts the modem and interrupts it for roughly 10 to 30
seconds. ECM mode can consume chargeable SIM data. The mode-changing commands
request `sudo` when run as a normal user.

The ECM NetworkManager connection is named `eg25-ecm` and uses route metric 10,
matching the upstream behavior where cellular becomes an internet route.
Returning to VoHive deletes that temporary connection profile.

For a direct USB-C iPad connection, run `eg25-to-ipad.sh`. After it validates
ECM and DHCP on NixOS, unplug the modem and connect it to the iPad with a
data-capable USB-C cable. iPadOS should expose the adapter under Settings →
General → Ethernet. If the modem repeatedly disconnects or re-enumerates, use a
powered USB-C hub.

To change the modem IMEI and keep VoHive's identity anchor synchronized:

```sh
sudo eg25-set-imei.sh 490154203237518
```

The command accepts only a 15-digit IMEI with a valid Luhn check digit. It
backs up `config.yaml`, verifies the immediate AT readback, reboots the modem,
verifies the persistent value, and restores VoHive only if it was running
before the operation. IMEI modification may be restricted by local law,
carrier policy, firmware, or warranty terms.
