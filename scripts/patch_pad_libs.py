#!/usr/bin/env python3
"""Copy the 3.3 V-corner pad Liberty files and add the missing ANA pin to the
gf180mcu_ocd_io__bi_a cell (the PDK Liberty omits it, so OpenROAD's linker
silently drops the ANA connection and the analog macro input floats).
Writes ip/bi_a/lib/<corner>.lib; run-chip.sh calls this before the flow.
Usage: patch_pad_libs.py <pdk_root>"""
import os
import sys

pdk_root = sys.argv[1]
src_dir = os.path.join(pdk_root, "gf180mcuD", "libs.ref", "gf180mcu_ocd_io", "lib")
dst_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ip", "bi_a", "lib")
os.makedirs(dst_dir, exist_ok=True)
PIN = '\t\tpin ("ANA") {\n\t\t\tdirection : inout;\n\t\t\tcapacitance : 0.010000;\n\t\t}\n'
for corner in ("tt_025C_3v30", "ff_n40C_3v63", "ss_125C_2v97"):
    name = f"gf180mcu_ocd_io__{corner}.lib"
    lines = open(os.path.join(src_dir, name)).read().splitlines(keepends=True)
    out, in_cell, done = [], False, False
    for line in lines:
        out.append(line)
        if 'cell ("gf180mcu_ocd_io__bi_a")' in line:
            in_cell = True
        elif in_cell and not done and line.strip().startswith("dont_touch"):
            out.append(PIN)
            done = True
    assert done, name
    open(os.path.join(dst_dir, name), "w").write("".join(out))
    print("patched", name)
