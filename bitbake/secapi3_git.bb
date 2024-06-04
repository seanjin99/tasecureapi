#
# ============================================================================
# COMCAST C O N F I D E N T I A L AND PROPRIETARY
# ============================================================================
# This file and its contents are the intellectual property of Comcast.  It may
# not be used, copied, distributed or otherwise  disclosed in whole or in part
# without the express written permission of Comcast.
# ============================================================================
# Copyright (c) 2021 Comcast. All rights reserved.
# ============================================================================
#
SUMMARY = "Security Api3 Module"
LICENSE = "CLOSED"
DEPENDS = "openssl yajl cjson googletest ninja-native doxygen-native"

inherit cmake

SECAPI_VER="3.0"
#PR = "r${SECAPI_VER}"

# secapi
#S = "${WORKDIR}/git"
#BBCLASS += "local"

#SRC_URI = "file:///home/xjin776/rtk/6.6_secapi_x1_skyxione_2/meta-rdk-comcast-video/recipes-extended/secapi3/files/secapi3.zip"
#SRC_URI = "./files/secapi3.zip"
#SRC_URL = "git@github.com:rdkcentral/tasecureapi.git;protocol=${RDK_GIT_PROTOCOL};name=secapi3"
#SRC_URI =  "git@github.com:seanjin99/tasecureapi.git;protocol=${RDK_GIT_PROTOCOL};branch=secapi_openssl"
SRC_URI  = "https://code.rdkcentral.com/r/components/generic/tasecureapi"
#
#SRC_URI = "https://github.com/rdkcentral/tasecureapi/archive/refs/heads/main.zip"
#SRC_URI[sha256sum] = "640754bcb2a5d4509c8ead642d61e35e04188e55a7555b71cc11ea160e24abfe"
#SRC_URI[sha256sum] = "287d58c637ea2cb7730b83cd469b7bec84c4c40fea09d5e0021e0025b0f4da7c"

PV = "${RDK_RELEASE}+git"
SRCREV = "${AUTOREV}"

#do_unpack () {
#    unzip -q "${SRC_URI}" d="${WORKDIR}"
#}

INSANE_SKIP_${PN} = "dev-so"
PROVIDES += "secapi3"
RPROVIDES_${PN} += "secapi3"

CFLAGS_append = " -Wno-error=maybe-uninitialized -Wno-error=poison-system-directories"
CXXFLAGS_append = " -Wno-error=maybe-uninitialized -Wno-error=poison-system-directories "

do_install() {
    install -d ${D}${libdir}
    install -d ${D}${bindir}
    install -d ${D}${oldincludedir}

    #bbwarn "The value of WORKDIR is: ${WORKDIR}"
    #bbwarn "The value of S is: ${S}"
    #bbwarn "The value of D is: ${D}"
    install -m 0644 ${WORKDIR}/git/client/include/*.h ${D}${oldincludedir}/
    install -m 0644 ${WORKDIR}/git/../build/client/libsaclient.so.3.4.0 ${D}${libdir}/libsaclient.so.3.4.0
    ln -sf libsaclient.so.3.4.0  ${D}${libdir}/libsaclient.so
    #install -m 0755 ${WORKDIR}/git/../build/client/saclienttest ${D}${bindir}/saclienttest
}

FILES_${PN} += "${libdir}/libsaclient.so"
FILES_${PN} += "${libdir}/libsaclient.so.3.4.0"
FILES_${PN} += "${bindir}/saclienttest"
FILES_SOLIBSDEV=""
