const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
const ALLOWED_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);

function jsonResponse(body, status, headers = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      ...headers,
    },
  });
}

function getAllowedOrigin(request, env) {
  const origin = request.headers.get("Origin");
  if (!origin) return "*";
  const allowedOrigins = (env.ALLOWED_ORIGINS ?? env.ALLOWED_ORIGIN ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  return allowedOrigins.includes(origin) ? origin : null;
}

async function authorizeAdmin(request, env) {
  const token = request.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token || !env.FIREBASE_PROJECT_ID) return false;

  let uid;
  try {
    const payload = JSON.parse(
      atob(token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")),
    );
    uid = payload.sub;
  } catch {
    return false;
  }

  if (typeof uid !== "string" || !/^[A-Za-z0-9_-]+$/.test(uid)) return false;

  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(env.FIREBASE_PROJECT_ID)}/databases/(default)/documents/admins/${encodeURIComponent(uid)}`,
  );
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  return response.ok;
}

function corsHeaders(origin) {
  return {
    "access-control-allow-origin": origin,
    "access-control-allow-methods": "GET, POST, OPTIONS",
    "access-control-allow-headers": "Authorization, Content-Type",
    "access-control-max-age": "86400",
    vary: "Origin",
  };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = getAllowedOrigin(request, env);
    if (!origin) return jsonResponse({ error: "Origin is not allowed." }, 403);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }

    if (url.pathname === "/upload" && request.method === "POST") {
      if (!(await authorizeAdmin(request, env))) {
        return jsonResponse(
          { error: "Only an allowlisted Google account can upload images." },
          403,
          corsHeaders(origin),
        );
      }

      const length = Number(request.headers.get("Content-Length") ?? 0);
      if (length > MAX_UPLOAD_BYTES + 64 * 1024) {
        return jsonResponse({ error: "Image must be 10 MB or smaller." }, 413, corsHeaders(origin));
      }

      const form = await request.formData();
      const file = form.get("file");
      if (!(file instanceof File) || !ALLOWED_TYPES.has(file.type)) {
        return jsonResponse(
          { error: "Upload a JPEG, PNG, or WebP image." },
          415,
          corsHeaders(origin),
        );
      }
      if (file.size > MAX_UPLOAD_BYTES) {
        return jsonResponse({ error: "Image must be 10 MB or smaller." }, 413, corsHeaders(origin));
      }

      const extension = file.type === "image/jpeg" ? "jpg" : file.type.slice(6);
      const key = `uploads/${crypto.randomUUID()}.${extension}`;
      await env.SEITHATI_BUCKET.put(key, file.stream(), {
        httpMetadata: {
          contentType: file.type,
          cacheControl: "public, max-age=31536000, immutable",
        },
      });

      return jsonResponse(
        { key, url: `${url.origin}/media/${encodeURIComponent(key)}` },
        201,
        corsHeaders(origin),
      );
    }

    if (url.pathname.startsWith("/media/") && request.method === "GET") {
      const key = decodeURIComponent(url.pathname.slice("/media/".length));
      if (!key.startsWith("uploads/") || key.includes("..")) {
        return new Response("Not found", { status: 404 });
      }
      const object = await env.SEITHATI_BUCKET.get(key);
      if (!object) return new Response("Not found", { status: 404 });

      const headers = new Headers(corsHeaders(origin));
      object.writeHttpMetadata(headers);
      headers.set("etag", object.httpEtag);
      headers.set("cross-origin-resource-policy", "cross-origin");
      return new Response(object.body, { headers });
    }

    return jsonResponse({ error: "Not found." }, 404, corsHeaders(origin));
  },
};
