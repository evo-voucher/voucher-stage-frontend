// Voucher Stage business operations wrapper.
// This file only calls verified RPC contracts from the Stage voucher schema.
(() => {
  const auth = window.VOUCHER_STAGE_AUTH;
  if (!auth) throw new Error('Voucher Stage auth runtime missing');

  async function rpc(scope, name, args = {}) {
    const db = auth.client(scope);
    const { data, error } = await db.rpc(name, args);
    if (error) throw error;
    return data;
  }

  const partner = Object.freeze({
    async context() {
      return rpc('partner', 'resolve_partner_portal_context', { p_partner_id: null });
    },
    async catalog() {
      return rpc('partner', 'partner_issuable_voucher_catalog');
    },
    async summary() {
      return rpc('partner', 'partner_voucher_summary');
    },
    async recent(limit = 50) {
      return rpc('partner', 'partner_recent_vouchers', { p_limit: limit });
    },
    async claimAccess() {
      return rpc('partner', 'get_my_partner_claim_access');
    },
    async issue({ versionId, customerName, customerPhone = null }) {
      return rpc('partner', 'issue_engine_voucher', {
        p_version_id: versionId,
        p_customer_name: customerName,
        p_customer_phone: customerPhone || null
      });
    },
    async share(voucherId) {
      return rpc('partner', 'get_partner_voucher_share', { p_voucher_id: voucherId });
    }
  });

  const staff = Object.freeze({
    async context() {
      return rpc('staff', 'resolve_staff_portal_context');
    },
    async operationalContext() {
      return rpc('staff', 'staff_operational_context');
    },
    async today() {
      return rpc('staff', 'staff_today_summary');
    },
    async recent(limit = 20) {
      return rpc('staff', 'staff_recent_redemptions', { p_limit: limit });
    },
    async publicVoucher(token) {
      return rpc('staff', 'get_public_voucher', { p_token: token });
    },
    async verify({ voucherCode, branchCode = null }) {
      return rpc('staff', 'verify_voucher', {
        p_voucher_code: voucherCode,
        p_branch_code: branchCode || null
      });
    },
    async redeem({ voucherCode, branchCode = null, notes = null, method = 'manual_code' }) {
      return rpc('staff', 'redeem_voucher', {
        p_voucher_code: voucherCode,
        p_notes: notes || null,
        p_branch_code: branchCode || null,
        p_redeem_method: method
      });
    }
  });

  window.VOUCHER_STAGE_OPS = Object.freeze({ rpc, partner, staff });
})();
