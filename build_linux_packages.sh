#!/bin/bash
set -e

echo "=== Marka IDE Packaging Runner (v3.3.8) ==="

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

# 3. Package AppImage (Optional Fallback)
echo "Packaging AppImage..."
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
  curl -L -o ./appimagetool-x86_64.AppImage https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage || true
  chmod +x ./appimagetool-x86_64.AppImage || true
fi

if [ -f ./appimagetool-x86_64.AppImage ]; then
  echo "Extracting appimagetool..."
  ./appimagetool-x86_64.AppImage --appimage-extract || true
  if [ -d squashfs-root ]; then
    mv squashfs-root build/squashfs-root
    ./build/squashfs-root/AppRun build/AppDir build/Marka-3.3.8-x86_64.AppImage || true
    if [ -f build/Marka-3.3.8-x86_64.AppImage ]; then
      cp build/Marka-3.3.8-x86_64.AppImage dist/
      echo "AppImage created successfully at dist/Marka-3.3.8-x86_64.AppImage"
    fi
  fi
fi

# Clean temp folders
rm -rf build/AppDir
rm -rf build/rpmbuild
rm -rf build/squashfs-root

echo "=== Packaging Complete! ==="
ls -l dist/
