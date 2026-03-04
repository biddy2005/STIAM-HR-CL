-- ============================================================
--  STIAM-HR  —  Supabase Schema
--  Run this entire file in: Supabase Dashboard → SQL Editor
-- ============================================================


-- ─── EXTENSIONS ─────────────────────────────────────────────
create extension if not exists "uuid-ossp";


-- ─── TABLE: staff ───────────────────────────────────────────
create table if not exists staff (
  id            text primary key,
  name          text not null,
  email         text unique not null,
  phone         text default '—',
  designation   text default 'Staff',
  dept          text default 'General',
  company       text default 'STIAM',
  color         text default '#2980B9',
  manager       text default '',
  photo         text,                       -- base64 data URL or storage URL
  achievements  text default '',
  is_admin      boolean default false,
  is_super_admin boolean default false,
  created_at    timestamptz default now()
);

-- ─── TABLE: leave_requests ──────────────────────────────────
create table if not exists leave_requests (
  id          text primary key default 'LR-' || to_char(now(), 'YYYYMMDDHH24MISS'),
  staff_id    text references staff(id) on delete cascade,
  employee    text not null,
  type        text default 'Annual Leave',
  from_date   date not null,
  to_date     date not null,
  days        integer not null,
  relief      text,
  reason      text,
  status      text default 'Pending' check (status in ('Pending','Approved','Declined')),
  submitted   date default current_date,
  created_at  timestamptz default now()
);

-- ─── TABLE: clock_records ───────────────────────────────────
create table if not exists clock_records (
  id          uuid primary key default uuid_generate_v4(),
  staff_id    text references staff(id) on delete cascade,
  record_date date default current_date,
  clock_in    time,
  clock_out   time,
  status      text default 'Present' check (status in ('Present','Late','On Leave','Absent')),
  device_id   text,                         -- for biometric device integration
  created_at  timestamptz default now(),
  unique(staff_id, record_date)             -- one record per staff per day
);

-- ─── TABLE: exited_staff ────────────────────────────────────
create table if not exists exited_staff (
  id          text primary key default 'EX-' || to_char(now(), 'YYYYMMDDHH24MISS'),
  name        text not null,
  role        text,
  dept        text,
  exit_date   date,
  reason      text,
  type        text default 'Voluntary' check (type in ('Voluntary','Involuntary','Contractual')),
  clearance   text default 'Pending' check (clearance in ('Cleared','Pending','Withheld')),
  company     text default 'STIAM',
  notes       text default '',
  created_at  timestamptz default now()
);

-- ─── TABLE: redeployment_posts ──────────────────────────────
create table if not exists redeployment_posts (
  id           text primary key default 'RD-' || to_char(now(), 'YYYYMMDDHH24MISS'),
  title        text not null,
  dept         text,
  type         text default 'Permanent' check (type in ('Permanent','Contract')),
  requirements text,
  status       text default 'Open' check (status in ('Open','Closed')),
  company      text default 'STIAM',
  posted_date  date default current_date,
  created_at   timestamptz default now()
);

-- ─── TABLE: staff_documents ─────────────────────────────────
create table if not exists staff_documents (
  id          uuid primary key default uuid_generate_v4(),
  staff_id    text references staff(id) on delete cascade,
  name        text not null,
  file_url    text,                          -- Supabase Storage URL
  uploaded_at timestamptz default now()
);


-- ============================================================
--  ROW LEVEL SECURITY (RLS)
-- ============================================================

alter table staff             enable row level security;
alter table leave_requests    enable row level security;
alter table clock_records     enable row level security;
alter table exited_staff      enable row level security;
alter table redeployment_posts enable row level security;
alter table staff_documents   enable row level security;

-- For now: allow all operations with anon key (tighten per your auth setup)
-- Replace these with proper user-based policies once you add Supabase Auth

create policy "allow_all_staff"             on staff             for all using (true) with check (true);
create policy "allow_all_leave_requests"    on leave_requests    for all using (true) with check (true);
create policy "allow_all_clock_records"     on clock_records     for all using (true) with check (true);
create policy "allow_all_exited_staff"      on exited_staff      for all using (true) with check (true);
create policy "allow_all_redeployment"      on redeployment_posts for all using (true) with check (true);
create policy "allow_all_documents"         on staff_documents   for all using (true) with check (true);


-- ============================================================
--  ENABLE REAL-TIME (for clock-in live updates)
-- ============================================================

alter publication supabase_realtime add table clock_records;
alter publication supabase_realtime add table leave_requests;


-- ============================================================
--  SEED DATA — Staff
-- ============================================================

