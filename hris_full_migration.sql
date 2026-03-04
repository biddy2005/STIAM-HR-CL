-- ================================================================
--  STIAM-HR · COMPLETE HRIS EXPANSION MIGRATION
--  Run this entire script in Supabase → SQL Editor
--  Safe to re-run (uses IF NOT EXISTS / ADD COLUMN IF NOT EXISTS)
-- ================================================================

-- 1. PASSWORD CENTER: custom password column
ALTER TABLE staff ADD COLUMN IF NOT EXISTS custom_password TEXT DEFAULT NULL;

-- 2. ADMIN MANAGEMENT: already handled by is_admin column
-- (should already exist from schema_complete.sql)
ALTER TABLE staff ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- ================================================================
--  3. CONTRACTS & EMPLOYMENT RECORDS
-- ================================================================
CREATE TABLE IF NOT EXISTS contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id TEXT NOT NULL,
  staff_name TEXT NOT NULL,
  contract_type TEXT NOT NULL DEFAULT 'Permanent',
  start_date DATE NOT NULL,
  end_date DATE,
  probation_end DATE,
  notice_period TEXT DEFAULT '3 months',
  job_grade TEXT,
  salary_band TEXT,
  status TEXT NOT NULL DEFAULT 'Active',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS contracts_all ON contracts;
CREATE POLICY contracts_all ON contracts USING (TRUE) WITH CHECK (TRUE);

-- ================================================================
--  4. DISCIPLINARY RECORDS
-- ================================================================
CREATE TABLE IF NOT EXISTS disciplinary_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id TEXT NOT NULL,
  staff_name TEXT NOT NULL,
  record_type TEXT NOT NULL DEFAULT 'Query',
  description TEXT NOT NULL,
  issued_date DATE NOT NULL,
  issued_by TEXT NOT NULL,
  outcome TEXT,
  status TEXT NOT NULL DEFAULT 'Open',
  response TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE disciplinary_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS disciplinary_all ON disciplinary_records;
CREATE POLICY disciplinary_all ON disciplinary_records USING (TRUE) WITH CHECK (TRUE);

-- ================================================================
--  5. ONBOARDING & OFFBOARDING TASKS
-- ================================================================
CREATE TABLE IF NOT EXISTS onboarding_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id TEXT NOT NULL,
  staff_name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'onboarding', -- onboarding | offboarding
  task TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Pending',       -- Pending | Complete
  assigned_to TEXT DEFAULT 'HR',
  due_date DATE,
  completed_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE onboarding_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS onboarding_all ON onboarding_tasks;
CREATE POLICY onboarding_all ON onboarding_tasks USING (TRUE) WITH CHECK (TRUE);

-- ================================================================
--  6. PAYROLL RUNS & LINE ITEMS
-- ================================================================
CREATE TABLE IF NOT EXISTS payroll_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pay_month TEXT NOT NULL UNIQUE,  -- e.g. '2026-02'
  status TEXT NOT NULL DEFAULT 'Draft',
  staff_count INT DEFAULT 0,
  total_gross NUMERIC(14,2) DEFAULT 0,
  total_net NUMERIC(14,2) DEFAULT 0,
  total_paye NUMERIC(14,2) DEFAULT 0,
  total_pension NUMERIC(14,2) DEFAULT 0,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE payroll_runs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS payroll_runs_all ON payroll_runs;
CREATE POLICY payroll_runs_all ON payroll_runs USING (TRUE) WITH CHECK (TRUE);

