-- Run this in the Supabase SQL Editor for this project.
-- It creates/repairs all tables used by the iOS app with proper RLS policies.

-- =============================================
-- 1. User Table & Functions (already existing)
-- =============================================

create table if not exists public."User" (
    id uuid primary key,
    "authUserID" uuid unique references auth.users(id) on delete cascade,
    "First Name" text not null default '',
    "Last Name" text not null default '',
    "Email" text not null default '',
    "User Role" text not null default 'Sales Associate',
    "Assigned StoreID" uuid,
    "isApprovedByAdmin" boolean not null default false,
    "isActive" boolean not null default false,
    "createdAt" timestamptz not null default now(),
    "updatedAt" timestamptz not null default now()
);

alter table public."User"
    add column if not exists "authUserID" uuid unique references auth.users(id) on delete cascade,
    add column if not exists "First Name" text not null default '',
    add column if not exists "Last Name" text not null default '',
    add column if not exists "Email" text not null default '',
    add column if not exists "User Role" text not null default 'Sales Associate',
    add column if not exists "Assigned StoreID" uuid,
    add column if not exists "isApprovedByAdmin" boolean not null default false,
    add column if not exists "isActive" boolean not null default false,
    add column if not exists "createdAt" timestamptz not null default now(),
    add column if not exists "updatedAt" timestamptz not null default now();

create unique index if not exists user_auth_user_id_idx
    on public."User" ("authUserID");

create unique index if not exists user_email_idx
    on public."User" (lower("Email"))
    where "Email" <> '';

create or replace function public.touch_user_updated_at()
returns trigger
language plpgsql
as $$
begin
    new."updatedAt" = now();
    return new;
end;
$$;

drop trigger if exists touch_user_updated_at on public."User";
create trigger touch_user_updated_at
before update on public."User"
for each row
execute function public.touch_user_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    begin
        insert into public."User" (
            id,
            "authUserID",
            "First Name",
            "Last Name",
            "Email",
            "User Role",
            "Assigned StoreID",
            "isApprovedByAdmin",
            "isActive"
        )
        values (
            new.id,
            new.id,
            coalesce(new.raw_user_meta_data ->> 'first_name', ''),
            coalesce(new.raw_user_meta_data ->> 'last_name', ''),
            coalesce(new.email, ''),
            coalesce(new.raw_user_meta_data ->> 'user_role', 'Sales Associate'),
            nullif(new.raw_user_meta_data ->> 'assigned_store_id', '')::uuid,
            coalesce((new.raw_user_meta_data ->> 'is_approved_by_admin')::boolean, false),
            coalesce((new.raw_user_meta_data ->> 'is_active')::boolean, false)
        )
        on conflict ("authUserID") do update
        set
            "First Name" = excluded."First Name",
            "Last Name" = excluded."Last Name",
            "Email" = excluded."Email",
            "User Role" = excluded."User Role",
            "Assigned StoreID" = excluded."Assigned StoreID",
            "isApprovedByAdmin" = excluded."isApprovedByAdmin",
            "isActive" = excluded."isActive";
    exception
        when others then
            raise warning 'Profile creation skipped for auth user %, %', new.id, sqlerrm;
    end;

    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_auth_user();

create or replace function public.current_user_is_corporate_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public."User"
        where "authUserID" = auth.uid()
          and "User Role" = 'Corporate Admin'
          and "isActive" = true
    );
$$;

create or replace function public.ensure_user_profile(
    target_auth_user_id uuid,
    first_name text,
    last_name text,
    email text,
    user_role text,
    assigned_store_id uuid,
    is_approved_by_admin boolean,
    is_active boolean
)
returns public."User"
language plpgsql
security definer
set search_path = public
as $$
declare
    profile public."User"%rowtype;
begin
    if auth.uid() is distinct from target_auth_user_id
       and not public.current_user_is_corporate_admin() then
        raise exception 'Cannot create or repair a profile for another auth user.';
    end if;

    insert into public."User" (
        id,
        "authUserID",
        "First Name",
        "Last Name",
        "Email",
        "User Role",
        "Assigned StoreID",
        "isApprovedByAdmin",
        "isActive"
    )
    values (
        target_auth_user_id,
        target_auth_user_id,
        coalesce(first_name, ''),
        coalesce(last_name, ''),
        coalesce(email, ''),
        user_role,
        assigned_store_id,
        coalesce(is_approved_by_admin, false),
        coalesce(is_active, false)
    )
    on conflict ("authUserID") do update
    set
        "First Name" = excluded."First Name",
        "Last Name" = excluded."Last Name",
        "Email" = excluded."Email",
        "User Role" = excluded."User Role",
        "Assigned StoreID" = excluded."Assigned StoreID",
        "isApprovedByAdmin" = excluded."isApprovedByAdmin",
        "isActive" = excluded."isActive"
    returning * into profile;

    return profile;
