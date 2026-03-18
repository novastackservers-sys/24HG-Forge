import type { Context, Next } from "hono";

const HUB_API = process.env.HUB_API_URL || "https://api.24hgaming.com";
const ALLOWED_ROLES = ["admin", "moderator", "staff"];
const ADMIN_ONLY_ROLES = ["admin"];

export interface AuthUser {
  id: number;
  username: string;
  role: string;
}

async function validateToken(token: string): Promise<AuthUser | null> {
  try {
    const res = await fetch(`${HUB_API}/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) return null;
    const data = await res.json();
    const user = data.user || data;
    if (!user || !ALLOWED_ROLES.includes(user.role)) return null;
    return { id: user.id, username: user.username, role: user.role };
  } catch {
    return null;
  }
}

export function authMiddleware(adminOnly: boolean = false) {
  return async (c: Context, next: Next) => {
    const authHeader = c.req.header("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return c.json({ error: "Unauthorized" }, 401);
    }

    const token = authHeader.slice(7);
    const user = await validateToken(token);
    if (!user) {
      return c.json({ error: "Invalid or expired token" }, 401);
    }

    if (adminOnly && !ADMIN_ONLY_ROLES.includes(user.role)) {
      return c.json({ error: "Admin access required" }, 403);
    }

    c.set("user", user);
    await next();
  };
}

export async function verifyAuth(token: string): Promise<AuthUser | null> {
  return validateToken(token);
}