CREATE TABLE IF NOT EXISTS payroll_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID REFERENCES payroll_runs(id) ON DELETE CASCADE,
  staff_id TEXT NOT NULL,
  staff_name TEXT NOT NULL,
  dept TEXT,
  company TEXT,
  gross NUMERIC(12,2) DEFAULT 0,
  basic NUMERIC(12,2) DEFAULT 0,
  transport NUMERIC(12,2) DEFAULT 0,
  housing NUMERIC(12,2) DEFAULT 0,
  paye NUMERIC(12,2) DEFAULT 0,
  pension_emp NUMERIC(12,2) DEFAULT 0,
  pension_er NUMERIC(12,2) DEFAULT 0,
  nhf NUMERIC(12,2) DEFAULT 0,
  total_deductions NUMERIC(12,2) DEFAULT 0,
  net_pay NUMERIC(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE payroll_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS payroll_items_all ON payroll_items;
CREATE POLICY payroll_items_all ON payroll_items USING (TRUE) WITH CHECK (TRUE);

-- ================================================================
--  7. BENEFITS (HMO, PENSION, LIFE INSURANCE)
-- ================================================================
CREATE TABLE IF NOT EXISTS benefits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id TEXT NOT NULL UNIQUE,
  staff_name TEXT NOT NULL,
  hmo_provider TEXT,
  hmo_plan TEXT DEFAULT 'Standard',
  hmo_expiry DATE,
  pfa_name TEXT,
  pfa_id TEXT,
  life_insured BOOLEAN DEFAULT FALSE,
  life_amount NUMERIC(14,2),
  notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE benefits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS benefits_all ON benefits;
CREATE POLICY benefits_all ON benefits USING (TRUE) WITH CHECK (TRUE);

-- ================================================================
--  8. LEAVE BALANCES
-- ================================================================
CREATE TABLE IF NOT EXISTS leave_balances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id TEXT NOT NULL,
  staff_name TEXT NOT NULL,
  year INT NOT NULL DEFAULT EXTRACT(YEAR FROM NOW()),
  annual_entitled INT DEFAULT 21,
  annual_taken INT DEFAULT 0,
  sick_entitled INT DEFAULT 10,
  sick_taken INT DEFAULT 0,
  maternity_entitled INT DEFAULT 84,
  maternity_taken INT DEFAULT 0,
  paternity_entitled INT DEFAULT 5,
  paternity_taken INT DEFAULT 0,
  other_taken INT DEFAULT 0,
  UNIQUE(staff_id, year)
);
ALTER TABLE leave_balances ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS leave_balances_all ON leave_balances;
CREATE POLICY leave_balances_all ON leave_balances USING (TRUE) WITH CHECK (TRUE);

-- ================================================================
--  9. AUDIT LOG
-- ================================================================
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action TEXT NOT NULL,
  actor TEXT,
  detail TEXT,
  module TEXT DEFAULT 'General',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS audit_log_all ON audit_log;
CREATE POLICY audit_log_all ON audit_log USING (TRUE) WITH CHECK (TRUE);

-- ================================================================
--  10. TRAINING RECORDS
-- ================================================================
CREATE TABLE IF NOT EXISTS training_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id TEXT NOT NULL,
  staff_name TEXT NOT NULL,
  title TEXT NOT NULL,
  provider TEXT,
  category TEXT DEFAULT 'Technical',
  training_date DATE NOT NULL,
  end_date DATE,
  duration_days INT DEFAULT 1,
  status TEXT DEFAULT 'Completed',
  cost NUMERIC(12,2),
  certificate_obtained BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE training_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS training_all ON training_records;
CREATE POLICY training_all ON training_records USING (TRUE) WITH CHECK (TRUE);

-- ================================================================
--  11. SURVEYS & RESPONSES
-- ================================================================
CREATE TABLE IF NOT EXISTS surveys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  questions JSONB NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'Active',
  created_by TEXT,
  deadline DATE,
  anonymous BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE surveys ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS surveys_all ON surveys;
CREATE POLICY surveys_all ON surveys USING (TRUE) WITH CHECK (TRUE);

CREATE TABLE IF NOT EXISTS survey_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE,
  staff_id TEXT,
  staff_name TEXT,
  answers JSONB NOT NULL DEFAULT '{}',
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS survey_responses_all ON survey_responses;
CREATE POLICY survey_responses_all ON survey_responses USING (TRUE) WITH CHECK (TRUE);

-- ================================================================
--  DONE — All 11 feature tables created.
--  Summary of what each powers:
--
--  custom_password (staff)  → Password Center
--  is_admin (staff)         → Admin Center
--  contracts                → Contracts & Employment Records
--  disciplinary_records     → Disciplinary Module
--  onboarding_tasks         → Onboarding & Offboarding
--  payroll_runs + items     → Payroll Engine (PAYE, Pension, NHF)
--  benefits                 → Benefits Admin (HMO, PFA, Life Insurance)
--  leave_balances           → Leave entitlement ledger
--  audit_log                → Audit Trail
--  training_records         → Training & Development
--  surveys + responses      → Pulse Surveys & Feedback
-- ================================================================
