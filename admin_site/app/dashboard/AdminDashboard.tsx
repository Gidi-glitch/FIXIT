"use client";

import { useState, ReactNode, useEffect } from "react";
import { useRouter } from "next/navigation";

// ─────────────────────────────────────────────────────────────────
// TYPES
// ─────────────────────────────────────────────────────────────────
type Page = "dashboard" | "verification" | "tradesmen" | "homeowners" | "profile";
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
  joined: string;
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
  jobs: number;
  status: "Active" | "Inactive" | "Pending";
  idNumber: string;
  idStatus: "Pending" | "Approved" | "Rejected";
  idImageUrl: string;
}

interface Verification {
  id: number;
  userId: number;
  name?: string;
  type: "homeowner_id" | "tradesperson_license";
  status: "pending" | "approved" | "rejected";
  documentUrl: string;
  createdAt?: string;
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
    Pending:  { bg: "#FEF3E0", color: "#B86A00", border: "1px solid rgba(184,106,0,0.2)" },
    Verified: { bg: "#E6F5EE", color: "#1A7A4A", border: "1px solid rgba(26,122,74,0.2)"  },
    Approved: { bg: "#E6F5EE", color: "#1A7A4A", border: "1px solid rgba(26,122,74,0.2)"  },
    Active:   { bg: "#E6F5EE", color: "#1A7A4A", border: "1px solid rgba(26,122,74,0.2)"  },
    Inactive: { bg: "#FFF0F1", color: "#DC3545", border: "1px solid rgba(220,53,69,0.2)"  },
    Rejected: { bg: "#FFF0F1", color: "#DC3545", border: "1px solid rgba(220,53,69,0.2)"  },
    Suspended:{ bg: "#FFF0F1", color: "#DC3545", border: "1px solid rgba(220,53,69,0.2)"  },
  };
  const s = styles[status] || styles.Pending;
  return (
    <span style={{
      display: "inline-block", padding: "4px 10px", borderRadius: 100,
      fontSize: 11, fontWeight: 700, background: s.bg, color: s.color, border: s.border,
    }}>
      {status === "Verified" || status === "Approved" ? "✓ " : ""}{status}
    </span>
  );
};

// Small button
const Btn = ({
  children, variant = "default", onClick, disabled,
}: {
  children: ReactNode; variant?: "approve" | "reject" | "view" | "default" | "navy";
  onClick?: () => void; disabled?: boolean;
}) => {
  const [hov, setHov] = useState(false);
  const base: Record<string, { bg: string; color: string; border: string; hovBg: string; hovColor: string }> = {
    approve: { bg: "#E6F5EE", color: "#1A7A4A", border: "1.5px solid rgba(26,122,74,0.2)",  hovBg: "#1A7A4A", hovColor: "white" },
    reject:  { bg: "#FFF0F1", color: "#DC3545", border: "1.5px solid rgba(220,53,69,0.18)", hovBg: "#DC3545", hovColor: "white" },
    view:    { bg: "#EEF1FA", color: "#1B2B5E", border: "1.5px solid rgba(27,43,94,0.15)",  hovBg: "#1B2B5E", hovColor: "white" },
    navy:    { bg: "#EEF1FA", color: "#1B2B5E", border: "1.5px solid rgba(27,43,94,0.15)",  hovBg: "#1B2B5E", hovColor: "white" },
    default: { bg: "#F7F8FA", color: "#4A5568", border: "1.5px solid #E3E8F0",              hovBg: "#E3E8F0", hovColor: "#0F1923" },
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
      }}
    >
      {children}
    </button>
  );
};

// Card wrapper
const Card = ({ children, style = {} }: { children: ReactNode; style?: React.CSSProperties }) => (
  <div style={{
    background: "#fff", borderRadius: 12, border: "1.5px solid #E3E8F0",
    boxShadow: "0 1px 3px rgba(15,25,35,.06)", overflow: "hidden", ...style,
  }}>
    {children}
  </div>
);

// Card header
const CardHead = ({ title, subtitle, right }: { title: string; subtitle?: string; right?: ReactNode }) => (
  <div style={{
    padding: "18px 24px", borderBottom: "1px solid #E3E8F0",
    display: "flex", alignItems: "center", justifyContent: "space-between",
  }}>
    <div>
      <div style={{ fontSize: 15, fontWeight: 800, color: "#0F1923" }}>{title}</div>
      {subtitle && <div style={{ fontSize: 12, color: "#9AA3B8", marginTop: 2 }}>{subtitle}</div>}
    </div>
    {right && <div style={{ display: "flex", alignItems: "center", gap: 10 }}>{right}</div>}
  </div>
);

