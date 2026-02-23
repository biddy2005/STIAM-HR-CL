// ============================================================
//  STIAM-HR  —  Supabase Client
//  File: src/supabaseClient.js
// ============================================================
//
//  HOW TO USE:
//  1. Replace SUPABASE_URL with your project URL
//     (found in: Supabase Dashboard → Settings → API → Project URL)
//
//  2. Replace SUPABASE_PUBLIC_KEY with your anon/public key
//     (found in: Supabase Dashboard → Settings → API → anon public)
//
//  3. Import this client anywhere in your app:
//     import { supabase } from './src/supabaseClient.js';
//
// ============================================================

import { createClient } from '@supabase/supabase-js';

// ─── PASTE YOUR SUPABASE URL HERE ────────────────────────────
const SUPABASE_URL = "https://qvtyqrwitdtxaomgaujr.supabase.co";

// ─── PASTE YOUR SUPABASE PUBLIC (ANON) KEY HERE ──────────────
const SUPABASE_PUBLIC_KEY = "sb_publishable_YHqznPjbfc9uV-LuWcSANw_MQgaCNkS";

// ─── SUPABASE CLIENT (do not edit below this line) ───────────
export const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLIC_KEY);
