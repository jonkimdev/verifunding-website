# Intake wiring guide (internal — not deployed)

When you are ready to connect real intake, use one path only. Do not re-add form UI until the endpoint exists.

## 1. CTA-only (no form)

Edit `public/site.js`:

```javascript
ctaHref: 'mailto:requests@verifunding.com',
ctaTarget: '_self',
```

Or point at an external URL:

```javascript
ctaHref: 'https://forms.example.com/verifunding-intake',
ctaTarget: '_blank',
```

All CTAs on the site read from `window.SITE`. No other files need changing.

## 2. Third-party form

Same as above — set `ctaHref` to Typeform, Google Form, or similar URL with `ctaTarget: '_blank'`.

## 3. Own API (production)

1. Build one POST endpoint for intake submissions.
2. Enforce RBAC at the API gateway (roles: admin, partner, borrower).
3. Enforce RLS on intake/application database tables.
4. Add `intakeApiUrl` to `public/site.js`.
5. Re-introduce intake UI in `public/index.html` with:

```javascript
const res = await fetch(window.SITE.intakeApiUrl, { method: 'POST', body: ... });
if (!res.ok) throw new Error(`Intake failed: ${res.status}`);
```

**Rule:** Do not re-add form UI until `intakeApiUrl` returns 201 in staging. No fake success states.
