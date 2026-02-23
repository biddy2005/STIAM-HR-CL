-- ================================================================
--  STIAM-HR · Complete Supabase Schema
--  Paste this entire file into:
--  Supabase Dashboard → SQL Editor → Run
-- ================================================================
--
--  TABLES CREATED:
--  1. staff                — employee records (core)
--  2. leave_requests       — leave applications
--  3. clock_records        — daily attendance / biometric
--  4. exited_staff         — former employees archive
--  5. redeployment_posts   — internal transfer requests
--  6. grievances           — anonymous grievance reports
--  7. salary_advances      — loan / advance requests
--  8. appraisal_requests   — performance review requests
--  9. staff_documents      — employee-uploaded files (metadata)
--
-- ================================================================


-- ────────────────────────────────────────────────────────────────
-- STEP 0 · EXTENSIONS
-- ────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ────────────────────────────────────────────────────────────────
-- STEP 1 · DROP EXISTING (safe re-run)
-- ────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS staff_documents     CASCADE;
DROP TABLE IF EXISTS appraisal_requests  CASCADE;
DROP TABLE IF EXISTS salary_advances     CASCADE;
DROP TABLE IF EXISTS grievances          CASCADE;
DROP TABLE IF EXISTS redeployment_posts  CASCADE;
DROP TABLE IF EXISTS exited_staff        CASCADE;
DROP TABLE IF EXISTS clock_records       CASCADE;
DROP TABLE IF EXISTS leave_requests      CASCADE;
DROP TABLE IF EXISTS staff               CASCADE;


