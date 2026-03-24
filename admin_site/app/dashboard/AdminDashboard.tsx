"use client";

import { useState, ReactNode, useEffect, CSSProperties, useRef } from "react";
import { useRouter } from "next/navigation";

// ─────────────────────────────────────────────────────────────────
// TYPES
// ─────────────────────────────────────────────────────────────────
type Page = "dashboard" | "verification" | "tradesmen" | "homeowners" | "profile" | "settings";
type ToastType = "success" | "error" | "info";

interface Tradesman {
  id: string;
  userId?: string;
  initials: string;
  color: string;
  name: string;
  email: string;
  category: string;
  license: string;
  credentialUrl: string;
  governmentIdUrl?: string;
  joined: string;
  createdAt?: string;
  jobs: number;
  status: "Pending" | "Verified" | "Suspended";
}

interface Homeowner {
  id: string;
  userId?: string;
  initials: string;
  color: string;
  name: string;
  email: string;
  location: string;
  registered: string;
  createdAt?: string;
  jobs: number;
  status: "Active" | "Inactive" | "Pending";
  idNumber: string;
  idStatus: "Pending" | "Approved" | "Rejected" | "Archived";
  idImageUrl: string;
}

interface Verification {
  id: number;
  userId: number;
  name?: string;
  type: "homeowner_id" | "tradesperson_license";
  status: "pending" | "approved" | "rejected" | "archived";
  documentUrl: string;
  createdAt?: string;
}

interface ActivityEntry {
  id: string;
  dot: string;
  title: string;
  sub: string;
  time: string;
}

interface UserGrowthPoint {
  key: string;
  label: string;
  homeowners: number;
  tradesmen: number;
  total: number;
}

const toTitle = (s: string) => (s ? s[0].toUpperCase() + s.slice(1) : s);
const verificationTypeLabel = (t: Verification["type"]) =>
  t === "homeowner_id" ? "Homeowner ID" : "Tradesperson License";

const avatarPalette = [
  "linear-gradient(135deg,#1560B0,#2E82D8)",
  "linear-gradient(135deg,#0F7060,#17A88E)",
  "linear-gradient(135deg,#5B2D8E,#8040C0)",
  "linear-gradient(135deg,#1B2B5E,#2D44A0)",
  "linear-gradient(135deg,#1A7A4A,#26A864)",
  "linear-gradient(135deg,#A82040,#D03060)",
  "linear-gradient(135deg,#B85010,#E87722)",
];

const initialsFromName = (name: string) => {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "NA";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
};

const colorFromSeed = (seed: string) => {
  let hash = 0;
  for (let i = 0; i < seed.length; i += 1) {
    hash = (hash * 31 + seed.charCodeAt(i)) % avatarPalette.length;
  }
  return avatarPalette[hash];
};

const formatDate = (value?: string) => {
  if (!value) return "—";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString();
};

const formatTimeAgo = (value?: string) => {
  if (!value) return "—";
  const d = new Date(value);
  const ts = d.getTime();
  if (Number.isNaN(ts)) return "—";
  const diffMs = Date.now() - ts;
  const sec = Math.floor(diffMs / 1000);
  if (sec < 30) return "just now";
  if (sec < 60) return `${sec}s ago`;
  const min = Math.floor(sec / 60);
  if (min < 60) return `${min}m ago`;
  const hr = Math.floor(min / 60);
  if (hr < 24) return `${hr}h ago`;
  const day = Math.floor(hr / 24);
  if (day < 7) return `${day}d ago`;
  return d.toLocaleDateString();
};

const monthLabelFormatter = new Intl.DateTimeFormat("en-US", { month: "short" });
const getMonthKey = (date: Date) => `${date.getFullYear()}-${date.getMonth()}`;

const parseDashboardDate = (value?: string) => {
  if (!value) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
};

const buildUserGrowthData = (homeowners: Homeowner[], tradesmen: Tradesman[], months = 6) => {
  const now = new Date();
  const buckets: UserGrowthPoint[] = Array.from({ length: months }, (_, index) => {
    const date = new Date(now.getFullYear(), now.getMonth() - (months - 1 - index), 1);
    return {
      key: getMonthKey(date),
      label: monthLabelFormatter.format(date),
      homeowners: 0,
      tradesmen: 0,
      total: 0,
    };
  });

  const bucketMap = new Map(buckets.map((bucket) => [bucket.key, bucket]));

  homeowners.forEach((homeowner) => {
    const parsed = parseDashboardDate(homeowner.createdAt);
    if (!parsed) return;
    const bucket = bucketMap.get(getMonthKey(parsed));
    if (!bucket) return;
    bucket.homeowners += 1;
    bucket.total += 1;
  });

  tradesmen.forEach((tradesman) => {
    const parsed = parseDashboardDate(tradesman.createdAt);
    if (!parsed) return;
    const bucket = bucketMap.get(getMonthKey(parsed));
    if (!bucket) return;
    bucket.tradesmen += 1;
    bucket.total += 1;
  });

  return buckets;
};

const activityDot = (type: string) => {
  switch (type) {
    case "verification_approved":
    case "verification_restored":
      return "var(--success-solid)";
    case "verification_rejected":
      return "var(--danger-solid)";
    case "verification_archived":
    case "tradesperson_reverify":
      return "var(--warning-solid)";
    default:
      return "var(--info-solid)";
  }
};

// ─────────────────────────────────────────────────────────────────
// MOCK DATA
// ─────────────────────────────────────────────────────────────────
const TRADESMEN_DATA: Tradesman[] = [
  { id: "t1", initials: "MR", color: "linear-gradient(135deg,#1560B0,#2E82D8)", name: "Marco Reyes",      email: "marco.r@gmail.com",   category: "⚡ Electrician",     license: "ELEC-2024-00847", credentialUrl: "", joined: "Jan 2025", jobs: 0,  status: "Pending"  },
  { id: "t2", initials: "JC", color: "linear-gradient(135deg,#0F7060,#17A88E)", name: "Jake Cruz",        email: "jakecruz@gmail.com",  category: "🔧 Plumber",         license: "PLMB-2023-11204", credentialUrl: "", joined: "Feb 2025", jobs: 0,  status: "Pending"  },
  { id: "t3", initials: "AL", color: "linear-gradient(135deg,#5B2D8E,#8040C0)", name: "Ana Lim",          email: "ana.lim@gmail.com",   category: "❄️ HVAC Technician", license: "HVAC-2024-05563", credentialUrl: "", joined: "Mar 2025", jobs: 0,  status: "Pending"  },
  { id: "t4", initials: "RD", color: "linear-gradient(135deg,#1B2B5E,#2D44A0)", name: "Ramon Dela Cruz",  email: "ramon.dc@gmail.com",  category: "🔌 Appliance Repair",license: "APPL-2022-00312", credentialUrl: "", joined: "Nov 2024", jobs: 34, status: "Verified" },
  { id: "t5", initials: "PV", color: "linear-gradient(135deg,#1A7A4A,#26A864)", name: "Pedro Villarta",   email: "pedro.v@yahoo.com",   category: "🎨 Painter",         license: "PAINT-2023-07791", credentialUrl: "", joined: "Oct 2024", jobs: 21, status: "Verified" },
];

const HOMEOWNERS_DATA: Homeowner[] = [
  { id: "h1", initials: "SM", color: "linear-gradient(135deg,#A82040,#D03060)", name: "Sofia Mendoza",  email: "sofia.m@gmail.com",       location: "Quezon City",  registered: "Feb 12, 2025", jobs: 4,  status: "Pending", idNumber: "HO-2025-0183", idStatus: "Pending",  idImageUrl: "/fixit_logo.png" },
  { id: "h2", initials: "BT", color: "linear-gradient(135deg,#1560B0,#2E82D8)", name: "Ben Torres",     email: "bentorres@yahoo.com",     location: "Makati",       registered: "Jan 4, 2025",  jobs: 7,  status: "Active",  idNumber: "HO-2025-0199", idStatus: "Approved", idImageUrl: "/fixit_logo.png" },
  { id: "h3", initials: "LV", color: "linear-gradient(135deg,#B85010,#E87722)", name: "Liza Villanueva",email: "liza.v@outlook.com",       location: "Pasig City",   registered: "Mar 1, 2025",  jobs: 2,  status: "Pending", idNumber: "HO-2025-02A1", idStatus: "Pending",  idImageUrl: "/fixit_logo.png" },
  { id: "h4", initials: "KS", color: "linear-gradient(135deg,#0F7060,#17A88E)", name: "Karl Santos",    email: "karlsantos99@gmail.com",   location: "Mandaluyong",  registered: "Dec 18, 2024", jobs: 11, status: "Active",  idNumber: "HO-2024-5543", idStatus: "Approved", idImageUrl: "/fixit_logo.png" },
  { id: "h5", initials: "MG", color: "linear-gradient(135deg,#5B2D8E,#8040C0)", name: "Maria Garcia",   email: "maria.g@fixit.ph",         location: "Taguig",       registered: "Nov 5, 2024",  jobs: 6,  status: "Active",  idNumber: "HO-2024-1208", idStatus: "Approved", idImageUrl: "/fixit_logo.png" },
  { id: "h6", initials: "JR", color: "linear-gradient(135deg,#1B2B5E,#2D44A0)", name: "Jose Ramos",     email: "jose.r@gmail.com",         location: "Quezon City",  registered: "Oct 22, 2024", jobs: 3,  status: "Inactive",idNumber: "HO-2024-0X12", idStatus: "Rejected", idImageUrl: "/fixit_logo.png" },
];

// ─────────────────────────────────────────────────────────────────
// SHARED MINI-COMPONENTS
// ─────────────────────────────────────────────────────────────────

// Avatar circle
const Avatar = ({ initials, color, size = 40 }: { initials: string; color: string; size?: number }) => (
  <div style={{
    width: size, height: size, borderRadius: size * 0.28,
    background: color, display: "flex", alignItems: "center", justifyContent: "center",
    fontSize: size * 0.33, fontWeight: 800, color: "white", flexShrink: 0,
  }}>
    {initials}
  </div>
);

// Status badge
const Badge = ({ status }: { status: string }) => {
  const styles: Record<string, { bg: string; color: string; border: string }> = {
    Pending:  { bg: "var(--warning-bg)", color: "var(--warning-text)", border: "1px solid var(--warning-border)" },
    Verified: { bg: "var(--success-bg)", color: "var(--success-text)", border: "1px solid var(--success-border)"  },
    Approved: { bg: "var(--success-bg)", color: "var(--success-text)", border: "1px solid var(--success-border)"  },
    Active:   { bg: "var(--success-bg)", color: "var(--success-text)", border: "1px solid var(--success-border)"  },
    Inactive: { bg: "var(--danger-bg)", color: "var(--danger-text)", border: "1px solid var(--danger-border)"  },
    Rejected: { bg: "var(--danger-bg)", color: "var(--danger-text)", border: "1px solid var(--danger-border)"  },
    Suspended:{ bg: "var(--danger-bg)", color: "var(--danger-text)", border: "1px solid var(--danger-border)"  },
    Archived: { bg: "var(--neutral-bg)", color: "var(--neutral-text)", border: "1px solid var(--neutral-border)" },
  };
  const s = styles[status] || styles.Pending;
  return (
    <span style={{
      display: "inline-block", padding: "4px 10px", borderRadius: 100,
      fontSize: 11, fontWeight: 700, background: s.bg, color: s.color, border: s.border,
    }}>
      {status === "Verified" || status === "Approved" ? "" : ""}{status}
    </span>
  );
};