end;
$$;

create or replace function public.delete_user_profile(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
    target_auth_user_id uuid;
    target_role text;
begin
    if not public.current_user_is_corporate_admin() then
        raise exception 'Only an active Corporate Admin can delete users.';
    end if;

    select "authUserID", "User Role"
    into target_auth_user_id, target_role
    from public."User"
    where id = target_user_id;

    if target_auth_user_id is null then
        raise exception 'User profile not found.';
    end if;

    if target_role = 'Corporate Admin' then
        raise exception 'Corporate Admin users cannot be deleted from the app.';
    end if;

    delete from auth.users
    where id = target_auth_user_id;
end;
$$;

alter table public."User" enable row level security;

drop policy if exists "Read users" on public."User";
create policy "Read users"
on public."User"
for select
to authenticated
using (true);

drop policy if exists "Corporate admin updates users" on public."User";
create policy "Corporate admin updates users"
on public."User"
for update
to authenticated
using (public.current_user_is_corporate_admin())
with check (public.current_user_is_corporate_admin());

-- =============================================
-- 2. Store Table
-- =============================================

create table if not exists public."Store" (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    location text,
    region text not null,
    "managerID" uuid,
    "inventoryControllerID" uuid,
    "salesAssociateIDs" uuid[] default '{}',
    currency text not null default 'INR',
    "taxType" text not null default 'GST',
    "taxName" text not null default 'CGST + SGST',
    "taxRate" numeric not null default 0.18,
    "createdAt" timestamptz not null default now(),
    "updatedAt" timestamptz not null default now()
);

create or replace function public.touch_store_updated_at()
returns trigger
language plpgsql
as $$
begin
    new."updatedAt" = now();
    return new;
end;
$$;

drop trigger if exists touch_store_updated_at on public."Store";
create trigger touch_store_updated_at
before update on public."Store"
for each row
execute function public.touch_store_updated_at();

alter table public."Store" enable row level security;

drop policy if exists "Read stores" on public."Store";
create policy "Read stores"
on public."Store"
for select
to authenticated
using (true);

drop policy if exists "Corporate admin manages stores" on public."Store";
create policy "Corporate admin manages stores"
on public."Store"
for all
to authenticated
using (public.current_user_is_corporate_admin())
with check (public.current_user_is_corporate_admin());

-- =============================================
-- 3. Category Table
-- =============================================

create table if not exists public."Category" (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    description text,
    "createdAt" timestamptz not null default now()
);

alter table public."Category" enable row level security;

drop policy if exists "Read categories" on public."Category";
create policy "Read categories"
on public."Category"
for select
to authenticated
using (true);

drop policy if exists "Corporate admin manages categories" on public."Category";
create policy "Corporate admin manages categories"
on public."Category"
for all
to authenticated
using (public.current_user_is_corporate_admin())
with check (public.current_user_is_corporate_admin());

-- =============================================
-- 4. Product Table
-- =============================================

create table if not exists public."Product" (
    id uuid primary key default gen_random_uuid(),
    sku text not null unique,
    name text not null,
    description text,
    brand text,
    category text,
    barcode text,
    "basePrice" numeric not null default 0,
    "costPrice" numeric not null default 0,
    tax numeric not null default 18,
    "isActive" boolean not null default true,
    "isArchived" boolean not null default false,
    "image_url" text,
    "isNFCEnabled" boolean not null default false,
    "requiresCertificate" boolean not null default false,
    "authenticityNotes" text,
    "createdAt" timestamptz not null default now(),
    "updatedAt" timestamptz not null default now()
);

create or replace function public.touch_product_updated_at()
returns trigger
language plpgsql
as $$
begin
    new."updatedAt" = now();
    return new;
end;
$$;

drop trigger if exists touch_product_updated_at on public."Product";
create trigger touch_product_updated_at
before update on public."Product"
for each row
execute function public.touch_product_updated_at();

alter table public."Product" enable row level security;

drop policy if exists "Read products" on public."Product";
create policy "Read products"
on public."Product"
for select
to authenticated
using (true);

drop policy if exists "Corporate admin manages products" on public."Product";
create policy "Corporate admin manages products"
on public."Product"
for all
to authenticated
using (public.current_user_is_corporate_admin())
with check (public.current_user_is_corporate_admin());

-- =============================================
-- 5. Pricing Table
-- =============================================

create table if not exists public."Pricing" (
    id uuid primary key default gen_random_uuid(),
    "productID" uuid not null references public."Product"(id) on delete cascade,
    "costPrice" numeric not null default 0,
    "basePrice" numeric not null default 0,
    tax numeric not null default 18,
    "isActive" boolean not null default true,
    "createdAt" timestamptz not null default now(),
    "updatedAt" timestamptz not null default now()
);

create or replace function public.touch_pricing_updated_at()
returns trigger
language plpgsql
as $$
begin
    new."updatedAt" = now();
    return new;
end;
$$;

drop trigger if exists touch_pricing_updated_at on public."Pricing";
create trigger touch_pricing_updated_at
before update on public."Pricing"
for each row
execute function public.touch_pricing_updated_at();

alter table public."Pricing" enable row level security;

drop policy if exists "Read pricing" on public."Pricing";
create policy "Read pricing"
on public."Pricing"
for select
to authenticated
using (true);

drop policy if exists "Corporate admin manages pricing" on public."Pricing";
create policy "Corporate admin manages pricing"
on public."Pricing"
for all
to authenticated
using (public.current_user_is_corporate_admin())
with check (public.current_user_is_corporate_admin());

-- =============================================
-- 6. CompanyPolicy Table
-- =============================================

create table if not exists public."CompanyPolicy" (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    content text not null,
    "lastUpdated" timestamptz not null default now()
);

create or replace function public.touch_policy_updated_at()
returns trigger
language plpgsql
as $$
begin
    new."lastUpdated" = now();
    return new;
end;
$$;

drop trigger if exists touch_policy_updated_at on public."CompanyPolicy";
create trigger touch_policy_updated_at
before update on public."CompanyPolicy"
for each row
execute function public.touch_policy_updated_at();

alter table public."CompanyPolicy" enable row level security;

drop policy if exists "Read policies" on public."CompanyPolicy";
create policy "Read policies"
on public."CompanyPolicy"
for select
to authenticated
using (true);

drop policy if exists "Corporate admin manages policies" on public."CompanyPolicy";
create policy "Corporate admin manages policies"
on public."CompanyPolicy"
for all
to authenticated
using (public.current_user_is_corporate_admin())
with check (public.current_user_is_corporate_admin());

-- =============================================
-- 7. Grant Permissions
-- =============================================

grant usage on schema public to anon, authenticated;

grant select, update on public."User" to authenticated;
grant all on public."Store" to authenticated;
grant all on public."Category" to authenticated;
grant all on public."Product" to authenticated;
grant all on public."Pricing" to authenticated;
grant all on public."CompanyPolicy" to authenticated;

grant execute on function public.ensure_user_profile(uuid, text, text, text, text, uuid, boolean, boolean) to authenticated;
grant execute on function public.delete_user_profile(uuid) to authenticated;

-- =============================================
-- 7. Mock Data
-- =============================================

-- Insert Stores
insert into public."Store" (id, name, location, region, currency, "taxType", "taxName", "taxRate")
values
    ('550e8400-e29b-41d4-a716-446655440001', 'Corporate Headquarters', 'Mumbai', 'India', 'INR', 'GST', 'CGST + SGST', 0.18),
    ('550e8400-e29b-41d4-a716-446655440002', 'Mumbai Flagship', 'Horniman Circle, Fort', 'India', 'INR', 'GST', 'CGST + SGST', 0.18),
    ('550e8400-e29b-41d4-a716-446655440003', 'Delhi Boutique', 'Connaught Place', 'India', 'INR', 'GST', 'CGST + SGST', 0.18),
    ('550e8400-e29b-41d4-a716-446655440004', 'Chennai Studio', 'T Nagar', 'India', 'INR', 'GST', 'IGST', 0.18)
on conflict (id) do update set
    name = EXCLUDED.name,
    location = EXCLUDED.location,
    region = EXCLUDED.region,
    currency = EXCLUDED.currency,
    "taxType" = EXCLUDED."taxType",
    "taxName" = EXCLUDED."taxName",
    "taxRate" = EXCLUDED."taxRate";

-- Insert Categories
insert into public."Category" (id, name, description)
values
    ('550e8400-e29b-41d4-a716-446655440010', 'Handbags', 'Luxury leather goods & clutches'),
    ('550e8400-e29b-41d4-a716-446655440011', 'Watches', 'High-end timepieces'),
    ('550e8400-e29b-41d4-a716-446655440012', 'Jewelry', 'Fine jewelry & accessories'),
    ('550e8400-e29b-41d4-a716-446655440013', 'Fragrances', 'Signature scents')
on conflict (id) do update set
    name = EXCLUDED.name,
    description = EXCLUDED.description;

-- Insert Products
insert into public."Product" (id, sku, name, brand, category, "basePrice", "costPrice", tax, "isActive")
values
    ('550e8400-e29b-41d4-a716-446655440020', 'SKU-BAG-001', 'Leather Tote', 'Noir Luxe', 'Handbags', 2500, 2118, 18, true),
    ('550e8400-e29b-41d4-a716-446655440021', 'SKU-BAG-002', 'Handbag', 'Noir Luxe', 'Handbags', 0, 0, 18, true),
    ('550e8400-e29b-41d4-a716-446655440022', 'SKU-BAG-003', 'Hermès Birkin', 'Hermès', 'Handbags', 1500000, 1271186, 18, true),
    ('550e8400-e29b-41d4-a716-446655440023', 'SKU-WATCH-001', 'Rolex Submariner', 'Rolex', 'Watches', 850000, 720339, 18, true),
    ('550e8400-e29b-41d4-a716-446655440024', 'SKU-WATCH-002', 'Patek Philippe Nautilus', 'Patek Philippe', 'Watches', 2500000, 2118644, 18, true),
    ('550e8400-e29b-41d4-a716-446655440025', 'SKU-WATCH-003', 'Rolex Daytona', 'Rolex', 'Watches', 1200000, 1016949, 18, true),
    ('550e8400-e29b-41d4-a716-446655440026', 'SKU-WATCH-004', 'Diamond Datejust', 'Rolex', 'Watches', 950000, 805085, 18, true),
    ('550e8400-e29b-41d4-a716-446655440027', 'SKU-RNG-004', 'Diamond Ring', 'Noir Luxe', 'Jewelry', 450000, 381356, 18, true),
    ('550e8400-e29b-41d4-a716-446655440028', 'SKU-PER-002', 'Signature Scent', 'Noir Luxe', 'Fragrances', 8500, 7203, 18, true)
on conflict (id) do update set
    "basePrice" = EXCLUDED."basePrice",
    "costPrice" = EXCLUDED."costPrice",
    tax = EXCLUDED.tax,
    "isActive" = EXCLUDED."isActive";

-- Insert Pricing Rules
insert into public."Pricing" (id, "productID", "costPrice", "basePrice", tax, "isActive")
values
    ('550e8400-e29b-41d4-a716-446655440040', '550e8400-e29b-41d4-a716-446655440020', 2118, 2500, 18, true),
    ('550e8400-e29b-41d4-a716-446655440041', '550e8400-e29b-41d4-a716-446655440021', 0, 0, 18, true),
    ('550e8400-e29b-41d4-a716-446655440042', '550e8400-e29b-41d4-a716-446655440022', 1271186, 1500000, 18, true),
    ('550e8400-e29b-41d4-a716-446655440043', '550e8400-e29b-41d4-a716-446655440023', 720339, 850000, 18, true),
    ('550e8400-e29b-41d4-a716-446655440044', '550e8400-e29b-41d4-a716-446655440024', 2118644, 2500000, 18, true),
    ('550e8400-e29b-41d4-a716-446655440045', '550e8400-e29b-41d4-a716-446655440025', 1016949, 1200000, 18, true),
    ('550e8400-e29b-41d4-a716-446655440046', '550e8400-e29b-41d4-a716-446655440026', 805085, 950000, 18, true),
    ('550e8400-e29b-41d4-a716-446655440047', '550e8400-e29b-41d4-a716-446655440027', 381356, 450000, 18, true),
    ('550e8400-e29b-41d4-a716-446655440048', '550e8400-e29b-41d4-a716-446655440028', 7203, 8500, 18, true)
on conflict (id) do update set
    "productID" = EXCLUDED."productID",
    "costPrice" = EXCLUDED."costPrice",
    "basePrice" = EXCLUDED."basePrice",
    tax = EXCLUDED.tax,
    "isActive" = EXCLUDED."isActive";

-- Insert Company Policies
insert into public."CompanyPolicy" (id, title, content)
values
    ('550e8400-e29b-41d4-a716-446655440030', 'Return & Exchange Policy', 'Items in pristine condition can be returned within 14 days of purchase. Excludes customized leather items and high-end watches, which require a boutique manager inspection.'),
    ('550e8400-e29b-41d4-a716-446655440031', 'Employee Discount Rules', 'Active boutique staff members receive a 30% discount on leather apparel and 15% on timepieces. Items must be purchased for personal use or direct family members only.'),
    ('550e8400-e29b-41d4-a716-446655440032', 'High-Value Transfer Verification', 'Double audit authorization (from both dispatching and receiving boutique managers) is strictly required for stock transfers exceeding ₹5,00,000 in retail value.')
on conflict (id) do update set
    title = EXCLUDED.title,
    content = EXCLUDED.content;
