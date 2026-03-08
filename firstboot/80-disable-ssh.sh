#!/usr/bin/env sh

# disable ssh in production (note: we cannot use systemctl disable while install RPM during image build)

#sed -i 's/#?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl disable --now sshd
