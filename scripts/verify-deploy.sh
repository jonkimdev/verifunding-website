#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUBLIC="$ROOT/public"
fail() { echo "ERROR: $1" >&2; exit 1; }

bash "$ROOT/scripts/generate-site.sh"

# 1. Required source and generated files exist and non-empty
for f in brand/verifunding_logo.png brand/verifunding_logo_white.png brand/verifunding_favicon.png site.config.json; do
  [[ -s "$ROOT/$f" ]] || fail "missing or empty: $f"
done
for f in index.html site.js site-bind.js support.js privacy.html robots.txt sitemap.xml _headers \
         assets/verifunding_logo.png assets/verifunding_logo_white.png assets/favicon.png; do
  [[ -s "$PUBLIC/$f" ]] || fail "missing or empty: public/$f"
done

# 2. No placeholder links
rg -q 'href="#"' "$PUBLIC" && fail 'found href="#" in public/'

# 3. No removed modal API
rg -q 'openModal|submitForm|modalOpen|INTAKE MODAL' "$PUBLIC/index.html" && fail 'stale modal references in index.html'

# 4. site.js generated from config
rg -q 'Generated from site.config.json' "$PUBLIC/site.js" || fail 'site.js was not generated'
rg -q '"contactEmail"' "$PUBLIC/site.js" || fail 'site.js contactEmail not set'

# 5. Metadata present in generated head block
rg -q 'SITE_HEAD_START' "$PUBLIC/index.html" || fail 'missing SITE_HEAD block in index.html'
rg -q '<title>' "$PUBLIC/index.html" || fail 'missing <title>'
rg -q 'name="description"' "$PUBLIC/index.html" || fail 'missing meta description'

# 6. Legacy artifacts absent
for legacy in "VeriFunding Website" "VeriFunding.html" "VeriFunding.dc.html" "VeriFunding.standalone-src.html"; do
  [[ ! -e "$ROOT/$legacy" ]] || fail "legacy file still present: $legacy"
done

# 7. contactEmail consistent: config → site.js → privacy.html data attribute
EMAIL=$(python3 -c "import json; print(json.load(open('$ROOT/site.config.json'))['contactEmail'])")
rg -q "\"contactEmail\": \"$EMAIL\"" "$PUBLIC/site.js" || fail "site.js contactEmail mismatch with site.config.json"
rg -q "data-site-field=\"contactEmail\"" "$PUBLIC/privacy.html" || fail 'privacy.html missing contactEmail binding'

# 8. dc-runtime bindings and CTA count
rg -q 'data-dc-script' "$PUBLIC/index.html" || fail 'index.html missing data-dc-script (CTA bindings will break)'
CTA_COUNT=$(rg -o 'href="\{\{ ctaHref \}\}"' "$PUBLIC/index.html" | wc -l | tr -d ' ')
[[ "$CTA_COUNT" == "7" ]] || fail "expected 7 CTA bindings in index.html, found $CTA_COUNT"

# 9. No design-tool placeholders left
rg -q 'hint-placeholder' "$PUBLIC/index.html" && fail 'design-tool hint-placeholder attributes remain'

# 10. canonicalOrigin consistent across config and generated files
ORIGIN=$(python3 -c "import json; print(json.load(open('$ROOT/site.config.json'))['canonicalOrigin'].rstrip('/'))")
rg -q "$ORIGIN" "$PUBLIC/sitemap.xml" || fail "sitemap.xml missing canonicalOrigin: $ORIGIN"
rg -q "$ORIGIN" "$PUBLIC/robots.txt" || fail "robots.txt missing canonicalOrigin: $ORIGIN"
rg -q 'rel="icon" href="/assets/favicon.png"' "$PUBLIC/index.html" || fail 'index.html missing favicon link'
rg -q 'SITE_FAVICON_START' "$PUBLIC/privacy.html" || fail 'privacy.html missing SITE_FAVICON block'

# 11. No duplicate contact strings outside allowed files
ALLOWED='site.js|site.config.json|privacy.html|DEPLOY.md|INTAKE.md'
MATCHES=$(rg -l "$EMAIL" "$ROOT" --glob '!*.git/*' 2>/dev/null || true)
if [[ -n "$MATCHES" ]]; then
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    echo "$file" | rg -q "$ALLOWED" && continue
    fail "contactEmail duplicated outside allowed files: $file"
  done <<< "$MATCHES"
fi

echo "verify-deploy: OK"
