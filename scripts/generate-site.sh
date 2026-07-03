#!/usr/bin/env bash
# Generates runtime artifacts from site.config.json (single source of truth).
# Cloudflare Pages env vars override config values at build time.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export SITE_ROOT="$ROOT"
fail() { echo "ERROR: generate-site: $1" >&2; exit 1; }

[[ -s "$ROOT/site.config.json" ]] || fail "missing site.config.json"

python3 << 'PYEOF'
import json, os, sys
from pathlib import Path

root = Path(os.environ["SITE_ROOT"])
config_path = root / "site.config.json"
public = root / "public"

with open(config_path) as f:
    cfg = json.load(f)

env_map = {
    "ctaHref": "SITE_CTA_HREF",
    "ctaTarget": "SITE_CTA_TARGET",
    "contactEmail": "SITE_CONTACT_EMAIL",
    "canonicalOrigin": "SITE_CANONICAL_ORIGIN",
    "companyLegal": "SITE_COMPANY_LEGAL",
    "productName": "SITE_PRODUCT_NAME",
}

for key, env_key in env_map.items():
    override = os.environ.get(env_key)
    if override:
        cfg[key] = override

required = ["ctaHref", "ctaTarget", "contactEmail", "canonicalOrigin", "companyLegal", "productName"]
for key in required:
    val = cfg.get(key)
    if not val or not isinstance(val, str):
        sys.exit(f"ERROR: generate-site: invalid or missing config key: {key}")

origin = cfg["canonicalOrigin"].rstrip("/")
if not origin.startswith("https://"):
    sys.exit("ERROR: generate-site: canonicalOrigin must start with https://")

site_js = "// Generated from site.config.json — do not edit. Run scripts/generate-site.sh\n"
site_js += f"window.SITE = Object.freeze({json.dumps(cfg, indent=2)});\n"
(public / "site.js").write_text(site_js)

(public / "sitemap.xml").write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    f"  <url><loc>{origin}/</loc></url>\n"
    f"  <url><loc>{origin}/privacy.html</loc></url>\n"
    "</urlset>\n"
)

(public / "robots.txt").write_text(
    "User-agent: *\nAllow: /\n\n"
    f"Sitemap: {origin}/sitemap.xml\n"
)

# index.html static head (helmet does not resolve {{ }} bindings)
index_path = public / "index.html"
index_html = index_path.read_text()
product = cfg["productName"]
page_title = f"{product} — Business funding, matched to your deal"
meta_desc = "Commercial financing referral for equipment finance, factoring, and ABL. One request, human review, routed with your consent."
og_desc = "Commercial financing referral for equipment finance, factoring, and ABL."
head_block = f"""<!-- SITE_HEAD_START -->
<title>{page_title}</title>
<meta name="description" content="{meta_desc}">
<link rel="canonical" href="{origin}/">
<meta property="og:title" content="{page_title}">
<meta property="og:description" content="{og_desc}">
<meta property="og:url" content="{origin}/">
<meta property="og:type" content="website">
<!-- SITE_HEAD_END -->"""
import re
patched, n = re.subn(
    r"<!-- SITE_HEAD_START -->.*?<!-- SITE_HEAD_END -->",
    head_block,
    index_html,
    count=1,
    flags=re.DOTALL,
)
if n != 1:
    sys.exit("ERROR: generate-site: could not patch SITE_HEAD block in index.html")
index_path.write_text(patched)

print("generate-site: OK")
PYEOF
