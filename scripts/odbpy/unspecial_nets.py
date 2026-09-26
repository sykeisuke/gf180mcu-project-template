# Make selected analog pad nets routable by the signal router.
#
# The pad ring marks every net attached to a bond-pad terminal (BTerm) as
# SPECIAL. For digital pads this is harmless (the pad's core-side pin is a
# different net), but an analog pad's ASIG5V pin *is* the bond pad, so a net
# from that pad to an analog macro pin is never routed and LVS fails.
#
# For each matched net this script (1) moves the chip-level BTerm (the
# 120 um bond-pad terminal, which the detailed router cannot access) onto a
# new special net "<name>_pad" and (2) clears SPECIAL on the original net,
# which then holds only the pad's ASIG5V pin and the macro pin(s). In the
# extracted layout the terminal and the pad pin are the same metal, so LVS
# still sees one net.
import re
import odb
from reader import click_odb, click


@click.command()
@click.option("--net", "patterns", multiple=True, help="regex matched against full net names")
@click_odb
def unspecial(reader, patterns):
    pats = [re.compile(p) for p in patterns]
    n = 0
    for net in list(reader.block.getNets()):
        name = net.getName()
        if not (net.isSpecial() and any(p.fullmatch(name) for p in pats)):
            continue
        bterms = list(net.getBTerms())
        if bterms:
            pad_net = odb.dbNet.create(reader.block, f"{name}_pad", True)
            pad_net.setSpecial()
            for bt in bterms:
                bt.disconnect()
                bt.connect(pad_net)
        net.clearSpecial()
        n += 1
        print(f"[INFO] net {name}: {len(bterms)} bond-pad terminal(s) moved to {name}_pad; "
              f"{len(net.getITerms())} instance pins left on the routable net")
    print(f"[INFO] {n} nets made routable")


if __name__ == "__main__":
    unspecial()
