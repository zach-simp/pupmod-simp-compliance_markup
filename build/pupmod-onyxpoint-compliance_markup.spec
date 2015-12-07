Summary: Additions to enable compliance annotations in Puppet code
Name: pupmod-onyxpoint-compliance_markup
Version: 0.1.0
Release: 0
License: Apache 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: puppet >= 3.8.0
Buildarch: noarch

Prefix: %{_sysconfdir}/puppet/environments/simp/modules

%description
Additions to enable compliance annotations in Puppet code

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/compliance_markup

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/compliance_markup
done

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/compliance_markup

%files
%defattr(0640,root,puppet,0750)
%{prefix}/compliance_markup

%post
#!/bin/sh

%postun
# Post uninstall stuff

%changelog
* Mon Nov 30 2015 Trevor Vaughan - 0.1.0-0
- Initial package.
