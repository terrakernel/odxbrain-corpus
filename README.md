# ODXBrain Corpus

The open data behind **ODXBrain**: the Odoo model descriptions it searches, the audited facts about
which Odoo versions contain each model, and the compiled packs built from them.

## What ODXBrain is

Odoo keeps its data in more than two thousand models, with names like `account.move`,
`stock.quant` and `mrp.production`. Before an application or an AI assistant can answer *"what do
customers still owe us?"*, it has to know that invoices live in `account.move`. People learn that
over years. A small language model running on a customer's own hardware usually doesn't know it
at all.

**ODXBrain answers that one question.** You give it a question in plain language, and it returns
the three Odoo models most likely to hold the answer, ranked. For example (illustrative; only the
top answer is shown):

```
"show me invoices nobody has paid yet"      →  account.move, …
"wie viel haben wir gerade auf Lager?"      →  stock.quant, …
```

It returns model names and nothing else. Once the model is known, the caller reads its fields from
the Odoo instance itself (through ODXProxy's `fields_get`, for example) and writes the query.

A few properties shape everything in this repo:

- **It runs entirely on the customer's premises and never contacts the internet.** Many Odoo
  deployments can't send their data anywhere, so ODXBrain uses a local embedding model and has no
  outbound network code at all.
- **It answers in many languages.** English, continental European languages and Mandarin are
  required; recall is measured separately for each, and changes are judged by the weakest one.
- **It knows Odoo versions.** Given the instance's version (14.0–19.0) and edition, it resolves
  renamed models to the name that instance uses, and leaves out models the instance can't have.
- **It covers the core of Odoo, 41 models, on purpose.** Those 41 hold the day-to-day data of
  accounting, sales, purchasing, inventory, manufacturing and point of sale, and they barely change
  between Odoo versions. Custom and add-on models are added per deployment, not here.

ODXBrain is part of the [ODXProxy](https://odxproxy.io) ecosystem. The engine is closed source.

## ODXBrain and ODXProxy, side by side

### No two Odoo instances look the same

Odoo is one of the most customisable ERPs there is, and that is exactly what makes it hard for an
AI to work with:

- **Studio and custom modules add fields**: an `x_studio_region` on sales orders, a
  `x_customs_code` on products. Every company adds its own.
- **Installed apps decide which models exist at all.** No Manufacturing app means no
  `mrp.production`; Enterprise adds models Community doesn't have.
- **Localisations add country-specific fields** for taxes, e-invoicing and statutory reports.
- **Versions rename and remove things.** `stock.location.route` became `stock.route` in 16.0.
  `stock.valuation.layer` is gone in 19.0.
- **Selection values differ**: the states an order can be in, the types of a journal.
- **Access rights differ per user.** Two people on the same instance can see different fields.

So there is no single "Odoo schema" to teach a model. A field list baked into an AI, a prompt or a
vector database is wrong for most real instances, and it goes on being wrong after every upgrade
and every Studio change.

### Split the stable part from the variable part

Not all of Odoo varies, though. **Which model holds which kind of business data barely changes.**
Invoices have lived in `account.move` since 13.0; stock on hand is in `stock.quant` everywhere. Of
the 41 core models here, 37 are identical in every version from 14.0 to 19.0, and the other four
change in ways this repo records exactly.

That suggests splitting the work between two tools, each answering the question it is right for:

| | **ODXBrain**: *which model?* | **ODXProxy `fields_get`**: *what does it look like here?* |
|---|---|---|
| knowledge | stable: which business concept lives where | variable: this instance's actual fields |
| source | this corpus, baked once, audited in public | the live Odoo instance, asked at the moment of the question |
| returns | three ranked model names | every field with its type, label, relations, selection values, required flag |
| includes custom fields | no, and it doesn't need to | yes, Studio fields and all |
| respects user access rights | not applicable, it holds no customer data | yes, it runs as the calling user |

### How an AI uses them together

```
question: "is there any incoming shipment today?"

1. ODXBrain   POST /v1/resolve  {query, odoo_version, edition}
              → stock.picking, …          which model to look in

2. ODXProxy   fields_get  stock.picking
              → picking_type_code, scheduled_date, state, partner_id, …
                                          what that model looks like on this instance

3. ODXProxy   search_read  stock.picking
              [("picking_type_code","=","incoming"), ("scheduled_date", …)]
              → the actual shipments
```

The AI knows none of Odoo's schema in advance. ODXBrain tells it where to look, `fields_get` tells
it what's there, and ODXProxy runs the query. ODXBrain never talks to Odoo itself; ODXProxy is
the only component that does.

### Why this is the right design

- **Always correct for the instance in front of it.** Fields come from the live system, so custom
  fields, localisations and upgrades are all visible with nothing to re-index.
- **Small enough for small models.** Dumping a whole Odoo schema into a prompt costs tens of
  thousands of tokens that a small model on local hardware can't afford. This way the model sees
  three names, then the fields of one model.
- **Nothing to fall out of sync.** ODXBrain stores no fields, so there is no field catalogue to
  maintain. The part it does store is the part that stays true across versions, and it's public so
  anyone can check it.
- **Private by construction.** ODXBrain never sees credentials or customer data: a question goes
  in and model names come out. Everything that touches the customer's data goes through ODXProxy,
  with the user's own permissions.
- **Each tool can be checked on its own.** Resolution is measured against a multilingual question
  set; `fields_get` is Odoo's own answer about itself.

## What this repo is for

**The engine is closed, but the data it runs on is open.** The answers ODXBrain gives come directly
from the material here, so it's public so that anyone can:

- **Read** exactly what text each model is found by, and what version facts filter it.
- **Audit** those facts against Odoo's own source. Every fact records the source it was read from.
- **Improve** the descriptions, especially with words people actually use in their own language.
- **Use** the compiled packs as they are, with no changes needed on the Odoo instance.

## What's here

| path | what it is | license |
|---|---|---|
| `descriptions/models/` | one card per Odoo model, 41 in all. The only text ODXBrain embeds | CC0-1.0 |
| `corpus/odoo-versions.json` | per-model version and edition facts, and where each one came from | CC0-1.0 |
| `corpus/models.txt` | the 41 model names | CC0-1.0 |
| `corpus/odoo-versions-audit*.txt` | raw audit tables, with the Odoo branch SHAs they were read from | CC0-1.0 |
| `tools/` | the audit scripts that produce those tables | 0BSD |
| `docs/PACK-FORMAT.md` | the on-disk pack format, so a pack can be checked without the engine | CC0-1.0 |
| Releases | compiled packs, one per supported embedder, with checksums | CC0-1.0 |

## Licensing: as free as possible, audit through provenance

Data is dedicated to the public domain under **CC0-1.0** (`LICENSES/CC0-1.0.txt`). Scripts are
**0BSD** (`LICENSES/0BSD.txt`). No attribution is required for either.

The license doesn't carry the audit trail; the repo does:

- **Signed tags.** Every release tag is the corpus version (`2026.09.4`) and is signed.
- **Checksums.** Every pack manifest records the SHA-256 of its vector and payload files. Every
  release publishes the SHA-256 of each pack archive.
- **Source provenance.** Every version/edition fact names the Odoo source it was read from, down
  to the branch SHA.

Anyone may redistribute or modify this data. Only a pack that matches a signed tag here is an
official ODXBrain corpus. "ODXBrain" is a name, not a license grant.

## Using a pack without changing anything

If the stock corpus fits your Odoo instance, download the pack for your embedder from the
release, check it against the published SHA-256, and point ODXBrain at it:

```bash
sha256sum -c odxbrain-pack-<corpus-version>-<model-id>.tar.gz.sha256
tar xzf odxbrain-pack-<corpus-version>-<model-id>.tar.gz
odxbrain --model <model>.gguf --model-id <model-id> --pack <extracted dir>
```

ODXBrain never downloads anything; it makes no outbound network connections. Fetch the pack on a
connected machine and carry it across if the deployment is air-gapped.

**A pack only works with the embedding model it was baked with.** The manifest names that model,
and ODXBrain refuses a pack that doesn't match. See `docs/PACK-FORMAT.md`.

Models outside these 41 (your custom modules, community add-ons) don't belong in this corpus. They
go into ODXBrain's per-instance custom layer (Layer 2) on your own deployment.

## Contributing

See `CONTRIBUTING.md`. In short: better descriptions, keywords in languages we're weak in, audit
corrections, and audits of new Odoo versions are all welcome. New models are not; the 41 are the
whole corpus by design.

## A note on `DECISIONS.md` references

Comments in the data and scripts cite sections like `DECISIONS.md 17a`. That is the engine's design
log, which is not public. The facts themselves are stated in full wherever they are used, so
nothing here depends on reading it.
