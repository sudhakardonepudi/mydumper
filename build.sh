#!/bin/sh
#
# This script builds RPM and DEB package for mydumper.
# To compile binaries look at https://github.com/mydumper/mydumper_builder
# Requirements: yum install rpm-build dpkg dpkg-devel fakeroot

SOURCE=/tmp/src/mydumper
TARGET=/tmp/package/
WORK_DIR=/tmp/pkgbuild-`date +%s`
EXTRA_SUFFIX=""
set -e

PROJECT=mydumper
WORKSPACE=$(dirname "$(readlink -f "$0")")

if [ "$#" = 2 ]; then
    VERSION=$1
    RELEASE=$2
else
    echo "USAGE: sh build.sh <version> <revision>"
    exit 1
fi

REALVERSION=${VERSION}

build_rpm() {
    ARCH=x86_64
    SUBDIR=$1
    DISTRO=$2
    EXTRA_SUFFIX=$3

    mkdir -p $WORK_DIR/{BUILD,BUILDROOT,RPMS,SOURCES,SRPMS} $WORK_DIR/SOURCES/$PROJECT-$VERSION $TARGET
    ls $SOURCE/$SUBDIR/*
    cp -r $SOURCE/$SUBDIR/* $WORK_DIR/SOURCES/$PROJECT-$VERSION
    cd $WORK_DIR/SOURCES
    tar czf $PROJECT-$VERSION${EXTRA_SUFFIX}.tar.gz $PROJECT-$VERSION/
    cd ..
    if [ -z "$EXTRA_SUFFIX"  ]
    then
    rpmbuild -ba $WORKSPACE/rpm/${PROJECT}$EXTRA_SUFFIX.spec \
             --define "_topdir $WORK_DIR" \
             --define "version $VERSION" \
             --define "release $RELEASE" \
             --define "distro $DISTRO"
         else
    rpmbuild -ba $WORKSPACE/rpm/${PROJECT}$EXTRA_SUFFIX.spec \
             --define "_topdir $WORK_DIR" \
             --define "version $VERSION" \
             --define "extra_suffix ${EXTRA_SUFFIX}" \
             --define "release $RELEASE" \
             --define "distro $DISTRO"
    fi
    PKG=$PROJECT-$VERSION-${RELEASE}${EXTRA_SUFFIX}.$DISTRO.$ARCH.rpm
    mv RPMS/$PKG $TARGET

    rpm -qpil --requires $TARGET/$PKG
    echo
    echo "RPM done: $TARGET/$PKG"
    echo
    rm -rf $WORK_DIR
}

build_deb() {
    ARCH=amd64
    SUBDIR=$1
    DISTRO=$2
    EXTRA_SUFFIX=$3
    mkdir -p $WORK_DIR/${PROJECT}_${VERSION}/DEBIAN $TARGET
    cd $WORK_DIR
    cp $WORKSPACE/deb/copyright $WORKSPACE/deb/files $WORKSPACE/deb/rules $WORK_DIR/${PROJECT}_$VERSION/DEBIAN/
    if [ -z "$EXTRA_SUFFIX"  ]
    then
            cp $WORKSPACE/deb/control $WORK_DIR/${PROJECT}_$VERSION/DEBIAN/
    else
            cp $WORKSPACE/deb/control${EXTRA_SUFFIX} $WORK_DIR/${PROJECT}_$VERSION/DEBIAN/control
    fi

    sed -i "s/%{version}/$VERSION-$RELEASE/" $WORK_DIR/${PROJECT}_$VERSION/DEBIAN/control
    sed -i "s/%{distro}/$DISTRO/" $WORK_DIR/${PROJECT}_$VERSION/DEBIAN/control
    $WORKSPACE/deb/files $SOURCE/$SUBDIR $WORK_DIR/${PROJECT}_$VERSION

    fakeroot dpkg-deb -Zxz --build ${PROJECT}_$VERSION
    PKG=${PROJECT}_$REALVERSION-${RELEASE}${EXTRA_SUFFIX}~${DISTRO}_${ARCH}.deb
    mv ${PROJECT}_$VERSION.deb $TARGET/$PKG

    echo
    dpkg -I $TARGET/$PKG
    dpkg -c $TARGET/$PKG
    echo
    echo "DEB done: $TARGET/$PKG"
    echo
#    rm -rf $WORK_DIR
}


for i in $(find /tmp/src/mydumper/*percona_57* -type d -printf '%f\n' | egrep "el7|stream8|el8" ) ; do
        echo $i
        build_rpm $i $(echo $i | cut -d'_' -f1) $(echo $i | grep zstd | cut -d'_' -f4 | awk '{print "-"$1}')
done
for i in $(find /tmp/src/mydumper/*mysql_80* -type d -printf '%f\n' | egrep "el9" ) ; do
        echo $i
        build_rpm $i $(echo $i | cut -d'_' -f1) $(echo $i | grep zstd | cut -d'_' -f4 | awk '{print "-"$1}')
done
for i in $(find /tmp/src/mydumper/*percona_57* -type d -printf '%f\n' | egrep -v "el7|stream8|el8" ) ; do
        echo $i
        build_deb $i $(echo $i | cut -d'_' -f1) $(echo $i | grep zstd | cut -d'_' -f4 | awk '{print "-"$1}')
done
for i in $(find /tmp/src/mydumper/*percona_80*zstd -type d -printf '%f\n' | egrep "bullseye" ) ; do
        echo $i
        build_deb $i $(echo $i | cut -d'_' -f1) $(echo $i | grep zstd | cut -d'_' -f4 | awk '{print "-"$1}')
done
for i in $(find /tmp/src/mydumper/*percona_80*gzip -type d -printf '%f\n' | egrep "bullseye" ) ; do
        echo $i
        build_deb $i $(echo $i | cut -d'_' -f1) $(echo $i | grep zstd | cut -d'_' -f4 | awk '{print "-"$1}')
done

for i in $(find /tmp/src/mydumper/*mysql_80*zstd -type d -printf '%f\n' | egrep "jammy" ) ; do
        echo $i
        build_deb $i $(echo $i | cut -d'_' -f1) $(echo $i | grep zstd | cut -d'_' -f4 | awk '{print "-"$1}')
done
for i in $(find /tmp/src/mydumper/*mysql_80*gzip -type d -printf '%f\n' | egrep "jammy" ) ; do
        echo $i
        build_deb $i $(echo $i | cut -d'_' -f1) $(echo $i | grep zstd | cut -d'_' -f4 | awk '{print "-"$1}')
done