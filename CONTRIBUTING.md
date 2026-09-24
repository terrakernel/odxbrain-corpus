# Contributing

## Terms

By contributing, you dedicate your contribution to the public domain under CC0-1.0 (data) or
license it under 0BSD (scripts), the same as the rest of this repo. **That includes its use in
ODXBrain, which is a proprietary product.** If that's not acceptable to you, please don't
contribute.

Sign off every commit (`git commit -s`) to certify the
[Developer Certificate of Origin](https://developercertificate.org/): you wrote it, or you have
the right to submit it under these terms. Don't paste code or text from Odoo Enterprise, or from
any other source whose license doesn't allow this. Describing what a model is for, and naming its
fields and methods, is fine. Copying its source is not.

## What's welcome

- **Better descriptions.** Especially the `RAG Routing Keywords` line, which is the part that
  moves retrieval the most (see below).
- **Keywords in your language.** Recall is weakest in German, Polish, Greek, Spanish and French.
  If you speak one of them, the words an accountant or a warehouse lead in your language would
  actually use are the most valuable thing you can add.
- **Audit corrections.** If `corpus/odoo-versions.json` is wrong about when a model appeared, was
  renamed or was removed, or about its edition, open an issue citing the Odoo source (branch and
  file).
- **Audits of new Odoo versions**, following `corpus/README.md`.

## New models: through extensions, not the core

The core is 41 models and stays that way: they cover the whole ERP cycle. Odoo's other apps will be
covered by per-app **extension packs** (see the README). Extensions aren't open for pull requests
yet. We're first measuring how recall holds up beyond 41 models, so that no one's work is refused
later because of a limit nobody knew about.

**What to do now:** open a "model coverage" issue naming the Odoo app and the models you need. If
you'd like to help write that extension, say so there. Pull requests that add models to the core
will be closed and pointed at the issue.

**Models specific to your own deployment** (custom modules, Studio) belong in ODXBrain's
per-instance custom layer (Layer 2), not here.

## What's declined

- **Changes that improve English and regress another language.** Changes are judged on the
  **worst** language, not the average and never on English alone.

## How a description card is read

Each file in `descriptions/models/` is named after the model and is free text. The bake reads
**two sections**, by their exact headers:

```
RAG Routing Keywords:
<one paragraph, comma-separated terms>

Ultra-Dense Vector Paragraph:
<one paragraph>
```

A section runs from the line after its header to the next blank line. The embedded text is the
keywords paragraph, a newline, then the dense paragraph, with whitespace collapsed (text form
`keywords+dense`). **Nothing else in a card is embedded.** The other sections are there for
people. Keep both headers spelled exactly as above, and keep each section as a single paragraph.
A blank line inside one cuts it short without any error.

Changing either section changes the vectors, so it needs a re-measure (below). Changing anything
else doesn't.

## How changes are checked

1. **`python3 tools/check_corpus.py`**, which you can run yourself. It checks that every card
   has both sections, that `models.txt` matches `descriptions/models/`, and that
   `odoo-versions.json` only names models in the corpus. CI runs it on every pull request.
2. **Recall, measured by the maintainers.** A change to the embedded text is re-baked and run
   against a held-out multilingual question set that isn't published; a published question set
   would stop being a fair test. You'll get the per-language result on your pull request. A
   drop in the worst language blocks the merge.

   *Planned:* a public dev question set and harness, so you can measure before submitting.

A change to `odoo-versions.json` alone must leave the vectors byte-identical, because version
facts are never embedded. The maintainers check that too.