// Small button
const Btn = ({
  children, variant = "default", onClick, disabled,
}: {
  children: ReactNode; variant?: "approve" | "reject" | "view" | "default" | "navy" | "neon";
  onClick?: () => void; disabled?: boolean;
}) => {
  const [hov, setHov] = useState(false);
  const base: Record<string, { bg: string; color: string; border: string; hovBg: string; hovColor: string }> = {
    approve: { bg: "var(--success-bg)", color: "var(--success-text)", border: "1.5px solid var(--success-border)",  hovBg: "var(--success-solid)", hovColor: "white" },
    reject:  { bg: "var(--danger-bg)", color: "var(--danger-text)", border: "1.5px solid var(--danger-border)", hovBg: "var(--danger-solid)", hovColor: "white" },
    view:    { bg: "var(--info-bg)", color: "var(--info-text)", border: "1.5px solid var(--info-border)",  hovBg: "var(--info-solid)", hovColor: "white" },
    navy:    { bg: "var(--info-bg)", color: "var(--info-text)", border: "1.5px solid var(--info-border)",  hovBg: "var(--info-solid)", hovColor: "white" },
    neon:    { bg: "var(--neon-bg)", color: "var(--neon-text)", border: "1.5px solid var(--neon-border)",  hovBg: "var(--neon-bg-hover)", hovColor: "var(--neon-text)" },
    default: { bg: "var(--surface-2)", color: "var(--text)", border: "1.5px solid var(--border)",              hovBg: "var(--border)", hovColor: "var(--text)" },
  };
  const v = base[variant];
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        display: "inline-flex", alignItems: "center", gap: 5,
        padding: "7px 13px", borderRadius: 7,
        fontFamily: "inherit", fontSize: 12, fontWeight: 700,
        border: v.border, cursor: disabled ? "not-allowed" : "pointer",
        background: hov && !disabled ? v.hovBg : v.bg,
        color:      hov && !disabled ? v.hovColor : v.color,
        opacity: disabled ? 0.45 : 1, transition: "all .2s",
        whiteSpace: "nowrap",
        boxShadow: variant === "neon" ? (hov && !disabled ? "var(--neon-glow-hover)" : "var(--neon-glow)") : "none",
      }}
    >
      {children}
    </button>
  );
};

// Card wrapper
const Card = ({ children, style = {} }: { children: ReactNode; style?: React.CSSProperties }) => (
  <div style={{
    background: "var(--surface)", borderRadius: 12, border: "1.5px solid var(--border)",
    boxShadow: "var(--shadow)", overflow: "hidden", ...style,
  }}>
    {children}
  </div>
);

// Card header
const CardHead = ({ title, subtitle, right }: { title: string; subtitle?: string; right?: ReactNode }) => (
  <div style={{
    padding: "18px 24px", borderBottom: "1px solid var(--border)",
    display: "flex", alignItems: "center", justifyContent: "space-between",
  }}>
    <div>
      <div style={{ fontSize: 15, fontWeight: 800, color: "var(--text)" }}>{title}</div>
      {subtitle && <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 2 }}>{subtitle}</div>}
    </div>
    {right && <div style={{ display: "flex", alignItems: "center", gap: 10 }}>{right}</div>}
  </div>
);

// Pill
const Pill = ({ children, color = "orange" }: { children: ReactNode; color?: "orange" | "navy" | "green" }) => {
  const c = { orange: ["var(--warning-bg)","var(--warning-text)"], navy: ["var(--info-bg)","var(--info-text)"], green: ["var(--success-bg)","var(--success-text)"] }[color] ?? ["var(--info-bg)","var(--info-text)"];
  return (
    <span style={{ padding: "4px 12px", borderRadius: 100, fontSize: 12, fontWeight: 700, background: c[0], color: c[1] }}>
      {children}
    </span>
  );
};

// Toggle switch
const Toggle = ({
  checked,
  onChange,
  label,
  description,
}: {
  checked: boolean;
  onChange: (value: boolean) => void;
  label: string;
  description?: string;
}) => (
  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 16, padding: "12px 0", borderBottom: "1px solid var(--border)" }}>
    <div>
      <div style={{ fontSize: 13, fontWeight: 700, color: "var(--text)" }}>{label}</div>
      {description && <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 3 }}>{description}</div>}
    </div>
    <button
      type="button"
      onClick={() => onChange(!checked)}
      aria-pressed={checked}
      style={{
        width: 46,
        height: 26,
        borderRadius: 999,
        border: "1px solid var(--border)",
        background: checked ? "var(--success-solid)" : "var(--surface-2)",
        display: "flex",
        alignItems: "center",
        padding: 3,
        cursor: "pointer",
        transition: "all .2s",
      }}
    >
      <span
        style={{
          width: 18,
          height: 18,
          borderRadius: 999,
          background: "white",
          transform: checked ? "translateX(20px)" : "translateX(0px)",
          transition: "transform .2s",
        }}
      />
    </button>
  </div>
);

// Sidebar shield logo
function SidebarShield() {
  return (
    <svg width="38" height="42" viewBox="0 0 100 112" fill="none">
      <path d="M50 5L9 22V54C9 77 27 97.5 50 105C73 97.5 91 77 91 54V22L50 5Z" fill="rgba(255,255,255,0.12)" />
      <path d="M50 14L16 29V54C16 74 31.5 92 50 99C68.5 92 84 74 84 54V29L50 14Z" fill="rgba(255,255,255,0.07)" />
      <polygon points="50,30 30,46 30,66 42,66 42,54 58,54 58,66 70,66 70,46" fill="white" opacity="0.9" />
      <polygon points="22,49 50,26 78,49" fill="white" opacity="0.6" />
      <circle cx="66" cy="70" r="12" fill="var(--accent)" />
      <line x1="62" y1="66" x2="70" y2="74" stroke="white" strokeWidth="2.5" strokeLinecap="round" />
    </svg>
  );
}

// Toast component
const Toast = ({ msg, type, show }: { msg: string; type: ToastType; show: boolean }) => {
  const colors = { success: "var(--success-solid)", error: "var(--danger-solid)", info: "var(--info-solid)" };
  return (
    <div style={{
      position: "fixed", top: 20, left: "50%",
      transform: `translateX(-50%) translateY(${show ? "0" : "-90px"})`,
      background: colors[type], color: "white",
      padding: "11px 20px", borderRadius: 8, fontSize: 13, fontWeight: 600,
      zIndex: 9999, display: "flex", alignItems: "center", gap: 8,
      boxShadow: "0 12px 40px rgba(15,25,35,.2)",
      transition: "transform .3s cubic-bezier(.16,1,.3,1)",
      whiteSpace: "nowrap", pointerEvents: "none",
    }}>
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="20 6 9 17 4 12" />
      </svg>
      {msg}
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────
// MODAL
// ─────────────────────────────────────────────────────────────────
const Modal = ({
  open, onClose, title, rows, actions,
}: {
  open: boolean; onClose: () => void; title: string;
  rows: { label: string; value: string; highlight?: boolean }[];
  actions?: ReactNode;
}) => {
  if (!open) return null;
  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed", inset: 0, background: "rgba(15,25,35,.5)",
        backdropFilter: "blur(4px)", zIndex: 200,
        display: "flex", alignItems: "center", justifyContent: "center",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: "var(--surface)", borderRadius: 16, padding: 28,
          width: "100%", maxWidth: 440,
          boxShadow: "0 12px 40px rgba(15,25,35,.18)",
          animation: "mIn .3s cubic-bezier(.16,1,.3,1)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 22 }}>
          <h3 style={{ fontSize: 18, fontWeight: 800, color: "var(--text)", margin: 0 }}>{title}</h3>
          <button onClick={onClose} style={{ width: 32, height: 32, borderRadius: 8, background: "var(--surface-2)", border: "1.5px solid var(--border)", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", color: "var(--muted)" }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
          </button>
        </div>
        {rows.map((r, i) => (
          <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "11px 0", borderBottom: i < rows.length - 1 ? "1px solid var(--border)" : "none" }}>
            <span style={{ fontSize: 13, color: "var(--muted)", fontWeight: 500 }}>{r.label}</span>
            <span style={{ fontSize: 13, fontWeight: 700, color: r.highlight ? "var(--success-solid)" : "var(--text)" }}>{r.value}</span>
          </div>
        ))}
        {actions && (
          <div style={{ display: "flex", gap: 8, marginTop: 16 }}>
            {actions}
          </div>
        )}
        <button onClick={onClose} style={{
          width: "100%", padding: 13, marginTop: 20,
          background: "var(--accent)", border: "none", borderRadius: 8,
          fontFamily: "inherit", fontSize: 14, fontWeight: 800, color: "white",
          cursor: "pointer", transition: "background .2s",
        }}
          onMouseEnter={(e) => (e.currentTarget.style.background = "var(--accent-hover)")}
          onMouseLeave={(e) => (e.currentTarget.style.background = "var(--accent)")}
        >
          Close
        </button>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────
// CONFIRMATION MODAL
// ─────────────────────────────────────────────────────────────────
const ConfirmModal = ({
  open,
  title,
  message,
  confirmLabel,
  onConfirm,
  onClose,
}: {
  open: boolean;
  title: string;
  message: string;
  confirmLabel: string;
  onConfirm: () => void;
  onClose: () => void;
}) => {
  if (!open) return null;
  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(15,25,35,.5)",
        backdropFilter: "blur(4px)",
        zIndex: 210,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: "var(--surface)",
          borderRadius: 16,
          padding: 24,
          width: "100%",
          maxWidth: 420,
          boxShadow: "0 12px 40px rgba(15,25,35,.18)",
          animation: "mIn .3s cubic-bezier(.16,1,.3,1)",
        }}
      >
        <div style={{ fontSize: 17, fontWeight: 800, color: "var(--text)", marginBottom: 8 }}>{title}</div>
        <div style={{ fontSize: 13, color: "var(--muted)", marginBottom: 18 }}>{message}</div>
        <div style={{ display: "flex", justifyContent: "flex-end", gap: 8 }}>
          <button
            onClick={onClose}
            style={{
              padding: "9px 14px",
              background: "var(--surface-2)",
              border: "1.5px solid var(--border)",
              borderRadius: 8,
              fontFamily: "inherit",
              fontSize: 13,
              fontWeight: 700,
              color: "var(--text)",
              cursor: "pointer",
            }}
          >
            Cancel
          </button>
          <Btn variant="reject" onClick={onConfirm}>{confirmLabel}</Btn>
        </div>
      </div>
    </div>
  );
};

