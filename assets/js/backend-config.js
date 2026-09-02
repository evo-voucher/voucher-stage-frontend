// Voucher Stage backend configuration.
// Browser clients use the Supabase publishable key only. Never place service_role here.
const EVOLUTION_ASSET_VERSION=(()=>{
  const pageVersion=new URLSearchParams(window.location.search).get('v');
  let scriptVersion='';
  try{scriptVersion=new URL(document.currentScript?.src||'',window.location.href).searchParams.get('v')||'';}catch(_){}
  return pageVersion||scriptVersion||'20260902-stage';
})();
window.EVOLUTION_ASSET_VERSION=EVOLUTION_ASSET_VERSION;
const evolutionAsset=path=>`${path}?v=${encodeURIComponent(EVOLUTION_ASSET_VERSION)}`;

const STAGE = Object.freeze({
  enabled: true,
  role: 'stage',
  authoritativeData: false,
  environment: 'stage',
  projectId: 'tagusbcluzoxueixjmwh',
  supabaseUrl: 'https://tagusbcluzoxueixjmwh.supabase.co',
  publishableKey: 'sb_publishable_R86zjGv4yso-krORZdj3IQ_7QZUtMMB',
  siteBase: 'https://evo-voucher.github.io/voucher-stage-frontend/'
});

let current = STAGE;
Object.defineProperty(window, 'EVOLUTION_VOUCHER_BACKEND', {
  configurable: true,
  enumerable: true,
  get() { return current; },
  set(value) { current = Object.freeze({ ...(value || {}), ...STAGE }); }
});

(function enforceVoucherStageBoundary(){
  const cfg=window.EVOLUTION_VOUCHER_BACKEND;
  if(!cfg||cfg.projectId!=='tagusbcluzoxueixjmwh'||cfg.supabaseUrl!=='https://tagusbcluzoxueixjmwh.supabase.co'||cfg.environment!=='stage'){
    document.documentElement.innerHTML='<body style="font-family:system-ui;background:#111;color:#fff;padding:32px"><h1>Voucher Stage blocked</h1><p>Environment isolation check failed. No request was sent.</p></body>';
    throw new Error('Voucher Stage environment isolation failure');
  }
  const show=()=>{if(document.getElementById('voucherStageBoundaryBadge'))return;const badge=document.createElement('div');badge.id='voucherStageBoundaryBadge';badge.textContent='VOUCHER STAGE';badge.style.cssText='position:fixed;right:10px;bottom:10px;z-index:2147483647;background:#5b3a00;color:#ffe08a;border:1px solid #9b6b00;border-radius:999px;padding:6px 10px;font:700 11px system-ui;letter-spacing:.08em;pointer-events:none';document.body.appendChild(badge);};
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',show,{once:true});else show();
})();