insert into staff (id, name, email, phone, designation, dept, company, color, manager, is_admin) values
('STI-001','Abimbola Oguntunde','abimbola.oguntunde@stiassetmgt.com','07064090090','Vice Chairman','Executive','STIAM','#C9A84C','',false),
('STI-002','Raji Momohjimoh','raji.momohjimoh@stiassetmgt.com','08033230987','MD/Ceo','Executive','STIAM','#0D1B3E','',false),
('STI-003','Bidemi Ajamajebi','bidemi.ajamajebi@stiassetmgt.com','08032417760','HOD IT','IT','STIAM','#2980B9','Raji Momohjimoh',false),
('STI-004','Odunayo Ajisebutu','odunayo.ajisebutu@stiassetmgt.com','07084674923','Staff','IT','STIAM','#1A7F64','Bidemi Ajamajebi',false),
('STI-005','Angel Okougbo','angel.okougbo@stiassetmgt.com','08056682832','Staff','Operations','STIAM','#7B4F9E','Oluwafemi Prosper',false),
('STI-006','Oluwatobi Adebisi','oluwatobi.adebisi@stiassetmgt.com','08136848745','Staff','Finance','STIAM','#C0392B','Samuel Akinola',false),
('STI-007','Temiloluwa Oshomo','temiloluwa.oshomo@stiassetmgt.com','09063700800','Staff','Investment','STIAM','#16A085','Oluwemimo Omotoso',false),
('STI-008','Delightsome Sewanu','delightsome.sewanu@stiassetmgt.com','07041540618','Staff','Operations','STIAM','#E67E22','Oluwafemi Prosper',false),
('STI-009','Precious Aduloju','precious.aduloju@stiassetmgt.com','08109628602','Staff','HR','STIAM','#D4AC0D','Bukola Ononye',false),
('STI-010','Samuel Akinola','samuel.akinola@stiassetmgt.com','07037067176','HOD Finance','Finance','STIAM','#27AE60','Raji Momohjimoh',false),
('STI-011','Moses Abejoye','moses.abejoye@stiassetmhgt.com','08134863623','Staff','Finance','STIAM','#8E44AD','Samuel Akinola',false),
('STI-012','Simileloluwa Ajisegbede','simileoluwa.ajisegbede@stiassetmgt.com','09023061393','Staff','Investment','STIAM','#2C3E50','Oluwemimo Omotoso',false),
('STI-013','Oluwemimo Omotoso','oluwemimo.omotoso@stiassetmgt.com','08022924837','HOD Investment','Investment','STIAM','#1A7F64','Raji Momohjimoh',false),
('STI-014','Obaloluwa Okunade','obaloluwa.okunade@stiassetmgt.com','09038253484','Staff','Investment','STIAM','#E74C3C','Oluwemimo Omotoso',false),
('STI-015','Eboselumhen Oyungbo','eboselumhen.oyungbo@stiassetmgt.com','07030790319','Staff','Operations','STIAM','#F39C12','Oluwafemi Prosper',false),
('STI-016','Ayomide Togbese','ayomide.togbese@stiassetmgt.com','08138005149','Staff','HR','STIAM','#2980B9','Bukola Ononye',false),
('STI-017','Imoleayo Olanrewaju','imoleayo.olanrewaju@stiassetmgt.com','09054353206','Staff','Operations','STIAM','#C0392B','Oluwafemi Prosper',false),
('STI-018','Oluwafemi Prosper','oluwafemi.prosper@stiassetmgt.com','08130069043','HOD Operations','Operations','STIAM','#16A085','Raji Momohjimoh',false),
('STI-019','Cynthia Monyei','cynthia.monyei@stiassetmgt.com','08180469050','Staff','Finance','STIAM','#7B4F9E','Samuel Akinola',false),
('STI-020','Raphael Akpani','raphael.akpani@stiassetmgt.com','08053335977','Staff','IT','STIAM','#E67E22','Bidemi Ajamajebi',false),
('STI-021','Ekene Robinson','ekene.robinson@stiassetmgt.com','08033785902','Staff','Operations','STIAM','#2C3E50','Oluwafemi Prosper',false),
('STI-022','Lateefat Omoboriowo','lateefat.omoboriowo@stiassetmgt.com','08089687033','Staff','Finance','STIAM','#27AE60','Samuel Akinola',false),
('STI-023','Amarachi Adolph','amarachi.adolph@stiassetmgt.com','09059455287','Staff','Investment','STIAM','#C9A84C','Oluwemimo Omotoso',false),
('STI-024','Bukola Ononye','bukola.ononye@stiassetmgt.com','08066642595','HOD HR Manager','HR','STIAM','#C9A84C','Raji Momohjimoh',true),
('DVT-001','Akinsooto Oluwafunmilayo','a.oluwafunmilayo@devtagefs.com','—','Staff','General','DEVTAGE','#2980B9','Oloruntola John',false),
('DVT-002','Emeka Miracle','e.miracle@devtagefs.com','—','Staff','General','DEVTAGE','#1A7F64','Oloruntola John',false),
('DVT-003','Favor Izege','i.favor@devtagefs.com','—','Staff','General','DEVTAGE','#7B4F9E','Oloruntola John',false),
('DVT-004','Kayode Oguntunde','o.kayode@devtagefs.com','—','Staff','General','DEVTAGE','#E67E22','Oloruntola John',false),
('DVT-005','Oloruntola John','o.john@devtagefs.com','07066085391','HOD Credit','Credit','DEVTAGE','#C0392B','Raji Momohjimoh',false),
('DVT-006','Prosper Oluwafemi','p.oluwafemi@devtagefs.com','08130069043','Staff','General','DEVTAGE','#16A085','Oloruntola John',false),
('DVT-007','Temitope Mohammed','m.temitope@devtagefs.com','07062296638','Staff','General','DEVTAGE','#F39C12','Oloruntola John',false),
('DVT-008','Raji Momohjomoh','r.momohjimoh@devtagefs.com','08033230987','Staff','Executive','DEVTAGE','#0D1B3E','Oloruntola John',false),
('DVT-009','Abimbola Oguntunde','o.abimbola@devtagefs.com','07064090090','Staff','Executive','DEVTAGE','#C9A84C','Oloruntola John',false)
on conflict (id) do nothing;


