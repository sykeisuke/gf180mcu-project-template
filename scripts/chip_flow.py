#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""LibreLane Chip flow plus one custom step for analog hard macros.

Digital-on-top with analog pads: the pad ring marks the nets on bond-pad
terminals SPECIAL. An analog pad (asig_5p0) exposes the bond pad itself as its
only pin, so a net from that pad to an analog macro pin is never routed and
LVS fails. The `Odb.UnspecialAnalogNets` step (inserted before global routing)
clears the flag on the nets listed in ANALOG_ROUTED_NETS so the router
connects them like any signal.

Usage (inside the pinned container, from the repository root):
  python3 scripts/chip_flow.py <configs...> --pdk gf180mcuD --pdk-root <root> \
      --manual-pdk --scl <scl> --pad <pad> [--tag TAG] [--last-run] [--from STEP]
"""
import os
import sys
import argparse
from typing import List, Optional

import yaml

from librelane.common import get_script_dir
from librelane.config import Variable
from librelane.flows.chip import Chip
from librelane.flows.flow import FlowError
from librelane.steps import Odb


class UnspecialAnalogNets(Odb.OdbpyStep):
    id = "Odb.UnspecialAnalogNets"
    name = "Make analog pad nets routable"

    config_vars = Odb.OdbpyStep.config_vars + [
        Variable(
            "ANALOG_ROUTED_NETS",
            Optional[List[str]],
            "Regexes of top-level nets (attached to analog pads) that the "
            "signal router must connect to macro pins.",
        ),
    ]

    def get_script_path(self):
        return os.path.join(os.path.dirname(os.path.abspath(__file__)), "odbpy", "unspecial_nets.py")

    def get_command(self) -> List[str]:
        command = super().get_command()
        for pat in self.config["ANALOG_ROUTED_NETS"] or []:
            command += ["--net", pat]
        return command


class ChipAnalog(Chip):
    # Chip.Substitutions is consumed by the flow metaclass (Chip.Steps already
    # contains the pad-ring steps); only the additional substitution is needed.
    Substitutions = {"-OpenROAD.GlobalRouting": UnspecialAnalogNets}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("configs", nargs="+")
    parser.add_argument("--pdk", required=True)
    parser.add_argument("--pdk-root", required=True)
    parser.add_argument("--manual-pdk", action="store_true")
    parser.add_argument("--scl", default=None)
    parser.add_argument("--pad", default=None)
    parser.add_argument("--tag", default=None)
    parser.add_argument("--last-run", action="store_true")
    parser.add_argument("--from", dest="frm", default=None)
    parser.add_argument("--to", dest="to", default=None)
    args = parser.parse_args()

    flow_cfg = {}
    for config in args.configs:
        flow_cfg.update(yaml.safe_load(open(config)))

    flow = ChipAnalog(
        flow_cfg,
        design_dir=os.path.join(os.path.abspath("."), "librelane"),
        pdk_root=args.pdk_root,
        pdk=args.pdk,
        scl=args.scl,
        pad=args.pad,
    )
    kwargs = {}
    if args.frm:
        kwargs["frm"] = args.frm
    if args.to:
        kwargs["to"] = args.to
    try:
        flow.start(tag=args.tag, last_run=args.last_run,
                   overwrite=bool(args.tag) and not args.last_run, **kwargs)
    except FlowError as e:
        print(f"Error:\n{e}")
        sys.exit(1)
    print("Run successfully completed.")


if __name__ == "__main__":
    main()
