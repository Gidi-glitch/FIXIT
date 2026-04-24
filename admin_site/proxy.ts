import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";

import { ADMIN_SESSION_COOKIE } from "./lib/admin-auth";

export function proxy(req: NextRequest) {
  const { pathname } = req.nextUrl;
  const hasAdminSession = Boolean(req.cookies.get(ADMIN_SESSION_COOKIE)?.value);

  if (pathname.startsWith("/dashboard") && !hasAdminSession) {
    return NextResponse.redirect(new URL("/login", req.url));
  }

  if (pathname === "/login" && hasAdminSession) {
    return NextResponse.redirect(new URL("/dashboard", req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/dashboard/:path*", "/login"],
};
