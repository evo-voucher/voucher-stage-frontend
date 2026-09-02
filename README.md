# Voucher Stage Frontend

Dedicated frontend for EVO Voucher Stage.

## Environment boundary
- Stage Supabase project: `tagusbcluzoxueixjmwh`
- Production frontend and Production Supabase are not deployment targets for this repository.
- This repository is the dedicated Stage frontend surface extracted from the isolation work in `evo-voucher/evolution-optical-voucher` PR #83.

## Safety rules
1. Stage-only backend configuration.
2. No Production project reference or Production publishable key may be committed into generated Stage frontend assets.
3. Production remains frozen/read-first during Stage development.
4. Stage deployment changes must be reviewed independently from Production.

## Migration status
Repository initialized for migration of the verified Stage preview architecture from PR #83.