const ImageModal = ({
  open, onClose, title, imageUrl, contentType,
}: {
  open: boolean; onClose: () => void; title: string; imageUrl: string; contentType: string;
}) => {
  if (!open) return null;
  const isPdf = contentType.includes("pdf") || imageUrl.toLowerCase().endsWith(".pdf");
  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed", inset: 0, background: "rgba(15,25,35,.5)",
        backdropFilter: "blur(4px)", zIndex: 220,
        display: "flex", alignItems: "center", justifyContent: "center",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: "var(--surface)", borderRadius: 16, padding: 24,
          width: "100%", maxWidth: 640,
          boxShadow: "0 12px 40px rgba(15,25,35,.18)",
          animation: "mIn .3s cubic-bezier(.16,1,.3,1)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
          <div>
            <h3 style={{ fontSize: 18, fontWeight: 800, color: "var(--text)", margin: 0 }}>{title}</h3>
            <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 3 }}>Uploaded ID image</div>
          </div>
          <button onClick={onClose} style={{ width: 32, height: 32, borderRadius: 8, background: "var(--surface-2)", border: "1.5px solid var(--border)", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", color: "var(--muted)" }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
          </button>
        </div>
        <div style={{ borderRadius: 12, border: "1.5px solid var(--border)", background: "var(--surface-2)", padding: 12 }}>
          {isPdf ? (
            <iframe
              src={imageUrl}
              title={`${title} document`}
              style={{ display: "block", width: "100%", height: 520, border: "none", borderRadius: 8, background: "white" }}
            />
          ) : (
            <img
              src={imageUrl}
              alt={`${title} ID`}
              style={{ display: "block", width: "100%", height: "auto", borderRadius: 8 }}
            />
          )}
        </div>
        <button onClick={onClose} style={{
          width: "100%", padding: 12, marginTop: 18,
          background: "var(--primary-bg)", border: "none", borderRadius: 8,
          fontFamily: "inherit", fontSize: 14, fontWeight: 800, color: "white",
          cursor: "pointer", transition: "background .2s",
        }}
          onMouseEnter={(e) => (e.currentTarget.style.background = "var(--primary-bg-hover)")}
          onMouseLeave={(e) => (e.currentTarget.style.background = "var(--primary-bg)")}
        >
          Close
        </button>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────
// TABLE WRAPPER
// ─────────────────────────────────────────────────────────────────
const Table = ({ children }: { children: ReactNode }) => (
  <div style={{ overflowX: "auto" }}>
    <table style={{ width: "100%", borderCollapse: "collapse" }}>{children}</table>
  </div>
);
const Th = ({ children }: { children: ReactNode }) => (
  <th style={{ padding: "12px 20px", textAlign: "left", fontSize: 11, fontWeight: 700, letterSpacing: "0.8px", textTransform: "uppercase", color: "var(--muted)", background: "var(--table-head)", borderBottom: "1px solid var(--border)", whiteSpace: "nowrap" }}>
    {children}
  </th>
);
const Td = ({ children, style = {}, colSpan }: { children: ReactNode; style?: React.CSSProperties; colSpan?: number }) => (
  <td colSpan={colSpan} style={{ padding: "14px 20px", fontSize: 13, color: "var(--text)", borderBottom: "1px solid var(--border)", verticalAlign: "middle", ...style }}>
    {children}
  </td>
);

// ─────────────────────────────────────────────────────────────────
// TOOLBAR (search + filters inside card)
// ─────────────────────────────────────────────────────────────────
const Toolbar = ({
  placeholder,
  filters,
  searchValue,
  onSearchChange,
  filterValues,
  onFilterChange,
}: {
  placeholder: string;
  filters: string[][];
  searchValue: string;
  onSearchChange: (value: string) => void;
  filterValues: string[];
  onFilterChange: (index: number, value: string) => void;
}) => (
  <div style={{ padding: "14px 24px", borderBottom: "1px solid var(--border)", background: "var(--surface-2)", display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap" }}>
    <div style={{ flex: 1, minWidth: 200, display: "flex", alignItems: "center", gap: 8, padding: "9px 14px", background: "var(--surface)", border: "1.5px solid var(--border)", borderRadius: 8 }}>
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>
      <input
        type="text"
        placeholder={placeholder}
        value={searchValue}
        onChange={(e) => onSearchChange(e.target.value)}
        style={{ border: "none", outline: "none", background: "transparent", fontFamily: "inherit", fontSize: 13, color: "var(--text)", width: "100%" }}
      />
    </div>
    {filters.map((opts, i) => (
      <select
        key={i}
        value={filterValues[i] ?? ""}
        onChange={(e) => onFilterChange(i, e.target.value)}
        style={{ padding: "9px 14px", background: "var(--surface)", border: "1.5px solid var(--border)", borderRadius: 8, fontFamily: "inherit", fontSize: 13, fontWeight: 600, color: "var(--text)", outline: "none", cursor: "pointer", minWidth: 140 }}
      >
        {opts.map((o) => <option key={o} value={o === opts[0] ? "" : o}>{o}</option>)}
      </select>
    ))}
  </div>
);

// ─────────────────────────────────────────────────────────────────
// ACTIVITY FEED ITEM
// ─────────────────────────────────────────────────────────────────
const ActivityItem = ({ dot, title, sub, time, isLast = false }: { dot: string; title: string; sub: string; time: string; isLast?: boolean }) => (
  <div style={{ display: "flex", alignItems: "flex-start", gap: 14, padding: "14px 24px", borderBottom: isLast ? "none" : "1px solid var(--border)" }}>
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", paddingTop: 3 }}>
      <div style={{ width: 10, height: 10, borderRadius: "50%", background: dot, flexShrink: 0 }} />
      {!isLast && <div style={{ width: 2, flex: 1, background: "var(--border)", marginTop: 4, minHeight: 24 }} />}
    </div>
    <div style={{ flex: 1 }}>
      <div style={{ fontSize: 13, fontWeight: 700, color: "var(--text)", marginBottom: 3 }}>{title}</div>
      <div style={{ fontSize: 12, color: "var(--muted)" }}>{sub}</div>
    </div>
    <div style={{ fontSize: 11, color: "var(--muted)", whiteSpace: "nowrap", paddingTop: 2 }}>{time}</div>
  </div>
);

// ─────────────────────────────────────────────────────────────────
// NOTIFICATION ITEM (Topbar)
// ─────────────────────────────────────────────────────────────────
const NotificationItem = ({
  dot, title, sub, time, isLast = false,
}: {
  dot: string; title: string; sub: string; time: string; isLast?: boolean;
}) => (
  <div style={{ display: "grid", gridTemplateColumns: "10px 1fr auto", gap: 10, padding: "10px 14px", borderBottom: isLast ? "none" : "1px solid var(--border)" }}>
    <div style={{ width: 8, height: 8, borderRadius: "50%", background: dot, marginTop: 5 }} />
    <div>
      <div style={{ fontSize: 12, fontWeight: 700, color: "var(--text)", marginBottom: 2 }}>{title}</div>
      <div style={{ fontSize: 11, color: "var(--muted)" }}>{sub}</div>
    </div>
    <div style={{ fontSize: 10, color: "var(--muted)", whiteSpace: "nowrap", marginTop: 2 }}>{time}</div>
  </div>
);

// ─────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────
const StatCard = ({ icon, iconBg, iconColor, num, label, trend, trendType }: {
  icon: ReactNode; iconBg: string; iconColor: string;
  num: number; label: string; trend: string; trendType: "up" | "warn";
}) => {
  const [hov, setHov] = useState(false);
  return (
    <div
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        background: "var(--surface)", borderRadius: 12, border: "1.5px solid var(--border)",
        padding: "20px", boxShadow: hov ? "0 4px 16px rgba(15,25,35,.09)" : "var(--shadow)",
        transform: hov ? "translateY(-2px)" : "translateY(0)",
        transition: "all .2s",
      }}
    >
      <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 16 }}>
        <div style={{ width: 44, height: 44, borderRadius: 11, background: iconBg, display: "flex", alignItems: "center", justifyContent: "center", color: iconColor }}>
          {icon}
        </div>
        <span style={{
          display: "flex", alignItems: "center", gap: 4, padding: "3px 8px", borderRadius: 100, fontSize: 11, fontWeight: 700,
          background: trendType === "up" ? "var(--success-bg)" : "var(--warning-bg)",
          color:      trendType === "up" ? "var(--success-text)"  : "var(--warning-text)",
        }}>
          {trend}
        </span>
      </div>
      <div style={{ fontSize: 32, fontWeight: 800, color: "var(--text)", letterSpacing: -1.5, lineHeight: 1, marginBottom: 5 }}>{num}</div>
      <div style={{ fontSize: 13, color: "var(--muted)", fontWeight: 500 }}>{label}</div>
    </div>
  );
};

const UserGrowthChart = ({
  homeownerCount,
  tradesmanCount,
  totalUsers,
  activeUsers,
  latestMonthUsers,
  averageMonthlyUsers,
}: {
  homeownerCount: number;
  tradesmanCount: number;
  totalUsers: number;
  activeUsers: number;
  latestMonthUsers: number;
  averageMonthlyUsers: number;
}) => {
  const hasData = totalUsers > 0;
  const homeownerRatio = hasData ? homeownerCount / totalUsers : 0;
  const tradesmanRatio = hasData ? tradesmanCount / totalUsers : 0;
  const radius = 76;
  const circumference = 2 * Math.PI * radius;
  const homeownerStroke = homeownerRatio * circumference;
  const tradesmanStroke = tradesmanRatio * circumference;

  return (
    <Card style={{ marginBottom: 28 }}>
      <CardHead
        title="User Distribution"
        subtitle="Current breakdown of homeowners and tradesmen on the platform"
        right={<Pill color="navy">Live User Mix</Pill>}
      />
      <div style={{ padding: "24px", display: "grid", gridTemplateColumns: "minmax(0,2fr) minmax(220px,1fr)", gap: 24, alignItems: "stretch" }}>
        <div>
          {hasData ? (
            <div style={{ minHeight: 260, display: "grid", gridTemplateColumns: "minmax(240px,320px) minmax(0,1fr)", gap: 24, alignItems: "center" }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center" }}>
                <div style={{ position: "relative", width: 220, height: 220 }}>
                  <svg viewBox="0 0 220 220" style={{ width: "100%", height: "100%", transform: "rotate(-90deg)" }} aria-label="User distribution pie chart">
                    <circle
                      cx="110"
                      cy="110"
                      r={radius}
                      fill="none"
                      stroke="var(--surface-2)"
                      strokeWidth="34"
                    />
                    <circle
                      cx="110"
                      cy="110"
                      r={radius}
                      fill="none"
                      stroke="var(--info-solid)"
                      strokeWidth="34"
                      strokeDasharray={`${homeownerStroke} ${circumference - homeownerStroke}`}
                      strokeLinecap="butt"
                    />
                    <circle
                      cx="110"
                      cy="110"
                      r={radius}
                      fill="none"
                      stroke="var(--accent)"
                      strokeWidth="34"
                      strokeDasharray={`${tradesmanStroke} ${circumference - tradesmanStroke}`}
                      strokeDashoffset={-homeownerStroke}
                      strokeLinecap="butt"
                    />
                  </svg>
                  <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", textAlign: "center" }}>
                    <div style={{ fontSize: 12, fontWeight: 700, color: "var(--muted)", letterSpacing: 0.4, textTransform: "uppercase" }}>Total Users</div>
                    <div style={{ fontSize: 38, lineHeight: 1, fontWeight: 800, color: "var(--text)", marginTop: 6 }}>{totalUsers}</div>
                  </div>
                </div>
              </div>
              <div style={{ display: "grid", gap: 14 }}>
                {[
                  {
                    label: "Homeowners",
                    count: homeownerCount,
                    ratio: homeownerRatio,
                    color: "var(--info-solid)",
                    bg: "var(--info-bg)",
                  },
                  {
                    label: "Tradesmen",
                    count: tradesmanCount,
                    ratio: tradesmanRatio,
                    color: "var(--accent)",
                    bg: "var(--accent-soft)",
                  },
                ].map((item) => (
                  <div key={item.label} style={{ border: "1px solid var(--border)", borderRadius: 16, background: "var(--surface-2)", padding: "16px 18px" }}>
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 16, marginBottom: 12 }}>
                      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                        <span style={{ width: 12, height: 12, borderRadius: "50%", background: item.color, flexShrink: 0 }} />
                        <span style={{ fontSize: 14, fontWeight: 800, color: "var(--text)" }}>{item.label}</span>
                      </div>
                      <span style={{ fontSize: 14, fontWeight: 800, color: item.color }}>{Math.round(item.ratio * 100)}%</span>
                    </div>
                    <div style={{ fontSize: 28, lineHeight: 1, fontWeight: 800, color: "var(--text)", marginBottom: 12 }}>{item.count}</div>
                    <div style={{ width: "100%", height: 10, borderRadius: 999, background: item.bg, overflow: "hidden" }}>
                      <div style={{ width: `${item.ratio * 100}%`, height: "100%", background: item.color, borderRadius: 999 }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div style={{ minHeight: 260, borderRadius: 16, border: "1.5px dashed var(--border)", background: "var(--surface-2)", display: "flex", alignItems: "center", justifyContent: "center", textAlign: "center", padding: "24px" }}>
              <div>
                <div style={{ fontSize: 15, fontWeight: 800, color: "var(--text)", marginBottom: 6 }}>No users yet</div>
                <div style={{ fontSize: 12, color: "var(--muted)" }}>The pie chart will populate once homeowner or tradesman accounts are available.</div>
              </div>
            </div>
          )}
        </div>

        <div style={{ display: "grid", gap: 12 }}>
          {[
            { label: "Total Users", value: totalUsers, tone: "var(--info-text)", bg: "var(--info-bg)" },
            { label: "Active Accounts", value: activeUsers, tone: "var(--success-text)", bg: "var(--success-bg)" },
            { label: "New This Month", value: latestMonthUsers, tone: "var(--accent)", bg: "var(--accent-soft)" },
            { label: "Monthly Average", value: averageMonthlyUsers, tone: "var(--warning-text)", bg: "var(--warning-bg)" },
          ].map((item) => (
            <div key={item.label} style={{ border: "1px solid var(--border)", borderRadius: 14, padding: "16px 18px", background: "var(--surface-2)" }}>
              <div style={{ display: "inline-flex", padding: "5px 10px", borderRadius: 999, background: item.bg, color: item.tone, fontSize: 11, fontWeight: 800, marginBottom: 12 }}>
                {item.label}
              </div>
              <div style={{ fontSize: 28, lineHeight: 1, fontWeight: 800, color: "var(--text)", letterSpacing: -1 }}>{item.value}</div>
            </div>
          ))}
        </div>
      </div>
    </Card>
  );
};

// ─────────────────────────────────────────────────────────────────
// VERIFICATION QUEUE CARD (Dashboard)
// ─────────────────────────────────────────────────────────────────
const VCard = ({ t, onApprove, onReject }: { t: Tradesman; onApprove: () => void; onReject: () => void }) => {
  const [hov, setHov] = useState(false);
  return (
    <div
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        background: "var(--surface-2)", border: "1.5px solid var(--border)", borderRadius: 12, padding: 18,
        transform: hov ? "translateY(-2px)" : "translateY(0)",
        boxShadow: hov ? "0 4px 16px rgba(15,25,35,.09)" : "none",
        transition: "all .2s",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <Avatar initials={t.initials} color={t.color} size={46} />
          <div>
            <div style={{ fontSize: 14, fontWeight: 800, color: "var(--text)", marginBottom: 2 }}>{t.name}</div>
            <div style={{ fontSize: 12, color: "var(--muted)", fontWeight: 500 }}>{t.category}</div>
          </div>
        </div>
        <Badge status={t.status} />
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 7, background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8, padding: "8px 12px", marginBottom: 12 }}>
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="7" width="20" height="14" rx="2" /><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16" /></svg>
        <span style={{ fontSize: 12, color: "var(--text)", fontWeight: 600 }}>
          <strong style={{ color: "var(--muted)", fontWeight: 600, marginRight: 6 }}>License:</strong>{t.license}
        </span>
      </div>
      <div style={{ display: "flex", gap: 8 }}>
        <Btn variant="approve" onClick={onApprove}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>
          Approve
        </Btn>
        <Btn variant="reject" onClick={onReject}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
          Reject
        </Btn>
      </div>
    </div>
  );
};

const VerificationCard = ({
  v, onApprove, onReject, onView, onArchive, name,
}: {
  v: Verification;
  onApprove: () => void;
  onReject: () => void;
  onView: () => void;
  onArchive: () => void;
  name: string;
}) => {
  const [hov, setHov] = useState(false);
  const statusLabel = toTitle(v.status);
  const viewLabel = v.type === "homeowner_id" ? "View ID" : "View License/Cert";
  return (
    <div
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        background: "var(--surface-2)", border: "1.5px solid var(--border)", borderRadius: 12, padding: 18,
        transform: hov ? "translateY(-2px)" : "translateY(0)",
        boxShadow: hov ? "0 4px 16px rgba(15,25,35,.09)" : "none",
        transition: "all .2s",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
        <div>
          <div style={{ fontSize: 13, fontWeight: 800, color: "var(--text)", marginBottom: 2 }}>
            {name ? `${name} · User #${v.userId}` : `User #${v.userId}`}
          </div>
          <div style={{ fontSize: 12, color: "var(--muted)", fontWeight: 600 }}>{verificationTypeLabel(v.type)}</div>
        </div>
        <Badge status={statusLabel} />
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 7, background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 8, padding: "8px 12px", marginBottom: 12 }}>
        {icons.license}
        <span style={{ fontSize: 12, color: "var(--text)", fontWeight: 600 }}>
          <strong style={{ color: "var(--muted)", fontWeight: 600, marginRight: 6 }}>Document:</strong>
          {v.documentUrl ? "Uploaded" : "Missing"}
        </span>
      </div>
      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        {v.status === "pending" ? (
          <>
            <Btn variant="approve" onClick={onApprove}>{icons.check} Approve</Btn>
            <Btn variant="reject" onClick={onReject}>{icons.x} Reject</Btn>
          </>
        ) : (
          <Btn disabled>{icons.check} {statusLabel}</Btn>
        )}
        <Btn variant="view" onClick={onView} disabled={!v.documentUrl}>{icons.license} {viewLabel}</Btn>
        <Btn variant="reject" onClick={onArchive}>{icons.x} Archive</Btn>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────
// SIDEBAR NAV ITEM
// ─────────────────────────────────────────────────────────────────
const NavItem = ({
  icon, label, active, badge, onClick,
}: {
  icon: ReactNode; label: string; active?: boolean; badge?: number; onClick: () => void;
}) => {
  const [hov, setHov] = useState(false);
  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        display: "flex", alignItems: "center", gap: 12,
        padding: "11px 12px", borderRadius: 10, width: "100%",
        fontFamily: "inherit", border: "none", textAlign: "left", cursor: "pointer",
        marginBottom: 2,
        background: active ? "var(--neon-bg)" : hov ? "var(--sidebar-hover)" : "transparent",
        boxShadow: active ? "var(--neon-glow)" : "none",
        transition: "all .2s",
      }}
    >
      <span style={{ color: active ? "var(--neon-text)" : "rgba(255,255,255,0.45)", flexShrink: 0, display: "flex" }}>
        {icon}
      </span>
      <span style={{ fontSize: 13, fontWeight: 600, color: active ? "var(--neon-text)" : "rgba(255,255,255,0.5)", flex: 1 }}>
        {label}
      </span>
      {badge !== undefined && badge > 0 && (
        <span style={{ background: active ? "rgba(255,255,255,0.3)" : "var(--accent)", color: "white", fontSize: 10, fontWeight: 800, padding: "2px 7px", borderRadius: 100 }}>
          {badge}
        </span>
      )}
    </button>
  );
};

