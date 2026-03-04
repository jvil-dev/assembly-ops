-- ============================================================
-- SECURITY HARDENING MIGRATION
-- AssemblyOps — 20260303000000_security_hardening
--
-- This migration does NOT affect application behavior.
-- Prisma connects as `postgres` which bypasses RLS.
-- These changes only block access via the Supabase `anon`
-- and `authenticated` roles (used by PostgREST Data API).
--
-- Safe to run against production with zero downtime.
-- ============================================================


-- ─────────────────────────────────────────────────────────────
-- SECTION 1: Revoke default public schema grants
--
-- By default Supabase grants USAGE on the public schema and
-- SELECT/INSERT/UPDATE/DELETE on all tables to anon/authenticated.
-- Revoke everything so even if the Data API is re-enabled,
-- these roles cannot access any data.
-- ─────────────────────────────────────────────────────────────

-- Revoke schema usage (prevents even seeing what tables exist)
REVOKE USAGE ON SCHEMA public FROM anon;
REVOKE USAGE ON SCHEMA public FROM authenticated;

-- Revoke all table-level privileges
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM anon;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM authenticated;

-- Revoke all sequence privileges (prevents nextval/ID enumeration)
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM anon;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM authenticated;

-- Revoke all function privileges
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM anon;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM authenticated;

-- Lock down future objects created in public schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL PRIVILEGES ON TABLES FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL PRIVILEGES ON TABLES FROM authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL PRIVILEGES ON SEQUENCES FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL PRIVILEGES ON SEQUENCES FROM authenticated;


-- ─────────────────────────────────────────────────────────────
-- SECTION 2: Enable RLS with deny-all policies on every table
--
-- Defense-in-depth: even if a role somehow regains SELECT,
-- RLS ensures zero rows are returned without an explicit policy.
-- ─────────────────────────────────────────────────────────────

DO $$
DECLARE
  tbl_name TEXT;
BEGIN
  FOR tbl_name IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename NOT LIKE '_prisma%'
  LOOP
    -- Enable RLS
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl_name);

    -- Deny-all policy for anon
    BEGIN
      EXECUTE format(
        'CREATE POLICY "deny_all_anon" ON public.%I
         AS RESTRICTIVE
         TO anon
         USING (false)
         WITH CHECK (false)',
        tbl_name
      );
    EXCEPTION WHEN duplicate_object THEN
      NULL;
    END;

    -- Deny-all policy for authenticated
    BEGIN
      EXECUTE format(
        'CREATE POLICY "deny_all_authenticated" ON public.%I
         AS RESTRICTIVE
         TO authenticated
         USING (false)
         WITH CHECK (false)',
        tbl_name
      );
    EXCEPTION WHEN duplicate_object THEN
      NULL;
    END;
  END LOOP;
END $$;


-- ─────────────────────────────────────────────────────────────
-- SECTION 3: Event trigger — auto-enable RLS on new tables
--
-- Fires on CREATE TABLE so future Prisma migrations that add
-- tables are automatically hardened without manual action.
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION auto_enable_rls_on_new_table()
RETURNS event_trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $fn$
DECLARE
  obj record;
  tbl_name TEXT;
BEGIN
  FOR obj IN
    SELECT * FROM pg_event_trigger_ddl_commands()
    WHERE command_tag = 'CREATE TABLE'
  LOOP
    -- Extract just the table name from the fully-qualified object_identity
    tbl_name := split_part(obj.object_identity, '.', 2);

    -- Only apply to public schema, skip Prisma internals
    IF obj.schema_name = 'public' AND tbl_name NOT LIKE '_prisma%' THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl_name);

      BEGIN
        EXECUTE format(
          'CREATE POLICY "deny_all_anon" ON public.%I
           AS RESTRICTIVE TO anon USING (false) WITH CHECK (false)',
          tbl_name
        );
      EXCEPTION WHEN duplicate_object THEN
        NULL;
      END;

      BEGIN
        EXECUTE format(
          'CREATE POLICY "deny_all_authenticated" ON public.%I
           AS RESTRICTIVE TO authenticated USING (false) WITH CHECK (false)',
          tbl_name
        );
      EXCEPTION WHEN duplicate_object THEN
        NULL;
      END;
    END IF;
  END LOOP;
END;
$fn$;

DROP EVENT TRIGGER IF EXISTS trg_auto_enable_rls;
CREATE EVENT TRIGGER trg_auto_enable_rls
  ON ddl_command_end
  WHEN TAG IN ('CREATE TABLE')
  EXECUTE FUNCTION auto_enable_rls_on_new_table();


-- ─────────────────────────────────────────────────────────────
-- SECTION 4: Harden _prisma_migrations table
-- ─────────────────────────────────────────────────────────────

REVOKE ALL PRIVILEGES ON TABLE public."_prisma_migrations" FROM anon;
REVOKE ALL PRIVILEGES ON TABLE public."_prisma_migrations" FROM authenticated;

DO $$
BEGIN
  ALTER TABLE public."_prisma_migrations" ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN others THEN
  NULL;
END $$;
