#!/bin/sh

# ---------------------------------------------------------------
# Hustler's Project
# ---------------------------------------------------------------

KPATH=""
TLPATH=""
CMD=""

usage() {
printf "
KERNEL                                       BUILDING SCRIPT 2024
-----------------------------------------------------------------
usage:                          ./cook.sh [options]

options:
    -h                          help information
    -p [path-to-kernel]         path to target kernel source code
    -t [path-to-toolchain]      absolute path of the toolchain
    -c [cmds]

cmds:
    build                       build the target kernel
    clean                       clean built kernel objects
    cleanall                    remove output directory
    config                      kernel menuconfig
    mrproper                    remove previous configuration
    tags                        tags for better code read
                                experience
-----------------------------------------------------------------

"
}

envset() {
    Host=$(uname -m)

    if [ "$Host" = "x86_64" ];then
        export CROSS_COMPILE=$TLPATH
        echo "[cook] Toolchain: $CROSS_COMPILE"
        export ARCH=arm64
    fi

    echo -n '[cook] Host machine: ' && echo $Host
}

remove_prev_config() {
    start=$(date +%s%N)
    make mrproper
    end=$(date +%s%N)
    echo ""
    echo "[cook] mrproper took $(($(($end-$start))/1000000)) mins"
}

clean_built_objects() {
    start=$(date +%s)
    make -j$(nproc) clean O=out/  && rm -rf out
    end=$(date +%s)
    total=$(($end-$start))
    echo ""
    echo "[cook] Done cleaning in $(($total/60)) mins $(($total%60)) secs"
}


build_kernel() {
    start=$(date +%s)
    make -j$(nproc) O=out/
    end=$(date +%s)
    total=$(($end-$start))
    echo ""
    echo "[cook] Done compiling kernel in $(($total/60)) mins $(($total%60)) secs"
}

kernel_track_tags() {
    start=$(date +%s)
    if [ ! -f "/usr/bin/ctags" ];then
        echo "[cook] ctags ain't installed yet, [sudo] apt install universal-ctags"
        TAGS=
    else
        TAGS=tags
    fi

    make -j$(nproc) $TAGS
    end=$(date +%s)
    total=$(($end-$start))
    echo ""
    echo "[cook] Done generating tags in $(($total/60)) mins $(($total%60)) secs"
}

kernel_menuconfig() {
    make menuconfig

    if [ -d "out" ];then
        mv .config out/
    else
        mkdir out
        mv .config out/
    fi
}

# TODO
kernel_on_qemu() {
    echo "[cook] Booting the Kernel with QEMU"
}

build() {
    if [ -z $KPATH ];then
        echo "[cook] Kernel path must needed (./kernel.sh -h for more information)"
        exit
    fi

    if [ ! -d "$KPATH/kernel" ];then
        echo "[cook] Invalid kernel path, make sure the target is kernel source"
        exit
    fi

    if [ -z $CMD ];then
        usage
        exit
    fi

    envset
    cd $KPATH

    case $CMD in
        build)
            build_kernel
            ;;
        config)
            kernel_menuconfig
            ;;
        tags)
            kernel_track_tags
            ;;
        clean)
            clean_built_objects
            ;;
        mrproper)
            remove_prev_config
            ;;
        qemu)
            kernel_on_qemu
            ;;
        *)
            usage
            exit
            ;;
    esac
}

while getopts 'p:c:t:h' OPT;do
    case $OPT in
        'h'| "--help")
            usage
            exit
            ;;
        'p' | "--path")
            KPATH="$OPTARG"
            ;;
        'c' | "--config")
            CMD="$OPTARG"
            ;;
        't' | "--toolchain")
            TLPATH="$OPTARG"
            ;;
        *)
            usage
            exit
            ;;
    esac
done

build
