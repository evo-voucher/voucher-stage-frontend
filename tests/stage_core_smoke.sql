-- Voucher Stage core regression smoke test.
-- Scope: Partner context -> catalog -> issue -> public lookup -> Staff context -> verify -> redeem.
-- Safety: all fixtures and voucher activity are wrapped in one transaction and rolled back.
-- Target only Voucher Stage project tagusbcluzoxueixjmwh. Never run against Production.

begin;

create temporary table smoke_ctx (
  k text primary key,
  v text not null
) on commit drop;

create temporary table smoke_results (
  k text primary key,
  payload jsonb not null
) on commit drop;

-- Stable fixture ids make failures easier to inspect. Everything is rolled back.
insert into smoke_ctx(k,v) values
  ('partner_user','11111111-1111-4111-8111-111111111111'),
  ('staff_user','22222222-2222-4222-8222-222222222222'),
  ('partner_id','33333333-3333-4333-8333-333333333333'),
  ('template_id','44444444-4444-4444-8444-444444444444'),
  ('version_id','55555555-5555-4555-8555-555555555555'),
  ('allocation_id','66666666-6666-4666-8666-666666666666');

insert into smoke_ctx(k,v)
select 'branch_id', id::text
from public.branches
where status='active'
order by branch_code
limit 1;

-- Fail early if Stage has no active branch seed data.
do $$
begin
  if not exists(select 1 from smoke_ctx where k='branch_id') then
    raise exception 'Smoke test requires at least one active Stage branch';
  end if;
end $$;

-- Fixture bootstrap is system-level setup. Use the same trusted-service path allowed by tenant guards.
select set_config('request.jwt.claims', jsonb_build_object('role','service_role')::text, true);

insert into auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
values
  ((select v::uuid from smoke_ctx where k='partner_user'),'authenticated','authenticated','stage-smoke-partner@example.invalid',now(),now(),false,false),
  ((select v::uuid from smoke_ctx where k='staff_user'),'authenticated','authenticated','stage-smoke-staff@example.invalid',now(),now(),false,false);

insert into public.partners(id,partner_code,partner_name,voucher_limit,staff_limit,staff_access_enabled,status)
values((select v::uuid from smoke_ctx where k='partner_id'),'SMOKE-PARTNER','Smoke Test Partner',2,1,true,'active');

insert into public.partner_users(user_id,partner_id,role,status,staff_name,login_email)
values((select v::uuid from smoke_ctx where k='partner_user'),(select v::uuid from smoke_ctx where k='partner_id'),'partner_admin','active','Smoke Partner Admin','stage-smoke-partner@example.invalid');

insert into public.staff_users(user_id,branch_id,staff_name,role,status,login_email)
values((select v::uuid from smoke_ctx where k='staff_user'),(select v::uuid from smoke_ctx where k='branch_id'),'Smoke Staff','staff','active','stage-smoke-staff@example.invalid');

insert into public.voucher_templates(id,template_code,template_name,voucher_category,status)
values((select v::uuid from smoke_ctx where k='template_id'),'SMOKE-RM10','Smoke RM10','value','active');

insert into public.voucher_versions(
  id,template_id,version_no,version_name,face_value,validity_mode,valid_days,
  usage_limit,transferable,all_branches,status,effective_from
) values(
  (select v::uuid from smoke_ctx where k='version_id'),
  (select v::uuid from smoke_ctx where k='template_id'),
  1,'Smoke v1',10,'days',30,1,true,false,'active',now()
);

update public.voucher_templates
set current_version_id=(select v::uuid from smoke_ctx where k='version_id')
where id=(select v::uuid from smoke_ctx where k='template_id');

insert into public.partner_voucher_access(partner_id,template_id,status,quota_type)
values((select v::uuid from smoke_ctx where k='partner_id'),(select v::uuid from smoke_ctx where k='template_id'),'active','allocation');

insert into public.partner_voucher_allocations(
  id,partner_id,version_id,quantity_allocated,quantity_revoked,status,
  validity_anchor,all_branches,validity_value,validity_unit
) values(
  (select v::uuid from smoke_ctx where k='allocation_id'),
  (select v::uuid from smoke_ctx where k='partner_id'),
  (select v::uuid from smoke_ctx where k='version_id'),
  2,0,'active','issue',false,30,'days'
);

insert into public.partner_claim_settings(partner_id,all_branches)
values((select v::uuid from smoke_ctx where k='partner_id'),false);

