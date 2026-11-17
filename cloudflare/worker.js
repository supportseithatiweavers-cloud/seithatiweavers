const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
const ALLOWED_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);
const UID_PATTERN = /^[A-Za-z0-9_-]+$/;

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

function getBearerToken(request) {
  return request.headers.get("Authorization")?.match(/^Bearer\s+(.+)$/i)?.[1] ?? null;
}

function getTokenUid(token) {
  try {
    const encodedPayload = token.split(".")[1];
    if (!encodedPayload) return null;
    const base64 = encodedPayload.replace(/-/g, "+").replace(/_/g, "/");
    const payload = JSON.parse(atob(base64.padEnd(Math.ceil(base64.length / 4) * 4, "=")));
    return typeof payload.sub === "string" && UID_PATTERN.test(payload.sub)
      ? payload.sub
      : null;
  } catch {
    return null;
  }
}

async function getChatRoom(request, env, uid) {
  const token = getBearerToken(request);
  const tokenUid = token ? getTokenUid(token) : null;
  if (!token || !env.FIREBASE_PROJECT_ID || !UID_PATTERN.test(uid)) return false;
  if (tokenUid !== uid && !(await authorizeAdmin(request, env))) return false;

  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(env.FIREBASE_PROJECT_ID)}/databases/(default)/documents/customerChats/customer-${encodeURIComponent(uid)}`,
  );
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!response.ok) return false;

  const document = await response.json();
  return document.fields?.uid?.stringValue === uid;
}

async function authorizeAdmin(request, env) {
  const token = getBearerToken(request);
  if (!token || !env.FIREBASE_PROJECT_ID) return false;

  const uid = getTokenUid(token);
  if (!uid) return false;

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

async function readUpload(request, origin) {
  const length = Number(request.headers.get("Content-Length") ?? 0);
  if (length > MAX_UPLOAD_BYTES + 64 * 1024) {
    return {
      response: jsonResponse(
        { error: "Image must be 10 MB or smaller." },
        413,
        corsHeaders(origin),
      ),
    };
  }

  const form = await request.formData();
  const file = form.get("file");
  if (!(file instanceof File) || !ALLOWED_TYPES.has(file.type)) {
    return {
      response: jsonResponse(
        { error: "Upload a JPEG, PNG, or WebP image." },
        415,
        corsHeaders(origin),
      ),
    };
  }
  if (file.size > MAX_UPLOAD_BYTES) {
    return {
      response: jsonResponse(
        { error: "Image must be 10 MB or smaller." },
        413,
        corsHeaders(origin),
      ),
    };
  }

  return { file };
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

      const { file, response } = await readUpload(request, origin);
      if (response) return response;

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

    if (url.pathname === "/chat-upload" && request.method === "POST") {
      const token = getBearerToken(request);
      const uid = token ? getTokenUid(token) : null;
      if (!uid || !(await getChatRoom(request, env, uid))) {
        return jsonResponse(
          { error: "Sign in to the customer chat before uploading an image." },
          403,
          corsHeaders(origin),
        );
      }

      const { file, response } = await readUpload(request, origin);
      if (response) return response;

      const extension = file.type === "image/jpeg" ? "jpg" : file.type.slice(6);
      const key = `${crypto.randomUUID()}.${extension}`;
      await env.SEITHATI_BUCKET.put(`customer-chat/${uid}/${key}`, file.stream(), {
        httpMetadata: {
          contentType: file.type,
          cacheControl: "private, no-store",
        },
      });

      return jsonResponse(
        {
          key,
          url: `${url.origin}/chat-media/${encodeURIComponent(uid)}/${encodeURIComponent(key)}`,
        },
        201,
        corsHeaders(origin),
      );
    }

    const adminChatUploadMatch = url.pathname.match(
      /^\/admin-chat-upload\/([A-Za-z0-9_-]+)$/,
    );
    if (adminChatUploadMatch && request.method === "POST") {
      const [, uid] = adminChatUploadMatch;
      if (
        !(await authorizeAdmin(request, env)) ||
        !(await getChatRoom(request, env, uid))
      ) {
        return jsonResponse(
          { error: "Only an administrator can upload to this customer chat." },
          403,
          corsHeaders(origin),
        );
      }

      const { file, response } = await readUpload(request, origin);
      if (response) return response;

      const extension = file.type === "image/jpeg" ? "jpg" : file.type.slice(6);
      const key = `${crypto.randomUUID()}.${extension}`;
      await env.SEITHATI_BUCKET.put(`customer-chat/${uid}/${key}`, file.stream(), {
        httpMetadata: {
          contentType: file.type,
          cacheControl: "private, no-store",
        },
      });

      return jsonResponse(
        {
          key,
          url: `${url.origin}/chat-media/${encodeURIComponent(uid)}/${encodeURIComponent(key)}`,
        },
        201,
        corsHeaders(origin),
      );
    }

    const chatMediaMatch = url.pathname.match(
      /^\/chat-media\/([A-Za-z0-9_-]+)\/([A-Za-z0-9-]+\.(?:jpg|png|webp))$/i,
    );
    if (chatMediaMatch && request.method === "GET") {
      const [, uid, name] = chatMediaMatch;
      if (!(await getChatRoom(request, env, uid))) {
        return jsonResponse(
          { error: "You are not allowed to view this chat image." },
          403,
          corsHeaders(origin),
        );
      }

      const object = await env.SEITHATI_BUCKET.get(`customer-chat/${uid}/${name}`);
      if (!object) {
        return new Response("Not found", { status: 404, headers: corsHeaders(origin) });
      }

      const headers = new Headers(corsHeaders(origin));
      object.writeHttpMetadata(headers);
      headers.set("etag", object.httpEtag);
      headers.set("cache-control", "private, no-store");
      headers.set("cross-origin-resource-policy", "same-origin");
      return new Response(object.body, { headers });
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