-- ============================================================
--  SEED DATA — Leave Requests
-- ============================================================

insert into leave_requests (id, staff_id, employee, type, from_date, to_date, days, relief, reason, status, submitted) values
('LR-001','STI-007','Temiloluwa Oshomo','Annual Leave','2026-02-25','2026-03-01',5,'Delightsome Sewanu','Family vacation','Pending','2026-02-10'),
('LR-002','STI-016','Ayomide Togbese','Sick Leave','2026-02-17','2026-02-21',5,'Precious Aduloju','Medical treatment','Approved','2026-02-16'),
('LR-003','STI-004','Odunayo Ajisebutu','Annual Leave','2026-03-10','2026-03-18',9,'Angel Okougbo','Personal','Pending','2026-02-12')
on conflict (id) do nothing;


-- ============================================================
--  SEED DATA — Exited Staff
-- ============================================================

insert into exited_staff (id, name, role, dept, exit_date, reason, type, clearance, company) values
('EX-001','Kelechi Nwosu','Portfolio Analyst','Investment','2023-08-31','Resignation','Voluntary','Cleared','STIAM'),
('EX-002','Blessing Okoro','Market Researcher','Research','2024-01-15','Contract End','Contractual','Cleared','STIAM'),
('EX-003','Yusuf Lawal','IT Support','IT','2024-06-30','Redundancy','Involuntary','Cleared','STIAM')
on conflict (id) do nothing;


-- ============================================================
--  SEED DATA — Redeployment Posts
-- ============================================================

insert into redeployment_posts (id, title, dept, type, requirements, status, company, posted_date) values
('RD-001','Senior Research Analyst','Investment','Permanent','5+ yrs investment research, CFA preferred','Open','STIAM','2026-02-01'),
('RD-002','Finance Officer','Finance','Permanent','3+ yrs finance/accounting, ACA advantage','Open','STIAM','2026-01-28'),
('RD-003','IT Support Specialist','IT','Contract','2+ yrs IT support, CCNA a plus','Closed','STIAM','2026-02-10')
on conflict (id) do nothing;


-- ============================================================
--  SEED DATA — Today's Clock Records
-- ============================================================

insert into clock_records (staff_id, record_date, clock_in, status) values
('STI-024', current_date, '08:01', 'Present'),
('STI-010', current_date, '08:15', 'Present'),
('STI-013', current_date, '07:55', 'Present'),
('STI-003', current_date, '09:20', 'Late'),
('STI-004', current_date, '08:30', 'Present'),
('STI-018', current_date, '08:00', 'Present'),
('STI-009', current_date, '08:10', 'Present'),
('STI-006', current_date, '09:45', 'Late'),
('STI-007', current_date, null,    'On Leave'),
('STI-016', current_date, null,    'Absent')
on conflict (staff_id, record_date) do nothing;


-- ============================================================
--  HELPFUL VIEWS
-- ============================================================

-- Today's attendance summary
create or replace view today_attendance as
select
  s.id, s.name, s.designation, s.dept, s.company, s.color,
  cr.clock_in, cr.clock_out, cr.status
from staff s
left join clock_records cr
  on cr.staff_id = s.id and cr.record_date = current_date
where s.company = 'STIAM';

-- Leave balance per staff
create or replace view leave_balances as
select
  s.id, s.name, s.designation,
  case when s.designation in (
    'Vice Chairman','MD/Ceo','HOD IT','HOD Finance','HOD Investment',
    'HOD Operations','HOD HR Manager','HOD Credit','CEO','Chairman',
    'Director','HOD Legal','Managing Director','Executive Director'
  ) then 20 else 15 end as entitlement,
  coalesce(sum(case when lr.status='Approved' then lr.days else 0 end),0) as used
from staff s
left join leave_requests lr on lr.staff_id = s.id
group by s.id, s.name, s.designation;
