#!/bin/bash
# SPDX-FileCopyrightText: 2026 TerraKernel Pte Ltd
# SPDX-License-Identifier: 0BSD
#
# Audit Layer 1's model names against real Odoo community source (DECISIONS.md 12, 17).
#
# A model exists in a version iff a class body declares `_name = '<model>'`. Two things this
# gets right that a naive grep does not:
#
#   * `_inherit` without `_name` EXTENDS an existing model and must not count as declaring one.
#   * the pattern is anchored to the start of the line, so `comodel_name='account.move'` does
#     not match. (`git grep -E` has no \s, so POSIX classes are required -- with `\s*` the
#     pattern silently degrades to a literal `s*` and matches comodel_name. Ask how we know.)
#
# Absence means absent from COMMUNITY. Odoo Enterprise is a separate private repository we
# cannot read, so `--` reads as "not in community" rather than "does not exist" -- that is the
# edition axis, not the version axis.
#
# usage: tools/audit_odoo_models.sh [workdir] [model-list]
set -u

WORK="${1:-/tmp/odoo-audit}"
MODELS="${2:-}"
VERSIONS=(14.0 15.0 16.0 17.0 18.0 19.0)
REPO="$WORK/odoo.git"

if [ -z "$MODELS" ]; then
    MODELS="$WORK/models.txt"
    cp "$(dirname "$0")/../corpus/models.txt" "$MODELS" 2>/dev/null \
        || { echo "pass a model list: $0 <workdir> <file>"; exit 2; }
fi

mkdir -p "$WORK"
if [ ! -d "$REPO" ]; then
    echo "cloning odoo ${VERSIONS[0]} (shallow, bare) -- a few minutes, ~500 MB for all branches"
    git clone --bare --depth 1 --branch "${VERSIONS[0]}" https://github.com/odoo/odoo "$REPO" || exit 1
fi
cd "$REPO" || exit 1
for v in "${VERSIONS[@]:1}"; do
    git rev-parse --verify "$v" >/dev/null 2>&1 || git fetch --depth 1 origin "$v:$v" || exit 1
done

P="^[[:space:]]*_name[[:space:]]*=[[:space:]]*['\"]"

echo "# audited $(date +%F) against:"
for v in "${VERSIONS[@]}"; do
    echo "#   $v  $(git rev-parse "$v")  $(git log -1 --format=%cs "$v")"
done
echo

printf "%-32s" "model"
for v in "${VERSIONS[@]}"; do printf "%7s" "$v"; done
printf "\n%s\n" "$(printf -- '-%.0s' $(seq 1 74))"

while read -r m; do
    [ -z "$m" ] && continue
    esc=$(printf '%s' "$m" | sed 's/\./\\./g')
    printf "%-32s" "$m"
    for v in "${VERSIONS[@]}"; do
        if git grep -qIE "${P}${esc}['\"]" "$v" -- '*.py' 2>/dev/null; then
            printf "%7s" "ok"
        else
            printf "%7s" "--"
        fi
    done
    printf "\n"
done < "$MODELS"
