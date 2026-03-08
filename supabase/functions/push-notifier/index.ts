import { createClient } from "supabase"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationRecord {
    id: string
    user_id: string
    message: string
    type: string
    deep_link?: string
}

interface ServiceAccount {
  client_email: string
  private_key: string
  project_id: string
}

Deno.serve(async (req: Request) => {
    // 1. Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        // 2. Parse request body
        const body = await req.json()
        const record = body?.record as NotificationRecord

        if (!record || !record.user_id) {
            console.error("[PushNotifier] Missing record or user_id in payload")
            return new Response(JSON.stringify({ error: "Missing record.user_id" }), {
                status: 400,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        }

        // 3. Initialize Supabase Client
        const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
        const supabase = createClient(supabaseUrl, supabaseServiceKey)

        // 4. Retrieve user's FCM token
        const { data: user, error: userError } = await supabase
            .from("users")
            .select("fcm_token")
            .eq("id", record.user_id)
            .single()

        if (userError || !user?.fcm_token) {
            const reason = userError ? `DB error: ${userError.message}` : "No FCM token"
            console.log(`[PushNotifier] Skipping user ${record.user_id}: ${reason}`)
            return new Response(JSON.stringify({ success: true, message: reason }), {
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        }

        // 5. Send FCM Notification (v1 API)
        const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")
        
        if (!serviceAccountJson) {
            console.error("[PushNotifier] FIREBASE_SERVICE_ACCOUNT secret not found")
            return new Response(JSON.stringify({ error: "Config missing" }), { status: 500 })
        }

        const serviceAccount = JSON.parse(serviceAccountJson) as ServiceAccount
        const projectId = serviceAccount.project_id || "littlewin-2fbc7"
        const accessToken = await getAccessToken(serviceAccount)

        const fcmResponse = await fetch(
            `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${accessToken}`,
                },
                body: JSON.stringify({
                    message: {
                        token: user.fcm_token,
                        notification: {
                            title: "Littlewin",
                            body: record.message,
                        },
                        data: {
                            deep_link: record.deep_link ?? "",
                            type: record.type,
                        },
                    },
                }),
            }
        )

        const fcmResult = await fcmResponse.json()
        if (!fcmResponse.ok) {
            console.error("[PushNotifier] FCM API Error:", fcmResult)
            return new Response(JSON.stringify({ error: "FCM delivery failed", details: fcmResult }), { status: 502 })
        }

        console.log(`[PushNotifier] Success: Notification sent to ${record.user_id}`)

        return new Response(JSON.stringify({ success: true, fcm_message_id: fcmResult.name }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        })

    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : String(error)
        console.error(`[PushNotifier] Runtime Error: ${message}`)
        return new Response(JSON.stringify({ error: message }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        })
    }
})

/**
 * Generates a Google OAuth2 Access Token for FCM v1 using a service account.
 */
async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const { client_email, private_key } = serviceAccount;

  // Header
  const header = b64url(new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));

  // Claim set
  const now = Math.floor(Date.now() / 1000);
  const claimSet = b64url(new TextEncoder().encode(JSON.stringify({
    iss: client_email,
    scope: "https://www.googleapis.com/auth/cloud-platform",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now
  })));

  // Signature
  const signatureInput = `${header}.${claimSet}`;
  const keyData = pemToBinary(private_key);
  
  const key = await crypto.subtle.importKey(
    "pkcs8",
    // deno-lint-ignore no-explicit-any
    keyData as any,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signatureInput)
  );

  const jwt = `${signatureInput}.${b64url(new Uint8Array(signature))}`;

  // Exchange JWT for access token
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`
  });

  const data = await response.json();
  if (!response.ok) throw new Error(`OAuth error: ${JSON.stringify(data)}`);
  return data.access_token;
}

function b64url(binary: Uint8Array): string {
  const base64 = btoa(String.fromCharCode(...binary));
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToBinary(pem: string): Uint8Array {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}
