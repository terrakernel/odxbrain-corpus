# Releasing a corpus version

Maintainers only. The bake uses ODXBrain's own `odxbake`, which is not public; everything it
reads and everything it produces is.

## Steps

1. **Choose the version.** `YYYY.MM.N`, the next unused one. It becomes the tag, the pack's
   `corpus_version` and the release name.
2. **Check the structure:** `python3 tools/check_corpus.py`.
3. **Bake** with the weights file that ships, on any backend; the release notes name it. Packs
   from different backends rank the same but differ in `vectors.f32` bits, so step 4's
   byte-identical check compares bakes from the same backend. Releases so far are Linux CPU
   bakes. On a machine with a GPU, `--n-gpu-layers 0` gives the CPU bake:
   ```bash
   odxbake --descriptions descriptions/models --versions corpus/odoo-versions.json \
       --model bge-m3-f16.gguf --model-id bge-m3 --n-gpu-layers 0 \
       --corpus-version <version> --out pack
   ```
4. **Pass the release gate** in the ODXBrain repo against this pack (`verify_pack.py
   --via-resolve`): per-language recall at or above the current baseline in **every** language,
   and 41/41 on the identifier gate. If only `odoo-versions.json` changed, `vectors.f32` must be
   byte-identical to the previous release's Linux pack. Version facts are never embedded, so
   changed vectors mean card text changed.
5. **Package and checksum,** reproducibly: sorted entries, the release commit's date as every
   mtime, root ownership and no gzip timestamp, so packaging the same pack twice gives the same
   SHA-256:
   ```bash
   T=odxbrain-pack-<version>-bge-m3.tar.gz
   tar --sort=name --mtime="$(git log -1 --format=%cI)" --owner=0 --group=0 --numeric-owner \
       --format=gnu -C pack -cf - . | gzip -9n > $T
   sha256sum $T > $T.sha256
   ```
6. **Draft the release** on the commit, with both files attached. A draft is private and
   editable, and creates no tag:
   ```bash
   gh release create <version> --draft --target "$(git rev-parse HEAD)" --title <version> \
       --notes-file notes.md $T $T.sha256
   ```
   Download it back and check it (`sha256sum -c`, and unpack with `--strip-components=1`).
7. **Publish:** `gh release edit <version> --draft=false`. That creates the tag. The repo has
   **immutable releases** on, so from then on the files can't be changed or deleted and the tag
   can't be moved, and GitHub signs an attestation for the release. Anyone can check a download
   with `gh release verify-asset <version> $T`. There's no maintainer signing key: GitHub signs,
   so the keys aren't ours to keep. A mistake after publishing needs a new version.

   The release notes must state:
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
