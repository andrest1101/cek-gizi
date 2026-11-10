// Edge Function `health` — health check tanpa auth (PRD §5.5).
// Menjalankan query roundtrip ke Postgres (setara "select 1") untuk
// memastikan database dapat dijangkau; dipakai oleh keep-alive terjadwal
// (Batch 9). TIDAK mencatat data apa pun di log.
//
// Deploy (sekali):
//   npx supabase login
//   npx supabase link --project-ref hvjqjjqgwpmpqnchnxts
//   npx supabase functions deploy health
// Atau lewat dashboard: Edge Functions → New function → tempel file ini,
// pastikan "Verify JWT" = OFF.

import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async () => {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !serviceRoleKey) {
    return jsonResponse({ status: "misconfigured" }, 500);
  }

  const db = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { error } = await db.from("ai_usage").select("user_id", {
    head: true,
    count: "exact",
    limit: 1,
  });

  if (error) {
    return jsonResponse({ status: "unreachable" }, 503);
  }

  return jsonResponse({ status: "ok" }, 200);
});

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}
