// Edge Function `delete-account` — penghapusan akun (PRD §6.8, §9.4).
//
// Alur:
// 1. Verifikasi JWT via `auth.getUser` (uid dari token).
// 2. RPC `public.delete_account(p_user)` — hapus semua baris milik user
//    (anak + pengukuran/log makan/chat, konsent, ai_usage). Fungsi dari
//    file migrasi `20261110000005_delete_account.sql` (terapkan sekali
//    dari SQL Editor sebelum fungsi dipakai).
// 3. `auth.admin.deleteUser(uid)` — hapus akun dari sisi autentikasi
//    (identities, session).
//
// Aturan keras: tanpa nama/birthdate/child di log (privacy). Response hanya
// berisi status/error kode, bukan data pribadi.
//
// Deploy lewat Dashboard Supabase (Windows tanpa CLI/Docker):
// Edge Functions -> New function -> nama "delete-account" -> tempel file ini
// -> Verify JWT: ON -> Deploy. (`config.toml` hanya berlaku bagi CLI.)

import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "invalid_request" }, 400);
  }
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return jsonResponse({ error: "misconfigured" }, 500);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // 1) Verifikasi JWT
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }
  const jwt = authorization.slice("Bearer ".length).trim();
  const { data: userData, error: authError } = await admin.auth.getUser(jwt);
  if (authError || !userData?.user?.id) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }
  const uid = userData.user.id;

  // 2) Hapus data (semuanya benar sejauh ini hanya data anak/gizi).
  const { error: rpcError } = await admin.rpc("delete_account", {
    p_user: uid,
  });
  if (rpcError) {
    return jsonResponse({ error: "delete_account_error" }, 500);
  }

  // 3) Hapus akun dari sisi autentikasi.
  try {
    await admin.auth.admin.deleteUser(uid);
  } catch (_) {
    // Informasi di sini tidak penting; RPC (langkah 2) sudah dihapus.
    return jsonResponse({ error: "delete_account_error" }, 500);
  }

  return jsonResponse({ status: "deleted" }, 200);
});
