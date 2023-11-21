# 
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.32
# 

Name:       harbour-timeline

# >> macros
# << macros
%define __provides_exclude_from ^%{_datadir}/.*$

Summary:    ImgOrganizer
Version:    0.6
Release:    5
Group:      Qt/Qt
License:    GPL v3
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.bz2
Source100:  harbour-timeline.yaml
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   pyotherside-qml-plugin-python3-qt5
Requires:   sailfish-version >= 4.2
Requires:   python3-imaging
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils

%description
Show images on your device in chronological order and sort in albums.


%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qmake5 

make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%attr(644,root,root) %{_datadir}/%{name}/qml/py/timelinex.py
%attr(644,root,root) %{_datadir}/%{name}/qml/py/iptcinfo3.py
%attr(755,root,root) %{_datadir}/%{name}/qml/py/piexif/
# >> files
# << files
