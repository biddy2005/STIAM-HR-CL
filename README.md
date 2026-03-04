# STIAM-HR Portal

A comprehensive, browser-based **Human Resources Information System (HRIS)** for STI Asset Management Ltd and group companies.

---

## 🚀 Quick Start

```bash
npm install
npm start
# Open http://localhost:3000
```

**Default credentials:**
- Super Admin: `superadmin@stiam.com` / `admin@STIAM2024`
- Staff: work email / staff ID (e.g. `STI-004`)

---

## ✨ Modules (30+)

| Module | Description |
|---|---|
| 📊 Dashboard | Live workforce KPIs, pending actions |
| 📈 HR Analytics | Headcount, leave, department charts |
| 👥 Employee Directory | Search & filter all staff across entities |
| 📝 Contracts | Employment records, probation & expiry alerts |
| 🗓 Leave Management | Requests, approvals, leave calendar |
| 💵 Payroll Engine | Full Nigerian payroll — PAYE, Pension, NHF |
| 🏥 Benefits Admin | HMO, PFA pension, life insurance tracking |
| 📊 Performance | KPI appraisals with animated sliders |
| ⏰ Clock-In Register | Real-time attendance + biometric integration |
| ⚖️ Disciplinary | Queries, warnings, suspensions (confidential) |
| 🎯 Onboarding | New hire checklists + employee creation |
| 🎓 Training | Course log, budget, certificates |
| 📋 Surveys | Pulse surveys with Likert analytics |
| 📁 Document Vault | Secure file storage (Supabase Storage) |
| ⚠️ Compliance | Auto alerts — HMO expiry, contracts, PFA |
| 🔍 Audit Log | Real-time activity trail (Supabase Realtime) |
| ✉️ Messages | Internal messaging with broadcast support |
| 🔄 Redeployment | Internal transfer requests and job board |
| 🔐 Admin Centre | Promote/revoke HR Admin roles |

---

## 🗂 Project Structure

```
STIAM-HR/
├── public/
│   └── index.html              ← Full working app (single file, Babel standalone)
├── server.js                   ← Express server
├── package.json
├── render.yaml                 ← Render.com auto-deploy config
├── src/                        ← Full source split by component (reference/development)
│   ├── index.js                ← Architecture documentation
│   ├── App.jsx                 ← Root component
│   ├── config/
│   │   ├── supabase.js         ← Supabase client + all db.* methods
│   │   └── constants.js        ← COMPANIES, SALARY, NAV, etc.
│   ├── utils/
│   │   ├── mappers.js          ← Row mappers
│   │   └── payroll.js          ← PAYE / Pension / NHF calculations
│   ├── context/
│   │   ├── NotifContext.jsx
│   │   └── ToastContext.jsx
│   └── components/
│       ├── ui/                 ← Shared UI primitives
│       ├── layout/             ← TopBar, Sidebar, NotificationPanel
│       ├── auth/               ← SignIn
│       ├── analytics/          ← Dashboard, HRAnalytics
│       ├── employees/          ← AddStaffModal, AllEmployees, MyProfile, Directory
│       ├── leave/              ← MyLeave, Requests, LeaveCalendar
│       ├── payroll/            ← PayrollEngine, Payslip
│       ├── hr/                 ← Performance, ClockIn, Onboarding, Benefits, etc.
│       ├── comms/              ← DocumentVault, MessageCenter, DressCode
│       ├── compliance/         ← AuditLog, ComplianceCenter
│       └── admin/              ← PasswordCenter, AdminCenter
├── supabase/
│   └── hris_full_migration.sql ← Run this in Supabase SQL Editor
└── STIAM-HR_Documentation.pdf  ← Full 30-page documentation
```

---

## 🗄 Database Setup (Supabase)

1. Go to your Supabase project → SQL Editor
2. Paste and run `supabase/hris_full_migration.sql`
3. Creates all 16 tables with Row-Level Security enabled

Update the Supabase URL and key in `src/config/supabase.js` (also at the top of `public/index.html`).

---

## 🚀 Deployment (Render.com)

1. Push repo to GitHub (`git push origin main`)
2. Go to [render.com](https://render.com) → New → Web Service
3. Connect `biddy2005/STIAM-HR-CL`
4. Settings: Runtime = **Node**, Build = `npm install`, Start = `npm start`
5. Deploy — live in ~2 minutes at `https://stiam-hr.onrender.com`

**Auto-deploy:** Every `git push origin main` triggers a new deploy automatically.

---

## 🇳🇬 Nigerian Payroll Compliance

| Deduction | Rate |
|---|---|
| PAYE | Progressive 7–24% (FIRS, annual basis) |
| Employee Pension | 8% of gross (PENCOM) |
| Employer Pension | 10% of gross |
| NHF | 2.5% of basic salary |
| Personal Allowance | ₦200,000 p.a. |
| Salary Structure | 70% Basic \| 15% Transport \| 15% Housing |

---

## 🏢 Supported Entities

| Entity | ID Prefix |
|---|---|
| STI Asset Management Ltd | STI-xxx |
| DEVTAGE | DVT-xxx |
| Cedar London | CLS-xxx |
| Cedar Asset Partners | CAP-xxx |

---

## 🛠 Tech Stack

- **Frontend** — React 18 (Babel standalone, zero build step)
- **Backend** — Supabase (PostgreSQL, Realtime, Storage, Auth)
- **Server** — Express.js (Node.js)
- **PDF** — jsPDF for client-side payslip generation
- **Hosting** — Render.com (auto-deploy from GitHub)

---

*Confidential — STI Asset Management Ltd*
