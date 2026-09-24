# Releasing a corpus version

Maintainers only. The bake uses ODXBrain's own `odxbake`, which is not public; everything it
reads and everything it produces is.

## Steps

1. **Choose the version.** `YYYY.MM.N`, the next unused one. It becomes the tag, the pack's
   `corpus_version` and the release name.
2. **Check the structure:** `python3 tools/check_corpus.py`.
3. **Bake** on the Linux release target, with the weights file that ships:
   ```bash
   odxbake --descriptions descriptions/models --versions corpus/odoo-versions.json \
       --model bge-m3-f16.gguf --model-id bge-m3 \
       --corpus-version <version> --out pack
   ```
4. **Pass the release gate** in the ODXBrain repo against this pack (`verify_pack.py
   --via-resolve`): per-language recall at or above the current baseline in **every** language,
   and 41/41 on the identifier gate. If only `odoo-versions.json` changed, `vectors.f32` must be
   byte-identical to the previous release's Linux pack. Version facts are never embedded, so
   changed vectors mean card text changed.
5. **Tag and sign:** `git tag -s <version> -m "corpus <version>"`, then push the tag.
6. **Package and checksum:**
   ```bash
   tar czf odxbrain-pack-<version>-bge-m3.tar.gz -C pack .
   sha256sum odxbrain-pack-<version>-bge-m3.tar.gz > odxbrain-pack-<version>-bge-m3.tar.gz.sha256
   ```
7. **Publish the release** on the tag, with both files attached. The release notes must state:
   - the per-language recall from step 4;
   - the exact weights file (name and SHA-256) the pack was baked with (see the known gap in
     `PACK-FORMAT.md`);
   - what changed in the data since the previous version.

## Open

- **Vector-equivalence threshold.** A third party can't rerun `odxbake`, so vectors are verified
  by re-embedding and comparing, not by matching bytes. Rankings must match. The per-vector cosine
  threshold is to be set by measuring Metal against Linux bakes of the same tag, not guessed.
- **Public dev question set and harness**, so contributors can measure recall before submitting.
  The held-out set stays private.