// ─────────────────────────────────────────────────────────────────
// ICONS
// ─────────────────────────────────────────────────────────────────
const icons = {
  grid:    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>,
  shield:  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>,
  wrench:  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>,
  home:    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>,
  user:    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>,
  chart:   <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>,
  settings:<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>,
  logout:  <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>,
  bell:    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>,
  check:   <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>,
  x:       <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>,
  license: <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>,
};

// ─────────────────────────────────────────────────────────────────
// MAIN DASHBOARD PAGE
// ─────────────────────────────────────────────────────────────────
export default function DashboardPage() {
  const router = useRouter();

  // State
  const [activePage, setActivePage] = useState<Page>("dashboard");
  const [tradesmen, setTradesmen]   = useState<Tradesman[]>([]);
  const [homeowners, setHomeowners] = useState<Homeowner[]>([]);
  const [verifications, setVerifications] = useState<Verification[]>([]);
  const [authToken, setAuthToken] = useState<string | null>(null);
  const [isDark, setIsDark] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [toast, setToast]           = useState({ show: false, msg: "", type: "success" as ToastType });
  const [modal, setModal]           = useState<{ open: boolean; title: string; rows: { label: string; value: string; highlight?: boolean }[]; actions?: ReactNode }>({ open: false, title: "", rows: [] });
  const [idModal, setIdModal]       = useState<{ open: boolean; title: string; imageUrl: string; contentType: string }>({ open: false, title: "", imageUrl: "", contentType: "" });
  const [confirm, setConfirm]       = useState<{ open: boolean; title: string; message: string; confirmLabel: string; onConfirm: () => void }>({
    open: false,
    title: "",
    message: "",
    confirmLabel: "Confirm",
    onConfirm: () => {},
  });
  const [searchVerification, setSearchVerification] = useState("");
  const [searchTradesmen, setSearchTradesmen] = useState("");
  const [searchHomeowners, setSearchHomeowners] = useState("");
  const [searchDashboard, setSearchDashboard] = useState("");
  const [showArchivedOnly, setShowArchivedOnly] = useState(false);
  const [verificationFilters, setVerificationFilters] = useState<string[]>(["", ""]);
  const [tradesmenFilters, setTradesmenFilters] = useState<string[]>(["", ""]);
  const [homeownerFilters, setHomeownerFilters] = useState<string[]>(["", ""]);
  const [activity, setActivity] = useState<ActivityEntry[]>([]);
  const [bellOpen, setBellOpen] = useState(false);
  const bellButtonRef = useRef<HTMLButtonElement | null>(null);
  const bellPanelRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const stored = localStorage.getItem("admin_theme");
    if (stored === "dark") {
      setIsDark(true);
    }
  }, []);

  useEffect(() => {
    localStorage.setItem("admin_theme", isDark ? "dark" : "light");
  }, [isDark]);

  useEffect(() => {
    document.body.style.background = isDark ? "#0B1220" : "#F1F3F7";
    document.body.style.color = isDark ? "#E5E7EB" : "#0F1923";
  }, [isDark]);

  useEffect(() => {
    const stored = localStorage.getItem("admin_autorefresh");
    if (stored === "off") {
      setAutoRefresh(false);
    }
  }, []);

  useEffect(() => {
    localStorage.setItem("admin_autorefresh", autoRefresh ? "on" : "off");
  }, [autoRefresh]);

  useEffect(() => {
    if (!bellOpen) return;
    const handleClick = (event: MouseEvent) => {
      const target = event.target as Node;
      if (bellButtonRef.current?.contains(target)) return;
      if (bellPanelRef.current?.contains(target)) return;
      setBellOpen(false);
    };
    const handleKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") setBellOpen(false);
    };
    document.addEventListener("mousedown", handleClick);
    document.addEventListener("keydown", handleKey);
    return () => {
      document.removeEventListener("mousedown", handleClick);
      document.removeEventListener("keydown", handleKey);
    };
  }, [bellOpen]);

  useEffect(() => {
    setBellOpen(false);
  }, [activePage]);

  const themeVars: CSSProperties & Record<string, string> = isDark
    ? {
        "--bg": "#0B1220",
        "--surface": "#0F172A",
        "--surface-2": "#111827",
        "--border": "#1F2A3B",
        "--text": "#E5E7EB",
        "--muted": "#94A3B8",
        "--shadow": "0 1px 3px rgba(0,0,0,.35)",
        "--sidebar": "#0B1220",
        "--sidebar-accent": "#111E35",
        "--table-head": "#0F172A",
        "--accent": "#F59E0B",
        "--accent-hover": "#FBBF24",
        "--accent-soft": "rgba(245,158,11,0.18)",
        "--success-bg": "rgba(34,197,94,0.16)",
        "--success-text": "#6EE7B7",
        "--success-border": "rgba(34,197,94,0.35)",
        "--success-solid": "#22C55E",
        "--warning-bg": "rgba(245,158,11,0.16)",
        "--warning-text": "#FACC15",
        "--warning-border": "rgba(245,158,11,0.35)",
        "--warning-solid": "#F59E0B",
        "--danger-bg": "rgba(239,68,68,0.16)",
        "--danger-text": "#FCA5A5",
        "--danger-border": "rgba(239,68,68,0.35)",
        "--danger-solid": "#EF4444",
        "--info-bg": "rgba(59,130,246,0.16)",
        "--info-text": "#93C5FD",
        "--info-border": "rgba(59,130,246,0.35)",
        "--info-solid": "#60A5FA",
        "--neutral-bg": "rgba(148,163,184,0.18)",
        "--neutral-text": "#CBD5E1",
        "--neutral-border": "rgba(148,163,184,0.35)",
        "--neutral-solid": "#94A3B8",
        "--row-hover": "rgba(148,163,184,0.12)",
        "--primary-bg": "#1D4ED8",
        "--primary-bg-hover": "#2563EB",
        "--sidebar-hover": "rgba(255,255,255,0.08)",
        "--neon-bg": "linear-gradient(135deg,#00E5FF,#A78BFA)",
        "--neon-bg-hover": "linear-gradient(135deg,#00CFFF,#8B5CF6)",
        "--neon-text": "#0B1220",
        "--neon-border": "rgba(0,229,255,0.45)",
        "--neon-glow": "0 0 14px rgba(0,229,255,0.35)",
        "--neon-glow-hover": "0 0 20px rgba(0,229,255,0.55)",
        "--scrollbar": "#475569",
        "--scrollbar-hover": "#64748B",
      }
    : {
        "--bg": "#F1F3F7",
        "--surface": "#FFFFFF",
        "--surface-2": "#F7F8FA",
        "--border": "#E3E8F0",
        "--text": "#0F1923",
        "--muted": "#9AA3B8",
        "--shadow": "0 1px 3px rgba(15,25,35,.06)",
        "--sidebar": "#1B2B5E",
        "--sidebar-accent": "#1B2B5E",
        "--table-head": "#F7F8FA",
        "--accent": "#E87722",
        "--accent-hover": "#F09040",
        "--accent-soft": "#FEF0E4",
        "--success-bg": "#E6F5EE",
        "--success-text": "#1A7A4A",
        "--success-border": "rgba(26,122,74,0.2)",
        "--success-solid": "#1A7A4A",
        "--warning-bg": "#FEF3E0",
        "--warning-text": "#B86A00",
        "--warning-border": "rgba(184,106,0,0.2)",
        "--warning-solid": "#B86A00",
        "--danger-bg": "#FFF0F1",
        "--danger-text": "#DC3545",
        "--danger-border": "rgba(220,53,69,0.2)",
        "--danger-solid": "#DC3545",
        "--info-bg": "#EEF1FA",
        "--info-text": "#1B2B5E",
        "--info-border": "rgba(27,43,94,0.15)",
        "--info-solid": "#1B2B5E",
        "--neutral-bg": "#EEF1FA",
        "--neutral-text": "#4A5568",
        "--neutral-border": "rgba(74,85,104,0.25)",
        "--neutral-solid": "#4A5568",
        "--row-hover": "#FAFBFD",
        "--primary-bg": "#1B2B5E",
        "--primary-bg-hover": "#243673",
        "--sidebar-hover": "rgba(255,255,255,0.06)",
        "--neon-bg": "linear-gradient(135deg,#00E5FF,#00FFB2)",
        "--neon-bg-hover": "linear-gradient(135deg,#00CFFF,#00FF89)",
        "--neon-text": "#0F1923",
        "--neon-border": "rgba(0,229,255,0.6)",
        "--neon-glow": "0 0 12px rgba(0,229,255,0.35)",
        "--neon-glow-hover": "0 0 18px rgba(0,229,255,0.5)",
        "--scrollbar": "#64748B",
        "--scrollbar-hover": "#94A3B8",
      };

  const pendingCount  = verifications.filter((v) => v.status === "pending").length;
  const archivedCount = verifications.filter((v) => v.status === "archived").length;
  const verifiedCount = tradesmen.filter((t) => t.status === "Verified").length;
  const pendingHomeownerIds = homeowners.filter((h) => h.idStatus === "Pending").length;
  const notificationCount = activity.length;
  const totalUsers = homeowners.length + tradesmen.length;
  const activeUsers = homeowners.filter((h) => h.status === "Active").length + verifiedCount;
  const userGrowthData = buildUserGrowthData(homeowners, tradesmen);
  const latestMonthUsers = userGrowthData[userGrowthData.length - 1]?.total ?? 0;
  const averageMonthlyUsers = Math.round(
    userGrowthData.reduce((sum, point) => sum + point.total, 0) / Math.max(userGrowthData.length, 1)
  );

  const normalize = (value: string) => value.trim().toLowerCase();
  const matchesQuery = (query: string, fields: Array<string | number | undefined>) => {
    const q = normalize(query);
    if (!q) return true;
    return fields.some((field) => String(field ?? "").toLowerCase().includes(q));
  };
  const matchesExactFilter = (filter: string, value: string) => {
    if (!filter) return true;
    return value.toLowerCase() === filter.toLowerCase();
  };
  const matchesLooseFilter = (filter: string, value: string) => {
    if (!filter) return true;
    return value.toLowerCase().includes(filter.toLowerCase());
  };
  const getVerificationUserName = (v: Verification) => {
    if (v.name) return v.name;
    const id = String(v.userId ?? "");
    if (v.type === "homeowner_id") {
      return homeowners.find((h) => h.userId === id || h.id === id)?.name ?? "";
    }
    if (v.type === "tradesperson_license") {
      return tradesmen.find((t) => t.userId === id || t.id === id)?.name ?? "";
    }
    return "";
  };

  const statusFilter = showArchivedOnly ? "Archived" : (verificationFilters[0] ?? "");
  const baseVerifications = showArchivedOnly
    ? verifications.filter((v) => v.status === "archived")
    : verifications.filter((v) => v.status !== "archived");

  const filteredVerifications = baseVerifications.filter((v) => {
    const statusLabel = toTitle(v.status);
    const typeLabel = verificationTypeLabel(v.type);
    return (
      matchesQuery(searchVerification, [v.userId, v.id, statusLabel, typeLabel, getVerificationUserName(v)]) &&
      matchesExactFilter(statusFilter, statusLabel) &&
      matchesExactFilter(verificationFilters[1] ?? "", typeLabel)
    );
  });

  const filteredTradesmen = tradesmen.filter((t) => (
    matchesQuery(searchTradesmen, [t.name, t.email, t.license, t.category, t.status, t.id]) &&
    matchesLooseFilter(tradesmenFilters[0] ?? "", t.category) &&
    matchesExactFilter(tradesmenFilters[1] ?? "", t.status)
  ));

  const filteredHomeowners = homeowners.filter((h) => (
    matchesQuery(searchHomeowners, [h.name, h.email, h.idNumber, h.location, h.status, h.idStatus, h.id]) &&
    matchesLooseFilter(homeownerFilters[0] ?? "", h.location) &&
    matchesExactFilter(homeownerFilters[1] ?? "", h.status)
  ));

  const filteredDashboardVerifications = verifications.filter((v) => {
    const statusLabel = toTitle(v.status);
    const typeLabel = verificationTypeLabel(v.type);
    return v.status === "pending" && matchesQuery(searchDashboard, [v.userId, v.id, statusLabel, typeLabel, getVerificationUserName(v)]);
  });
  const filteredDashboardHomeowners = homeowners.filter((h) =>
    matchesQuery(searchDashboard, [h.name, h.email, h.idNumber, h.location, h.status, h.idStatus, h.id])
  );
  const recentDashboardHomeowners = [...filteredDashboardHomeowners].sort((a, b) => {
    const aTime = a.createdAt ? new Date(a.createdAt).getTime() : 0;
    const bTime = b.createdAt ? new Date(b.createdAt).getTime() : 0;
    return bTime - aTime;
  });

  const canSearchTopbar =
    activePage === "dashboard" ||
    activePage === "verification" ||
    activePage === "tradesmen" ||
    activePage === "homeowners";
  const topbarSearchValue = activePage === "dashboard"
    ? searchDashboard
    : activePage === "verification"
    ? searchVerification
    : activePage === "tradesmen"
      ? searchTradesmen
      : activePage === "homeowners"
        ? searchHomeowners
        : "";
  const setTopbarSearchValue = (value: string) => {
    if (activePage === "dashboard") setSearchDashboard(value);
    if (activePage === "verification") setSearchVerification(value);
    if (activePage === "tradesmen") setSearchTradesmen(value);
    if (activePage === "homeowners") setSearchHomeowners(value);
  };

  // Toast helper
  const showToast = (msg: string, type: ToastType = "success") => {
    setToast({ show: true, msg, type });
    setTimeout(() => setToast((t) => ({ ...t, show: false })), 3000);
  };

  const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8080";
  const withApiBase = (url?: string) => {
    if (!url) return "";
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    return `${apiBase}${url.startsWith("/") ? "" : "/"}${url}`;
  };

  useEffect(() => {
    const token = localStorage.getItem("admin_token");
    if (!token) {
      router.push("/login");
      return;
    }
    setAuthToken(token);
  }, [router]);

  useEffect(() => {
    if (!authToken) return;
    const fetchVerifications = async () => {
      try {
        const res = await fetch(`${apiBase}/api/verifications`, {
          headers: { Authorization: `Bearer ${authToken}` },
        });
        if (!res.ok) {
          if (res.status === 401 || res.status === 403) {
            localStorage.removeItem("admin_token");
            router.push("/login");
            return;
          }
          showToast("Failed to load verifications.", "error");
          return;
        }
        const data = await res.json();
        const list = Array.isArray(data)
          ? data
          : Array.isArray(data?.verifications)
            ? data.verifications
            : [];
        const mapped = list.map((v) => ({
          id: v.id ?? v.ID,
          userId: v.user_id ?? v.UserID,
          name:
            v.user_name ??
            v.UserName ??
            v.full_name ??
            v.FullName ??
            v.name ??
            v.Name ??
            "",
          type: v.type as Verification["type"],
          status: v.status as Verification["status"],
          documentUrl: withApiBase(v.document_url ?? v.DocumentURL ?? v.documentUrl ?? ""),
          createdAt: v.created_at ?? v.CreatedAt,
        })) as Verification[];
        setVerifications(mapped);
      } catch {
        showToast("Failed to load verifications.", "error");
      }
    };
    fetchVerifications();
  }, [authToken, apiBase]);

  const loadUsers = async () => {
    if (!authToken) return;
    try {
      const [tpRes, hoRes] = await Promise.all([
        fetch(`${apiBase}/api/admin/tradespeople`, {
          headers: { Authorization: `Bearer ${authToken}` },
        }),
        fetch(`${apiBase}/api/admin/homeowners`, {
          headers: { Authorization: `Bearer ${authToken}` },
        }),
      ]);

      if (!tpRes.ok || !hoRes.ok) {
        if (tpRes.status === 401 || tpRes.status === 403 || hoRes.status === 401 || hoRes.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }
        showToast("Failed to load users.", "error");
        return;
      }

      const [tpData, hoData] = await Promise.all([tpRes.json(), hoRes.json()]);
      const tpList = Array.isArray(tpData)
        ? tpData
        : Array.isArray(tpData?.tradespeople)
          ? tpData.tradespeople
          : [];
      const hoList = Array.isArray(hoData)
        ? hoData
        : Array.isArray(hoData?.homeowners)
          ? hoData.homeowners
          : [];

      const mappedTradesmen = tpList.map((t) => {
        const name =
          (t.full_name ??
            t.FullName ??
            [t.first_name ?? t.FirstName, t.last_name ?? t.LastName].filter(Boolean).join(" ")) ||
          "Unknown";
        const userId = String(t.user_id ?? t.UserID ?? t.userId ?? t.UserId ?? "");
        const statusRaw = String(
          t.status ?? t.Status ?? t.verification_status ?? t.VerificationStatus ?? "pending"
        ).toLowerCase();
        const status: Tradesman["status"] =
          statusRaw === "verified" || statusRaw === "approved"
            ? "Verified"
            : statusRaw === "suspended" || statusRaw === "rejected"
              ? "Suspended"
              : "Pending";
        const credentialUrl = withApiBase(
          t.credential_url ??
            t.CredentialUrl ??
            t.license_document_url ??
            t.LicenseDocumentUrl ??
            t.license_document ??
            t.LicenseDocument ??
            t.document_url ??
            t.DocumentUrl ??
            ""
        );
        const governmentIdUrl = withApiBase(
          t.government_id_document_url ??
            t.GovernmentIdDocumentUrl ??
            t.government_id_document ??
            t.GovernmentIdDocument ??
            ""
        );
        return {
          id: String(t.id ?? t.ID ?? ""),
          userId: userId || undefined,
          initials: initialsFromName(name),
          color: colorFromSeed(name),
          name,
          email: t.email ?? t.Email ?? t.user_email ?? t.UserEmail ?? "—",
          category: t.category ?? t.Category ?? t.trade_category ?? t.TradeCategory ?? "—",
          license: t.license ?? t.License ?? t.license_no ?? t.LicenseNo ?? "—",
          credentialUrl,
          governmentIdUrl,
          joined: formatDate(t.created_at ?? t.CreatedAt),
          createdAt: t.created_at ?? t.CreatedAt,
          jobs: t.jobs_count ?? t.JobsCount ?? 0,
          status,
        };
      });

      const mappedHomeowners = hoList.map((h) => {
        const name =
          (h.full_name ??
            h.FullName ??
            [h.first_name ?? h.FirstName, h.last_name ?? h.LastName].filter(Boolean).join(" ")) ||
          "Unknown";
        const userId = String(h.user_id ?? h.UserID ?? h.userId ?? h.UserId ?? "");
        const statusRaw = String(h.status ?? h.Status ?? "active").toLowerCase();
        const status: Homeowner["status"] =
          statusRaw === "inactive" ? "Inactive" : statusRaw === "pending" ? "Pending" : "Active";
        const idStatusRaw = String(h.id_status ?? h.IdStatus ?? h.idStatus ?? "pending").toLowerCase();
        const idStatus: Homeowner["idStatus"] =
          idStatusRaw === "approved"
            ? "Approved"
            : idStatusRaw === "rejected"
              ? "Rejected"
              : idStatusRaw === "archived"
                ? "Archived"
                : "Pending";
        const createdAt = h.created_at ?? h.CreatedAt;
        return {
          id: String(h.id ?? h.ID ?? ""),
          userId: userId || undefined,
          initials: initialsFromName(name),
          color: colorFromSeed(name),
          name,
          email: h.email ?? h.Email ?? h.user_email ?? h.UserEmail ?? "—",
          location: h.barangay ?? h.Barangay ?? h.location ?? "—",
          registered: formatDate(createdAt),
          createdAt,
          jobs: h.jobs_count ?? h.JobsCount ?? 0,
          status,
          idNumber: h.id_number ?? h.IdNumber ?? "—",
          idStatus,
          idImageUrl: withApiBase(h.id_document_url ?? h.IdDocumentUrl ?? h.idImageUrl ?? ""),
        };
      });

      setTradesmen(mappedTradesmen);
      setHomeowners(mappedHomeowners);
    } catch {
      showToast("Failed to load users.", "error");
    }
  };

  const loadActivity = async () => {
    if (!authToken) return;
    try {
      const res = await fetch(`${apiBase}/api/admin/activity?limit=6`, {
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }
        showToast("Failed to load activity.", "error");
        return;
      }
      const data = await res.json();
      const list = Array.isArray(data)
        ? data
        : Array.isArray(data?.activity)
          ? data.activity
          : [];
      const mapped = list.map((a) => {
        const createdAt = a.created_at ?? a.CreatedAt;
        const type = String(a.type ?? a.Type ?? "");
        return {
          id: String(a.id ?? a.ID ?? ""),
          title: String(a.title ?? a.Title ?? ""),
          sub: String(a.sub ?? a.Sub ?? ""),
          dot: activityDot(type),
          time: formatTimeAgo(createdAt),
        } as ActivityEntry;
      });
      setActivity(mapped);
    } catch {
      showToast("Failed to load activity.", "error");
    }
  };

  useEffect(() => {
    loadUsers();
    loadActivity();
  }, [authToken, apiBase, router]);

  useEffect(() => {
    if (!authToken) return;
    if (!autoRefresh) return;
    const interval = setInterval(() => {
      loadUsers();
    }, 30000);
    return () => clearInterval(interval);
  }, [authToken, apiBase, autoRefresh]);

  // Approve / Reject
  const rejectTradesman = (id: string, name: string) => {
    setTradesmen((prev) => prev.filter((t) => t.id !== id));
    showToast(`${name} rejected`, "error");
  };
  const revokeTradesman = async (id: string, name: string) => {
    if (!authToken) {
      showToast("Please sign in again.", "error");
      return;
    }
    try {
      const res = await fetch(`${apiBase}/api/admin/tradespeople/${id}/revoke`, {
        method: "PATCH",
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }
        showToast("Failed to re-verify tradesman.", "error");
        return;
      }
      setTradesmen((prev) => prev.map((t) => (t.id === id ? { ...t, status: "Pending" } : t)));
      showToast(`${name} set to re-verify`, "info");
      loadUsers();
      loadActivity();
    } catch {
      showToast("Failed to re-verify tradesman.", "error");
    }
  };
  const restoreTradesman = async (id: string, name: string) => {
    if (!authToken) {
      showToast("Please sign in again.", "error");
      return;
    }
    try {
      const res = await fetch(`${apiBase}/api/admin/tradespeople/${id}/restore`, {
        method: "PATCH",
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }
        showToast("Failed to restore tradesman.", "error");
        return;
      }
      setTradesmen((prev) => prev.map((t) => (t.id === id ? { ...t, status: "Verified" } : t)));
      showToast(`${name} restored`, "success");
      loadUsers();
      loadActivity();
    } catch {
      showToast("Failed to restore tradesman.", "error");
    }
  };
  const revokeHomeowner = async (id: string, name: string) => {
    if (!authToken) {
      showToast("Please sign in again.", "error");
      return;
    }
    try {
      const res = await fetch(`${apiBase}/api/admin/homeowners/${id}/revoke`, {
        method: "PATCH",
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }
        showToast("Failed to revoke homeowner.", "error");
        return;
      }
      setHomeowners((prev) => prev.map((h) => (h.id === id ? { ...h, status: "Inactive" } : h)));
      showToast(`${name} revoked`, "error");
      loadUsers();
      loadActivity();
    } catch {
      showToast("Failed to revoke homeowner.", "error");
    }
  };
  const restoreHomeowner = async (id: string, name: string) => {
    if (!authToken) {
      showToast("Please sign in again.", "error");
      return;
    }
    try {
      const res = await fetch(`${apiBase}/api/admin/homeowners/${id}/restore`, {
        method: "PATCH",
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }
        showToast("Failed to restore homeowner.", "error");
        return;
      }
      setHomeowners((prev) => prev.map((h) => (h.id === id ? { ...h, status: "Active" } : h)));
      showToast(`${name} restored`, "success");
      loadUsers();
      loadActivity();
    } catch {
      showToast("Failed to restore homeowner.", "error");
    }
  };

  const reviewVerification = async (id: number, status: "approved" | "rejected") => {
    if (!authToken) return;
    try {
      const res = await fetch(`${apiBase}/api/verifications/review`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${authToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ verification_id: id, status }),
      });
      if (!res.ok) {
        showToast("Failed to update verification.", "error");
        return;
      }
      const reviewed = verifications.find((v) => v.id === id);
      setVerifications((prev) => prev.filter((v) => v.id !== id));
      if (reviewed) {
        const targetId = String(reviewed.userId ?? "");
        if (reviewed.type === "tradesperson_license" && status === "approved") {
          setTradesmen((prev) =>
            prev.map((t) =>
              t.userId === targetId || t.id === targetId ? { ...t, status: "Verified" } : t
            )
          );
        }
        if (reviewed.type === "homeowner_id") {
          const nextStatus = status === "approved" ? "Approved" : "Rejected";
          setHomeowners((prev) =>
            prev.map((h) =>
              h.userId === targetId || h.id === targetId
                ? { ...h, idStatus: nextStatus, status: status === "approved" ? "Active" : h.status }
                : h
            )
          );
        }
      }
      loadUsers();
      loadActivity();
      showToast(`Verification ${status}`, status === "approved" ? "success" : "error");
    } catch {
      showToast("Failed to update verification.", "error");
    }
  };
  const archiveVerification = async (id: number) => {
    if (!authToken) {
      showToast("Please sign in again.", "error");
      return;
    }
    try {
      const res = await fetch(`${apiBase}/api/verifications/${id}`, {
        method: "DELETE",
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }
        let message = "Failed to archive verification.";
        try {
          const data = await res.json();
          message = String(data?.message ?? message);
        } catch {}
        showToast(message, "error");
        return;
      }
      setVerifications((prev) =>
        prev.map((v) => (v.id === id ? { ...v, status: "archived" } : v))
      );
      loadActivity();
      showToast("Verification archived", "success");
    } catch {
      showToast("Failed to archive verification.", "error");
    }
  };
  const restoreVerification = async (id: number) => {
    if (!authToken) {
      showToast("Please sign in again.", "error");
      return;
    }
    try {
      const res = await fetch(`${apiBase}/api/verifications/${id}`, {
        method: "PATCH",
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }
        let message = "Failed to restore verification.";
        try {
          const data = await res.json();
          message = String(data?.message ?? message);
        } catch {}
        showToast(message, "error");
        return;
      }

      const restored = verifications.find((v) => v.id === id);
      setVerifications((prev) =>
        prev.map((v) => (v.id === id ? { ...v, status: "approved" } : v))
      );

      if (restored) {
        const targetId = String(restored.userId ?? "");
        if (restored.type === "tradesperson_license") {
          setTradesmen((prev) =>
            prev.map((t) =>
              t.userId === targetId || t.id === targetId ? { ...t, status: "Verified" } : t
            )
          );
        }
        if (restored.type === "homeowner_id") {
          setHomeowners((prev) =>
            prev.map((h) =>
              h.userId === targetId || h.id === targetId
                ? { ...h, idStatus: "Approved", status: "Active" }
                : h
            )
          );
        }
      }

      loadUsers();
      loadActivity();
      showToast("Verification restored to approved", "success");
    } catch {
      showToast("Failed to restore verification. Check if the backend was restarted.", "error");
    }
  };

  const openConfirm = (config: { title: string; message: string; confirmLabel: string; onConfirm: () => void }) => {
    setConfirm({ open: true, ...config });
  };
  const closeConfirm = () => setConfirm((prev) => ({ ...prev, open: false }));
  const handleConfirm = () => {
    confirm.onConfirm();
    closeConfirm();
  };

  // Modal helpers
  const openHOModal = (h: Homeowner) => {
    setModal({
      open: true, title: h.name,
      rows: [
        { label: "Full Name", value: h.name },
        { label: "Email",     value: h.email },
        { label: "Location",  value: h.location },
        { label: "Registered",value: h.registered },
        { label: "Jobs Posted",value: String(h.jobs) },
        { label: "Account Status", value: h.status, highlight: h.status === "Active" },
        { label: "ID Number", value: h.idNumber },
        { label: "ID Status", value: h.idStatus, highlight: h.idStatus === "Approved" },
        { label: "ID Image", value: h.idImageUrl ? "Uploaded" : "Not uploaded", highlight: Boolean(h.idImageUrl) },
      ],
      actions: (
        <Btn
          variant="view"
          onClick={() => openDocumentModal(`${h.name} · Homeowner ID`, h.idImageUrl)}
          disabled={!h.idImageUrl}
        >
          {icons.license} View Uploaded ID
        </Btn>
      ),
    });
  };
  const openDocumentModal = async (title: string, url: string) => {
    if (!url) {
      showToast(`No document image for ${title}.`, "error");
      return;
    }
    if (!authToken) {
      showToast("Please sign in again to view documents.", "error");
      return;
    }
    try {
      const res = await fetch(url, { headers: { Authorization: `Bearer ${authToken}` } });
      if (!res.ok) {
        showToast("Unable to load document.", "error");
        return;
      }
      const blob = await res.blob();
      const objectUrl = URL.createObjectURL(blob);
      setIdModal((m) => {
        if (m.imageUrl.startsWith("blob:")) {
          URL.revokeObjectURL(m.imageUrl);
        }
        return { open: true, title, imageUrl: objectUrl, contentType: blob.type };
      });
    } catch {
      showToast("Unable to load document.", "error");
    }
  };
  const closeIdModal = () => {
    setIdModal((m) => {
      if (m.imageUrl.startsWith("blob:")) {
        URL.revokeObjectURL(m.imageUrl);
      }
      return { ...m, open: false, imageUrl: "", contentType: "" };
    });
  };
  const openTMModal = (t: Tradesman) => {
    setModal({
      open: true, title: t.name,
      rows: [
        { label: "Full Name",  value: t.name },
        { label: "Email",      value: t.email },
        { label: "Category",   value: t.category },
        { label: "License No.",value: t.license },
        { label: "Joined",     value: t.joined },
        { label: "Jobs Done",  value: String(t.jobs) },
        { label: "Status",     value: t.status, highlight: t.status === "Verified" },
        { label: "Credentials", value: (t.credentialUrl || t.governmentIdUrl) ? "Uploaded" : "Not uploaded", highlight: Boolean(t.credentialUrl || t.governmentIdUrl) },
      ],
      actions: (
        <>
          <Btn
            variant="view"
            onClick={() => openDocumentModal(`${t.name} · Government ID`, t.governmentIdUrl ?? "")}
            disabled={!t.governmentIdUrl}
          >
            {icons.license} View Gov ID
          </Btn>
          <Btn
            variant="view"
            onClick={() => openDocumentModal(`${t.name} · License/Cert`, t.credentialUrl)}
            disabled={!t.credentialUrl}
          >
            {icons.license} View License/Cert
          </Btn>
        </>
      ),
    });
  };

  const handleLogout = () => {
    localStorage.removeItem("admin_token");
    router.push("/login");
  };

  // page titles
  const pageTitles: Record<Page, string> = {
    dashboard:    "Dashboard",
    verification: "Verifications",
    tradesmen:    "Tradesmen",
    homeowners:   "Homeowners",
    profile:      "Profile",
    settings:     "Settings",
  };

  // ── PAGES ──────────────────────────────────────────────────────

  const PageDashboard = () => (
    <div style={{ animation: "fadeUp .35s ease both" }}>
      {/* Stats */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 16, marginBottom: 28 }}>
        <StatCard iconBg="var(--info-bg)" iconColor="var(--info-text)" num={homeowners.length} label="Total Homeowners" trend="+12%" trendType="up"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>}
        />
        <StatCard iconBg="var(--accent-soft)" iconColor="var(--accent)" num={tradesmen.length} label="Total Tradesmen" trend="+8%" trendType="up"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>}
        />
        <StatCard iconBg="var(--warning-bg)" iconColor="var(--warning-text)" num={pendingCount} label="Pending Verifications" trend="Needs review" trendType="warn"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>}
        />
        <StatCard iconBg="var(--success-bg)" iconColor="var(--success-text)" num={verifiedCount} label="Verified Tradesmen" trend={`${Math.round((verifiedCount/Math.max(tradesmen.length,1))*100)}% rate`} trendType="up"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>}
        />
      </div>

      {/* Two-column: verification queue + activity */}
      <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: 20, marginBottom: 28 }}>
        {/* Verification queue */}
        <Card>
          <CardHead
            title="Verification Queue"
            subtitle="Latest ID/license submissions"
            right={
              <>
                <Pill color="orange">{pendingCount} Pending</Pill>
                <Btn variant="neon" onClick={() => setActivePage("verification")}>View All</Btn>
              </>
            }
          />
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill,minmax(280px,1fr))", gap: 16, padding: "20px 24px" }}>
            {filteredDashboardVerifications.slice(0, 4).map((v) => (
              <VerificationCard
                key={v.id}
                v={v}
                name={getVerificationUserName(v)}
                onApprove={() => reviewVerification(v.id, "approved")}
                onReject={() => reviewVerification(v.id, "rejected")}
                onView={() => openDocumentModal(`User #${v.userId}`, v.documentUrl)}
                onArchive={() => archiveVerification(v.id)}
              />
            ))}
            {pendingCount === 0 && (
              <div style={{ gridColumn: "1/-1", textAlign: "center", padding: "40px 20px", color: "var(--muted)" }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>All caught up! No pending verifications.</div>
              </div>
            )}
            {pendingCount > 0 && filteredDashboardVerifications.length === 0 && (
              <div style={{ gridColumn: "1/-1", textAlign: "center", padding: "40px 20px", color: "var(--muted)" }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>No matching verifications.</div>
              </div>
            )}
          </div>
        </Card>

        {/* Recent activity */}
        <Card>
          <CardHead title="Recent Activity" subtitle="Latest events" />
          {activity.map((a, i) => (
            <ActivityItem
              key={a.id}
              dot={a.dot}
              title={a.title}
              sub={a.sub}
              time={a.time}
              isLast={i === activity.length - 1}
            />
          ))}
        </Card>
      </div>

      <UserGrowthChart
        homeownerCount={homeowners.length}
        tradesmanCount={tradesmen.length}
        totalUsers={totalUsers}
        activeUsers={activeUsers}
        latestMonthUsers={latestMonthUsers}
        averageMonthlyUsers={averageMonthlyUsers}
      />
    </div>
  );

  const PageVerification = () => (
    <div style={{ animation: "fadeUp .35s ease both" }}>
      <Card>
        <CardHead title="Verification Requests" subtitle="Review and approve ID/license submissions"
          right={
            <>
              <Pill color="orange">{pendingCount} Pending</Pill>
              <button
                onClick={() => setShowArchivedOnly((prev) => !prev)}
                style={{
                  padding: "4px 12px",
                  borderRadius: 100,
                  fontSize: 12,
                  fontWeight: 700,
                  border: "1px solid var(--border)",
                  background: showArchivedOnly ? "var(--info-solid)" : "var(--info-bg)",
                  color: showArchivedOnly ? "white" : "var(--info-text)",
                  cursor: "pointer",
                  transition: "all .2s",
                  fontFamily: "inherit",
                }}
              >
                {showArchivedOnly ? "Show All" : `Archived (${archivedCount})`}
              </button>
            </>
          }
        />
        <Toolbar
          placeholder="Search by user ID or type…"
          filters={[["All Status","Pending","Approved","Rejected"],["All Types","Homeowner ID","Tradesperson License"]]}
          searchValue={searchVerification}
          onSearchChange={setSearchVerification}
          filterValues={verificationFilters}
          onFilterChange={(index, value) => setVerificationFilters((prev) => {
            const next = [...prev];
            next[index] = value;
            return next;
          })}
        />
        <Table>
          <thead><tr><Th>User</Th><Th>Type</Th><Th>Submitted</Th><Th>Status</Th><Th>Actions</Th></tr></thead>
          <tbody>
            {filteredVerifications.map((v) => {
              const userName = getVerificationUserName(v);
              return (
                <tr key={v.id}
                  onMouseEnter={(e) => (e.currentTarget.style.background = "var(--row-hover)")}
                  onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                  style={{ transition: "background .15s" }}>
                  <Td>
                    <div style={{ fontWeight: 700, fontSize: 13 }}>{userName || `User #${v.userId}`}</div>
                    {userName && <div style={{ fontSize: 12, color: "var(--muted)" }}>User #{v.userId}</div>}
                  </Td>
                  <Td>{verificationTypeLabel(v.type)}</Td>
                  <Td>{v.createdAt ? new Date(v.createdAt).toLocaleDateString() : "—"}</Td>
                  <Td><Badge status={toTitle(v.status)} /></Td>
                  <Td>
                    <div style={{ display: "flex", gap: 8 }}>
                      {v.status === "pending" ? (
                        <>
                          <Btn variant="approve" onClick={() => reviewVerification(v.id, "approved")}>{icons.check} Approve</Btn>
                          <Btn variant="reject"  onClick={() => reviewVerification(v.id, "rejected")}>{icons.x} Reject</Btn>
                        </>
                      ) : (
                        <>
                          <Btn disabled>{icons.check} {toTitle(v.status)}</Btn>
                          {v.type === "tradesperson_license" && (
                            <Btn variant="view" onClick={() => openDocumentModal(`User #${v.userId}`, v.documentUrl)}>{icons.license} View ID/Cert</Btn>
                          )}
                        </>
                      )}
                      {v.status === "pending" && v.type === "tradesperson_license" && (
                        <Btn variant="view" onClick={() => openDocumentModal(`User #${v.userId}`, v.documentUrl)}>{icons.license} View ID/Cert</Btn>
                      )}
                      {v.status === "archived" ? (
                        <Btn variant="approve" onClick={() => restoreVerification(v.id)}>{icons.check} Restore</Btn>
                      ) : (
                        <Btn variant="reject" onClick={() => archiveVerification(v.id)}>{icons.x} Archive</Btn>
                      )}
                    </div>
                  </Td>
                </tr>
              );
            })}
          </tbody>
        </Table>
      </Card>
    </div>
  );

  const PageTradesmen = () => (
    <div style={{ animation: "fadeUp .35s ease both" }}>
      <Card>
        <CardHead title="All Tradesmen" subtitle={`${tradesmen.length} registered tradesmen`} right={<Pill color="navy">{tradesmen.length} Total</Pill>} />
        <Toolbar
          placeholder="Search tradesmen…"
          filters={[["All Categories","Electrician","Plumbing","HVAC","Carpentry","Painter","Appliance Repair"],["All Status","Verified","Pending"]]}
          searchValue={searchTradesmen}
          onSearchChange={setSearchTradesmen}
          filterValues={tradesmenFilters}
          onFilterChange={(index, value) => setTradesmenFilters((prev) => {
            const next = [...prev];
            next[index] = value;
            return next;
          })}
        />
        <Table>
          <thead><tr><Th>Tradesman</Th><Th>Category</Th><Th>License</Th><Th>Joined</Th><Th>Jobs Done</Th><Th>Status</Th><Th>Actions</Th></tr></thead>
          <tbody>
            {filteredTradesmen.map((t) => (
              <tr key={t.id}
                onMouseEnter={(e) => (e.currentTarget.style.background = "var(--row-hover)")}
                onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                style={{ transition: "background .15s" }}>
                <Td>
                  <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <Avatar initials={t.initials} color={t.color} size={38} />
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 13 }}>{t.name}</div>
                      <div style={{ fontSize: 12, color: "var(--muted)" }}>{t.email}</div>
                    </div>
                  </div>
                </Td>
                <Td>{t.category}</Td>
                <Td><span style={{ fontFamily: "monospace", fontSize: 12 }}>{t.license}</span></Td>
                <Td>{t.joined}</Td>
                <Td>{t.jobs}</Td>
                <Td><Badge status={t.status} /></Td>
                <Td>
                  <div style={{ display: "flex", gap: 8 }}>
                    <Btn variant="view" onClick={() => openTMModal(t)}>View Details</Btn>
                    {t.status === "Verified" ? (
                      <Btn
                        variant="reject"
                        onClick={() =>
                          openConfirm({
                            title: `Revoke ${t.name}?`,
                            message: "This will reset their verification status to pending.",
                            confirmLabel: "Revoke",
                            onConfirm: () => revokeTradesman(t.id, t.name),
                          })
                        }
                      >
                        {icons.x} Revoke
                      </Btn>
                    ) : (
                      <Btn variant="approve" onClick={() => restoreTradesman(t.id, t.name)}>{icons.check} Restore</Btn>
                    )}
                  </div>
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      </Card>
    </div>
  );

  const PageHomeowners = () => (
    <div style={{ animation: "fadeUp .35s ease both" }}>
      <Card>
        <CardHead
          title="All Homeowners"
          subtitle={`${homeowners.length} registered homeowners`}
          right={
            <>
              <Pill color="orange">{pendingHomeownerIds} ID Pending</Pill>
              <Pill color="navy">{homeowners.length} Total</Pill>
            </>
          }
        />
        <Toolbar
          placeholder="Search homeowners…"
          filters={[["All Locations",'Balayhangin','Bangyas','Dayap','Hanggan','Imok','Kanluran (Poblacion)','Lamot 1','Lamot 2','Limao','Mabacan','Masiit','Paliparan','Perez','Prinza','San Isidro','Silangan (Poblacion)','Santo Tomas'],["All Status","Pending","Active","Inactive"]]}
              searchValue={searchHomeowners}
          onSearchChange={setSearchHomeowners}
          filterValues={homeownerFilters}
          onFilterChange={(index, value) => setHomeownerFilters((prev) => {
            const next = [...prev];
            next[index] = value;
            return next;
          })}
        />
        <Table>
          <thead><tr><Th>Homeowner</Th><Th>Location</Th><Th>Registered</Th><Th>ID No.</Th><Th>ID Status</Th><Th>Jobs Posted</Th><Th>Status</Th><Th>Actions</Th></tr></thead>
          <tbody>
            {filteredHomeowners.map((h) => (
              <tr key={h.id}
                onMouseEnter={(e) => (e.currentTarget.style.background = "var(--row-hover)")}
                onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                style={{ transition: "background .15s" }}>
                <Td>
                  <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <Avatar initials={h.initials} color={h.color} size={38} />
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 13 }}>{h.name}</div>
                      <div style={{ fontSize: 12, color: "var(--muted)" }}>{h.email}</div>
                    </div>
                  </div>
                </Td>
                <Td>{h.location}</Td>
                <Td>{h.registered}</Td>
                <Td><span style={{ fontFamily: "monospace", fontSize: 12 }}>{h.idNumber}</span></Td>
                <Td><Badge status={h.idStatus} /></Td>
                <Td>{h.jobs}</Td>
                <Td><Badge status={h.status} /></Td>
                <Td>
                  <div style={{ display: "flex", gap: 8 }}>
                    <Btn variant="view" onClick={() => openHOModal(h)}>View Details</Btn>
                    {h.status === "Active" ? (
                      <Btn
                        variant="reject"
                        onClick={() =>
                          openConfirm({
                            title: `Revoke ${h.name}?`,
                            message: "This will deactivate the homeowner account.",
                            confirmLabel: "Revoke",
                            onConfirm: () => revokeHomeowner(h.id, h.name),
                          })
                        }
                      >
                        {icons.x} Revoke
                      </Btn>
                    ) : (
                      <Btn variant="approve" onClick={() => restoreHomeowner(h.id, h.name)}>{icons.check} Restore</Btn>
                    )}
                  </div>
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      </Card>
    </div>
  );

  const PageSettings = () => (
    <div style={{ animation: "fadeUp .35s ease both" }}>
      <Card>
        <CardHead title="Settings" subtitle="Personalize your admin experience" />
        <div style={{ padding: 24 }}>
          <div style={{ fontSize: 12, fontWeight: 800, letterSpacing: "0.8px", textTransform: "uppercase", color: "var(--muted)", marginBottom: 10 }}>
            Appearance
          </div>
          <Toggle
            checked={isDark}
            onChange={setIsDark}
            label="Dark mode"
            description="Switch the admin portal to a darker theme."
          />
          <div style={{ fontSize: 12, fontWeight: 800, letterSpacing: "0.8px", textTransform: "uppercase", color: "var(--muted)", margin: "18px 0 10px" }}>
            Data
          </div>
          <Toggle
            checked={autoRefresh}
            onChange={setAutoRefresh}
            label="Auto-refresh dashboard"
            description="Refresh recent lists every 30 seconds."
          />
        </div>
      </Card>
    </div>
  );

  const PageProfile = () => (
    <div style={{ display: "grid", gridTemplateColumns: "300px 1fr", gap: 24, animation: "fadeUp .35s ease both" }}>
      {/* Left: profile card */}
      <div>
        <Card style={{ marginBottom: 16 }}>
          {/* Hero */}
          <div style={{ background: "var(--sidebar-accent)", padding: "32px 24px", display: "flex", flexDirection: "column", alignItems: "center", position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", width: 200, height: 200, borderRadius: "50%", background: "rgba(255,255,255,0.04)", top: -70, right: -60 }} />
            <div style={{ position: "absolute", width: 120, height: 120, borderRadius: "50%", background: "rgba(232,119,34,0.12)", bottom: -40, left: 10 }} />
            <div style={{ width: 76, height: 76, background: "var(--accent)", borderRadius: 22, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 28, fontWeight: 800, color: "white", marginBottom: 14, border: "3px solid rgba(255,255,255,0.2)", position: "relative", zIndex: 1 }}>AD</div>
            <div style={{ fontSize: 20, fontWeight: 800, color: "white", position: "relative", zIndex: 1 }}>Admin User</div>
            <div style={{ fontSize: 13, color: "rgba(255,255,255,0.5)", marginTop: 4, position: "relative", zIndex: 1 }}>Super Administrator</div>
          </div>
          {/* Items */}
          {[
            { icon: icons.bell, label: "Email", sub: "admin@fixit.com" },
            { icon: icons.shield, label: "Password", sub: "Last changed 30 days ago" },
            { icon: icons.shield, label: "Security", sub: "2FA enabled" },
          ].map((item, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "15px 20px", borderBottom: i < 2 ? "1px solid var(--border)" : "none", cursor: "pointer", transition: "background .15s" }}
              onMouseEnter={(e) => (e.currentTarget.style.background = "var(--surface-2)")}
              onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}>
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <div style={{ width: 36, height: 36, borderRadius: 9, background: "var(--accent-soft)", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--accent)" }}>{item.icon}</div>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 700, color: "var(--text)" }}>{item.label}</div>
                  <div style={{ fontSize: 11, color: "var(--muted)", marginTop: 1 }}>{item.sub}</div>
                </div>
              </div>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 18 15 12 9 6"/></svg>
            </div>
          ))}
        </Card>
      </div>

      {/* Right: details + activity */}
      <div>
        <Card style={{ marginBottom: 20 }}>
          <CardHead title="Account Details" />
          <div style={{ padding: 24, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
            {[["Full Name","Admin User"],["Role","Super Administrator"],["Email","admin@fixit.com"],["Last Login","Today, 5:29 AM"]].map(([l,v]) => (
              <div key={l}>
                <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.8px", textTransform: "uppercase", color: "var(--muted)", marginBottom: 6 }}>{l}</div>
                <div style={{ fontSize: 14, fontWeight: 700, color: "var(--text)" }}>{v}</div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );

  // ── RENDER ─────────────────────────────────────────────────────
  return (
    <div style={{ ...themeVars, display: "flex", minHeight: "100vh", fontFamily: "'Plus Jakarta Sans', sans-serif", background: "var(--bg)", color: "var(--text)" }}>

      {/* SIDEBAR */}
      <nav style={{ width: 260, flexShrink: 0, background: "var(--sidebar)", display: "flex", flexDirection: "column", position: "fixed", top: 0, left: 0, bottom: 0, zIndex: 50, boxShadow: "2px 0 20px rgba(15,25,35,.15)", overflowY: "auto" }}>
        {/* Logo */}
        <div style={{ padding: "22px 20px 18px", borderBottom: "1px solid rgba(255,255,255,.08)", display: "flex", alignItems: "center", gap: 12 }}>
          <SidebarShield />
          <div>
            <div style={{ fontSize: 20, fontWeight: 800, color: "white", letterSpacing: -0.3 }}>Fix It</div>
            <div style={{ fontSize: 11, color: "rgba(255,255,255,.4)", fontWeight: 500, letterSpacing: 0.5 }}>Admin Portal</div>
          </div>
        </div>

        {/* Admin tag */}
        <div style={{ margin: "14px 14px 4px", padding: "10px 14px", background: "var(--accent-soft)", border: "1px solid rgba(232,119,34,.25)", borderRadius: 10, display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 36, height: 36, borderRadius: 9, background: "var(--accent)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 800, color: "white", flexShrink: 0 }}>AD</div>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700, color: "white" }}>Admin User</div>
            <div style={{ fontSize: 11, color: "rgba(255,255,255,.45)", marginTop: 1 }}>Super Administrator</div>
          </div>
        </div>

        {/* Nav */}
        <div style={{ flex: 1, padding: "4px 12px" }}>
          {[
            { label: "Main" },
            { icon: icons.grid,     label: "Dashboard",     page: "dashboard" as Page },
            { icon: icons.shield,   label: "Verifications", page: "verification" as Page, badge: pendingCount },
            { label: "Users" },
            { icon: icons.wrench,   label: "Tradesmen",     page: "tradesmen" as Page },
            { icon: icons.home,     label: "Homeowners",    page: "homeowners" as Page },
            { label: "System" },
            { icon: icons.user,     label: "Profile",       page: "profile" as Page },
            { icon: icons.settings, label: "Settings",      page: "settings" as Page },
          ].map((item, i) =>
            !item.icon ? (
              <div key={i} style={{ fontSize: 10, fontWeight: 700, letterSpacing: "1.5px", textTransform: "uppercase", color: "rgba(255,255,255,.3)", padding: "14px 8px 8px" }}>{item.label}</div>
            ) : (
              <NavItem
                key={i}
                icon={item.icon}
                label={item.label}
                active={item.page === activePage}
                badge={item.badge}
                onClick={() => item.page ? setActivePage(item.page) : showToast(`${item.label} opened`, "info")}
              />
            )
          )}
        </div>

        {/* Sign out */}
        <div style={{ padding: "12px 16px 24px", borderTop: "1px solid rgba(255,255,255,.08)" }}>
          <button onClick={handleLogout}
            style={{ display: "flex", alignItems: "center", gap: 10, padding: "11px 12px", borderRadius: 10, background: "var(--danger-bg)", border: "1px solid var(--danger-border)", cursor: "pointer", width: "100%", fontFamily: "inherit", transition: "background .2s", color: "var(--danger-text)" }}
            onMouseEnter={(e) => { e.currentTarget.style.background = "var(--danger-solid)"; e.currentTarget.style.color = "white"; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = "var(--danger-bg)"; e.currentTarget.style.color = "var(--danger-text)"; }}>
            <span style={{ display: "flex" }}>{icons.logout}</span>
            <span style={{ fontSize: 13, fontWeight: 700 }}>Sign Out</span>
          </button>
        </div>
      </nav>

      {/* MAIN */}
      <div style={{ marginLeft: 260, flex: 1, display: "flex", flexDirection: "column", minHeight: "100vh" }}>
        {/* Topbar */}
        <div style={{ background: "var(--surface)", height: 64, borderBottom: "1px solid var(--border)", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 32px", position: "sticky", top: 0, zIndex: 40, boxShadow: "var(--shadow)" }}>
          <div>
            <div style={{ fontSize: 18, fontWeight: 800, color: "var(--text)", letterSpacing: -0.3 }}>{pageTitles[activePage]}</div>
            <div style={{ fontSize: 12, color: "var(--muted)", fontWeight: 500, marginTop: 1 }}>Fix It Marketplace › Admin Portal › {pageTitles[activePage]}</div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            {/* Search */}
            <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "9px 14px", background: "var(--surface-2)", border: "1.5px solid var(--border)", borderRadius: 8, width: 220, color: "var(--muted)", fontSize: 13, cursor: canSearchTopbar ? "text" : "not-allowed", opacity: canSearchTopbar ? 1 : 0.6 }}>
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <input
                type="text"
                placeholder="Search anything…"
                value={topbarSearchValue}
                onChange={(e) => setTopbarSearchValue(e.target.value)}
                disabled={!canSearchTopbar}
                style={{ border: "none", outline: "none", background: "transparent", fontFamily: "inherit", fontSize: 13, color: "var(--text)", width: "100%" }}
              />
            </div>
            {/* Bell */}
            <div style={{ position: "relative" }}>
              <button
                ref={bellButtonRef}
                onClick={() => setBellOpen((prev) => !prev)}
                aria-haspopup="true"
                aria-expanded={bellOpen}
                style={{ width: 38, height: 38, borderRadius: 9, border: "1.5px solid var(--border)", background: "var(--surface)", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", position: "relative", transition: "all .2s" }}
                onMouseEnter={(e) => { e.currentTarget.style.borderColor = "var(--accent)"; e.currentTarget.style.background = "var(--accent-soft)"; }}
                onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border)"; e.currentTarget.style.background = "var(--surface)"; }}>
                <span style={{ color: "var(--muted)" }}>{icons.bell}</span>
                {notificationCount > 0 && (
                  <span style={{ position: "absolute", top: 6, right: 6, minWidth: 16, height: 16, padding: "0 4px", background: "var(--accent)", borderRadius: 100, border: "1.5px solid white", color: "white", fontSize: 9, fontWeight: 800, display: "flex", alignItems: "center", justifyContent: "center" }}>
                    {notificationCount > 9 ? "9+" : notificationCount}
                  </span>
                )}
              </button>
              {bellOpen && (
                <div
                  ref={bellPanelRef}
                  style={{
                    position: "absolute",
                    top: 46,
                    right: 0,
                    width: 320,
                    background: "var(--surface)",
                    border: "1.5px solid var(--border)",
                    borderRadius: 12,
                    boxShadow: "var(--shadow)",
                    zIndex: 60,
                    overflow: "hidden",
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 14px", borderBottom: "1px solid var(--border)" }}>
                    <div style={{ fontSize: 13, fontWeight: 800, color: "var(--text)" }}>Notifications</div>
                    {notificationCount > 0 && (
                      <span style={{ fontSize: 11, fontWeight: 700, color: "var(--muted)" }}>{notificationCount} new</span>
                    )}
                  </div>
                  <div style={{ maxHeight: 280, overflowY: "auto" }}>
                    {activity.length > 0 ? (
                      activity.map((a, i) => (
                        <NotificationItem
                          key={a.id}
                          dot={a.dot}
                          title={a.title}
                          sub={a.sub}
                          time={a.time}
                          isLast={i === activity.length - 1}
                        />
                      ))
                    ) : (
                      <div style={{ padding: "16px 14px", fontSize: 12, color: "var(--muted)" }}>No notifications yet.</div>
                    )}
                  </div>
                  <button
                    onClick={() => { setActivePage("dashboard"); setBellOpen(false); }}
                    style={{ width: "100%", padding: "10px 14px", borderTop: "1px solid var(--border)", border: "none", background: "var(--surface-2)", fontSize: 12, fontWeight: 700, color: "var(--text)", cursor: "pointer" }}
                    onMouseEnter={(e) => { e.currentTarget.style.background = "var(--accent-soft)"; }}
                    onMouseLeave={(e) => { e.currentTarget.style.background = "var(--surface-2)"; }}
                  >
                    View activity
                  </button>
                </div>
              )}
            </div>
            {/* Avatar */}
            <div onClick={() => setActivePage("profile")}
              style={{ width: 38, height: 38, borderRadius: 9, background: "var(--accent)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 800, color: "white", cursor: "pointer" }}>
              AD
            </div>
          </div>
        </div>

        {/* Page content */}
        <div style={{ padding: "28px 32px", flex: 1 }}>
          {activePage === "dashboard"    && <PageDashboard />}
          {activePage === "verification" && <PageVerification />}
          {activePage === "tradesmen"    && <PageTradesmen />}
          {activePage === "homeowners"   && <PageHomeowners />}
          {activePage === "profile"      && <PageProfile />}
          {activePage === "settings"     && <PageSettings />}
        </div>
      </div>

      {/* Toast */}
      <Toast msg={toast.msg} type={toast.type} show={toast.show} />

      {/* Modal */}
      <Modal open={modal.open} onClose={() => setModal((m) => ({ ...m, open: false }))} title={modal.title} rows={modal.rows} actions={modal.actions} />
      <ConfirmModal
        open={confirm.open}
        title={confirm.title}
        message={confirm.message}
        confirmLabel={confirm.confirmLabel}
        onConfirm={handleConfirm}
        onClose={closeConfirm}
      />
      <ImageModal open={idModal.open} onClose={closeIdModal} title={idModal.title} imageUrl={idModal.imageUrl} contentType={idModal.contentType} />

      <style suppressHydrationWarning>{`
        * { box-sizing: border-box; }
        @keyframes fadeUp { from{opacity:0;transform:translateY(14px)} to{opacity:1;transform:translateY(0)} }
        @keyframes mIn    { from{opacity:0;transform:scale(.95)} to{opacity:1;transform:scale(1)} }
        body { margin: 0; }
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: var(--bg); }
        ::-webkit-scrollbar-thumb { background: #64748B; border-radius: 100px; }
        ::-webkit-scrollbar-thumb:hover { background: #94A3B8; }
      `}</style>
    </div>
  );
}
