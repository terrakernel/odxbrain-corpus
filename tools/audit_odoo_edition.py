#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 TerraKernel Pte Ltd
# SPDX-License-Identifier: 0BSD
"""Classify Layer 1 models by Odoo edition, from module licenses (DECISIONS.md 17a).

The authoritative edition test is the DECLARING MODULE'S `__manifest__.py` license, not whether
the model appears in the community repository:

    LGPL-3 / AGPL-3   community
    OEEL-1            Odoo Enterprise Edition License
    OPL-1             Odoo Proprietary License

Why this rather than absence-from-community: absence is an inference across two different source
sets that have to be kept in step, and it cannot distinguish "Enterprise-only" from "removed in
this version". The license is a fact stated in the tree we already have, and one Enterprise
checkout answers it for every model at once. A model declared in several modules is available in
Community if ANY declaring module is community-licensed.

usage: tools/audit_odoo_edition.py <model-list> <enterprise-tree> [<enterprise-tree> ...]
       where a tree is an extracted `odoo_<ver>+e` package (it contains odoo/addons/).
"""
from __future__ import annotations

import pathlib
import re
import sys

COMMUNITY_LICENSES = {"LGPL-3", "AGPL-3"}
# Odoo's documented default when a manifest omits the key.
DEFAULT_LICENSE = "LGPL-3"


def license_of(module_dir: pathlib.Path) -> str:
    manifest = module_dir / "__manifest__.py"
    if not manifest.exists():
        return "?"
    m = re.search(r"['\"]license['\"]\s*:\s*['\"]([^'\"]+)['\"]",
                  manifest.read_text(errors="replace"))
    return m.group(1) if m else DEFAULT_LICENSE


def classify(model: str, addons: pathlib.Path) -> tuple[str, set[str]]:
    # Anchored: `comodel_name='x'` must not count, and `_inherit` alone does not declare.
    pattern = re.compile(r"^\s*_name\s*=\s*['\"]" + re.escape(model) + r"['\"]", re.M)
    licenses: set[str] = set()
    for py in addons.rglob("*.py"):
        try:
            if pattern.search(py.read_text(errors="replace")):
                licenses.add(license_of(addons / py.relative_to(addons).parts[0]))
        except OSError:
            continue
    if not licenses:
        return "absent", licenses
    if licenses & COMMUNITY_LICENSES:
        return "community", licenses
    return "enterprise", licenses


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    models = [l.strip() for l in open(sys.argv[1]) if l.strip()]
    trees = [pathlib.Path(t) for t in sys.argv[2:]]

    labels = [t.name for t in trees]
    print(f"{'model':<30}" + "".join(f"{l:>26}" for l in labels))
    print("-" * (30 + 26 * len(trees)))

    interesting = 0
    for model in models:
        row = []
        for tree in trees:
            addons = tree / "odoo" / "addons"
            if not addons.is_dir():
                addons = tree / "addons"
            verdict, lics = classify(model, addons)
            row.append(verdict if verdict != "enterprise"
                       else "ENTERPRISE(" + ",".join(sorted(lics)) + ")")
        if any(c != "community" for c in row):
            interesting += 1
            print(f"{model:<30}" + "".join(f"{c:>26}" for c in row))

    print("-" * (30 + 26 * len(trees)))
    print(f"{len(models) - interesting}/{len(models)} are community in every tree (not shown)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
