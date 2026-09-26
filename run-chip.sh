#!/bin/sh
# Digital-on-top chip build: asic_rd 8-bit digital top + comparator hard macro
# inside the modified 0p5x1 ring, 3.3 V library set, in the pinned container.
# Usage: ./run-chip.sh                       (full LibreLane flow, condensed log)
#        ./run-chip.sh --last-run --from KLayout.DRC   (resume the last run at a step)
# Uses scripts/chip_flow.py (Chip flow + analog-net routing step).
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
EDA_IMAGE='docker.io/hpretl/iic-osic-tools:2026.07@sha256:5d6adf1f437cd0f2f8f8614488ec3c247ba8c768f4663a25d5e997b30ccb13b0'
DOCKER_CLI=$(command -v docker || echo /Applications/Docker.app/Contents/Resources/bin/docker)
"$DOCKER_CLI" run --rm --entrypoint /bin/bash \
    -v "$script_dir:/foss/designs/padring-experiment:rw" \
    "$EDA_IMAGE" -lc '
        set -euo pipefail
        cd /foss/designs/padring-experiment
        make defines PDK=gf180mcuD SLOT=0p5x1 SRAM=gf180mcu_ocd_ip_sram
        python3 scripts/patch_pad_libs.py gf180mcu
        # The librelane CLI wrapper prepends the LibreLane-matched OpenROAD build;
        # the Python flow needs the same (the default openroad lacks the STA "scene" API).
        export PATH=/foss/tools/openroad-librelane/bin:$PATH
        SRAM_DEFINE=SRAM_gf180mcu_ocd_ip_sram python3 scripts/chip_flow.py \
            librelane/slots/slot_0p5x1.yaml librelane/macros/macros_3v3.yaml librelane/config.yaml \
            --pdk gf180mcuD --pdk-root /foss/designs/padring-experiment/gf180mcu --manual-pdk \
            --scl gf180mcu_as_sc_mcu7t3v3 --pad gf180mcu_ocd_io '"$*"'
    '