-- ================================================================
--  TABLE 1 · STAFF
--  One row per employee. HR admins read all rows.
--  Staff can only read/update their own row.
-- ================================================================
CREATE TABLE staff (
  -- Identity
  id              TEXT        PRIMARY KEY,          -- e.g. STI-001, DVT-004
  name            TEXT        NOT NULL,
  email           TEXT        UNIQUE NOT NULL,
  phone           TEXT,

  -- Role
  designation     TEXT,                             -- "Staff" | "HOD Finance" | "MD/Ceo" …
  dept            TEXT,                             -- "Finance" | "IT" | "Operations" …
  company         TEXT        NOT NULL DEFAULT 'STIAM',
                                                    -- STIAM | DEVTAGE | CEDAR_LON | CEDAR_ASSET
  manager         TEXT,                             -- line manager name (denormalised for speed)

  -- Profile extras
  color           TEXT        DEFAULT '#2980B9',    -- avatar background hex
  photo           TEXT,                             -- base64 data-url or Storage path
  achievements    TEXT,                             -- latest achievement text notified to HR

  -- Permissions (no Supabase Auth yet — managed by app logic)
  is_admin        BOOLEAN     NOT NULL DEFAULT FALSE,
  is_super_admin  BOOLEAN     NOT NULL DEFAULT FALSE,

  -- Supabase Auth link (populate when you migrate to supa.auth.signIn)
  -- Once set, RLS policies below will auto-enforce row ownership
  auth_uid        UUID        UNIQUE,               -- maps to auth.users.id

  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;
CREATE TRIGGER trg_staff_updated BEFORE UPDATE ON staff
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ================================================================
--  TABLE 2 · LEAVE REQUESTS
--  Staff submit their own requests. Admins approve/decline any.
-- ================================================================
CREATE TABLE leave_requests (
  id          TEXT        PRIMARY KEY,              -- "LR-<timestamp>"
  staff_id    TEXT        NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  employee    TEXT        NOT NULL,                 -- denormalised name for display speed

  -- Leave details
  type        TEXT        NOT NULL,                 -- "Annual Leave" | "Sick Leave" …
  from_date   DATE        NOT NULL,
  to_date     DATE        NOT NULL,
  days        INTEGER     NOT NULL,
  relief      TEXT,                                 -- relief officer name
  reason      TEXT,

  -- Workflow
  status      TEXT        NOT NULL DEFAULT 'Pending',
                                                    -- Pending | Approved | Declined
  submitted   DATE        NOT NULL DEFAULT CURRENT_DATE,
  reviewed_by TEXT,                                 -- admin staff_id who actioned it
  reviewed_at TIMESTAMPTZ,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_leave_staff_id ON leave_requests(staff_id);
CREATE INDEX idx_leave_status   ON leave_requests(status);


-- ================================================================
--  TABLE 3 · CLOCK RECORDS
--  One row per staff per day. Upserted on clock-in/out.
-- ================================================================
CREATE TABLE clock_records (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id    TEXT        NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  record_date DATE        NOT NULL DEFAULT CURRENT_DATE,

  clock_in    TEXT,                                 -- "08:01"
  clock_out   TEXT,
  status      TEXT        NOT NULL DEFAULT 'Present',
                                                    -- Present | Late | Absent | On Leave

  -- Biometric device info (optional — populated by webhook)
  device_id   TEXT,
  biometric_match BOOLEAN,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (staff_id, record_date)
);
CREATE TRIGGER trg_clock_updated BEFORE UPDATE ON clock_records
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_clock_date    ON clock_records(record_date);
CREATE INDEX idx_clock_staff   ON clock_records(staff_id);


-- ================================================================
--  TABLE 4 · EXITED STAFF
--  Archived former employees. Super Admin only can write.
-- ================================================================
CREATE TABLE exited_staff (
  id          TEXT        PRIMARY KEY,              -- "EX-001"
  name        TEXT        NOT NULL,
  role        TEXT,
  dept        TEXT,
  company     TEXT,

  exit_date   DATE,
  reason      TEXT,
  type        TEXT        NOT NULL DEFAULT 'Voluntary',
                                                    -- Voluntary | Involuntary | Contractual
  clearance   TEXT        NOT NULL DEFAULT 'Pending',
                                                    -- Cleared | Pending | Withheld
  notes       TEXT,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER trg_exited_updated BEFORE UPDATE ON exited_staff
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ================================================================
--  TABLE 5 · REDEPLOYMENT POSTS  (internal transfer requests)
--  dept  = from_company key  (repurposed field)
--  type  = to_company key    (repurposed field)
-- ================================================================
CREATE TABLE redeployment_posts (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  title         TEXT        NOT NULL,   -- "Bukola Ononye → Devtage"
  dept          TEXT,                   -- from_company (STIAM | DEVTAGE | …)
  type          TEXT,                   -- to_company
  requirements  TEXT,                   -- free-text: role | dept | reason | requested by
  status        TEXT        NOT NULL DEFAULT 'Pending',
                                        -- Pending | Approved | Declined | Under Review
  company       TEXT,                   -- requesting staff_id
  posted_date   DATE        NOT NULL DEFAULT CURRENT_DATE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_redeploy_status ON redeployment_posts(status);


-- ================================================================
--  TABLE 6 · GRIEVANCES  (fully anonymous)
--  No staff_id stored — privacy by design.
-- ================================================================
CREATE TABLE grievances (
  id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  category       TEXT        NOT NULL,
                                         -- "Workplace Harassment" | "Unfair Treatment" …
  description    TEXT        NOT NULL,
  incident_date  DATE,
  status         TEXT        NOT NULL DEFAULT 'Received',
                                         -- Received | Under Review | Resolved | Closed
  hr_notes       TEXT,                   -- internal HR response (visible to admins only)
  submitted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ================================================================
--  TABLE 7 · SALARY ADVANCES
--  Staff submit; Admins approve/decline.
-- ================================================================
CREATE TABLE salary_advances (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id         TEXT        NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  employee         TEXT        NOT NULL,   -- denormalised name
  amount           NUMERIC(14,2) NOT NULL,
  reason           TEXT,
  repayment_months INTEGER     NOT NULL DEFAULT 1,
  status           TEXT        NOT NULL DEFAULT 'Pending',
                                           -- Pending | Approved | Declined | Repaid
  reviewed_by      TEXT,
  reviewed_at      TIMESTAMPTZ,
  submitted_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_advance_staff  ON salary_advances(staff_id);
CREATE INDEX idx_advance_status ON salary_advances(status);


-- ================================================================
--  TABLE 8 · APPRAISAL REQUESTS
--  Staff submit self-assessment; HR manages the cycle.
-- ================================================================
CREATE TABLE appraisal_requests (
  id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id        TEXT        NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  employee        TEXT        NOT NULL,   -- denormalised name
  type            TEXT        NOT NULL,  -- "Annual Appraisal" | "Quarterly Review" …
  period          TEXT        NOT NULL,  -- "Q1 2026" | "Annual 2025"
  self_assessment TEXT,
  kpi_score       NUMERIC(5,2),          -- populated by HR after review
  attitude_score  NUMERIC(5,2),
  output_score    NUMERIC(5,2),
  overall_rating  TEXT,                  -- Outstanding | Excellent | Good | Satisfactory
  status          TEXT        NOT NULL DEFAULT 'Submitted',
                                         -- Submitted | In Review | Completed
  hr_comments     TEXT,
  submitted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_appraisal_staff ON appraisal_requests(staff_id);


-- ================================================================
--  TABLE 9 · STAFF DOCUMENTS
--  Metadata for files uploaded to Supabase Storage by employees.
-- ================================================================
CREATE TABLE staff_documents (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id    TEXT        NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,   -- display name (original filename)
  storage_path TEXT       NOT NULL,  -- path inside "hr-documents" bucket
  file_size   TEXT,                  -- e.g. "240 KB"
  file_type   TEXT,                  -- "PDF" | "DOCX" | "JPG" …
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_staff_docs ON staff_documents(staff_id);


-- ================================================================
--  ROW LEVEL SECURITY
-- ================================================================
ALTER TABLE staff               ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests      ENABLE ROW LEVEL SECURITY;
ALTER TABLE clock_records       ENABLE ROW LEVEL SECURITY;
ALTER TABLE exited_staff        ENABLE ROW LEVEL SECURITY;
ALTER TABLE redeployment_posts  ENABLE ROW LEVEL SECURITY;
ALTER TABLE grievances          ENABLE ROW LEVEL SECURITY;
ALTER TABLE salary_advances     ENABLE ROW LEVEL SECURITY;
ALTER TABLE appraisal_requests  ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_documents     ENABLE ROW LEVEL SECURITY;


-- ─────────────────────────────────────────────────────────
--  RLS POLICIES
--
--  CURRENT SETUP  (internal app, anon key, no Supabase Auth):
--    All authenticated users (anon key holders) have full access.
--    This is safe for an internal intranet HR tool.
--
--  FUTURE SETUP  (when you add supa.auth.signIn()):
--    Uncomment the stricter policies below and remove the
--    permissive ones. Also populate staff.auth_uid for every row.
-- ─────────────────────────────────────────────────────────

-- ── PERMISSIVE (works NOW with anon key) ──────────────────
CREATE POLICY "internal_all_staff"              ON staff              FOR ALL USING (TRUE);
CREATE POLICY "internal_all_leave"              ON leave_requests     FOR ALL USING (TRUE);
CREATE POLICY "internal_all_clock"              ON clock_records      FOR ALL USING (TRUE);
CREATE POLICY "internal_all_exited"             ON exited_staff       FOR ALL USING (TRUE);
CREATE POLICY "internal_all_redeploy"           ON redeployment_posts FOR ALL USING (TRUE);
CREATE POLICY "internal_all_grievances"         ON grievances         FOR ALL USING (TRUE);
CREATE POLICY "internal_all_advances"           ON salary_advances    FOR ALL USING (TRUE);
CREATE POLICY "internal_all_appraisals"         ON appraisal_requests FOR ALL USING (TRUE);
CREATE POLICY "internal_all_staff_docs"         ON staff_documents    FOR ALL USING (TRUE);


-- ── STRICT (uncomment when Supabase Auth is active) ───────
-- These replace the permissive ones above.  Run these SQL commands
-- after setting staff.auth_uid = auth.uid() during sign-in.

/*
-- Staff: everyone can read; only owner updates their own row
DROP POLICY IF EXISTS "internal_all_staff" ON staff;
CREATE POLICY "staff_select_all"   ON staff FOR SELECT USING (TRUE);
CREATE POLICY "staff_update_own"   ON staff FOR UPDATE USING (auth_uid = auth.uid());
CREATE POLICY "staff_insert_admin" ON staff FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);

-- Leave requests: staff read own, admins read all; staff insert own
DROP POLICY IF EXISTS "internal_all_leave" ON leave_requests;
CREATE POLICY "leave_select" ON leave_requests FOR SELECT USING (
  staff_id = (SELECT id FROM staff WHERE auth_uid = auth.uid())
  OR EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);
CREATE POLICY "leave_insert" ON leave_requests FOR INSERT WITH CHECK (
  staff_id = (SELECT id FROM staff WHERE auth_uid = auth.uid())
);
CREATE POLICY "leave_update_admin" ON leave_requests FOR UPDATE USING (
  EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);

-- Clock records: staff read own today; admins read all
DROP POLICY IF EXISTS "internal_all_clock" ON clock_records;
CREATE POLICY "clock_select" ON clock_records FOR SELECT USING (
  staff_id = (SELECT id FROM staff WHERE auth_uid = auth.uid())
  OR EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);
CREATE POLICY "clock_upsert_own" ON clock_records FOR ALL USING (
  staff_id = (SELECT id FROM staff WHERE auth_uid = auth.uid())
);

-- Exited staff: admins only
DROP POLICY IF EXISTS "internal_all_exited" ON exited_staff;
CREATE POLICY "exited_admin_only" ON exited_staff FOR ALL USING (
  EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);

-- Salary advances: staff read/insert own; admins read/update all
DROP POLICY IF EXISTS "internal_all_advances" ON salary_advances;
CREATE POLICY "advance_own_select" ON salary_advances FOR SELECT USING (
  staff_id = (SELECT id FROM staff WHERE auth_uid = auth.uid())
  OR EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);
CREATE POLICY "advance_own_insert" ON salary_advances FOR INSERT WITH CHECK (
  staff_id = (SELECT id FROM staff WHERE auth_uid = auth.uid())
);
CREATE POLICY "advance_admin_update" ON salary_advances FOR UPDATE USING (
  EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);

-- Appraisals: staff read/insert own; admins read/update all
DROP POLICY IF EXISTS "internal_all_appraisals" ON appraisal_requests;
CREATE POLICY "appraisal_own_select" ON appraisal_requests FOR SELECT USING (
  staff_id = (SELECT id FROM staff WHERE auth_uid = auth.uid())
  OR EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);
CREATE POLICY "appraisal_own_insert" ON appraisal_requests FOR INSERT WITH CHECK (
  staff_id = (SELECT id FROM staff WHERE auth_uid = auth.uid())
);
CREATE POLICY "appraisal_admin_update" ON appraisal_requests FOR UPDATE USING (
  EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);

-- Grievances: anyone can INSERT (anonymous); only admins can SELECT
DROP POLICY IF EXISTS "internal_all_grievances" ON grievances;
CREATE POLICY "grievance_anon_insert" ON grievances FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "grievance_admin_select" ON grievances FOR SELECT USING (
  EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);

-- Staff documents: owner reads own; admins read all; owner inserts
DROP POLICY IF EXISTS "internal_all_staff_docs" ON staff_documents;
CREATE POLICY "staffdoc_own" ON staff_documents FOR SELECT USING (
  staff_id = (SELECT id FROM staff WHERE auth_uid = auth.uid())
  OR EXISTS (SELECT 1 FROM staff WHERE auth_uid = auth.uid() AND (is_admin OR is_super_admin))
);
CREATE POLICY "staffdoc_insert_own" ON staff_documents FOR INSERT WITH CHECK (
  staff_id = (SELECT id FROM staff WHERE auth_uid = auth.uid())
);
*/


-- ================================================================
--  REALTIME  (for live clock + leave updates)
-- ================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE clock_records;
ALTER PUBLICATION supabase_realtime ADD TABLE leave_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE salary_advances;
ALTER PUBLICATION supabase_realtime ADD TABLE appraisal_requests;


-- ================================================================
--  SUPABASE STORAGE — BUCKET + RLS POLICIES
--  Run ALL of this in the SQL Editor (not just the tables above)
--  This creates the bucket AND grants upload/download rights.
-- ================================================================

-- 1. Create the bucket (safe to run even if it already exists)
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('hr-documents', 'hr-documents', false, 52428800)   -- 50 MB limit
ON CONFLICT (id) DO UPDATE SET file_size_limit = 52428800;

-- 2. Drop any old conflicting policies
DROP POLICY IF EXISTS "storage_select_hr_docs" ON storage.objects;
DROP POLICY IF EXISTS "storage_insert_hr_docs" ON storage.objects;
DROP POLICY IF EXISTS "storage_update_hr_docs" ON storage.objects;
DROP POLICY IF EXISTS "storage_delete_hr_docs" ON storage.objects;

-- 3. Allow any authenticated or anon user to SELECT (download)
CREATE POLICY "storage_select_hr_docs" ON storage.objects
  FOR SELECT USING (bucket_id = 'hr-documents');

-- 4. Allow upload (INSERT) — this is what was missing!
CREATE POLICY "storage_insert_hr_docs" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'hr-documents');

-- 5. Allow update / upsert
CREATE POLICY "storage_update_hr_docs" ON storage.objects
  FOR UPDATE USING (bucket_id = 'hr-documents');

-- 6. Allow delete (admins only in practice, but permissive at DB level)
CREATE POLICY "storage_delete_hr_docs" ON storage.objects
  FOR DELETE USING (bucket_id = 'hr-documents');

-- Folder structure inside hr-documents/:
--   policy/           ← company-wide HR policies
--   appraisal/        ← appraisal templates
--   guidelines/       ← redeployment/transfer guides
--   compensation/     ← salary structures
--   hr-policy/        ← HR-specific docs
--   staff-docs/{id}/  ← individual staff uploads (photo, certs)


-- ================================================================
--  SEED DATA  (copy-paste from schema.sql or re-insert here)
-- ================================================================

INSERT INTO staff (id,name,email,phone,designation,dept,company,color,manager,is_admin) VALUES
('STI-001','Abimbola Oguntunde','abimbola.oguntunde@stiassetmgt.com','07064090090','Vice Chairman','Executive','STIAM','#C9A84C','',FALSE),
('STI-002','Raji Momohjimoh','raji.momohjimoh@stiassetmgt.com','08033230987','MD/Ceo','Executive','STIAM','#0D1B3E','',FALSE),
('STI-003','Bidemi Ajamajebi','bidemi.ajamajebi@stiassetmgt.com','08032417760','HOD IT','IT','STIAM','#2980B9','Raji Momohjimoh',FALSE),
('STI-004','Odunayo Ajisebutu','odunayo.ajisebutu@stiassetmgt.com','07084674923','IT Officer II','IT','STIAM','#1A7F64','Bidemi Ajamajebi',FALSE),
('STI-005','Angel Okougbo','angel.okougbo@stiassetmgt.com','08056682832','Staff','Operation','STIAM','#7B4F9E','Oluwafemi Prosper',FALSE),
('STI-006','Oluwatobi Adebisi','oluwatobi.adebisi@stiassetmgt.com','08136848745','Staff','Finance','STIAM','#C0392B','Samuel Akinola',FALSE),
('STI-007','Temiloluwa Oshomo','temiloluwa.oshomo@stiassetmgt.com','09063700800','Staff','Finance','STIAM','#16A085','Samuel Akinola',FALSE),
('STI-008','Delightsome Sewanu','delightsome.sewanu@stiassetmgt.com','07041540618','Staff','Finance','STIAM','#E67E22','Samuel Akinola',FALSE),
('STI-009','Precious Aduloju','precious.aduloju@stiassetmgt.com','08109628602','Staff','Finance','STIAM','#D4AC0D','Samuel Akinola',FALSE),
('STI-010','Samuel Akinola','samuel.akinola@stiassetmgt.com','07037067176','HOD Finance','Finance','STIAM','#27AE60','Raji Momohjimoh',FALSE),
('STI-011','Moses Abejoye','moses.abejoye@stiassetmhgt.com','08134863623','Staff','Investment','STIAM','#8E44AD','Oluwemimo Omotoso',FALSE),
('STI-012','Simileloluwa Ajisegbede','simileoluwa.ajisegbede@stiassetmgt.com','09023061393','Staff','Investment','STIAM','#2C3E50','Oluwemimo Omotoso',FALSE),
('STI-013','Oluwemimo Omotoso','oluwemimo.omotoso@stiassetmgt.com','08022924837','HOD Investment','Investment','STIAM','#1A7F64','Raji Momohjimoh',FALSE),
('STI-014','Obaloluwa Okunade','obaloluwa.okunade@stiassetmgt.com','09038253484','Staff','Investment','STIAM','#E74C3C','Oluwemimo Omotoso',FALSE),
('STI-016','Ayomide Togbese','ayomide.togbese@stiassetmgt.com','08138005149','Staff','Investment','STIAM','#2980B9','Oluwemimo Omotoso',FALSE),
('STI-017','Imoleayo Olanrewaju','imoleayo.olanrewaju@stiassetmgt.com','09054353206','Staff','Operation','STIAM','#C0392B','Oluwafemi Prosper',FALSE),
('STI-018','Oluwafemi Prosper','oluwafemi.prosper@stiassetmgt.com','08130069043','HOD Operations','Operations','STIAM','#16A085','Raji Momohjimoh',FALSE),
('STI-019','Cynthia Monyei','cynthia.monyei@stiassetmgt.com','08180469050','Staff','Credit','STIAM','#7B4F9E','Samuel Akinola',FALSE),
('STI-020','Raphael Akpani','raphael.akpani@stiassetmgt.com','08053335977','Staff','Operation','STIAM','#E67E22','Oluwafemi Prosper',FALSE),
('STI-021','Ekene Robinson','ekene.robinson@stiassetmgt.com','08033785902','Staff','Compliance','STIAM','#2C3E50','Raji Momohjimoh',FALSE),
('STI-022','Lateefat Omoboriowo','lateefat.omoboriowo@stiassetmgt.com','08089687033','Staff','Admin','STIAM','#27AE60','Bukola Ononye',FALSE),
('STI-023','Amarachi Adolph','amarachi.adolph@stiassetmgt.com','09059455287','Staff','Admin','STIAM','#C9A84C','Bukola Ononye',FALSE),
('STI-024','Bukola Ononye','bukola.ononye@stiassetmgt.com','08066642595','HOD HR Manager/Admin','HR','STIAM','#C9A84C','Raji Momohjimoh',TRUE),
('DVT-001','Akinsooto Oluwafunmilayo','a.oluwafunmilayo@devtagefs.com','','Staff','General','DEVTAGE','#2980B9','Oloruntola John',FALSE),
('DVT-003','Favor Izege','i.favor@devtagefs.com','','Staff','General','DEVTAGE','#7B4F9E','Oloruntola John',FALSE),
('DVT-004','Kayode Oguntunde','o.kayode@devtagefs.com','','Chief Operating Officer','Operations','DEVTAGE','#E67E22','Raji Momohjimoh',FALSE),
('DVT-005','Oloruntola John','o.john@devtagefs.com','07066085391','HOD Credit','Credit','DEVTAGE','#C0392B','Raji Momohjimoh',FALSE),
('DVT-006','Prosper Oluwafemi','p.oluwafemi@devtagefs.com','08130069043','Staff','Operation','DEVTAGE','#16A085','Oloruntola John',FALSE),
('DVT-008','Raji Momohjomoh','r.momohjimoh@devtagefs.com','08033230987','Director','Executive','DEVTAGE','#0D1B3E','Raji Momohjimoh',FALSE),
('DVT-009','Abimbola Oguntunde','o.abimbola@devtagefs.com','07064090090','Director','Executive','DEVTAGE','#C9A84C','Raji Momohjimoh',FALSE)
ON CONFLICT (id) DO UPDATE SET
  name=EXCLUDED.name, email=EXCLUDED.email, phone=EXCLUDED.phone,
  designation=EXCLUDED.designation, dept=EXCLUDED.dept,
  company=EXCLUDED.company, color=EXCLUDED.color,
  manager=EXCLUDED.manager, is_admin=EXCLUDED.is_admin;

INSERT INTO exited_staff (id,name,role,dept,exit_date,reason,type,clearance,company,notes) VALUES
('EX-001','Eboselumhen Oyungbo','Staff','Operations','2026-01-31','Contract Exhausted','Contractual','Cleared','STIAM','STI-015 — Contract not renewed'),
('EX-002','Emeka Miracle','Staff','General','2026-01-15','Resignation','Voluntary','Cleared','DEVTAGE','DVT-002 — Resigned voluntarily'),
('EX-003','Temitope Mohammed','Staff','General','2026-01-20','Resignation','Voluntary','Cleared','DEVTAGE','DVT-007 — Resigned voluntarily')
ON CONFLICT (id) DO UPDATE SET
  name=EXCLUDED.name, role=EXCLUDED.role, dept=EXCLUDED.dept,
  exit_date=EXCLUDED.exit_date, reason=EXCLUDED.reason,
  type=EXCLUDED.type, clearance=EXCLUDED.clearance,
  company=EXCLUDED.company, notes=EXCLUDED.notes;


-- ================================================================
--  QUICK VERIFY QUERIES
-- ================================================================
-- SELECT company, COUNT(*) AS staff_count FROM staff GROUP BY company ORDER BY company;
-- SELECT * FROM exited_staff ORDER BY exit_date DESC;
-- SELECT COUNT(*) FROM leave_requests;
-- SELECT COUNT(*) FROM grievances;


-- ================================================================
--  MIGRATION PATH → Supabase Auth (future)
-- ================================================================
--
--  When you're ready to use real auth (supa.auth.signIn):
--
--  1. In the sign-in screen, replace buildCreds() logic with:
--       const { data, error } = await supa.auth.signInWithPassword({
--         email: email,
--         password: password
--       });
--
--  2. After sign-in, link the auth user to your staff row:
--       await supa.from('staff')
--         .update({ auth_uid: data.user.id })
--         .eq('email', email);
--
--  3. Remove the permissive RLS policies (USING TRUE) and
--     uncomment the strict policies in the block above.
--
--  4. The app will then enforce per-user row ownership
--     automatically via auth.uid() in every policy.
-- ================================================================


-- ================================================================
--  TABLE 10 · NOTIFICATIONS
--  In-app message center — sent by HR to staff or admin.
--  No auth.uid() needed; recipient_id maps to staff.id
-- ================================================================
CREATE TABLE IF NOT EXISTS notifications (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipient_id TEXT        NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  from_name    TEXT,                -- display name of sender (HR admin / system)
  title        TEXT        NOT NULL,
  message      TEXT        NOT NULL,
  type         TEXT        NOT NULL DEFAULT 'info',
                                    -- info | success | warning | error
  read         BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notifs_recipient ON notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifs_read      ON notifications(recipient_id, read);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "internal_all_notifs" ON notifications FOR ALL USING (TRUE);

-- Add to realtime publications
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- Sample notifications (optional — remove if not wanted)
-- INSERT INTO notifications (recipient_id, from_name, title, message, type) VALUES
-- ('STI-024','System','👋 Welcome to STIAM-HR','Your notification center is now active. You will receive messages here when staff submit requests or when actions are taken on your requests.','info');


-- ================================================================
--  TABLE 11 · VAULT_DOCUMENTS
--  Metadata for every file uploaded to the hr-documents bucket.
--  This is the source of truth for the Document Vault listing.
-- ================================================================
CREATE TABLE IF NOT EXISTS vault_documents (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  name         TEXT        NOT NULL,                       -- display name (e.g. "Leave Policy 2026")
  category     TEXT        NOT NULL DEFAULT 'General',     -- Policy | Appraisal | Guidelines | Compensation | HR Policy | General
  file_type    TEXT        NOT NULL,                       -- PDF | DOCX | XLSX | PPT | PNG | JPG
  file_size    TEXT        NOT NULL,                       -- human-readable: "1.2 MB"
  storage_path TEXT        NOT NULL,                       -- path inside hr-documents bucket
  access_level TEXT        NOT NULL DEFAULT 'All Staff',   -- All Staff | Management | HR Only
  uploaded_by  TEXT,                                       -- staff name of uploader
  uploaded_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vault_docs_cat ON vault_documents(category);

ALTER TABLE vault_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "internal_all_vault_docs" ON vault_documents FOR ALL USING (TRUE);
