# HyGARDE image config

This repo stores files needed for the Hummingboard to work according to
HyGARDE's requirements.

## Changes

A few systemd units associate all processes to CPU cores 0, 1 and 3
while the helloworld-binding runs on core 2.

A mount unit sets `/var/tmp` as a tmpfs with SMACK support.

## Setup a Wifi access

```shell
[root@localhost ~]# nmcli device wifi connect <SSID> password <PASSWORD>
Device 'wlan0' successfully activated with 'c6ed38b3-a0e4-4eea-bec6-62b6fdc626db'.
[root@localhost ~]# nmcli connection down <SSID>
Connection 'IoTBZH' successfully deactivated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/4)
[root@localhost ~]# nmcli connection up <SSID>
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/5)
```

> `nmcli device` can be shortened to `nmcli dev`.

During testing, it appeared that an active Wifi connection influences
the cellular connection in a bad way (very slow pings, any other
internet access attempt failed). A temporary solution is to disable Wifi
completely:

```shell
[root@localhost ~]# nmcli radio wifi off
```
