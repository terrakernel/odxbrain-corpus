# ODXBrain Corpus

The open data behind ODXBrain, which turns a plain-language question into the three Odoo models
most likely to hold the answer. This repo holds what that engine searches and filters on: 41
model cards, the audited version/edition facts, and the scripts that audit them. Compiled packs
are release assets, never commits. Read `README.md` first for the why.

**This file is public**, like everything in the repo. It carries only rules for working on the
data. The engine, the bake tool and the evaluation question set are closed and not in this repo.

## Rules

These are not preferences. Breaking one produces wrong answers that raise no error.

- **41 models is the whole corpus, deliberately.** Don't add a model, even a common one. Core Odoo
  models are ~90% stable across 14.0–19.0; the full model list is ~41% stable, and every extra
  near-neighbour competes for the top three. Deployment-specific models belong in the engine's
  per-instance layer (Layer 2), not here.
- **An absent fact is not a default.** In `corpus/odoo-versions.json`, a model with no entry
  exists in every supported version and in Community. A missing `since` is not "since 14.0"; a
  missing `edition` is not "community". Only write a fact you have read in Odoo source. Filtering
  on a guess silently removes correct answers.
- **Check Odoo facts against Odoo source, never memory.** Odoo moves faster than training data.
  This corpus has been wrong from memory before (the `stock.route` rename is 16.0, not 17.0; edition
  comes from the declaring module's manifest `license`, not from absence in the community repo).
  Every fact records its source: branch SHA or package version.
- **Judge a text change on the worst language, never on English.** Recall is measured per
  language. A change that helps English and costs Greek is a regression.
- **Never copy Odoo Enterprise source into this repo.** Describing a model and naming its fields
  and methods is fine. Excerpts are not. Audit results (`ok`/`--` tables, facts) are fine.
- **Everything here is CC0-1.0 (data) or 0BSD (scripts)**, and contributions are used in a
  proprietary product. New script files carry the SPDX header the existing ones have.

## How a card becomes a vector

Only two sections of a card in `descriptions/models/` are embedded, found by their exact headers:
`RAG Routing Keywords` and `Ultra-Dense Vector Paragraph`. Each runs from the line after its header
to the **next blank line**, not the next heading. The embedded text is keywords + `\n` + dense
paragraph, each with whitespace collapsed. `tools/check_corpus.py` reproduces this extraction
exactly.

Consequences:

- Editing either section changes the vectors and needs a recall re-measure by the maintainers.
  Editing any other part of a card changes nothing that is searched.
- A blank line inside a section cuts it short silently. Renaming a header drops the section.
- Some cards embed a trailing `Related Models (most joined):` line because no blank line precedes
  it. Recall was measured with that text included. Don't "fix" it as a drive-by change.
- The keyword line moves retrieval more than anything else. Short, hand-picked terms beat long
  prose; long LLM-written paragraphs dilute the vector.
- **A change to `odoo-versions.json` alone must leave the vectors byte-identical.** Facts are never
  embedded.

## Commands

```bash
python3 tools/check_corpus.py                                    # before every commit
tools/audit_odoo_models.sh /tmp/odoo-audit corpus/models.txt     # Community audit, clones odoo/odoo
tools/audit_odoo_edition.py corpus/models.txt <odoo_<ver>+e tree>...   # Enterprise audit
```

"Run the corpus audit" means the runbook in `corpus/README.md`: audit the new source, fold the
results into `odoo-versions.json` with provenance, remove `provisional` where the new source
verifies it, then run `check_corpus.py`.

## What a session here can't do

Baking a pack and running the recall gate need the closed engine repo. For work that spans both,
start with `--add-dir` pointing at it. Release steps are in `docs/RELEASING.md`; the pack format is
in `docs/PACK-FORMAT.md`.

## Norms

- Commits are signed off (`git commit -s`, DCO).
- Comments cite `DECISIONS.md §N`. That's the engine's private design log; state the fact in
  full wherever you use it, so nothing here depends on reading it.
