// CTA swap: external form → set ctaHref + ctaTarget '_blank'
// Own API → set ctaHref to app URL; enforce RBAC/RLS server-side only
// Do not re-add intake UI until intakeApiUrl returns 201 in staging
window.SITE = Object.freeze({
  ctaHref: 'mailto:requests@verifunding.com',
  ctaTarget: '_self',
  contactEmail: 'requests@verifunding.com',
  canonicalOrigin: 'https://verifunding.com',
  companyLegal: 'ClearMetric LLC',
  productName: 'VeriFunding',
});
