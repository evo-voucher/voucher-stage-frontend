# Voucher Stage Frontend Migration Status

Target Supabase project: `tagusbcluzoxueixjmwh`

Production repository and Production Supabase remain unchanged.

## Completed in independent Stage repository

- Independent repository initialized
- Stage bootstrap branch created: `stage-bootstrap-20260902`
- Stage test entry added: `index.html`
- Self-contained Stage backend boundary added: `assets/js/backend-config.js`
- Stage Admin login added: `admin-login.html`
- Stage Admin dashboard entry added: `admin-dashboard.html`
- Stage-only CI integrity guard added

## Migration rule

Every migrated frontend file must:

1. use the independent Stage backend configuration;
2. contain no Production Supabase project reference or Production publishable key;
3. avoid runtime dependency on `evolution-optical-voucher/stage-preview` or `uat-preview`;
4. keep Stage auth/session namespace separate from Production;
5. pass `Voucher Stage Integrity` before merge to `main`.

## Pending portal surface

- `admin.html`
- `partner.html`
- `staff.html`
- `voucher-engine.html`
- `voucher.html`
- `voucher-classifications.html`
- supporting `assets/css/**`
- supporting `assets/js/**`
- `experience/**`
- manifests and service worker files

Historical PR #83 in the Production repository is migration source material only and must not be merged into Production main.
