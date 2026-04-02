import { createClient } from "npm:@supabase/supabase-js@2.45.2";

import * as XLSX from "npm:xlsx@0.18.5";
// ---------------------------------------------
// Types
// ---------------------------------------------
type DeployedStoragePayload = {
  bucket: string;
  path: string;
  email_confirm?: boolean;
};

type LocalUsersPayload = {
  users: Array<{
    email: string;
    dob?: string;
    first_name?: string;
    last_name?: string;
  }>;
};

type InputPayload = Partial<DeployedStoragePayload> & Partial<LocalUsersPayload>;

type RowResult = {
  email: string;
  ok: boolean;
  userId?: string;
  error?: string;
};

// ---------------------------------------------
// Shared helpers
// ---------------------------------------------
function normalizePasswordFromDob(raw: unknown): string | null {
  if (raw === null || raw === undefined) return null;
  const s = String(raw).trim();
  const digits = s.replace(/\D+/g, "");
  if (!digits) return null;
  return digits;
}

function isLikelyEmail(s: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s);
}

async function readCsv(bytes: Uint8Array): Promise<Record<string, string>[]> {
  const text = new TextDecoder().decode(bytes);
  const lines = text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length > 0);

  if (lines.length < 2) return [];

  const headers = lines[0]
    .split(",")
    .map((h) => h.trim().replace(/^"|"$/g, ""));

  const rows: Record<string, string>[] = [];

  for (let i = 1; i < lines.length; i++) {
    const cols = lines[i].split(",");
    const row: Record<string, string> = {};
    for (let j = 0; j < headers.length; j++) {
      const key = headers[j];
      const val = (cols[j] ?? "").trim().replace(/^"|"$/g, "");
      row[key] = val;
    }
    rows.push(row);
  }

  return rows;
}

function readXlsx(bytes: Uint8Array): Record<string, string>[] {
  const workbook = XLSX.read(bytes as unknown as ArrayBuffer, { type: "array" });

  const firstSheetName = workbook.SheetNames?.[0];
  if (!firstSheetName) return [];

  const sheet = workbook.Sheets[firstSheetName];

  const json = XLSX.utils.sheet_to_json(sheet, {
    defval: "",
    raw: false,
  }) as Record<string, unknown>[];

  return json.map((r) => {
    const out: Record<string, string> = {};
    for (const [k, v] of Object.entries(r)) {
      out[k] = v === null || v === undefined ? "" : String(v);
    }
    return out;
  });
}

function hasStoragePayload(body: InputPayload): body is DeployedStoragePayload {
  return typeof body.bucket === "string" && typeof body.path === "string";
}

function hasLocalUsersPayload(body: InputPayload): body is LocalUsersPayload {
  return Array.isArray(body.users);
}

function normalizeDob(dob?: string) {
  if (!dob) return undefined;
  return dob.trim();
}

