#!/bin/sh
# Padring experiment: build the modified 0p5x1 ring (second core vdd/vss pair
# in place of bidir[43:42]) with the 3.3 V library set, inside the same pinned
# IIC-OSIC-TOOLS container used by the asic_rd project.
#
# Usage: ./run-experiment.sh [build|precheck]
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

EDA_IMAGE='docker.io/hpretl/iic-osic-tools:2026.07@sha256:5d6adf1f437cd0f2f8f8614488ec3c247ba8c768f4663a25d5e997b30ccb13b0'

if command -v docker >/dev/null 2>&1; then
    DOCKER_CLI=$(command -v docker)
elif [ -x /Applications/Docker.app/Contents/Resources/bin/docker ]; then
    DOCKER_CLI=/Applications/Docker.app/Contents/Resources/bin/docker
else
    printf '%s\n' 'Docker CLI was not found.' >&2
    exit 1
fi

step=${1:-build}

case "$step" in
build)
    "$DOCKER_CLI" run --rm --entrypoint /bin/bash \
        -v "$script_dir:/foss/designs/padring-experiment:rw" \
        "$EDA_IMAGE" -lc '
            set -euo pipefail
            cd /foss/designs/padring-experiment
            # The container login shell exports PDK=ihp-sg13g2, which would
            # override the Makefile default; pass PDK explicitly.
            make clone-pdk PDK=gf180mcuD \
                PDK_ROOT=/foss/designs/padring-experiment/gf180mcu
            make librelane-padring PDK=gf180mcuD \
                PDK_ROOT=/foss/designs/padring-experiment/gf180mcu \
                SLOT=0p5x1 \
                SCL=gf180mcu_as_sc_mcu7t3v3 \
                PAD=gf180mcu_ocd_io \
                SRAM=gf180mcu_ocd_ip_sram
        '
    ;;
precheck)
    if [ ! -d "$script_dir/gf180mcu-precheck" ]; then
        git clone https://github.com/wafer-space/gf180mcu-precheck.git \
            "$script_dir/gf180mcu-precheck"
    fi
    gds=$(ls -t "$script_dir"/librelane/runs/*/final/gds/chip_top.gds 2>/dev/null | head -1 || true)
    if [ -z "$gds" ]; then
        gds=$(ls -t "$script_dir"/librelane/runs/*/*-klayout-streamout/chip_top.gds 2>/dev/null | head -1 || true)
    fi
    if [ -z "$gds" ]; then
        printf '%s\n' 'No chip_top.gds found; run ./run-experiment.sh build first.' >&2
        exit 1
    fi
    gds_rel=${gds#"$script_dir"/}
    "$DOCKER_CLI" run --rm --entrypoint /bin/bash \
        -v "$script_dir:/foss/designs/padring-experiment:rw" \
        "$EDA_IMAGE" -lc "
            set -euo pipefail
            cd /foss/designs/padring-experiment/gf180mcu-precheck
            mkdir -p /foss/designs/padring-experiment/precheck-out
            PDK_ROOT=/foss/designs/padring-experiment/gf180mcu PDK=gf180mcuD \
            python3 precheck.py --slot 0p5x1 --cob \
                --input \"/foss/designs/padring-experiment/$gds_rel\" \
                --output /foss/designs/padring-experiment/precheck-out/chip_top.precheck.gds
        "
    ;;
*)
    printf 'Unknown step: %s (use build or precheck)\n' "$step" >&2
    exit 1
    ;;
esac