// Pill
const Pill = ({ children, color = "orange" }: { children: ReactNode; color?: "orange" | "navy" | "green" }) => {
  const c = { orange: ["#FEF0E4","#E87722"], navy: ["#EEF1FA","#1B2B5E"], green: ["#E6F5EE","#1A7A4A"] }[color] ?? ["#EEF1FA","#1B2B5E"];
  return (
    <span style={{ padding: "4px 12px", borderRadius: 100, fontSize: 12, fontWeight: 700, background: c[0], color: c[1] }}>
      {children}
    </span>
  );
};

// Sidebar shield logo
function SidebarShield() {
  return (
    <svg width="38" height="42" viewBox="0 0 100 112" fill="none">
      <path d="M50 5L9 22V54C9 77 27 97.5 50 105C73 97.5 91 77 91 54V22L50 5Z" fill="rgba(255,255,255,0.12)" />
      <path d="M50 14L16 29V54C16 74 31.5 92 50 99C68.5 92 84 74 84 54V29L50 14Z" fill="rgba(255,255,255,0.07)" />
      <polygon points="50,30 30,46 30,66 42,66 42,54 58,54 58,66 70,66 70,46" fill="white" opacity="0.9" />
      <polygon points="22,49 50,26 78,49" fill="white" opacity="0.6" />
      <circle cx="66" cy="70" r="12" fill="#E87722" />
      <line x1="62" y1="66" x2="70" y2="74" stroke="white" strokeWidth="2.5" strokeLinecap="round" />
    </svg>
  );
}

