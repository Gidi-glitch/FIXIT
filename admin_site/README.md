# FIXIT Admin Site

Next.js admin portal for FIXIT operations.

## Setup

1. Copy `.env.example` to `.env.local`.
2. Set `NEXT_PUBLIC_API_BASE_URL` to your backend API origin.
3. Install dependencies:

```bash
npm install
```

4. Run locally:

```bash
npm run dev
```

## Auth Hardening

- Admin session token is stored in local storage for API authorization.
- A session cookie (`admin_session`) is written at login for server-side route protection.
- `middleware.ts` protects `/dashboard` and redirects unauthenticated requests to `/login`.
- Unauthorized API responses clear session state and force re-authentication.

## Notes

- For production, use HTTPS so session cookies are set with the `Secure` attribute.
- This app assumes backend login returns a JWT and a `user.role` value of `admin`.
