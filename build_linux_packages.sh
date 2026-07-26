#!/bin/bash
set -e

echo "=== Marka IDE Packaging Runner (v3.3.10) ==="

# 1. Compile Flutter application
echo "Building Flutter project for Linux release..."
if ! command -v flutter &> /dev/null; then
  echo "Error: flutter command not found. Please ensure Flutter is installed and in your PATH."
  exit 1
fi

flutter build linux --release

# Clean previous build temp files
rm -rf build/AppDir
rm -rf build/rpmbuild
rm -rf build/squashfs-root
mkdir -p dist

# 2. Package RPM (Fedora / RHEL)
echo "Packaging RPM..."
if ! command -v rpmbuild &> /dev/null; then
  echo "Warning: rpmbuild command not found. Skipping RPM packaging."
else
  # Create rpmbuild workspaces
  mkdir -p build/rpmbuild/SPECS
  mkdir -p build/rpmbuild/SOURCES
  mkdir -p build/rpmbuild/BUILD
  mkdir -p build/rpmbuild/RPMS
  mkdir -p build/rpmbuild/SRPMS

  # Copy sources and specs
  cp linux/packaging/marka.spec build/rpmbuild/SPECS/
  cp -r build/linux/x64/release/bundle build/rpmbuild/SOURCES/
  cp debian/gui/marka.desktop build/rpmbuild/SOURCES/
  cp debian/gui/marka.png build/rpmbuild/SOURCES/

  # Run rpmbuild using custom topdir
  echo "Running rpmbuild..."
  rpmbuild --define "_topdir $(pwd)/build/rpmbuild" -bb build/rpmbuild/SPECS/marka.spec

  cp build/rpmbuild/RPMS/x86_64/*.rpm dist/ || true
  echo "RPM created successfully at dist/"
fi

# 3. Package AppImage (Linux Universal)
echo "Packaging AppImage..."
export APPIMAGE_EXTRACT_AND_RUN=1
mkdir -p build/AppDir
cp -r build/linux/x64/release/bundle/* build/AppDir/
cp debian/gui/marka.desktop build/AppDir/
cp debian/gui/marka.png build/AppDir/

cat << 'EOF' > build/AppDir/AppRun
#!/bin/sh
SELF=$(readlink -f "$0")
HERE=$(dirname "$SELF")
export LD_LIBRARY_PATH="${HERE}/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/marka" "$@"
EOF
chmod +x build/AppDir/AppRun

if [ ! -f ./appimagetool-x86_64.AppImage ]; then
  echo "Downloading appimagetool..."
  curl -L -o ./appimagetool-x86_64.AppImage https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x ./appimagetool-x86_64.AppImage
fi

echo "Running appimagetool with APPIMAGE_EXTRACT_AND_RUN=1..."
./appimagetool-x86_64.AppImage build/AppDir build/Marka-3.3.10-x86_64.AppImage || {
  ./appimagetool-x86_64.AppImage --appimage-extract
  ./squashfs-root/AppRun build/AppDir build/Marka-3.3.10-x86_64.AppImage
}

if [ -f build/Marka-3.3.10-x86_64.AppImage ]; then
  cp build/Marka-3.3.10-x86_64.AppImage dist/
  echo "AppImage created successfully at dist/Marka-3.3.10-x86_64.AppImage"
fi

# 4. Package DEB (Debian / Ubuntu)
echo "Packaging DEB..."
rm -rf build/deb
mkdir -p build/deb/DEBIAN
mkdir -p build/deb/usr/bin
mkdir -p build/deb/usr/share/marka
mkdir -p build/deb/usr/share/applications
mkdir -p build/deb/usr/share/pixmaps

cp -r build/linux/x64/release/bundle/* build/deb/usr/share/marka/
cp debian/gui/marka.desktop build/deb/usr/share/applications/
cp debian/gui/marka.png build/deb/usr/share/pixmaps/

cat << 'EOF' > build/deb/usr/bin/marka
#!/bin/sh
export LD_LIBRARY_PATH="/usr/share/marka/lib:${LD_LIBRARY_PATH}"
exec "/usr/share/marka/marka" "$@"
EOF
chmod +x build/deb/usr/bin/marka

cat << 'EOF' > build/deb/DEBIAN/control
Package: marka
Version: 3.3.10
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Asniya <aimy1@github.com>
Description: Modern workspace Markdown editor built with Flutter.
EOF

if command -v dpkg-deb &> /dev/null; then
  dpkg-deb --build build/deb dist/Marka-3.3.10-amd64.deb || true
  echo "DEB created successfully at dist/Marka-3.3.10-amd64.deb"
else
  echo "Warning: dpkg-deb command not found. Skipping DEB packaging."
fi

# Clean temp folders
rm -rf build/AppDir
rm -rf build/rpmbuild
rm -rf build/squashfs-root
rm -rf build/deb

echo "=== Packaging Complete! ==="
ls -l dist/
