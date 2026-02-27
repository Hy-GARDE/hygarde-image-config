# HyGARDE image config

This repo stores files needed for the Hummingboard to work according to
HyGARDE's requirements.

## Changes

The following configuration is applied regarding the modem's serial
ports:

- `/dev/ttyUSB2` is used by ModemManager for managing cellular access
  and cannot be used by anything else.
- `/dev/ttyUSB3` is free and can be used to manually send AT commands
  to the Hummingboard's SIM.

A repository containing PostgreSQL 15 is added to circumvent a bug on
the default PostgreSQL version of redpesk Batz 2.0.

A few systemd units associate all processes to CPU cores 0, 1 and 3
while the helloworld-binding runs on core 2.

## Setup cellular connection

After flashing an image on the board, a few steps are required for the
4G internet access to work.

Make sure you have inserted a valid SIM card (of which you know the PIN
code if there is any) and an appropriate antenna is plugged to the main
port of the modem. You also need to know your carrier's APN.

This command is an all-in-one which creates a GSM connection associated
to the modem and automatically set it up, even after a reboot:

```shell
[root@localhost ~]# nmcli connection add type gsm ifname ttyUSB2 autoconnect yes con-name quectel-lte apn <CARRIER APN> gsm.pin <SIM PIN>
Connection 'quectel-lte' (c8e809bb-1d68-4451-bd6e-d2b5e9a884cc) successfully added.
```

> `nmcli connection` can be shortened to `nmcli conn`, as can be most
> `nmcli` commands.

Informations about the modem (mainly signal quality) can be shown:

```shell
[root@localhost ~]# mmcli -m 1
...
  --------------------------------
  Status   |       unlock retries: sim-pin (3), sim-puk (10), sim-pin2 (3), sim-puk2 (10)
           |                state: connected
           |          power state: on
           |          access tech: umts
           |       signal quality: 0% (recent)
  --------------------------------
...
```

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
