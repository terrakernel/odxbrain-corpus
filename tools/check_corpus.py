#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 TerraKernel Pte Ltd
# SPDX-License-Identifier: 0BSD
"""Structural checks on the corpus. No embedder, no network: what a contributor can run locally.

    - models.txt and descriptions/models/ name the same set of models
    - every card has both embedded sections, each non-empty
    - odoo-versions.json parses, and every entry under `models` is a corpus model

Section extraction mirrors the bake exactly: `{header}:?\\s*\\n(.*?)(?:\\n\\s*\\n|\\Z)`, dotall.
A card that passes here embeds the text you expect; one that fails would bake short or empty.

usage: tools/check_corpus.py [repo-root]
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

SECTIONS = ("RAG Routing Keywords", "Ultra-Dense Vector Paragraph")


def section(text: str, header: str) -> str | None:
    m = re.search(re.escape(header) + r":?\s*\n(.*?)(?:\n\s*\n|\Z)", text, re.S)
    return m.group(1).strip() if m else None


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent)
    errors: list[str] = []

    cards_dir = root / "descriptions" / "models"
    cards = {p.name for p in cards_dir.iterdir() if p.is_file() and not p.name.startswith(".")}
    listed = {l.strip() for l in (root / "corpus" / "models.txt").read_text().splitlines() if l.strip()}

    for name in sorted(cards - listed):
        errors.append(f"{name}: card exists but is not in corpus/models.txt")
    for name in sorted(listed - cards):
        errors.append(f"{name}: listed in corpus/models.txt but has no card")

    for name in sorted(cards):
        text = (cards_dir / name).read_text(encoding="utf-8")
        for header in SECTIONS:
            body = section(text, header)
            if not body:
                errors.append(f"{name}: section '{header}' is missing or empty")

    try:
        versions = json.loads((root / "corpus" / "odoo-versions.json").read_text())
    except json.JSONDecodeError as e:
        errors.append(f"corpus/odoo-versions.json: {e}")
    else:
        for name in sorted(set(versions.get("models", {})) - cards):
            errors.append(f"corpus/odoo-versions.json: facts for '{name}', which is not a corpus model")

    for e in errors:
        print(e, file=sys.stderr)
    print(f"{len(cards)} cards, {len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