// Toast component
const Toast = ({ msg, type, show }: { msg: string; type: ToastType; show: boolean }) => {
  const colors = { success: "#1A7A4A", error: "#DC3545", info: "#1B2B5E" };
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
  open, onClose, title, rows,
}: {
  open: boolean; onClose: () => void; title: string;
  rows: { label: string; value: string; highlight?: boolean }[];
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
          background: "#fff", borderRadius: 16, padding: 28,
          width: "100%", maxWidth: 440,
          boxShadow: "0 12px 40px rgba(15,25,35,.18)",
          animation: "mIn .3s cubic-bezier(.16,1,.3,1)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 22 }}>
          <h3 style={{ fontSize: 18, fontWeight: 800, color: "#0F1923", margin: 0 }}>{title}</h3>
          <button onClick={onClose} style={{ width: 32, height: 32, borderRadius: 8, background: "#F7F8FA", border: "1.5px solid #E3E8F0", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", color: "#4A5568" }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
          </button>
        </div>
        {rows.map((r, i) => (
          <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "11px 0", borderBottom: i < rows.length - 1 ? "1px solid #E3E8F0" : "none" }}>
            <span style={{ fontSize: 13, color: "#9AA3B8", fontWeight: 500 }}>{r.label}</span>
            <span style={{ fontSize: 13, fontWeight: 700, color: r.highlight ? "#1A7A4A" : "#0F1923" }}>{r.value}</span>
          </div>
        ))}
        <button onClick={onClose} style={{
          width: "100%", padding: 13, marginTop: 20,
          background: "#E87722", border: "none", borderRadius: 8,
          fontFamily: "inherit", fontSize: 14, fontWeight: 800, color: "white",
          cursor: "pointer", transition: "background .2s",
        }}
          onMouseEnter={(e) => (e.currentTarget.style.background = "#F09040")}
          onMouseLeave={(e) => (e.currentTarget.style.background = "#E87722")}
        >
          Close
        </button>
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
          background: "#fff", borderRadius: 16, padding: 24,
          width: "100%", maxWidth: 640,
          boxShadow: "0 12px 40px rgba(15,25,35,.18)",
          animation: "mIn .3s cubic-bezier(.16,1,.3,1)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
          <div>
            <h3 style={{ fontSize: 18, fontWeight: 800, color: "#0F1923", margin: 0 }}>{title}</h3>
            <div style={{ fontSize: 12, color: "#9AA3B8", marginTop: 3 }}>Uploaded ID image</div>
          </div>
          <button onClick={onClose} style={{ width: 32, height: 32, borderRadius: 8, background: "#F7F8FA", border: "1.5px solid #E3E8F0", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", color: "#4A5568" }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
          </button>
        </div>
        <div style={{ borderRadius: 12, border: "1.5px solid #E3E8F0", background: "#F7F8FA", padding: 12 }}>
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
          background: "#1B2B5E", border: "none", borderRadius: 8,
          fontFamily: "inherit", fontSize: 14, fontWeight: 800, color: "white",
          cursor: "pointer", transition: "background .2s",
        }}
          onMouseEnter={(e) => (e.currentTarget.style.background = "#243673")}
          onMouseLeave={(e) => (e.currentTarget.style.background = "#1B2B5E")}
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
  <th style={{ padding: "12px 20px", textAlign: "left", fontSize: 11, fontWeight: 700, letterSpacing: "0.8px", textTransform: "uppercase", color: "#9AA3B8", background: "#F7F8FA", borderBottom: "1px solid #E3E8F0", whiteSpace: "nowrap" }}>
    {children}
  </th>
);
const Td = ({ children, style = {}, colSpan }: { children: ReactNode; style?: React.CSSProperties; colSpan?: number }) => (
  <td colSpan={colSpan} style={{ padding: "14px 20px", fontSize: 13, color: "#0F1923", borderBottom: "1px solid #E3E8F0", verticalAlign: "middle", ...style }}>
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
  <div style={{ padding: "14px 24px", borderBottom: "1px solid #E3E8F0", background: "#F7F8FA", display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap" }}>
    <div style={{ flex: 1, minWidth: 200, display: "flex", alignItems: "center", gap: 8, padding: "9px 14px", background: "#fff", border: "1.5px solid #E3E8F0", borderRadius: 8 }}>
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#9AA3B8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>
      <input
        type="text"
        placeholder={placeholder}
        value={searchValue}
        onChange={(e) => onSearchChange(e.target.value)}
        style={{ border: "none", outline: "none", background: "transparent", fontFamily: "inherit", fontSize: 13, color: "#0F1923", width: "100%" }}
      />
    </div>
    {filters.map((opts, i) => (
      <select
        key={i}
        value={filterValues[i] ?? ""}
        onChange={(e) => onFilterChange(i, e.target.value)}
        style={{ padding: "9px 14px", background: "#fff", border: "1.5px solid #E3E8F0", borderRadius: 8, fontFamily: "inherit", fontSize: 13, fontWeight: 600, color: "#4A5568", outline: "none", cursor: "pointer", minWidth: 140 }}
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
  <div style={{ display: "flex", alignItems: "flex-start", gap: 14, padding: "14px 24px", borderBottom: isLast ? "none" : "1px solid #E3E8F0" }}>
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", paddingTop: 3 }}>
      <div style={{ width: 10, height: 10, borderRadius: "50%", background: dot, flexShrink: 0 }} />
      {!isLast && <div style={{ width: 2, flex: 1, background: "#E3E8F0", marginTop: 4, minHeight: 24 }} />}
    </div>
    <div style={{ flex: 1 }}>
      <div style={{ fontSize: 13, fontWeight: 700, color: "#0F1923", marginBottom: 3 }}>{title}</div>
      <div style={{ fontSize: 12, color: "#9AA3B8" }}>{sub}</div>
    </div>
    <div style={{ fontSize: 11, color: "#9AA3B8", whiteSpace: "nowrap", paddingTop: 2 }}>{time}</div>
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
        background: "#fff", borderRadius: 12, border: "1.5px solid #E3E8F0",
        padding: "20px", boxShadow: hov ? "0 4px 16px rgba(15,25,35,.09)" : "0 1px 3px rgba(15,25,35,.06)",
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
          background: trendType === "up" ? "#E6F5EE" : "#FEF3E0",
          color:      trendType === "up" ? "#1A7A4A"  : "#B86A00",
        }}>
          {trend}
        </span>
      </div>
      <div style={{ fontSize: 32, fontWeight: 800, color: "#0F1923", letterSpacing: -1.5, lineHeight: 1, marginBottom: 5 }}>{num}</div>
      <div style={{ fontSize: 13, color: "#9AA3B8", fontWeight: 500 }}>{label}</div>
    </div>
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
        background: "#F7F8FA", border: "1.5px solid #E3E8F0", borderRadius: 12, padding: 18,
        transform: hov ? "translateY(-2px)" : "translateY(0)",
        boxShadow: hov ? "0 4px 16px rgba(15,25,35,.09)" : "none",
        transition: "all .2s",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <Avatar initials={t.initials} color={t.color} size={46} />
          <div>
            <div style={{ fontSize: 14, fontWeight: 800, color: "#0F1923", marginBottom: 2 }}>{t.name}</div>
            <div style={{ fontSize: 12, color: "#9AA3B8", fontWeight: 500 }}>{t.category}</div>
          </div>
        </div>
        <Badge status={t.status} />
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 7, background: "#fff", border: "1px solid #E3E8F0", borderRadius: 8, padding: "8px 12px", marginBottom: 12 }}>
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#9AA3B8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="7" width="20" height="14" rx="2" /><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16" /></svg>
        <span style={{ fontSize: 12, color: "#4A5568", fontWeight: 600 }}>
          <strong style={{ color: "#9AA3B8", fontWeight: 600, marginRight: 6 }}>License:</strong>{t.license}
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
  v, onApprove, onReject, onView, name,
}: {
  v: Verification;
  onApprove: () => void;
  onReject: () => void;
  onView: () => void;
  name: string;
}) => {
  const [hov, setHov] = useState(false);
  const statusLabel = toTitle(v.status);
  return (
    <div
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        background: "#F7F8FA", border: "1.5px solid #E3E8F0", borderRadius: 12, padding: 18,
        transform: hov ? "translateY(-2px)" : "translateY(0)",
        boxShadow: hov ? "0 4px 16px rgba(15,25,35,.09)" : "none",
        transition: "all .2s",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
        <div>
          <div style={{ fontSize: 13, fontWeight: 800, color: "#0F1923", marginBottom: 2 }}>
            {name ? `${name} · User #${v.userId}` : `User #${v.userId}`}
          </div>
          <div style={{ fontSize: 12, color: "#9AA3B8", fontWeight: 600 }}>{verificationTypeLabel(v.type)}</div>
        </div>
        <Badge status={statusLabel} />
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 7, background: "#fff", border: "1px solid #E3E8F0", borderRadius: 8, padding: "8px 12px", marginBottom: 12 }}>
        {icons.license}
        <span style={{ fontSize: 12, color: "#4A5568", fontWeight: 600 }}>
          <strong style={{ color: "#9AA3B8", fontWeight: 600, marginRight: 6 }}>Document:</strong>
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
        {v.type === "tradesperson_license" && (
          <Btn variant="view" onClick={onView}>{icons.license} View ID/Cert</Btn>
        )}
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
        background: active ? "#E87722" : hov ? "rgba(255,255,255,0.06)" : "transparent",
        transition: "all .2s",
      }}
    >
      <span style={{ color: active ? "white" : "rgba(255,255,255,0.45)", flexShrink: 0, display: "flex" }}>
        {icon}
      </span>
      <span style={{ fontSize: 13, fontWeight: 600, color: active ? "white" : "rgba(255,255,255,0.5)", flex: 1 }}>
        {label}
      </span>
      {badge !== undefined && badge > 0 && (
        <span style={{ background: active ? "rgba(255,255,255,0.3)" : "#E87722", color: "white", fontSize: 10, fontWeight: 800, padding: "2px 7px", borderRadius: 100 }}>
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
  const [toast, setToast]           = useState({ show: false, msg: "", type: "success" as ToastType });
  const [modal, setModal]           = useState<{ open: boolean; title: string; rows: { label: string; value: string; highlight?: boolean }[] }>({ open: false, title: "", rows: [] });
  const [idModal, setIdModal]       = useState<{ open: boolean; title: string; imageUrl: string; contentType: string }>({ open: false, title: "", imageUrl: "", contentType: "" });
  const [searchVerification, setSearchVerification] = useState("");
  const [searchTradesmen, setSearchTradesmen] = useState("");
  const [searchHomeowners, setSearchHomeowners] = useState("");
  const [searchDashboard, setSearchDashboard] = useState("");
  const [verificationFilters, setVerificationFilters] = useState<string[]>(["", ""]);
  const [tradesmenFilters, setTradesmenFilters] = useState<string[]>(["", ""]);
  const [homeownerFilters, setHomeownerFilters] = useState<string[]>(["", ""]);

  const pendingCount  = verifications.filter((v) => v.status === "pending").length;
  const verifiedCount = tradesmen.filter((t) => t.status === "Verified").length;
  const pendingHomeownerIds = homeowners.filter((h) => h.idStatus === "Pending").length;

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

  const filteredVerifications = verifications.filter((v) => {
    const statusLabel = toTitle(v.status);
    const typeLabel = verificationTypeLabel(v.type);
    return (
      matchesQuery(searchVerification, [v.userId, v.id, statusLabel, typeLabel, getVerificationUserName(v)]) &&
      matchesExactFilter(verificationFilters[0] ?? "", statusLabel) &&
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
          statusRaw === "verified" ? "Verified" : statusRaw === "suspended" ? "Suspended" : "Pending";
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
          joined: formatDate(t.created_at ?? t.CreatedAt),
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
          idStatusRaw === "approved" ? "Approved" : idStatusRaw === "rejected" ? "Rejected" : "Pending";
        return {
          id: String(h.id ?? h.ID ?? ""),
          userId: userId || undefined,
          initials: initialsFromName(name),
          color: colorFromSeed(name),
          name,
          email: h.email ?? h.Email ?? h.user_email ?? h.UserEmail ?? "—",
          location: h.barangay ?? h.Barangay ?? h.location ?? "—",
          registered: formatDate(h.created_at ?? h.CreatedAt),
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

  useEffect(() => {
    loadUsers();
  }, [authToken, apiBase, router]);

  // Approve / Reject
  const rejectTradesman = (id: string, name: string) => {
    setTradesmen((prev) => prev.filter((t) => t.id !== id));
    showToast(`${name} rejected`, "error");
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
      if (reviewed && status === "approved") {
        const targetId = String(reviewed.userId ?? "");
        if (reviewed.type === "tradesperson_license") {
          setTradesmen((prev) =>
            prev.map((t) =>
              t.userId === targetId || t.id === targetId ? { ...t, status: "Verified" } : t
            )
          );
        }
        if (reviewed.type === "homeowner_id") {
          setHomeowners((prev) =>
            prev.map((h) =>
              h.userId === targetId || h.id === targetId
                ? { ...h, idStatus: "Approved", status: "Active" }
                : h
            )
          );
        }
      }
      if (status === "approved") {
        loadUsers();
      }
      showToast(`Verification ${status}`, status === "approved" ? "success" : "error");
    } catch {
      showToast("Failed to update verification.", "error");
    }
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
        { label: "Credentials", value: t.credentialUrl ? "Uploaded" : "Not uploaded", highlight: Boolean(t.credentialUrl) },
      ],
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
  };

  // ── PAGES ──────────────────────────────────────────────────────

  const PageDashboard = () => (
    <div style={{ animation: "fadeUp .35s ease both" }}>
      {/* Stats */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 16, marginBottom: 28 }}>
        <StatCard iconBg="#EEF1FA" iconColor="#1B2B5E" num={homeowners.length} label="Total Homeowners" trend="+12%" trendType="up"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>}
        />
        <StatCard iconBg="#FEF0E4" iconColor="#E87722" num={tradesmen.length} label="Total Tradesmen" trend="+8%" trendType="up"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>}
        />
        <StatCard iconBg="#FEF3E0" iconColor="#B86A00" num={pendingCount} label="Pending Verifications" trend="Needs review" trendType="warn"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>}
        />
        <StatCard iconBg="#E6F5EE" iconColor="#1A7A4A" num={verifiedCount} label="Verified Tradesmen" trend={`${Math.round((verifiedCount/Math.max(tradesmen.length,1))*100)}% rate`} trendType="up"
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
                <Btn variant="navy" onClick={() => setActivePage("verification")}>View All</Btn>
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
              />
            ))}
            {pendingCount === 0 && (
              <div style={{ gridColumn: "1/-1", textAlign: "center", padding: "40px 20px", color: "#9AA3B8" }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>All caught up! No pending verifications.</div>
              </div>
            )}
            {pendingCount > 0 && filteredDashboardVerifications.length === 0 && (
              <div style={{ gridColumn: "1/-1", textAlign: "center", padding: "40px 20px", color: "#9AA3B8" }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>No matching verifications.</div>
              </div>
            )}
          </div>
        </Card>

        {/* Recent activity */}
        <Card>
          <CardHead title="Recent Activity" subtitle="Latest events" />
          <ActivityItem dot="#1A7A4A" title="New tradesman registered" sub="Jose Buenaventura · Carpenter"  time="2m ago" />
          <ActivityItem dot="#E87722" title="Verification submitted"   sub="Ana Lim · HVAC-2024-05563"      time="14m ago" />
          <ActivityItem dot="#1B2B5E" title="New homeowner signed up"  sub="Maria Garcia · San Miguel"          time="1h ago" />
          <ActivityItem dot="#1A7A4A" title="License approved"         sub="Ramon Dela Cruz · APPL-2022"    time="3h ago" />
          <ActivityItem dot="#DC3545" title="License rejected"         sub="Unknown applicant"              time="5h ago" isLast />
        </Card>
      </div>

      {/* Homeowners quick table */}
      <Card>
        <CardHead
          title="Recent Homeowners"
          subtitle="Latest registrations"
          right={<Btn variant="navy" onClick={() => setActivePage("homeowners")}>View All</Btn>}
        />
        <Table>
          <thead><tr><Th>User</Th><Th>Location</Th><Th>Joined</Th><Th>Jobs</Th><Th>Status</Th><Th>Actions</Th></tr></thead>
          <tbody>
            {filteredDashboardHomeowners.slice(0, 4).map((h) => (
              <tr key={h.id} style={{ transition: "background .15s" }}
                onMouseEnter={(e) => (e.currentTarget.style.background = "#FAFBFD")}
                onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}>
                <Td>
                  <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <Avatar initials={h.initials} color={h.color} size={38} />
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 13, color: "#0F1923" }}>{h.name}</div>
                      <div style={{ fontSize: 12, color: "#9AA3B8" }}>{h.email}</div>
                    </div>
                  </div>
                </Td>
                <Td>{h.location}</Td>
                <Td>{h.registered}</Td>
                <Td>{h.jobs}</Td>
                <Td><Badge status={h.status} /></Td>
                <Td><Btn variant="view" onClick={() => openHOModal(h)}>Details</Btn></Td>
              </tr>
            ))}
            {filteredDashboardHomeowners.length === 0 && (
              <tr>
                <Td style={{ textAlign: "center", color: "#9AA3B8" }} colSpan={6}>No matching homeowners.</Td>
              </tr>
            )}
          </tbody>
        </Table>
      </Card>
    </div>
  );

  const PageVerification = () => (
    <div style={{ animation: "fadeUp .35s ease both" }}>
      <Card>
        <CardHead title="Verification Requests" subtitle="Review and approve ID/license submissions"
          right={<Pill color="orange">{pendingCount} Pending</Pill>}
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
                  onMouseEnter={(e) => (e.currentTarget.style.background = "#FAFBFD")}
                  onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                  style={{ transition: "background .15s" }}>
                  <Td>
                    <div style={{ fontWeight: 700, fontSize: 13 }}>{userName || `User #${v.userId}`}</div>
                    {userName && <div style={{ fontSize: 12, color: "#9AA3B8" }}>User #{v.userId}</div>}
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
          filters={[["All Categories","Electrician","Plumber","HVAC","Carpenter","Painter"],["All Status","Verified","Pending"]]}
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
                onMouseEnter={(e) => (e.currentTarget.style.background = "#FAFBFD")}
                onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                style={{ transition: "background .15s" }}>
                <Td>
                  <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <Avatar initials={t.initials} color={t.color} size={38} />
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 13 }}>{t.name}</div>
                      <div style={{ fontSize: 12, color: "#9AA3B8" }}>{t.email}</div>
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
                    <Btn variant="view" onClick={() => openTMModal(t)}>View</Btn>
                    {t.status === "Verified" && <Btn variant="reject" onClick={() => showToast(`${t.name} revoked`, "error")}>{icons.x} Revoke</Btn>}
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
          filters={[["All Locations","San Miguel","Barangay II-A","San Bartolome","Santa Ana","San Pedro"],["All Status","Pending","Active","Inactive"]]}
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
                onMouseEnter={(e) => (e.currentTarget.style.background = "#FAFBFD")}
                onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                style={{ transition: "background .15s" }}>
                <Td>
                  <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <Avatar initials={h.initials} color={h.color} size={38} />
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 13 }}>{h.name}</div>
                      <div style={{ fontSize: 12, color: "#9AA3B8" }}>{h.email}</div>
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
                    <Btn variant="view" onClick={() => openDocumentModal(h.name, h.idImageUrl)}>{icons.license} View ID</Btn>
                    <Btn variant="view" onClick={() => openHOModal(h)}>Details</Btn>
                  </div>
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      </Card>
    </div>
  );

  const PageProfile = () => (
    <div style={{ display: "grid", gridTemplateColumns: "300px 1fr", gap: 24, animation: "fadeUp .35s ease both" }}>
      {/* Left: profile card */}
      <div>
        <Card style={{ marginBottom: 16 }}>
          {/* Hero */}
          <div style={{ background: "#1B2B5E", padding: "32px 24px", display: "flex", flexDirection: "column", alignItems: "center", position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", width: 200, height: 200, borderRadius: "50%", background: "rgba(255,255,255,0.04)", top: -70, right: -60 }} />
            <div style={{ position: "absolute", width: 120, height: 120, borderRadius: "50%", background: "rgba(232,119,34,0.12)", bottom: -40, left: 10 }} />
            <div style={{ width: 76, height: 76, background: "#E87722", borderRadius: 22, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 28, fontWeight: 800, color: "white", marginBottom: 14, border: "3px solid rgba(255,255,255,0.2)", position: "relative", zIndex: 1 }}>AD</div>
            <div style={{ fontSize: 20, fontWeight: 800, color: "white", position: "relative", zIndex: 1 }}>Admin User</div>
            <div style={{ fontSize: 13, color: "rgba(255,255,255,0.5)", marginTop: 4, position: "relative", zIndex: 1 }}>Super Administrator</div>
          </div>
          {/* Items */}
          {[
            { icon: icons.bell, label: "Email", sub: "admin@fixit.com" },
            { icon: icons.shield, label: "Password", sub: "Last changed 30 days ago" },
            { icon: icons.shield, label: "Security", sub: "2FA enabled" },
          ].map((item, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "15px 20px", borderBottom: i < 2 ? "1px solid #E3E8F0" : "none", cursor: "pointer", transition: "background .15s" }}
              onMouseEnter={(e) => (e.currentTarget.style.background = "#F7F8FA")}
              onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}>
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <div style={{ width: 36, height: 36, borderRadius: 9, background: "#FEF0E4", display: "flex", alignItems: "center", justifyContent: "center", color: "#E87722" }}>{item.icon}</div>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 700, color: "#0F1923" }}>{item.label}</div>
                  <div style={{ fontSize: 11, color: "#9AA3B8", marginTop: 1 }}>{item.sub}</div>
                </div>
              </div>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#9AA3B8" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 18 15 12 9 6"/></svg>
            </div>
          ))}
        </Card>
        {/* Sign out */}
        <button onClick={handleLogout}
          style={{ width: "100%", padding: 14, background: "#FFF0F1", border: "1.5px solid rgba(220,53,69,0.2)", borderRadius: 12, fontFamily: "inherit", fontSize: 14, fontWeight: 800, color: "#DC3545", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 8, transition: "all .2s" }}
          onMouseEnter={(e) => { e.currentTarget.style.background = "#DC3545"; e.currentTarget.style.color = "white"; }}
          onMouseLeave={(e) => { e.currentTarget.style.background = "#FFF0F1"; e.currentTarget.style.color = "#DC3545"; }}>
          {icons.logout} Sign Out
        </button>
      </div>

      {/* Right: details + activity */}
      <div>
        <Card style={{ marginBottom: 20 }}>
          <CardHead title="Account Details" />
          <div style={{ padding: 24, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
            {[["Full Name","Admin User"],["Role","Super Administrator"],["Email","admin@fixit.com"],["Last Login","Today, 5:29 AM"]].map(([l,v]) => (
              <div key={l}>
                <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.8px", textTransform: "uppercase", color: "#9AA3B8", marginBottom: 6 }}>{l}</div>
                <div style={{ fontSize: 14, fontWeight: 700, color: "#0F1923" }}>{v}</div>
              </div>
            ))}
          </div>
        </Card>
        <Card>
          <CardHead title="Activity Log" />
          <ActivityItem dot="#1A7A4A" title="Approved: Ramon Dela Cruz" sub="License APPL-2022-00312 verified" time="3h ago" />
          <ActivityItem dot="#DC3545" title="Rejected: Unknown applicant" sub="Insufficient documentation" time="5h ago" />
          <ActivityItem dot="#1B2B5E" title="Admin login" sub="admin@fixit.com · Chrome · Pasig" time="Today" isLast />
        </Card>
      </div>
    </div>
  );

  // ── RENDER ─────────────────────────────────────────────────────
  return (
    <div style={{ display: "flex", minHeight: "100vh", fontFamily: "'Plus Jakarta Sans', sans-serif", background: "#F1F3F7" }}>

      {/* SIDEBAR */}
      <nav style={{ width: 260, flexShrink: 0, background: "#1B2B5E", display: "flex", flexDirection: "column", position: "fixed", top: 0, left: 0, bottom: 0, zIndex: 50, boxShadow: "2px 0 20px rgba(15,25,35,.15)", overflowY: "auto" }}>
        {/* Logo */}
        <div style={{ padding: "22px 20px 18px", borderBottom: "1px solid rgba(255,255,255,.08)", display: "flex", alignItems: "center", gap: 12 }}>
          <SidebarShield />
          <div>
            <div style={{ fontSize: 20, fontWeight: 800, color: "white", letterSpacing: -0.3 }}>Fix It</div>
            <div style={{ fontSize: 11, color: "rgba(255,255,255,.4)", fontWeight: 500, letterSpacing: 0.5 }}>Admin Portal</div>
          </div>
        </div>

        {/* Admin tag */}
        <div style={{ margin: "14px 14px 4px", padding: "10px 14px", background: "rgba(232,119,34,.12)", border: "1px solid rgba(232,119,34,.25)", borderRadius: 10, display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 36, height: 36, borderRadius: 9, background: "#E87722", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 800, color: "white", flexShrink: 0 }}>AD</div>
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
            { icon: icons.chart,    label: "Activity Log",  page: undefined },
            { icon: icons.settings, label: "Settings",      page: undefined },
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
            style={{ display: "flex", alignItems: "center", gap: 10, padding: "11px 12px", borderRadius: 10, background: "rgba(220,53,69,.1)", border: "1px solid rgba(220,53,69,.2)", cursor: "pointer", width: "100%", fontFamily: "inherit", transition: "background .2s" }}
            onMouseEnter={(e) => (e.currentTarget.style.background = "rgba(220,53,69,.2)")}
            onMouseLeave={(e) => (e.currentTarget.style.background = "rgba(220,53,69,.1)")}>
            <span style={{ color: "#F08090", display: "flex" }}>{icons.logout}</span>
            <span style={{ fontSize: 13, fontWeight: 700, color: "#F08090" }}>Sign Out</span>
          </button>
        </div>
      </nav>

      {/* MAIN */}
      <div style={{ marginLeft: 260, flex: 1, display: "flex", flexDirection: "column", minHeight: "100vh" }}>
        {/* Topbar */}
        <div style={{ background: "#fff", height: 64, borderBottom: "1px solid #E3E8F0", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 32px", position: "sticky", top: 0, zIndex: 40, boxShadow: "0 1px 3px rgba(15,25,35,.06)" }}>
          <div>
            <div style={{ fontSize: 18, fontWeight: 800, color: "#0F1923", letterSpacing: -0.3 }}>{pageTitles[activePage]}</div>
            <div style={{ fontSize: 12, color: "#9AA3B8", fontWeight: 500, marginTop: 1 }}>Fix It Marketplace › Admin Portal › {pageTitles[activePage]}</div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            {/* Search */}
            <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "9px 14px", background: "#F7F8FA", border: "1.5px solid #E3E8F0", borderRadius: 8, width: 220, color: "#9AA3B8", fontSize: 13, cursor: canSearchTopbar ? "text" : "not-allowed", opacity: canSearchTopbar ? 1 : 0.6 }}>
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <input
                type="text"
                placeholder="Search anything…"
                value={topbarSearchValue}
                onChange={(e) => setTopbarSearchValue(e.target.value)}
                disabled={!canSearchTopbar}
                style={{ border: "none", outline: "none", background: "transparent", fontFamily: "inherit", fontSize: 13, color: "#0F1923", width: "100%" }}
              />
            </div>
            {/* Bell */}
            <button onClick={() => showToast("3 pending verifications", "info")}
              style={{ width: 38, height: 38, borderRadius: 9, border: "1.5px solid #E3E8F0", background: "#fff", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", position: "relative", transition: "all .2s" }}
              onMouseEnter={(e) => { e.currentTarget.style.borderColor = "#E87722"; e.currentTarget.style.background = "#FEF0E4"; }}
              onMouseLeave={(e) => { e.currentTarget.style.borderColor = "#E3E8F0"; e.currentTarget.style.background = "#fff"; }}>
              <span style={{ color: "#4A5568" }}>{icons.bell}</span>
              <span style={{ position: "absolute", top: 7, right: 7, width: 7, height: 7, background: "#E87722", borderRadius: "50%", border: "1.5px solid white" }} />
            </button>
            {/* Avatar */}
            <div onClick={() => setActivePage("profile")}
              style={{ width: 38, height: 38, borderRadius: 9, background: "#E87722", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 800, color: "white", cursor: "pointer" }}>
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
        </div>
      </div>

      {/* Toast */}
      <Toast msg={toast.msg} type={toast.type} show={toast.show} />

      {/* Modal */}
      <Modal open={modal.open} onClose={() => setModal((m) => ({ ...m, open: false }))} title={modal.title} rows={modal.rows} />
      <ImageModal open={idModal.open} onClose={closeIdModal} title={idModal.title} imageUrl={idModal.imageUrl} contentType={idModal.contentType} />

      <style suppressHydrationWarning>{`
        * { box-sizing: border-box; }
        @keyframes fadeUp { from{opacity:0;transform:translateY(14px)} to{opacity:1;transform:translateY(0)} }
        @keyframes mIn    { from{opacity:0;transform:scale(.95)} to{opacity:1;transform:scale(1)} }
        body { margin: 0; }
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: #F1F3F7; }
        ::-webkit-scrollbar-thumb { background: #C8D0DC; border-radius: 100px; }
        ::-webkit-scrollbar-thumb:hover { background: #9AA3B8; }
      `}</style>
    </div>
  );
}
