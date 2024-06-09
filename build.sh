#!/bin/bash
#
# Copyright (C) 2024 Affe Null <affenull2345@gmail.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the <organization> nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

need_repo () {
    repo=$1
    shift
    if ! [ -d "$repo/.git" ]; then
        mkdir -p "$repo"
        git clone --recurse-submodules "$@" "$repo"
    fi
}

if [ -z "$DEVICE" ]; then
    DEVICE=sparkler
fi
if [ -z "$RELEASE" ]; then
    RELEASE=4.6.0.11
fi

need_repo packages/community-adaptation https://github.com/mer-hybris/community-adaptation.git

source ./config-$DEVICE.sh

LOCAL_REPO="$PWD/local-repos/$DEVICE-$ARCH"
mkdir -p "$LOCAL_REPO/repo"

build () {
    local specfile=${2:-rpm/$1.spec}
    pushd packages/$1 >/dev/null
    mb2 -s $specfile -t $VENDOR-$DEVICE-$ARCH --output-dir "$LOCAL_REPO" build --no-check
    exit_status=$?
    popd >/dev/null
    if [ "$exit_status" != 0 ]; then
        echo "*** Build failed for $1 ***" >&2
        exit 1
    fi
    echo "*** Build successful for $1 ***" >&2
}

build_kernel () {
    pushd packages/$KERNEL_PACKAGE_DIR >/dev/null
    mb2 -s rpm/$KERNEL_PACKAGE.spec -t native --output-dir "$LOCAL_REPO" build --no-check
    exit_status=$?
    popd >/dev/null
    if [ "$exit_status" != 0 ]; then
        echo "*** Build failed for $KERNEL_PACKAGE ***" >&2
        exit 1
    fi
    echo "*** Build successful for $KERNEL_PACKAGE ***" >&2
}

BUILD_MW=

for pkg in "$@"; do
    case "$pkg" in
        community-adaptation)   BUILD_COMMUNITY_ADAPTATION=1 ;;
        configs)                BUILD_CONFIGS=1 ;;
        kernel)                 BUILD_KERNEL=1 ;;
        image)                  BUILD_IMAGE=1 ;;
        bootimg)                BUILD_BOOTIMG=1 ;;
        mw)                     BUILD_MW=$DEFAULT_MW ;;
        all)
            BUILD_COMMUNITY_ADAPTATION=1
            BUILD_MW=$DEFAULT_MW
            BUILD_CONFIGS=1
            BUILD_KERNEL=1
            BUILD_BOOTIMG=1
            BUILD_IMAGE=1
            ;;
        *)
            if [ -d "packages/$pkg" ]; then
                BUILD_MW="$BUILD_MW $pkg"
            else
                echo "*** Unknown package $pkg ***" >&2
            fi
            ;;
    esac
done

if [ "$BUILD_COMMUNITY_ADAPTATION" = 1 ]; then
    echo "*** Building community-adaptation ***" >&2
    build community-adaptation rpm/community-adaptation-localbuild.spec
fi

for mw in $BUILD_MW; do
    echo "*** Building $mw ***" >&2
    build $mw
done

if [ "$BUILD_CONFIGS" = 1 ]; then
    echo "*** Building configs ***" >&2
    build device-configuration-$DEVICE
fi

if [ "$BUILD_KERNEL" = 1 ]; then
    echo "*** Building kernel ***" >&2
    build_kernel
fi

if [ "$BUILD_BOOTIMG" = 1 ]; then
    echo "*** Building bootimg ***" >&2
    build device-$DEVICE-img-boot
fi

if [ "$BUILD_IMAGE" = 1 ]; then
    echo "*** Building image ***" >&2
    ks="Jolla-@RELEASE@-$DEVICE-@ARCH@.ks"
    rpm=$(ls "$LOCAL_REPO"/device-configuration-$DEVICE-ssu-kickstarts-*.rpm | tail -1)
    if [ -f "$rpm" ]; then
        rpm2cpio "$rpm" | cpio -i --to-stdout --quiet ./usr/share/kickstarts/$ks >$ks
    else
        echo "Please build configs package first!" >&2
        exit 1
    fi
    community_repo="repo --name=adaptation-community-common-$DEVICE-@RELEASE@"
    device_repo="repo --name=adaptation-community-$DEVICE-@RELEASE@"
    sed -i "/$community_repo/i$device_repo --baseurl=file://$LOCAL_REPO/repo" $ks
    sed -i "/store-repository.jolla.com/d" $ks
    createrepo_c --outputdir="$LOCAL_REPO/repo" --location-prefix=../ "$LOCAL_REPO"
    tokenmap="ARCH:$ARCH,RELEASE:$RELEASE,EXTRA_NAME:$EXTRA_NAME"
    sudo mic create loop --arch=$ARCH \
        --tokenmap=$tokenmap \
        --record-pkgs=name,url \
        --outdir=out \
        --copy-kernel \
        $ks
fi
