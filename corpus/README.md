# Corpus facts and their audits

The facts about Layer 1: which of the 41 models exist in which Odoo versions and editions, and
under what names. Every fact is read from real Odoo source, and the audit tables record exactly
which source (branch SHAs for Community, package versions for Enterprise).

| file | what it is |
|---|---|
| `models.txt` | the 41 model names, one per line |
| `odoo-versions.json` | per-model version and edition facts, and how a running instance's version and edition are detected |
| `odoo-versions-audit.txt` | raw 41 × 6 table, Odoo **Community** 14.0–19.0, with branch SHAs |
| `odoo-versions-audit-enterprise.txt` | raw table against **Enterprise** source trees |

A model with no entry in `odoo-versions.json`'s `models` exists, unchanged, in every supported
version and in Community. That's 37 of the 41.

## Re-running the audit

Re-audit when a new Odoo version ships, or when a source tree nobody has audited becomes
available. These are data files, so a new audit never needs a new ODXBrain engine, only a new
corpus release.

### Community, any version range

```bash
tools/audit_odoo_models.sh /tmp/odoo-audit corpus/models.txt
```

Clones `odoo/odoo` shallow and bare, fetches each branch, prints the table with branch SHAs.
Adding a version means editing the `VERSIONS` array at the top of the script.

### Enterprise, from extracted source packages

```bash
tools/audit_odoo_edition.py corpus/models.txt \
    /path/to/odoo-14.0+e /path/to/odoo-15.0+e /path/to/odoo-16.0+e
```

Takes any number of extracted `odoo_<ver>+e` trees. Edition comes from the declaring module's
`__manifest__.py` license (`LGPL-3`/`AGPL-3` → community, `OEEL-1`/`OPL-1` → enterprise), which is
a stated fact rather than an inference from absence — see the tool's docstring for why that
distinction matters.

### Then

1. Fold the results into `odoo-versions.json`. Remove `"provisional": true` from any entry the new
   source verifies. Record the source you audited (branch SHAs, or package versions) in `audit`.
2. `python3 tools/check_corpus.py`.
3. Open a pull request with the new audit table and the JSON change. A facts-only change leaves
   the vectors byte-identical; the maintainers confirm that at release (`docs/RELEASING.md`).

**Only audit Enterprise source you are licensed to have.** Commit the results table and the
facts, never excerpts of Enterprise source.

## Known gaps

- **Enterprise 14.0, 15.0 and 16.0 have never been audited** — those trees were not available.
  The only entry affected is `account.asset`, whose edition is directly verified for 17.0–19.0
  and inferred below that from its absence across all six community branches. It carries
  `"provisional": true` for exactly this reason, and re-running the Enterprise audit over those
  trees is what clears it.
- **Odoo Online versions** (`saas~16.3`) have no audit of their own. ODXBrain floors them to
  their major version (16), which is what these facts are keyed on.
