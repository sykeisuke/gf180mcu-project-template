# Comparator hard macro (asic_rd): LEF power pins are vertical Metal3 bars,
# vdd x = 4.09..4.47 and vss x = 4.85..5.23 from the macro's left edge. Two
# 0.44 um Metal4 straps centred on them (-offset is the strap centreline);
# pdngen drops Via3 where Metal4 overlaps the Metal3 bars.
define_pdn_grid -macro -instances i_chip_core.cmp0 -name cmp_macro -starts_with POWER \
    -halo "$::env(PDN_HORIZONTAL_HALO) $::env(PDN_VERTICAL_HALO)"
add_pdn_stripe -grid cmp_macro -layer Metal4 -width 0.44 -offset 4.28 -pitch 100 -spacing 0.28 \
    -starts_with POWER -number_of_straps 1
add_pdn_stripe -grid cmp_macro -layer Metal4 -width 0.44 -offset 5.04 -pitch 100 -spacing 0.28 \
    -starts_with GROUND -number_of_straps 1
add_pdn_connect -grid cmp_macro -layers "Metal4 Metal3"
add_pdn_connect -grid cmp_macro -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