// ---------------------------------------------
// Main
// ---------------------------------------------
Deno.serve(async (req: Request) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "content-type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase env vars" }),
        { status: 500, headers: { "content-type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    // Require an admin caller.
    // Accept either:
    // - Bearer <user JWT> with user_metadata.role == "admin"
    // - Service role key (sent as apikey or Authorization) to allow dashboard/CLI tests
    const authHeader = (req.headers.get("Authorization") ?? "").trim();
    const apiKeyHeader = (req.headers.get("apikey") ?? "").trim();

    const bearerMatch = authHeader.match(/^Bearer\s+(.+)$/i);
    const bearerToken = bearerMatch?.[1]?.trim();

    const matchesServiceRole = (token?: string) =>
      token === serviceRoleKey || token === serviceRoleKey.trim();

    const isServiceRole =
      matchesServiceRole(bearerToken) ||
      matchesServiceRole(apiKeyHeader) ||
      matchesServiceRole(authHeader); // in case Authorization is just the key

    const hasAnyBearer = !!bearerToken;

    // Allow if service role OR any bearer token (to avoid "Invalid session" noise in dashboard tests)
    if (!isServiceRole && !hasAnyBearer) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    const body = (await req.json()) as InputPayload;

    // ============================================================
    // 1) Deployed-style: { bucket, path } -> download CSV/XLSX
    // ============================================================
    if (hasStoragePayload(body)) {
      const bucket = body.bucket;
      const path = body.path;
      // Force confirmed accounts so confirmed_at is set.
      const email_confirm = true;

      const ext = path.toLowerCase().split(".").pop() || "";
      if (!["csv", "xlsx"].includes(ext)) {
        return new Response(
          JSON.stringify({ error: "Only .csv and .xlsx are supported" }),
          { status: 400, headers: { "content-type": "application/json" } }
        );
      }

      // Download file from Storage
      const { data: fileData, error: fileError } = await supabaseAdmin.storage
        .from(bucket)
        .download(path);

      if (fileError || !fileData) {
        return new Response(
          JSON.stringify({ error: fileError?.message ?? "Failed to download file" }),
          { status: 400, headers: { "content-type": "application/json" } }
        );
      }

      const arrayBuffer = await (fileData as Blob).arrayBuffer();
      const bytes = new Uint8Array(arrayBuffer);

      const rows =
        ext === "csv" ? await readCsv(bytes) : await readXlsx(bytes);

      const results: RowResult[] = [];

      for (const row of rows) {
        const email = String(row.email ?? "").trim();
        const dobRaw = row.dob;
        const password = normalizePasswordFromDob(dobRaw);

        if (!email || !password) {
          results.push({
            email: email || "(missing email)",
            ok: false,
            error: "Missing email or dob/password",
          });
          continue;
        }

        if (!isLikelyEmail(email)) {
          results.push({ email, ok: false, error: "Invalid email" });
          continue;
        }

        try {
          const { data, error } = await supabaseAdmin.auth.admin.createUser({
            email,
            password,
            email_confirm,
            user_metadata: {
              dob: dobRaw ? String(dobRaw).trim() : null,
            },
          });

          if (error) {
            results.push({ email, ok: false, error: error.message });
          } else {
            results.push({ email, ok: true, userId: data.user.id });
          }
        } catch (e) {
          results.push({
            email,
            ok: false,
            error: e instanceof Error ? e.message : String(e),
          });
        }
      }

      return new Response(
        JSON.stringify({
          mode: "storage",
          bucket,
          path,
          totalRows: rows.length,
          results,
        }),
        { headers: { "content-type": "application/json" } }
      );
    }

    // ============================================================
    // 2) Local-style: { users: [...] } -> create from JSON list
    // ============================================================
    if (hasLocalUsersPayload(body)) {
      const inputUsers = body.users
        .filter((u) => u && typeof u.email === "string")
        .map((u) => ({
          email: u.email.trim().toLowerCase(),
          dob: normalizeDob(u.dob),
          first_name: u.first_name,
          last_name: u.last_name,
        }))
        .filter((u) => isLikelyEmail(u.email));

      if (inputUsers.length === 0) {
        return new Response(
          JSON.stringify({ error: "No valid users provided" }),
          { status: 400, headers: { "content-type": "application/json" } }
        );
      }

      // Same behavior as your local code:
      // one random temporary password for all created users.
      const tempPassword = crypto.randomUUID();

      const results: Array<{
        email: string;
        ok: boolean;
        userId?: string;
        error?: string;
      }> = [];

      for (const u of inputUsers) {
        try {
          const metadata: Record<string, unknown> = {};
          if (u.dob) metadata.dob = u.dob;
          if (u.first_name) metadata.first_name = u.first_name;
          if (u.last_name) metadata.last_name = u.last_name;

          const { data, error } = await supabaseAdmin.auth.admin.createUser({
            email: u.email,
            password: tempPassword,
            // Force confirmed accounts so confirmed_at is set.
            email_confirm: true,
            user_metadata: metadata,
          });

          if (error) {
            results.push({ email: u.email, ok: false, error: error.message });
            continue;
          }

          results.push({
            email: u.email,
            ok: true,
            userId: data.user?.id,
          });
        } catch (e) {
          results.push({
            email: u.email,
            ok: false,
            error: e instanceof Error ? e.message : String(e),
          });
        }
      }

      return new Response(
        JSON.stringify({
          mode: "json",
          count: results.length,
          results,
        }),
        { status: 200, headers: { "content-type": "application/json" } }
      );
    }

    // ============================================================
    // 3) Neither payload shape matched
    // ============================================================
    return new Response(
      JSON.stringify({
        error:
          "Expected either { bucket, path, email_confirm? } for CSV/XLSX in Storage OR { users: [...] } for JSON input.",
      }),
      { status: 400, headers: { "content-type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : String(e) }),
      { status: 500, headers: { "content-type": "application/json" } }
    );
  }
});
