#!/bin/bash

msvc_pkgs=()

# DESIRED VERSION DEFINITIONS
VS_VER=16

get_msvc_manifest() {
    wget -O ${MANIFEST_DIR}/vsrel.json https://aka.ms/vs/${VS_VER}/release/channel || return 1
    wget -O ${MANIFEST_DIR}/vspkgs.json `jq '.channelItems[] | select(.type == "Manifest") | .payloads[0].url' ${MANIFEST_DIR}/vsrel.json -r` || return 1

    return 0
}

find_msvc_package() {
    deps=`jq ".packages[] | select(.id == \"$1\") | .dependencies | select(. != null) | keys[]" ${MANIFEST_DIR}/vspkgs.json -r` 2> /dev/null

    for dep in $deps; do
        find_msvc_package "$dep" "$2" || return 1
    done

    if [[ ! "${msvc_pkg_names[*]}" =~ "$1" ]]; then
        echo "Needs package: $1"
        msvc_pkgs+=("$1")
    fi

    return 0
}

install_msvc_package() {
    echo "Downloading $1..."

    wget -O "${MSVC_ARCHIVE_DIR}/$1.vsix" `jq ".packages[] | select(.id == \"$1\") | .payloads[0].url" ${MANIFEST_DIR}/vspkgs.json -r` || return 1

    return 0
}

install_msvc_packages() {
    for pkg in ${msvc_pkgs[@]}; do
        install_msvc_package "$pkg" || return 1
    done

    return 0
}

sys_install() {
    get_msvc_manifest || return 1

    find_msvc_package "Microsoft.VisualCpp.CRT.Headers" || return 1
    find_msvc_package "Microsoft.VisualCpp.CRT.x64.Desktop" || return 1

    install_msvc_packages || return 1

    return 0
}

sys_install
