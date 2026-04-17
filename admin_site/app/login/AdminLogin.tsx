"use client";

import { useState, FormEvent, KeyboardEvent } from "react";
import { useRouter } from "next/navigation";
// ─── Big Logo (right panel center) ─────────────────────────────────────────
function ShieldLogo({ size = 80 }: { size?: number }) {
  return (
    <img
      src="/fixit_logo.png"
      alt="FIXit Logo"
      width={size}
      height={size}
      style={{ objectFit: "contain" }}
    />
  );
}

// ─── Small Logo (top left corner) ───────────────────────────────────────────
function ShieldSmall() {
  return (
    <img
      src="/fixit_logo.png"
      alt="FIXit Logo"
      width={50}
      height={50}
      style={{ objectFit: "contain" }}
    />
  );
}

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail]       = useState("");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw]     = useState(false);
  const [loading, setLoading]   = useState(false);
  const [error, setError]       = useState("");
  const [remember, setRemember] = useState(false);
  const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8080";

  const handleLogin = async (e?: FormEvent) => {
    e?.preventDefault();
    if (!email || !password) { setError("Please enter your email and password."); return; }
    setError("");
    setLoading(true);
    try {
      const res = await fetch(`${apiBase}/api/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      if (!res.ok) {
        setLoading(false);
        setError("Invalid email or password. Please try again.");
        return;
      }
      const data = await res.json();
      if (data?.user?.role !== "admin") {
        setLoading(false);
        setError("This portal is only available to admin accounts.");
        return;
      }
      if (!data?.token) {
        setLoading(false);
        setError("Login response did not include a token.");
        return;
      }
      localStorage.setItem("admin_token", data.token);
      router.push("/dashboard");
    } catch {
      setLoading(false);
      setError("Unable to connect to server. Please try again.");
    }
  };

  const handleKey = (e: KeyboardEvent) => { if (e.key === "Enter") handleLogin(); };

  return (
    <div style={{ display: "flex", minHeight: "100vh", fontFamily: "'Plus Jakarta Sans', sans-serif" }}>

      {/* ── LEFT: Form ─────────────────────────────────────────────────── */}
      <div style={{
        flex: 1,
        background: "#F0F2F5",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "60px 80px",
        maxWidth: 560,
      }}>
        {/* Logo row */}
        <div style={{ display: "flex", alignItems: "center", gap: 14, marginBottom: 32, alignSelf: "flex-start" }}>
          <ShieldSmall />
          <div>
            <div style={{ fontSize: 22, fontWeight: 800, color: "#1B2B5E", letterSpacing: -0.4 }}>
              Fix It <span style={{ fontWeight: 400, color: "#0F1923" }}>Marketplace</span>
            </div>
            <div style={{ fontSize: 11, fontWeight: 700, color: "#9AA3B8", letterSpacing: 1, textTransform: "uppercase" }}>
              Admin Portal
            </div>
          </div>
        </div>

        {/* Admin-only badge */}
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 7,
          padding: "6px 16px", borderRadius: 100,
          background: "#EEF1FA", border: "1.5px solid rgba(27,43,94,0.2)",
          fontSize: 12, fontWeight: 700, color: "#1B2B5E", letterSpacing: 0.3,
          marginBottom: 28, alignSelf: "flex-start",
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
          </svg>
          Authorized Personnel Only
        </div>

        <div style={{ alignSelf: "flex-start", marginBottom: 6 }}>
          <h1 style={{ fontSize: 32, fontWeight: 800, color: "#0F1923", letterSpacing: -0.8, margin: 0 }}>
            Admin Portal
          </h1>
        </div>
        <p style={{ fontSize: 14, color: "#9AA3B8", fontWeight: 500, marginBottom: 32, alignSelf: "flex-start" }}>
          Sign in to manage Fix It Marketplace users and verifications.
        </p>

        {/* Error */}
        {error && (
          <div style={{
            display: "flex", alignItems: "center", gap: 8,
            padding: "12px 14px", background: "#FFF0F1",
            border: "1px solid rgba(220,53,69,0.25)", borderRadius: 8,
            marginBottom: 16, color: "#DC3545", fontSize: 13, fontWeight: 500,
            width: "100%", animation: "shake 0.35s ease",
          }}>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            {error}
          </div>
        )}

        {/* Email */}
        <div style={{ width: "100%", marginBottom: 18 }}>
          <label style={{ display: "block", fontSize: 13, fontWeight: 700, color: "#4A5568", marginBottom: 8 }}>
            Email Address
          </label>
          <div style={{ position: "relative" }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#9AA3B8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
              style={{ position: "absolute", left: 14, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}>
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" /><polyline points="22,6 12,13 2,6" />
            </svg>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              onKeyDown={handleKey}
              placeholder="Enter your professional email"
              autoComplete="email"
              style={{
                width: "100%", padding: "13px 14px 13px 44px",
                background: "#fff", border: "1.5px solid #E3E8F0", borderRadius: 8,
                fontFamily: "inherit", fontSize: 14, color: "#0F1923", outline: "none",
                boxSizing: "border-box",
                transition: "border-color .2s, box-shadow .2s",
              }}
              onFocus={(e) => { e.target.style.borderColor = "#E87722"; e.target.style.boxShadow = "0 0 0 3px rgba(232,119,34,0.15)"; }}
              onBlur={(e)  => { e.target.style.borderColor = "#E3E8F0"; e.target.style.boxShadow = "none"; }}
            />
          </div>
        </div>

        {/* Password */}
        <div style={{ width: "100%", marginBottom: 8 }}>
          <label style={{ display: "block", fontSize: 13, fontWeight: 700, color: "#4A5568", marginBottom: 8 }}>
            Password
          </label>
          <div style={{ position: "relative" }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#9AA3B8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
              style={{ position: "absolute", left: 14, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}>
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            <input
              type={showPw ? "text" : "password"}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              onKeyDown={handleKey}
              placeholder="Enter your password"
              autoComplete="current-password"
              style={{
                width: "100%", padding: "13px 44px 13px 44px",
                background: "#fff", border: "1.5px solid #E3E8F0", borderRadius: 8,
                fontFamily: "inherit", fontSize: 14, color: "#0F1923", outline: "none",
                boxSizing: "border-box", transition: "border-color .2s, box-shadow .2s",
              }}
              onFocus={(e) => { e.target.style.borderColor = "#E87722"; e.target.style.boxShadow = "0 0 0 3px rgba(232,119,34,0.15)"; }}
              onBlur={(e)  => { e.target.style.borderColor = "#E3E8F0"; e.target.style.boxShadow = "none"; }}
            />
            <button
              type="button"
              onClick={() => setShowPw(!showPw)}
              style={{ position: "absolute", right: 13, top: "50%", transform: "translateY(-50%)", background: "none", border: "none", cursor: "pointer", color: "#9AA3B8", padding: 4, display: "flex" }}
            >
              {showPw ? (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" />
                  <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" />
                  <line x1="1" y1="1" x2="23" y2="23" />
                </svg>
              ) : (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" />
                </svg>
              )}
            </button>
          </div>
        </div>

        {/* Remember / Forgot row */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", width: "100%", marginBottom: 24 }}>
          <label style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, color: "#9AA3B8", fontWeight: 500, cursor: "pointer" }}>
            <input type="checkbox" checked={remember} onChange={(e) => setRemember(e.target.checked)} style={{ accentColor: "#E87722", width: 15, height: 15 }} />
            Remember me
          </label>
          <a href="#" style={{ fontSize: 13, fontWeight: 700, color: "#1B2B5E", textDecoration: "none" }}
            onMouseEnter={(e) => (e.currentTarget.style.textDecoration = "underline")}
            onMouseLeave={(e) => (e.currentTarget.style.textDecoration = "none")}>
            Forgot Password?
          </a>
        </div>

        {/* Login button */}
        <button
          onClick={() => handleLogin()}
          disabled={loading}
          style={{
            width: "100%", padding: "15px", background: "#E87722", border: "none",
            borderRadius: 8, fontFamily: "inherit", fontSize: 14, fontWeight: 800,
            letterSpacing: "1.5px", textTransform: "uppercase", color: "white",
            cursor: loading ? "not-allowed" : "pointer",
            boxShadow: "0 4px 18px rgba(232,119,34,0.38)",
            display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
            transition: "background .2s, transform .15s, box-shadow .2s",
            opacity: loading ? 0.85 : 1,
          }}
          onMouseEnter={(e) => { if (!loading) { (e.currentTarget as HTMLButtonElement).style.background = "#F09040"; (e.currentTarget as HTMLButtonElement).style.transform = "translateY(-1px)"; }}}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.background = "#E87722"; (e.currentTarget as HTMLButtonElement).style.transform = "translateY(0)"; }}
        >
          {loading ? (
            <>
              <span style={{
                width: 18, height: 18, border: "2.5px solid rgba(255,255,255,.4)",
                borderTopColor: "white", borderRadius: "50%",
                display: "inline-block", animation: "spin 0.65s linear infinite",
              }} />
              Signing in…
            </>
          ) : "Sign In"}
        </button>

        {/* Secure note */}
        <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 20, fontSize: 12, color: "#9AA3B8", justifyContent: "center" }}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
          256-bit encrypted · Sessions monitored · Admin access only
        </div>

      </div>

      {/* ── RIGHT: Branding panel ──────────────────────────────────────── */}
      <div style={{
        flex: 1,
        background: "#1B2B5E",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "60px 60px",
        position: "relative",
        overflow: "hidden",
        minHeight: "100vh",
      }}>
        {/* Decorative orbs */}
        <div style={{ position: "absolute", width: 600, height: 600, borderRadius: "50%", background: "radial-gradient(circle,rgba(232,119,34,0.18) 0%,transparent 60%)", top: -150, right: -150, pointerEvents: "none" }} />
        <div style={{ position: "absolute", width: 400, height: 400, borderRadius: "50%", background: "radial-gradient(circle,rgba(255,255,255,0.04) 0%,transparent 65%)", bottom: -100, left: -100, pointerEvents: "none" }} />
        {/* Grid */}
        <div style={{ position: "absolute", inset: 0, backgroundImage: "linear-gradient(rgba(255,255,255,0.03) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,0.03) 1px,transparent 1px)", backgroundSize: "40px 40px" }} />

        <div style={{ position: "relative", zIndex: 1, textAlign: "center", maxWidth: 420 }}>
          {/* Animated shield */}
          <div style={{ marginBottom: 24, animation: "floatShield 5s ease-in-out infinite", display: "inline-block" }}>
            <ShieldLogo size={96} />
          </div>

          <h2 style={{ fontSize: 36, fontWeight: 400, color: "white", letterSpacing: -0.5, margin: "0 0 8px" }}>
            <strong>Fix It</strong> Marketplace
          </h2>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 10, fontSize: 15, color: "rgba(255,255,255,0.55)", fontWeight: 500, marginBottom: 40 }}>
            <span>Fast</span>
            <span style={{ width: 5, height: 5, borderRadius: "50%", background: "#E87722", display: "inline-block" }} />
            <span>Verified</span>
            <span style={{ width: 5, height: 5, borderRadius: "50%", background: "#E87722", display: "inline-block" }} />
            <span>Local</span>
          </div>

          {/* Feature cards */}
          {[
            {
              icon: (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" />
                  <path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
                </svg>
              ),
              title: "User Management",
              sub: "Monitor homeowners & tradesmen",
            },
            {
              icon: (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                </svg>
              ),
              title: "License Verification",
              sub: "Approve & verify tradesmen licenses",
            },
            {
              icon: (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
                </svg>
              ),
              title: "Real-Time Activity",
              sub: "Track registrations & status changes",
            },
          ].map((f, i) => (
            <div key={i} style={{
              display: "flex", alignItems: "center", gap: 14,
              background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.1)",
              borderRadius: 12, padding: "14px 18px", marginBottom: 12, textAlign: "left",
            }}>
              <div style={{ width: 40, height: 40, borderRadius: 10, background: "rgba(232,119,34,0.2)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, color: "#E87722" }}>
                {f.icon}
              </div>
              <div>
                <p style={{ fontSize: 14, fontWeight: 700, color: "white", margin: "0 0 2px" }}>{f.title}</p>
                <span style={{ fontSize: 12, color: "rgba(255,255,255,0.45)" }}>{f.sub}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      <style suppressHydrationWarning>{`
        * { box-sizing: border-box; }
        input { box-sizing: border-box; }
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes floatShield { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-12px)} }
        @keyframes shake { 0%,100%{transform:translateX(0)} 25%{transform:translateX(-5px)} 75%{transform:translateX(5px)} }
      `}</style>
    </div>
  );
}
