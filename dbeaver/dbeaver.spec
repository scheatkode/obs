#
# spec file for package spec dbeaver
#
# Copyright (c) spec 2023 SUSE LLC
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#


Name:           dbeaver
Version:        23.1.0
Release:        0
Summary:        Universal Database Manager
License:        Apache-2.0
Group:          Productivity/Databases/Clients
URL:            https://dbeaver.io
Source0:        https://github.com/%{name}/%{name}/releases/download/%{version}/%{name}-ce-%{version}-linux.gtk.x86_64.tar.gz
BuildRequires:  fastjar
BuildRequires:  fdupes
BuildRequires:  update-desktop-files
Requires:       java >= 17
ExclusiveArch:  %{ix86} x86_64

%description
Free multi-platform database tool for developers, database administrators,
analysts and all people who need to work with databases. Supports all popular
databases: MySQL, PostgreSQL, SQLite, Oracle, DB2, SQL Server, Sybase, MS
Access, Teradata, Firebird, Apache Hive, Phoenix, Presto, etc.

%prep
%setup -q -T -b0 -n %{name}
rm -Rf jre
rm -Rf p2/org.eclipse.equinox.p2.engine/profileRegistry/DefaultProfile.profile/.lock

%build

%install
install -d %{buildroot}/%{_bindir}
install -d %{buildroot}/%{_datadir}
install -d %{buildroot}/%{_datadir}/%{name}-ce
install -d %{buildroot}/%{_datadir}/applications/
install -d %{buildroot}/%{_datadir}/pixmaps/
cp -R * %{buildroot}/%{_datadir}/%{name}-ce
install -m 0644 icon.xpm %{buildroot}/%{_datadir}/pixmaps/dbeaver.xpm
install -m 0755 dbeaver-ce.desktop %{buildroot}/%{_datadir}/applications/
ln -sf %{_datadir}/%{name}-ce/dbeaver %{buildroot}/%{_bindir}/dbeaver
%suse_update_desktop_file -i dbeaver-ce Development Building
%fdupes %{buildroot}%{_datadir}

%files
%dir %{_datadir}/dbeaver-ce
%{_bindir}/dbeaver
%{_datadir}/dbeaver-ce/*
%config(noreplace) %{_datadir}/dbeaver-ce/dbeaver.ini
%{_datadir}/pixmaps/dbeaver.xpm
%{_datadir}/applications/dbeaver-ce.desktop

%changelog

