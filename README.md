# STIAM-HR Portal

A comprehensive, browser-based **Human Resources Information System (HRIS)** for STI Asset Management Ltd and group companies (DEVTAGE, Cedar London, Cedar Asset).

---

## 🚀 Quick Start

1. Open `index.html` in any modern browser (Chrome 110+, Firefox 115+, Edge 110+)
2. Log in with your work email and staff ID as default password
3. Super Admin: `superadmin@stiam.com` / `admin@STIAM2024`

> **Note:** Must be served over HTTP/HTTPS — not `file://` — for Supabase features to work.

---

## ✨ Modules

| Module | Description |
|---|---|
| 📊 Dashboard | Live workforce overview, pending actions |
| 📈 HR Analytics | Headcount, leave, and department insights |
| 👥 Employee Directory | Search & filter all staff across entities |
| 📝 Contracts | Employment records, probation & expiry alerts |
| 🗓 Leave Management | Requests, approvals, and leave calendar |
| 💵 Payroll Engine | Full Nigerian payroll — PAYE, Pension, NHF |
| 🏥 Benefits Admin | HMO, PFA, and life insurance tracking |
| 📊 Performance | KPI-based appraisals with animated sliders |
| ⏰ Clock-In Register | Real-time attendance + biometric device integration |
| ⚖️ Disciplinary | Queries, warnings, suspensions — confidential records |
| 🎯 Onboarding | New hire induction checklists + employee creation |
| 🎓 Training | Course log, budget tracking, certificates |
| 📋 Surveys | Pulse surveys with Likert-scale analytics |
| 📁 Document Vault | Secure file storage via Supabase Storage |
| ⚠️ Compliance | Auto-generated alerts for HMO, contracts, PFA |
| 🔍 Audit Log | Real-time activity trail for all HR actions |
| ✉️ Messages | Internal messaging with broadcast support |
| 🔄 Redeployment | Internal transfer requests and approvals |
| 🔐 Admin Centre | Promote/revoke HR Admin roles (Super Admin only) |

---

## 🗄 Database Setup

Run the migration file in your **Supabase SQL Editor**:

```
supabase/hris_full_migration.sql
```

This creates all 16+ tables with Row-Level Security enabled.

---

## 🇳🇬 Nigerian Payroll Compliance

- **PAYE** — Progressive tax 7–24% with ₦200k personal allowance (FIRS)
- **Employee Pension** — 8% of gross (PENCOM Pension Reform Act 2014)
- **Employer Pension** — 10% of gross
- **NHF** — 2.5% of basic salary (National Housing Fund Act)
- **Salary structure** — 70% Basic | 15% Transport | 15% Housing

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

- **Frontend** — React 18 (Babel standalone, no build step)
- **Backend** — Supabase (PostgreSQL, Realtime, Storage)
- **PDF** — jsPDF for client-side payslip generation
- **Hosting** — Any static host (Netlify, Vercel, GitHub Pages)

---

## 📄 Documentation

Full documentation: [`STIAM-HR_Documentation.pdf`](./STIAM-HR_Documentation.pdf) *(30 pages)*

---

*Confidential — STI Asset Management Ltd*
