# Intake wiring guide (internal — not deployed)

Configuration source: [`site.config.json`](site.config.json) → generates [`public/site.js`](public/site.js).

When you are ready to connect real intake, use one path only. Do not re-add form UI until the endpoint exists.

## 1. CTA-only (no form)

Edit `site.config.json` (or set `SITE_CTA_HREF` / `SITE_CTA_TARGET` in Cloudflare Pages build env):

```json
{
  "ctaHref": "mailto:requests@verifunding.com",
  "ctaTarget": "_self"
}
```

Run `bash scripts/verify-deploy.sh` before deploy. All CTAs read from generated `window.SITE`.

## 2. Third-party form

Same as above — set `ctaHref` to Typeform, Google Form, or similar URL with `ctaTarget: "_blank"`.

## 3. Own API (production)

1. Build one POST endpoint for intake submissions.
2. Enforce RBAC at the API gateway (roles: admin, partner, borrower).
3. Enforce RLS on intake/application database tables.
4. Add `intakeApiUrl` to `site.config.json` and regenerate via `scripts/generate-site.sh`.
5. Re-introduce intake UI in `public/index.html` with:

```javascript
const res = await fetch(window.SITE.intakeApiUrl, { method: 'POST', body: ... });
if (!res.ok) throw new Error('Intake failed: ' + res.status);
```

**Rule:** Do not re-add form UI until `intakeApiUrl` returns 201 in staging. No fake success states.
