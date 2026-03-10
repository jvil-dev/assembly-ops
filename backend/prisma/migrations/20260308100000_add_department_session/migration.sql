-- Fix the auto_enable_rls trigger to strip surrounding quotes from object_identity
-- before using %I, preventing double-quoting of PascalCase table names.
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
    -- Strip surrounding double-quotes if present (PascalCase names are quoted)
    tbl_name := trim('"' FROM split_part(obj.object_identity, '.', 2));

    -- Only apply to public schema, skip Prisma internals
    IF obj.schema_name = 'public' AND tbl_name NOT LIKE '_prisma%' THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl_name);
    END IF;
  END LOOP;
END;
$fn$;

-- CreateTable
CREATE TABLE "DepartmentSession" (
    "id" TEXT NOT NULL,
    "departmentId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "startTime" TIME(6),
    "endTime" TIME(6),
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DepartmentSession_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "DepartmentSession_departmentId_sessionId_key" ON "DepartmentSession"("departmentId", "sessionId");

-- AddForeignKey
ALTER TABLE "DepartmentSession" ADD CONSTRAINT "DepartmentSession_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DepartmentSession" ADD CONSTRAINT "DepartmentSession_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE;
