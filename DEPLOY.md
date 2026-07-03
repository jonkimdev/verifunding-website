# Deploy VeriFunding to Cloudflare Pages

## Configuration

All site identity and CTA settings live in [`site.config.json`](site.config.json). Brand assets live in [`brand/`](brand/). Build generates `public/site.js`, `public/assets/*`, `sitemap.xml`, `robots.txt`, and the SEO head block in `index.html`. Generated files under `public/` are not committed — run `bash scripts/verify-deploy.sh` before serving locally or deploying.

Repository: https://github.com/jonkimdev/verifunding-website

Optional Cloudflare Pages environment overrides (applied at build time):

| Variable | Overrides |
|----------|-----------|
| `SITE_CTA_HREF` | `ctaHref` |
| `SITE_CTA_TARGET` | `ctaTarget` |
| `SITE_CONTACT_EMAIL` | `contactEmail` |
| `SITE_CANONICAL_ORIGIN` | `canonicalOrigin` |
| `SITE_COMPANY_LEGAL` | `companyLegal` |
| `SITE_PRODUCT_NAME` | `productName` |

## Prerequisites

- GitHub repo pushed from this directory
- Cloudflare account with `verifunding.com` on Cloudflare DNS

## Cloudflare Pages setup

1. Cloudflare Dashboard → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**
2. Select the repository containing this `website/` folder
3. Build settings:

| Setting | Value |
|---------|-------|
| Production branch | `main` |
| Build command | `bash scripts/verify-deploy.sh` |
| Build output directory | `public` |

4. Deploy and confirm preview URL (`*.pages.dev`) loads:
   - `/` renders with Borrower / Lender / Partner tabs
   - CTAs link to configured `ctaHref`
   - `/privacy.html` loads with contact email from `site.js`
   - `/site.js` returns the frozen `SITE` config

If the build fails, read the `ERROR:` line in the build log — fix the root cause; do not bypass `verify-deploy.sh`.

## Custom domain

1. Pages project → **Custom domains** → add `verifunding.com` (apex)
2. Add `www.verifunding.com`
3. Create a **Redirect Rule**: `www.verifunding.com/*` → `https://verifunding.com/$1` (301)

## Post-cutover verification

```bash
bash scripts/verify-deploy.sh
curl -sI https://verifunding.com | rg 'HTTP/|content-security-policy|x-frame-options|strict-transport'
curl -sI https://www.verifunding.com | rg 'HTTP/|location:'
curl -s https://verifunding.com/site.js | rg 'contactEmail'
```

Expected: apex 200 with security headers; www 301 to apex.

## Local validation

```bash
bash scripts/verify-deploy.sh
cd public && python3 -m http.server 8080
```

Open `http://localhost:8080/`.
