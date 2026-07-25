Name:           marka
Version:        3.3.8
Release:        1%{?dist}
Summary:        Modern workspace Markdown editor.
License:        MIT
URL:            https://github.com/aimy1/Marka

# Disable debuginfo packages
%define debug_package %{nil}

%description
Marka is a modern, high-performance Markdown IDE built with Flutter.

%install
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/marka
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/pixmaps

# Copy Flutter bundle contents (executable, lib, data)
cp -r %{_sourcedir}/bundle/* %{buildroot}/usr/share/marka/

# Create entrypoint launcher script
cat << 'EOF' > %{buildroot}/usr/bin/marka
#!/bin/sh
export LD_LIBRARY_PATH="/usr/share/marka/lib:${LD_LIBRARY_PATH}"
exec "/usr/share/marka/marka" "$@"
EOF
chmod +x %{buildroot}/usr/bin/marka

# Copy desktop file and icon
cp %{_sourcedir}/marka.desktop %{buildroot}/usr/share/applications/
cp %{_sourcedir}/marka.png %{buildroot}/usr/share/pixmaps/

%files
/usr/bin/marka
/usr/share/marka/
/usr/share/applications/marka.desktop
/usr/share/pixmaps/marka.png

%changelog
* Thu Jul 16 2026 Asniya <aimy1@github.com> - 3.3.8-1
- Package Marka IDE v3.3.8
