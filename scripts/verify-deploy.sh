#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUBLIC="$ROOT/public"
fail() { echo "ERROR: $1" >&2; exit 1; }

# 1. Required files exist and non-empty
for f in index.html site.js support.js privacy.html robots.txt sitemap.xml _headers \
         assets/verifunding_logo.png assets/verifunding_logo_white.png assets/favicon.ico; do
  [[ -s "$PUBLIC/$f" ]] || fail "missing or empty: $f"
done

# 2. No placeholder links
rg -q 'href="#"' "$PUBLIC" && fail 'found href="#" in public/'

# 3. No removed modal API
rg -q 'openModal|submitForm|modalOpen|INTAKE MODAL' "$PUBLIC/index.html" && fail 'stale modal references in index.html'

# 4. site.js config valid
rg -q "ctaHref: 'mailto:" "$PUBLIC/site.js" || fail 'site.js ctaHref not set'
rg -q "contactEmail: '" "$PUBLIC/site.js" || fail 'site.js contactEmail not set'

# 5. Metadata present
rg -q '<title>' "$PUBLIC/index.html" || fail 'missing <title>'
rg -q 'name="description"' "$PUBLIC/index.html" || fail 'missing meta description'

# 6. Legacy artifacts absent
for legacy in "VeriFunding Website" "VeriFunding.html" "VeriFunding.dc.html" "VeriFunding.standalone-src.html"; do
  [[ ! -e "$ROOT/$legacy" ]] || fail "legacy file still present: $legacy"
done

# 7. contactEmail consistent across site.js and privacy.html
EMAIL=$(rg -o "contactEmail: '([^']+)" "$PUBLIC/site.js" -r '$1')
rg -q "$EMAIL" "$PUBLIC/privacy.html" || fail "privacy.html missing contactEmail: $EMAIL"

# 8. No design-tool placeholders left
rg -q 'hint-placeholder' "$PUBLIC/index.html" && fail 'design-tool hint-placeholder attributes remain'

# 9. Canonical origin matches site.js
ORIGIN=$(rg -o "canonicalOrigin: '([^']+)" "$PUBLIC/site.js" -r '$1')
rg -q "$ORIGIN" "$PUBLIC/index.html" || fail "index.html missing canonicalOrigin: $ORIGIN"

echo "verify-deploy: OK"
