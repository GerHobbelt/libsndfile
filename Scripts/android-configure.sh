#!/bin/bash -e

# Copyright (C) 2013-2016 Erik de Castro Lopo <erikd@mega-nerd.com>
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Neither the author nor the names of any contributors may be used
#       to endorse or promote products derived from this software without
#       specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Android NDK version number; eg r8e, r9 etc
#ANDROID_NDK_VER=r9
ANDROID_NDK_VER=25.2.9519653

# Android NDK gcc version; eg 4.7, 4.9 etc.
#ANDROID_GCC_VER=4.8

# Android API version; eg 14 (Android 4.0), 21 (Android 5.0)  etc.
ANDROID_API_VER=${ANDROID_API_VER:-14}

ANDROID_TARGET=${ANDROID_TARGET:-arm-linux-androideabi}

ANDROID_TOOLCHAIN_HOME=$HOME/Android/Sdk/ndk/

if test -z ${ANDROID_TOOLCHAIN_HOME} ; then
	echo "Environment variable ANDROID_TOOLCHAIN_HOME not defined."
	echo "This should point to the directory containing the Android NDK."
    exit 1
	fi

#-------------------------------------------------------------------------------
# No more user config beyond here.

BUILD_MACHINE=$(uname -s | tr 'A-Z' 'a-z')-$(uname -m)

function die_with {
	echo $1
	exit 1
}

#export CROSS_COMPILE=arm-linux-androideabi
export CROSS_COMPILE=

# I put all my dev stuff in here
export DEV_PREFIX=$ANDROID_TOOLCHAIN_HOME
test -d ${DEV_PREFIX} || die_with "Error : DEV_PREFIX '$DEV_PREFIX' does not exist."

# Don't forget to adjust this to your NDK path
export ANDROID_NDK=${DEV_PREFIX}/${ANDROID_NDK_VER}
test -d ${ANDROID_NDK} || die_with "Error : ANDROID_NDK '$ANDROID_NDK' does not exist."

export ANDROID_PREFIX=${ANDROID_NDK}/toolchains/llvm/prebuilt/${BUILD_MACHINE}
test -d ${ANDROID_PREFIX} || die_with "Error : ANDROID_PREFIX '$ANDROID_PREFIX' does not exist."

#export SYSROOT=${ANDROID_NDK}/platforms/android-${ANDROID_API_VER}/arch-arm
#test -d ${SYSROOT} || die_with "Error : SYSROOT '$SYSROOT' does not exist."

export CROSS_PREFIX=${ANDROID_PREFIX}/bin/${CROSS_COMPILE}
test -f ${CROSS_PREFIX}clang || die_with "Error : CROSS_PREFIX compiler '${CROSS_PREFIX}clang' does not exist."


# Non-exhaustive lists of compiler + binutils
# Depending on what you compile, you might need more binutils than that
export CPP=${CROSS_PREFIX}llvm-cpp
export AR=${CROSS_PREFIX}llvm-ar
export AS=${CROSS_PREFIX}llvm-as
export NM=${CROSS_PREFIX}llvm-nm
export CC=${CROSS_PREFIX}clang
export CXX=${CROSS_PREFIX}clang++
export LD=${CROSS_PREFIX}llvm-ld
export RANLIB=${CROSS_PREFIX}llvm-ranlib

# Don't mix up .pc files from your host and build target
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

# Set up the needed FLAGS.
export CFLAGS="${CFLAGS} -D__LF_ANDROID__ --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -I${ANDROID_PREFIX}/include"
export CXXFLAGS="${CXXFLAGS} -D__LF_ANDROID__ -fno-exceptions --sysroot=${SYSROOT} -I${SYSROOT}/usr/include -I${ANDROID_PREFIX}/include -I${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/${ANDROID_GCC_VER}/include/ -I${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/${ANDROID_GCC_VER}/libs/armeabi/include"

export CPPFLAGS="${CFLAGS}"
export LDFLAGS="${LDFLAGS} -L${SYSROOT}/usr/lib -L${ANDROID_PREFIX}/lib"

# Create a symlink to the gdbclient.
test -h gdbclient || ln -s ${ANDROID_PREFIX}/bin/arm-linux-androideabi-gdb gdbclient

./configure --host=${CROSS_COMPILE} --with-sysroot=${SYSROOT} "$@"
