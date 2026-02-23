-- ================================================================
--  STIAM-HR · Supabase Schema + Seed Data
--  Run this in: Supabase Dashboard → SQL Editor → Run
-- ================================================================

-- ── 1. STAFF TABLE ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS staff (
  id            TEXT PRIMARY KEY,          -- e.g. STI-001
  name          TEXT NOT NULL,
  email         TEXT UNIQUE NOT NULL,
  phone         TEXT,
  designation   TEXT,
  dept          TEXT,
  company       TEXT NOT NULL,             -- STIAM | DEVTAGE | CEDAR_LON | CEDAR_ASSET
  color         TEXT DEFAULT '#2980B9',
  manager       TEXT,
  photo         TEXT,                      -- base64 or Supabase Storage URL
  achievements  TEXT,
  is_admin      BOOLEAN DEFAULT FALSE,
  is_super_admin BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. LEAVE REQUESTS TABLE ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS leave_requests (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id   TEXT REFERENCES staff(id),
  employee   TEXT NOT NULL,
  type       TEXT NOT NULL,
  from_date  DATE NOT NULL,
  to_date    DATE NOT NULL,
  days       INT  NOT NULL,
  relief     TEXT,
  reason     TEXT,
  status     TEXT DEFAULT 'Pending',       -- Pending | Approved | Declined
  submitted  DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. CLOCK RECORDS TABLE ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS clock_records (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id    TEXT REFERENCES staff(id),
  record_date DATE NOT NULL DEFAULT CURRENT_DATE,
  clock_in    TEXT,                         -- e.g. "08:01"
  clock_out   TEXT,
  status      TEXT DEFAULT 'Present',       -- Present | Late | Absent | On Leave
  device_id   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(staff_id, record_date)
);

-- ── 4. EXITED STAFF TABLE ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS exited_staff (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  role        TEXT,
  dept        TEXT,
  exit_date   DATE,
  reason      TEXT,
  type        TEXT DEFAULT 'Voluntary',     -- Voluntary | Involuntary | Contractual
  clearance   TEXT DEFAULT 'Pending',       -- Cleared | Pending | Withheld
  company     TEXT,
  notes       TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 5. REDEPLOYMENT / TRANSFER REQUESTS TABLE ───────────────────
CREATE TABLE IF NOT EXISTS redeployment_posts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT NOT NULL,
  dept          TEXT,                        -- repurposed: from_company
  type          TEXT,                        -- repurposed: to_company
  requirements  TEXT,
  status        TEXT DEFAULT 'Pending',      -- Pending | Approved | Declined | Under Review
  company       TEXT,                        -- requesting staff_id
  posted_date   DATE DEFAULT CURRENT_DATE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── 6. SUPABASE STORAGE BUCKET ──────────────────────────────────
-- Run in Supabase Dashboard → Storage → New Bucket
-- Name: hr-documents
-- Privacy: Private (recommended) or Public for open access

-- Storage policies (run in SQL Editor):
-- INSERT INTO storage.buckets (id, name, public) VALUES ('hr-documents', 'hr-documents', false);

-- ── 7. ROW LEVEL SECURITY ───────────────────────────────────────
ALTER TABLE staff          ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE clock_records  ENABLE ROW LEVEL SECURITY;
ALTER TABLE exited_staff   ENABLE ROW LEVEL SECURITY;
ALTER TABLE redeployment_posts ENABLE ROW LEVEL SECURITY;

-- For dev/quick setup: allow all authenticated users (tighten later)
CREATE POLICY "allow_all_staff"         ON staff              FOR ALL USING (TRUE);
CREATE POLICY "allow_all_leaves"        ON leave_requests     FOR ALL USING (TRUE);
CREATE POLICY "allow_all_clock"         ON clock_records      FOR ALL USING (TRUE);
CREATE POLICY "allow_all_exited"        ON exited_staff       FOR ALL USING (TRUE);
CREATE POLICY "allow_all_redeploy"      ON redeployment_posts FOR ALL USING (TRUE);

-- ── 8. REALTIME ─────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE clock_records;
ALTER PUBLICATION supabase_realtime ADD TABLE leave_requests;

-- ================================================================
--  SEED DATA — STIAM STAFF  (Updated Feb 2026)
-- ================================================================

INSERT INTO staff (id, name, email, phone, designation, dept, company, color, manager, is_admin) VALUES

-- STIAM — STI Asset Management Limited
('STI-001', 'Abimbola Oguntunde',       'abimbola.oguntunde@stiassetmgt.com',  '07064090090', 'Vice Chairman',        'Executive',  'STIAM', '#C9A84C', '',                  FALSE),
('STI-002', 'Raji Momohjimoh',          'raji.momohjimoh@stiassetmgt.com',     '08033230987', 'MD/Ceo',               'Executive',  'STIAM', '#0D1B3E', '',                  FALSE),
('STI-003', 'Bidemi Ajamajebi',         'bidemi.ajamajebi@stiassetmgt.com',    '08032417760', 'HOD IT',               'IT',         'STIAM', '#2980B9', 'Raji Momohjimoh',   FALSE),
('STI-004', 'Odunayo Ajisebutu',        'odunayo.ajisebutu@stiassetmgt.com',   '07084674923', 'IT Officer II',        'IT',         'STIAM', '#1A7F64', 'Bidemi Ajamajebi',  FALSE),
('STI-005', 'Angel Okougbo',            'angel.okougbo@stiassetmgt.com',       '08056682832', 'Staff',                'Operation',  'STIAM', '#7B4F9E', 'Oluwafemi Prosper', FALSE),
('STI-006', 'Oluwatobi Adebisi',        'oluwatobi.adebisi@stiassetmgt.com',   '08136848745', 'Staff',                'Finance',    'STIAM', '#C0392B', 'Samuel Akinola',    FALSE),
('STI-007', 'Temiloluwa Oshomo',        'temiloluwa.oshomo@stiassetmgt.com',   '09063700800', 'Staff',                'Finance',    'STIAM', '#16A085', 'Samuel Akinola',    FALSE),
('STI-008', 'Delightsome Sewanu',       'delightsome.sewanu@stiassetmgt.com',  '07041540618', 'Staff',                'Finance',    'STIAM', '#E67E22', 'Samuel Akinola',    FALSE),
('STI-009', 'Precious Aduloju',         'precious.aduloju@stiassetmgt.com',    '08109628602', 'Staff',                'Finance',    'STIAM', '#D4AC0D', 'Samuel Akinola',    FALSE),
('STI-010', 'Samuel Akinola',           'samuel.akinola@stiassetmgt.com',      '07037067176', 'HOD Finance',          'Finance',    'STIAM', '#27AE60', 'Raji Momohjimoh',   FALSE),
('STI-011', 'Moses Abejoye',            'moses.abejoye@stiassetmhgt.com',      '08134863623', 'Staff',                'Investment', 'STIAM', '#8E44AD', 'Oluwemimo Omotoso', FALSE),
('STI-012', 'Simileloluwa Ajisegbede',  'simileoluwa.ajisegbede@stiassetmgt.com','09023061393','Staff',               'Investment', 'STIAM', '#2C3E50', 'Oluwemimo Omotoso', FALSE),
('STI-013', 'Oluwemimo Omotoso',        'oluwemimo.omotoso@stiassetmgt.com',   '08022924837', 'HOD Investment',       'Investment', 'STIAM', '#1A7F64', 'Raji Momohjimoh',   FALSE),
('STI-014', 'Obaloluwa Okunade',        'obaloluwa.okunade@stiassetmgt.com',   '09038253484', 'Staff',                'Investment', 'STIAM', '#E74C3C', 'Oluwemimo Omotoso', FALSE),
('STI-016', 'Ayomide Togbese',          'ayomide.togbese@stiassetmgt.com',     '08138005149', 'Staff',                'Investment', 'STIAM', '#2980B9', 'Oluwemimo Omotoso', FALSE),
('STI-017', 'Imoleayo Olanrewaju',      'imoleayo.olanrewaju@stiassetmgt.com', '09054353206', 'Staff',                'Operation',  'STIAM', '#C0392B', 'Oluwafemi Prosper', FALSE),
('STI-018', 'Oluwafemi Prosper',        'oluwafemi.prosper@stiassetmgt.com',   '08130069043', 'HOD Operations',       'Operations', 'STIAM', '#16A085', 'Raji Momohjimoh',   FALSE),
('STI-019', 'Cynthia Monyei',           'cynthia.monyei@stiassetmgt.com',      '08180469050', 'Staff',                'Credit',     'STIAM', '#7B4F9E', 'Samuel Akinola',    FALSE),
('STI-020', 'Raphael Akpani',           'raphael.akpani@stiassetmgt.com',      '08053335977', 'Staff',                'Operation',  'STIAM', '#E67E22', 'Oluwafemi Prosper', FALSE),
('STI-021', 'Ekene Robinson',           'ekene.robinson@stiassetmgt.com',      '08033785902', 'Staff',                'Compliance', 'STIAM', '#2C3E50', 'Raji Momohjimoh',   FALSE),
('STI-022', 'Lateefat Omoboriowo',      'lateefat.omoboriowo@stiassetmgt.com', '08089687033', 'Staff',                'Admin',      'STIAM', '#27AE60', 'Bukola Ononye',     FALSE),
('STI-023', 'Amarachi Adolph',          'amarachi.adolph@stiassetmgt.com',     '09059455287', 'Staff',                'Admin',      'STIAM', '#C9A84C', 'Bukola Ononye',     FALSE),
('STI-024', 'Bukola Ononye',            'bukola.ononye@stiassetmgt.com',       '08066642595', 'HOD HR Manager/Admin', 'HR',         'STIAM', '#C9A84C', 'Raji Momohjimoh',   TRUE),

-- DEVTAGE — Devtage Financial Services (Emeka Miracle & Temitope Mohammed removed — moved to exited)
('DVT-001', 'Akinsooto Oluwafunmilayo', 'a.oluwafunmilayo@devtagefs.com',      '',            'Staff',                'General',    'DEVTAGE','#2980B9', 'Oloruntola John',   FALSE),
('DVT-003', 'Favor Izege',              'i.favor@devtagefs.com',               '',            'Staff',                'General',    'DEVTAGE','#7B4F9E', 'Oloruntola John',   FALSE),
('DVT-004', 'Kayode Oguntunde',         'o.kayode@devtagefs.com',              '',            'Chief Operating Officer','Operations','DEVTAGE','#E67E22', 'Raji Momohjimoh',   FALSE),
('DVT-005', 'Oloruntola John',          'o.john@devtagefs.com',                '07066085391', 'HOD Credit',           'Credit',     'DEVTAGE','#C0392B', 'Raji Momohjimoh',   FALSE),
('DVT-006', 'Prosper Oluwafemi',        'p.oluwafemi@devtagefs.com',           '08130069043', 'Staff',                'Operation',  'DEVTAGE','#16A085', 'Oloruntola John',   FALSE),
('DVT-008', 'Raji Momohjomoh',          'r.momohjimoh@devtagefs.com',          '08033230987', 'Director',             'Executive',  'DEVTAGE','#0D1B3E', 'Raji Momohjimoh',   FALSE),
('DVT-009', 'Abimbola Oguntunde',       'o.abimbola@devtagefs.com',            '07064090090', 'Director',             'Executive',  'DEVTAGE','#C9A84C', 'Raji Momohjimoh',   FALSE)

ON CONFLICT (id) DO UPDATE SET
  name=EXCLUDED.name, email=EXCLUDED.email, phone=EXCLUDED.phone,
  designation=EXCLUDED.designation, dept=EXCLUDED.dept, company=EXCLUDED.company,
  color=EXCLUDED.color, manager=EXCLUDED.manager, is_admin=EXCLUDED.is_admin;

-- ================================================================
--  SEED DATA — EXITED STAFF  (Updated Feb 2026)
-- ================================================================

INSERT INTO exited_staff (id, name, role, dept, exit_date, reason, type, clearance, company, notes) VALUES
('EX-001', 'Eboselumhen Oyungbo', 'Staff',  'Operations', '2026-01-31', 'Contract Exhausted', 'Contractual', 'Cleared',  'STIAM',   'Contract not renewed — STI-015'),
('EX-002', 'Emeka Miracle',       'Staff',  'General',    '2026-01-15', 'Resignation',        'Voluntary',   'Cleared',  'DEVTAGE', 'DVT-002 — Resigned voluntarily'),
('EX-003', 'Temitope Mohammed',   'Staff',  'General',    '2026-01-20', 'Resignation',        'Voluntary',   'Cleared',  'DEVTAGE', 'DVT-007 — Resigned voluntarily')

ON CONFLICT (id) DO UPDATE SET
  name=EXCLUDED.name, role=EXCLUDED.role, dept=EXCLUDED.dept,
  exit_date=EXCLUDED.exit_date, reason=EXCLUDED.reason, type=EXCLUDED.type,
  clearance=EXCLUDED.clearance, company=EXCLUDED.company, notes=EXCLUDED.notes;

-- ================================================================
--  SUPABASE STORAGE — CREATE BUCKET (run separately in Dashboard)
-- ================================================================
-- In Supabase Dashboard → Storage → Create bucket:
--   Name:   hr-documents
--   Public: false (private, authenticated access only)
--
-- Then add this Storage policy in SQL Editor:
-- CREATE POLICY "auth_users_storage"
--   ON storage.objects FOR ALL
--   USING (bucket_id = 'hr-documents' AND auth.role() = 'authenticated');
--
-- Folder structure inside hr-documents/:
--   policy/           ← company policies
--   appraisal/        ← appraisal templates
--   guidelines/       ← HR guidelines
--   compensation/     ← salary/comp files
--   hr-policy/        ← HR-specific docs
--   staff-docs/       ← individual staff uploads (photo, certs)

-- ================================================================
--  QUICK VERIFY
-- ================================================================
-- SELECT company, COUNT(*) FROM staff GROUP BY company;
-- Expected: STIAM=23, DEVTAGE=7
-- SELECT * FROM exited_staff ORDER BY exit_date DESC;
-- Expected: 3 rows (Eboselumhen, Emeka, Temitope)