insert into public.partner_claim_branches(partner_id,branch_id)
values((select v::uuid from smoke_ctx where k='partner_id'),(select v::uuid from smoke_ctx where k='branch_id'));

insert into public.voucher_version_branches(version_id,branch_id)
values((select v::uuid from smoke_ctx where k='version_id'),(select v::uuid from smoke_ctx where k='branch_id'));

insert into public.partner_voucher_allocation_branches(allocation_id,branch_id)
values((select v::uuid from smoke_ctx where k='allocation_id'),(select v::uuid from smoke_ctx where k='branch_id'));

-- Partner user path.
select set_config(
  'request.jwt.claims',
  jsonb_build_object('sub',(select v from smoke_ctx where k='partner_user'),'role','authenticated')::text,
  true
);

insert into smoke_results(k,payload)
values('partner_context', public.resolve_partner_portal_context(null));

insert into smoke_results(k,payload)
select 'catalog', to_jsonb(c)
from public.partner_issuable_voucher_catalog(null) c
where c.version_id=(select v::uuid from smoke_ctx where k='version_id');

insert into smoke_results(k,payload)
values(
  'issue',
  public.issue_engine_voucher(
    (select v::uuid from smoke_ctx where k='version_id'),
    'Smoke Customer',
    '0123456789',
    null
  )
);

insert into smoke_results(k,payload)
values(
  'public',
  public.get_public_voucher(
    ((select payload->>'public_token' from smoke_results where k='issue'))::uuid
  )
);

-- Staff user path.
select set_config(
  'request.jwt.claims',
  jsonb_build_object('sub',(select v from smoke_ctx where k='staff_user'),'role','authenticated')::text,
  true
);

insert into smoke_results(k,payload)
values('staff_context', public.resolve_staff_portal_context());

insert into smoke_results(k,payload)
values(
  'verify',
  public.verify_voucher(
    (select payload->>'voucher_code' from smoke_results where k='issue'),
    (select branch_code from public.branches where id=(select v::uuid from smoke_ctx where k='branch_id'))
  )
);

insert into smoke_results(k,payload)
values(
  'redeem',
  public.redeem_voucher(
    (select payload->>'voucher_code' from smoke_results where k='issue'),
    'Stage core smoke test',
    (select branch_code from public.branches where id=(select v::uuid from smoke_ctx where k='branch_id')),
    'manual_code'
  )
);

insert into smoke_results(k,payload)
select 'final_state', jsonb_build_object(
  'voucher_code',voucher_code,
  'status',status,
  'usage_count',usage_count,
  'usage_limit',usage_limit,
  'branch_scope_snapshotted',branch_scope_snapshotted
)
from public.vouchers
where id=((select payload->>'voucher_id' from smoke_results where k='issue'))::uuid;

-- Assertions: fail the transaction if any core contract regresses.
do $$
declare
  v_issue jsonb := (select payload from smoke_results where k='issue');
  v_public jsonb := (select payload from smoke_results where k='public');
  v_verify jsonb := (select payload from smoke_results where k='verify');
  v_redeem jsonb := (select payload from smoke_results where k='redeem');
  v_final jsonb := (select payload from smoke_results where k='final_state');
begin
  if coalesce((v_issue->>'success')::boolean,false) is not true then raise exception 'Smoke issue failed: %',v_issue; end if;
  if v_public->>'status' <> 'valid' then raise exception 'Smoke public lookup failed: %',v_public; end if;
  if coalesce((v_verify->>'can_redeem')::boolean,false) is not true then raise exception 'Smoke verify failed: %',v_verify; end if;
  if v_redeem->>'status' <> 'redeemed' then raise exception 'Smoke redeem failed: %',v_redeem; end if;
  if v_final->>'status' <> 'redeemed' or (v_final->>'usage_count')::int <> 1 then raise exception 'Smoke final state failed: %',v_final; end if;
  if coalesce((v_final->>'branch_scope_snapshotted')::boolean,false) is not true then raise exception 'Smoke branch snapshot failed: %',v_final; end if;
end $$;

select k,payload from smoke_results order by case k
  when 'partner_context' then 1 when 'catalog' then 2 when 'issue' then 3
  when 'public' then 4 when 'staff_context' then 5 when 'verify' then 6
  when 'redeem' then 7 when 'final_state' then 8 else 99 end;

rollback;
