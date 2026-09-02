// Shared Voucher Stage authentication/runtime helper.
// Stage-only: refuses to create a client unless the backend config is locked to Voucher Stage.
(() => {
  const cfg = window.EVOLUTION_VOUCHER_BACKEND || {};
  const EXPECTED_PROJECT = 'tagusbcluzoxueixjmwh';
  const EXPECTED_URL = `https://${EXPECTED_PROJECT}.supabase.co`;

  function assertStage() {
    if (
      cfg.enabled !== true ||
      cfg.environment !== 'stage' ||
      cfg.projectId !== EXPECTED_PROJECT ||
      cfg.supabaseUrl !== EXPECTED_URL ||
      typeof cfg.publishableKey !== 'string' ||
      cfg.publishableKey.length < 20 ||
      !window.supabase ||
      typeof window.supabase.createClient !== 'function'
    ) {
      throw new Error('Voucher Stage auth boundary check failed');
    }
  }

  const clients = new Map();

  function client(scope = 'default') {
    assertStage();
    const safeScope = String(scope || 'default').toLowerCase().replace(/[^a-z0-9_-]/g, '-');
    if (clients.has(safeScope)) return clients.get(safeScope);
    const db = window.supabase.createClient(cfg.supabaseUrl, cfg.publishableKey, {
      auth: {
        storageKey: `evolution-voucher-stage-auth-${safeScope}`,
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true
      }
    });
    clients.set(safeScope, db);
    return db;
  }

  async function session(scope = 'default') {
    const db = client(scope);
    const { data, error } = await db.auth.getSession();
    if (error) throw error;
    return data?.session || null;
  }

  async function signIn(scope, email, password) {
    const db = client(scope);
    const { data, error } = await db.auth.signInWithPassword({
      email: String(email || '').trim().toLowerCase(),
      password: String(password || '')
    });
    if (error) throw error;
    return data?.session || null;
  }

  async function signOut(scope = 'default') {
    const db = client(scope);
    const { error } = await db.auth.signOut({ scope: 'local' });
    if (error) throw error;
  }

  async function realm(scope = 'default') {
    const db = client(scope);
    const { data, error } = await db.rpc('current_operational_realm');
    if (error) throw error;
    return data || null;
  }

  async function identify(scope = 'default') {
    const s = await session(scope);
    if (!s) return { authenticated: false, session: null, realm: null };
    const r = await realm(scope);
    return { authenticated: true, session: s, realm: r };
  }

  window.VOUCHER_STAGE_AUTH = Object.freeze({
    projectId: EXPECTED_PROJECT,
    client,
    session,
    signIn,
    signOut,
    realm,
    identify
  });
})();
