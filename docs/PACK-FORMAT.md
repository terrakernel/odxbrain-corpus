# Pack format, version 2

A pack is a directory of three files. It is everything ODXBrain needs to answer from the stock
corpus, and it can be checked with nothing but `sha256sum` and a JSON parser.

```
manifest.json     what made the vectors, and the checksums of the other two files
vectors.f32       count × dim float32, row-major, little-endian, no header
payloads.jsonl    one JSON object per line, line i describes row i
```

## `manifest.json`

```json
{
  "pack_format_version": 2,
  "corpus_version": "2026.09.4",
  "count": 41,
  "embedding": {
    "model_id": "bge-m3",
    "dim": 1024,
    "pooling": "cls",
    "normalized": true,
    "text_form": "keywords+dense"
  },
  "vectors": {
    "file": "vectors.f32", "dtype": "float32", "layout": "row-major", "endian": "little",
    "rows": 41, "cols": 1024, "bytes": 167936, "sha256": "<hex>"
  },
  "payloads": { "file": "payloads.jsonl", "rows": 41, "bytes": 38234, "sha256": "<hex>" },
  "odoo": { "min_version": "14.0", "max_version": "19.0" },
  "retrieval": { "dense": true, "lexical": false }
}
```

- **`embedding` is a contract.** Vectors from one embedding model mean nothing to another, and
  nothing about the numbers shows it: cosine similarity still returns a value, and the results
  still come back sorted. ODXBrain compares `model_id`, `dim`, `pooling` and `normalized` against
  the model it's serving and refuses the pack on any difference. A consumer that stores these
  vectors should store `model_id` and `dim` with them.
- **`corpus_version`** is the release tag in this repo that the pack was baked from.
- **`pack_format_version`** changes only when the layout changes in a breaking way. A loader
  should refuse a version it doesn't know.

## `vectors.f32`

`rows × cols` little-endian IEEE-754 float32, row after row, with no header or padding. When
`normalized` is true, every row is unit length (ODXBrain rejects a row whose norm is more than
1e-4 from 1), so an inner product is cosine similarity.

## `payloads.jsonl`

One object per line. Line `i` has `"id": i` and describes row `i` of `vectors.f32`.

| key | always | meaning |
|---|---|---|
| `id` | yes | the row number |
| `model` | yes | the answer: the Odoo model name, e.g. `account.move` |
| `text` | yes | exactly the text that was embedded, byte for byte |
| `keywords` | yes | the keyword section alone (not searched) |
| `tokens` | yes | token count of `text` under the pack's embedder |
| `since` | no | first Odoo major version that has the model (integer) |
| `until` | no | last Odoo major version that has the model (integer) |
| `edition` | no | `"enterprise"` when the model isn't in Community |
| `aliases` | no | `{"<major>": "<name>"}`: the model's name on versions where it differs |
| `successor` | no | `{"<major>": "<name>"}`: where the concept went after the model was removed |
| `provisional` | no | `true` when a fact above is inferred rather than read from source |

A missing key means **no restriction**, not a default. A model with no `since` is not "since
14.0"; it exists in every supported version. An unknown fact filters nothing.

## Verifying a pack

1. `sha256sum vectors.f32 payloads.jsonl` must match the manifest.
2. Row counts and byte sizes must match the manifest, and every `id` must equal its line number.
3. **Payloads are checked exactly against the tag.** The version facts in `payloads.jsonl`
   must match `corpus/odoo-versions.json` at `corpus_version`. Each `text` must match what the
   card sections produce: the `RAG Routing Keywords` and `Ultra-Dense Vector Paragraph`
   sections, each with runs of whitespace collapsed to one space, joined by a newline.
4. **Vectors are checked for equivalence, not identical bytes.** Bakes on different hardware
   (for example Apple Metal vs Linux CPU) produce different bits and the same rankings.
   Re-embedding the `text` fields with the named model should reproduce the rankings. The
   per-vector cosine threshold that counts as "the same vector" is not set yet; see
   `docs/RELEASING.md`.

## Known gap

`model_id` names a model, not a file. Two different conversions of the same model (F16 and Q8,
say) share a `model_id` and produce different vectors. A future format version will record the
SHA-256 of the exact weights file the pack was baked with. Until then, each release states which
file that was.
