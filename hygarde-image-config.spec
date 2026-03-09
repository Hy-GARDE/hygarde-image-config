Name: hygarde-image-config
Version: 1.2.4
Release: 0%{?dist}
Summary: HyGARDE Hummingboard configuration

License: GPL-v3
URL: https://github.com/Hy-GARDE/hygarde-image-config
BuildArch: noarch

BuildRequires: systemd-rpm-macros

Requires: firewalld
%{?systemd_requires}

Source0: %{name}-%{version}.tar.gz

%description
Files needed for the Hummingboard to work according to HyGARDE's requirements

%prep
%autosetup

%build

%install
install -D -m 0644 systemd/afm-appli-helloworld-binding--main@.service.d/realtime.conf -t %{buildroot}%{_unitdir}/afm-appli-helloworld-binding--main@.service.d/
install -D -m 0644 systemd/init.scope.d/realtime.conf -t %{buildroot}%{_unitdir}/init.scope.d/
install -D -m 0644 systemd/system.slice.d/realtime.conf -t %{buildroot}%{_unitdir}/system.slice.d/
install -D -m 0644 systemd/user.slice.d/realtime.conf -t %{buildroot}%{_unitdir}/user.slice.d/
install -m 0644 systemd/realtime.slice %{buildroot}%{_unitdir}
install -m 0644 systemd/var-tmp.mount %{buildroot}%{_unitdir}
install -m 0644 systemd/fsverity-cert.service %{buildroot}%{_unitdir}
install -D -m 0644 firewalld/* -t %{buildroot}%{_sysconfdir}/firewalld/zones/
install -D -m 0755 firstboot/50-postgres.sh -t %{buildroot}%{_sharedstatedir}/rp-firstboot/
install -D -m 0755 firstboot/80-disable-ssh.sh -t %{buildroot}%{_sharedstatedir}/rp-firstboot/
install -D -m 0755 firstboot/90-fsverity-config.sh -t %{buildroot}%{_sharedstatedir}/rp-firstboot/

%files
%{_unitdir}/afm-appli-helloworld-binding--main@.service.d/realtime.conf
%{_unitdir}/init.scope.d/realtime.conf
%{_unitdir}/system.slice.d/realtime.conf
%{_unitdir}/user.slice.d/realtime.conf
%{_unitdir}/realtime.slice
%{_unitdir}/var-tmp.mount
%{_unitdir}/fsverity-cert.service
%{_sysconfdir}/firewalld/zones/hygarde-{w,l}an.xml
%{_sharedstatedir}/rp-firstboot/50-postgres.sh
%{_sharedstatedir}/rp-firstboot/80-disable-ssh.sh
%{_sharedstatedir}/rp-firstboot/90-fsverity-config.sh

%post
firewall-cmd --reload || true

%postun
firewall-cmd --reload || true

%changelog
* Mon Mar 9 2026 Valentin Geffroy <valentin.geffroy@iot.bzh> - 1.2.4
- Add systemd unit to load fsverity cert

* Mon Mar 9 2026 Sebastien Douheret <sebastien.douheret@iot.bzh > - 1.2.3
- Disable ssh as root

* Fri Mar 6 2026 Louis-Baptiste Sobolewski <lb.sobolewski@iot.bzh> - 1.2.2
- Add PostgreSQL firstboot script

* Thu Mar 5 2026 Valentin Geffroy <valentin.geffroy@iot.bzh> - 1.2.1
- Add fsverity firstboot systemd script

* Fri Feb 27 2026 Louis-Baptiste Sobolewski <lb.sobolewski@iot.bzh> - 1.2.0
- Add firewalld zones config
- Remove udev rule for ModemManager
- Mount /var/tmp as tmpfs
- Remove PostgreSQL 15 repository
- Rename package to hygarde-image-config

* Mon Dec 16 2024 Louis-Baptiste Sobolewski <lb.sobolewski@iot.bzh> - 1.1.0
- Add PostgreSQL 15 repository
- Add systemd configuration to isolate CPU core 2

* Tue Jan 9 2024 Louis-Baptiste Sobolewski <lb.sobolewski@iot.bzh> - 1.0.0-7.hygarde.hummingboard_5a46cd3a.rpbatz
- Initial release
- Add udev rule to keep one ttyUSB from being used by ModemManager
