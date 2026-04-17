"use client";

import { Fragment, useState, ReactNode, useEffect, CSSProperties, useRef } from "react";
import { useRouter } from "next/navigation";

// ─────────────────────────────────────────────────────────────────
// TYPES
// ─────────────────────────────────────────────────────────────────
type Page = "dashboard" | "verification" | "tradesmen" | "homeowners" | "ratings" | "reports" | "profile" | "settings";
type ToastType = "success" | "error" | "info";
type ReportTab = "all" | "homeowner" | "tradesman";

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

type ProfileEditorMode = "name" | "email" | "password";

interface AdminProfile {
  id: string;
  fullName: string;
  email: string;
  role: string;
  isActive: boolean;
  updatedAt?: string;
}

interface ActivityEntry {
  id: string;
  dot: string;
  title: string;
  sub: string;
  time: string;
}

interface RequestAnalyticsBooking {
  id: string;
  status: string;
  createdAt?: string;
  updatedAt?: string;
  completedAt?: string;
}

interface UserGrowthPoint {
  key: string;
  label: string;
  homeowners: number;
  tradesmen: number;
  total: number;
}

interface RequestAnalyticsPoint {
  key: string;
  label: string;
  total: number;
  completed: number;
  cancelled: number;
}

interface FailedBookingPoint {
  key: string;
  label: string;
  homeownerCancelled: number;
  tradesmanRejected: number;
  totalFailed: number;
}

interface ServiceBookingSlice {
  id: string;
  label: string;
  count: number;
  color: string;
}

type AnalyticsRange = "today" | "week" | "month";

interface ReportEntry {
  id: string;
  targetType: "Homeowner" | "Tradesman";
  targetName: string;
  targetEmail: string;
  reporterName: string;
  reporterRole: "Homeowner" | "Tradesman";
  reason: string;
  details: string;
  status: "Open" | "Reviewing" | "Resolved";
  submittedAt: string;
}

interface TradesmanReview {
  id: string;
  tradesmanId: string;
  tradesmanEmail: string;
  tradesmanName: string;
  reviewerName: string;
  reviewerRole: "Homeowner" | "Tradesman";
  rating: number;
  jobType: string;
  comment: string;
  submittedAt: string;
  verifiedBooking: boolean;
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

const formatDateTime = (value?: string) => {
  if (!value) return "—";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString([], {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
};

const humanizeRole = (value?: string) => {
  if (!value) return "—";
  if (value.toLowerCase() === "admin") return "Administrator";
  return value
    .split(/[_\s-]+/)
    .filter(Boolean)
    .map((part) => part[0].toUpperCase() + part.slice(1).toLowerCase())
    .join(" ");
};

const adminDisplayNameFromEmail = (email?: string) => {
  if (!email) return "Admin User";
  const local = email.split("@")[0]?.trim();
  if (!local) return "Admin User";
  return local
    .split(/[._-]+/)
    .filter(Boolean)
    .map((part) => part[0].toUpperCase() + part.slice(1))
    .join(" ");
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

const verificationStatusPriority: Record<Verification["status"], number> = {
  pending: 0,
  approved: 1,
  rejected: 2,
  archived: 3,
};

const sortVerifications = (items: Verification[]) =>
  [...items].sort((a, b) => {
    const priorityDelta = verificationStatusPriority[a.status] - verificationStatusPriority[b.status];
    if (priorityDelta !== 0) return priorityDelta;

    const aTime = a.createdAt ? new Date(a.createdAt).getTime() : 0;
    const bTime = b.createdAt ? new Date(b.createdAt).getTime() : 0;
    return bTime - aTime;
  });

const monthLabelFormatter = new Intl.DateTimeFormat("en-US", { month: "short" });
const getMonthKey = (date: Date) => `${date.getFullYear()}-${date.getMonth()}`;
const getDateKey = (date: Date) => `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
const startOfDay = (date: Date) => new Date(date.getFullYear(), date.getMonth(), date.getDate());
const addDays = (date: Date, days: number) => new Date(date.getFullYear(), date.getMonth(), date.getDate() + days);
const isSameDay = (left: Date, right: Date) =>
  left.getFullYear() === right.getFullYear() &&
  left.getMonth() === right.getMonth() &&
  left.getDate() === right.getDate();

const formatHourLabel = (hour: number) =>
  new Intl.DateTimeFormat("en-US", { hour: "numeric" }).format(new Date(2025, 0, 1, hour));

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

const buildRangeAnalyticsData = (
  homeowners: Homeowner[],
  tradesmen: Tradesman[],
  range: AnalyticsRange,
) => {
  const now = new Date();
  const today = startOfDay(now);
  let buckets: UserGrowthPoint[] = [];
  let resolveKey: (date: Date) => string | null = () => null;

  if (range === "today") {
    buckets = Array.from({ length: 24 }, (_, hour) => ({
      key: String(hour),
      label: formatHourLabel(hour),
      homeowners: 0,
      tradesmen: 0,
      total: 0,
    }));
    resolveKey = (date) => (isSameDay(date, now) ? String(date.getHours()) : null);
  } else if (range === "week") {
    const start = addDays(today, -6);
    buckets = Array.from({ length: 7 }, (_, index) => {
      const date = addDays(start, index);
      return {
        key: getDateKey(date),
        label: date.toLocaleDateString("en-US", { weekday: "short" }),
        homeowners: 0,
        tradesmen: 0,
        total: 0,
      };
    });
    resolveKey = (date) => {
      const value = startOfDay(date);
      if (value < start || value > today) return null;
      return getDateKey(value);
    };
  } else {
    const start = addDays(today, -29);
    buckets = Array.from({ length: 30 }, (_, index) => {
      const date = addDays(start, index);
      return {
        key: getDateKey(date),
        label: date.toLocaleDateString("en-US", { month: "short", day: "numeric" }),
        homeowners: 0,
        tradesmen: 0,
        total: 0,
      };
    });
    resolveKey = (date) => {
      const value = startOfDay(date);
      if (value < start || value > today) return null;
      return getDateKey(value);
    };
  }

  const bucketMap = new Map(buckets.map((bucket) => [bucket.key, bucket]));

  homeowners.forEach((homeowner) => {
    const parsed = parseDashboardDate(homeowner.createdAt);
    if (!parsed) return;
    const key = resolveKey(parsed);
    if (!key) return;
    const bucket = bucketMap.get(key);
    if (!bucket) return;
    bucket.homeowners += 1;
    bucket.total += 1;
  });

  tradesmen.forEach((tradesman) => {
    const parsed = parseDashboardDate(tradesman.createdAt);
    if (!parsed) return;
    const key = resolveKey(parsed);
    if (!key) return;
    const bucket = bucketMap.get(key);
    if (!bucket) return;
    bucket.tradesmen += 1;
    bucket.total += 1;
  });

  return buckets;
};

const buildMockRequestAnalyticsData = (range: AnalyticsRange): RequestAnalyticsPoint[] => {
  if (range === "today") {
    return [
      { key: "0", label: "12 AM", total: 1, completed: 0, cancelled: 0 },
      { key: "3", label: "3 AM", total: 0, completed: 0, cancelled: 0 },
      { key: "6", label: "6 AM", total: 2, completed: 1, cancelled: 0 },
      { key: "9", label: "9 AM", total: 6, completed: 3, cancelled: 1 },
      { key: "12", label: "12 PM", total: 8, completed: 5, cancelled: 1 },
      { key: "15", label: "3 PM", total: 7, completed: 4, cancelled: 2 },
      { key: "18", label: "6 PM", total: 5, completed: 3, cancelled: 1 },
      { key: "21", label: "9 PM", total: 3, completed: 2, cancelled: 1 },
    ];
  }

  if (range === "week") {
    return [
      { key: "mon", label: "Mon", total: 18, completed: 11, cancelled: 2 },
      { key: "tue", label: "Tue", total: 22, completed: 14, cancelled: 3 },
      { key: "wed", label: "Wed", total: 20, completed: 13, cancelled: 2 },
      { key: "thu", label: "Thu", total: 27, completed: 18, cancelled: 4 },
      { key: "fri", label: "Fri", total: 31, completed: 21, cancelled: 5 },
      { key: "sat", label: "Sat", total: 24, completed: 16, cancelled: 3 },
      { key: "sun", label: "Sun", total: 16, completed: 10, cancelled: 2 },
    ];
  }

  return [
    { key: "apr-1", label: "Apr 1", total: 11, completed: 7, cancelled: 1 },
    { key: "apr-4", label: "Apr 4", total: 15, completed: 10, cancelled: 2 },
    { key: "apr-7", label: "Apr 7", total: 14, completed: 9, cancelled: 2 },
    { key: "apr-10", label: "Apr 10", total: 18, completed: 12, cancelled: 3 },
    { key: "apr-13", label: "Apr 13", total: 22, completed: 15, cancelled: 3 },
    { key: "apr-16", label: "Apr 16", total: 19, completed: 13, cancelled: 2 },
    { key: "apr-19", label: "Apr 19", total: 24, completed: 17, cancelled: 4 },
    { key: "apr-22", label: "Apr 22", total: 27, completed: 18, cancelled: 5 },
    { key: "apr-25", label: "Apr 25", total: 21, completed: 14, cancelled: 3 },
    { key: "apr-28", label: "Apr 28", total: 25, completed: 17, cancelled: 4 },
  ];
};

const startOfWeekMonday = (date: Date) => {
  const normalized = startOfDay(date);
  const dayOffset = (normalized.getDay() + 6) % 7;
  return addDays(normalized, -dayOffset);
};

const resolveRequestBucketIndex = (range: AnalyticsRange, value: Date, now: Date) => {
  if (range === "today") {
    if (!isSameDay(value, now)) return -1;
    const blockIndex = Math.floor(value.getHours() / 3);
    return blockIndex >= 0 && blockIndex <= 7 ? blockIndex : -1;
  }

  if (range === "week") {
    const start = startOfWeekMonday(now);
    const day = startOfDay(value);
    const diffDays = Math.floor((day.getTime() - start.getTime()) / (24 * 60 * 60 * 1000));
    return diffDays >= 0 && diffDays <= 6 ? diffDays : -1;
  }

  const today = startOfDay(now);
  const day = startOfDay(value);
  const diffDays = Math.floor((today.getTime() - day.getTime()) / (24 * 60 * 60 * 1000));
  if (diffDays < 0 || diffDays > 29) return -1;
  return Math.max(0, 9 - Math.floor(diffDays / 3));
};

const buildMergedRequestAnalyticsData = (
  range: AnalyticsRange,
  bookings: RequestAnalyticsBooking[],
): RequestAnalyticsPoint[] => {
  const points = buildMockRequestAnalyticsData(range).map((point) => ({ ...point }));
  if (!bookings.length) return points;

  const now = new Date();
  const addToBucket = (dateValue: string | undefined, field: "total" | "completed" | "cancelled") => {
    const parsed = parseDashboardDate(dateValue);
    if (!parsed) return;
    const index = resolveRequestBucketIndex(range, parsed, now);
    if (index < 0 || index >= points.length) return;
    points[index][field] += 1;
  };

  bookings.forEach((booking) => {
    const status = String(booking.status ?? "").trim().toLowerCase();
    addToBucket(booking.createdAt, "total");

    if (status === "completed") {
      addToBucket(booking.completedAt ?? booking.updatedAt ?? booking.createdAt, "completed");
      return;
    }

    if (status === "cancelled" || status === "canceled") {
      addToBucket(booking.updatedAt ?? booking.createdAt, "cancelled");
    }
  });

  return points;
};

const buildMockFailedBookingsData = (range: AnalyticsRange): FailedBookingPoint[] => {
  if (range === "today") {
    return [
      { key: "0", label: "12 AM", homeownerCancelled: 0, tradesmanRejected: 0, totalFailed: 0 },
      { key: "3", label: "3 AM", homeownerCancelled: 1, tradesmanRejected: 0, totalFailed: 1 },
      { key: "6", label: "6 AM", homeownerCancelled: 1, tradesmanRejected: 1, totalFailed: 2 },
      { key: "9", label: "9 AM", homeownerCancelled: 2, tradesmanRejected: 1, totalFailed: 3 },
      { key: "12", label: "12 PM", homeownerCancelled: 3, tradesmanRejected: 1, totalFailed: 4 },
      { key: "15", label: "3 PM", homeownerCancelled: 2, tradesmanRejected: 2, totalFailed: 4 },
      { key: "18", label: "6 PM", homeownerCancelled: 1, tradesmanRejected: 2, totalFailed: 3 },
      { key: "21", label: "9 PM", homeownerCancelled: 1, tradesmanRejected: 1, totalFailed: 2 },
    ];
  }

  if (range === "week") {
    return [
      { key: "mon", label: "Mon", homeownerCancelled: 4, tradesmanRejected: 2, totalFailed: 6 },
      { key: "tue", label: "Tue", homeownerCancelled: 5, tradesmanRejected: 3, totalFailed: 8 },
      { key: "wed", label: "Wed", homeownerCancelled: 3, tradesmanRejected: 2, totalFailed: 5 },
      { key: "thu", label: "Thu", homeownerCancelled: 6, tradesmanRejected: 4, totalFailed: 10 },
      { key: "fri", label: "Fri", homeownerCancelled: 7, tradesmanRejected: 4, totalFailed: 11 },
      { key: "sat", label: "Sat", homeownerCancelled: 5, tradesmanRejected: 3, totalFailed: 8 },
      { key: "sun", label: "Sun", homeownerCancelled: 4, tradesmanRejected: 2, totalFailed: 6 },
    ];
  }

  return [
    { key: "apr-1", label: "Apr 1", homeownerCancelled: 3, tradesmanRejected: 2, totalFailed: 5 },
    { key: "apr-4", label: "Apr 4", homeownerCancelled: 5, tradesmanRejected: 2, totalFailed: 7 },
    { key: "apr-7", label: "Apr 7", homeownerCancelled: 4, tradesmanRejected: 3, totalFailed: 7 },
    { key: "apr-10", label: "Apr 10", homeownerCancelled: 6, tradesmanRejected: 3, totalFailed: 9 },
    { key: "apr-13", label: "Apr 13", homeownerCancelled: 7, tradesmanRejected: 4, totalFailed: 11 },
    { key: "apr-16", label: "Apr 16", homeownerCancelled: 5, tradesmanRejected: 4, totalFailed: 9 },
    { key: "apr-19", label: "Apr 19", homeownerCancelled: 8, tradesmanRejected: 4, totalFailed: 12 },
    { key: "apr-22", label: "Apr 22", homeownerCancelled: 7, tradesmanRejected: 5, totalFailed: 12 },
    { key: "apr-25", label: "Apr 25", homeownerCancelled: 6, tradesmanRejected: 3, totalFailed: 9 },
    { key: "apr-28", label: "Apr 28", homeownerCancelled: 8, tradesmanRejected: 4, totalFailed: 12 },
  ];
};

const formatPercent = (value: number) => {
  const rounded = Math.abs(value) >= 10 ? Math.round(value) : Math.round(value * 10) / 10;
  return `${rounded > 0 ? "+" : rounded < 0 ? "" : ""}${rounded}%`;
};

const formatMonthlyTrend = (current: number, previous: number) => {
  if (current === 0 && previous === 0) return "0%";
  if (previous === 0) return current > 0 ? "No baseline last month" : "0%";
  const percentChange = ((current - previous) / previous) * 100;
  if (percentChange === 0) return "0%";
  return `${formatPercent(percentChange)}`;
};

const trendDirectionFromDelta = (current: number, previous: number): "up" | "warn" | "down" => {
  const delta = current - previous;
  if (delta > 0) return "up";
  if (delta < 0) return "down";
  return "warn";
};

const formatPendingVerificationTrend = (homeownerPending: number, tradesmanPending: number) => {
  if (homeownerPending === 0 && tradesmanPending === 0) return "Queue clear";
  if (homeownerPending === 0) return `${tradesmanPending} tradesman pending`;
  if (tradesmanPending === 0) return `${homeownerPending} homeowner pending`;
  return `${homeownerPending} homeowner, ${tradesmanPending} tradesman`;
};

const formatVerifiedTradesmanTrend = (verifiedCount: number, totalTradesmen: number) => {
  if (totalTradesmen === 0) return "No tradesmen yet";
  if (verifiedCount === totalTradesmen) return "All verified";
  return `${Math.round((verifiedCount / totalTradesmen) * 100)}% verified`;
};

const averageRating = (reviews: TradesmanReview[]) => {
  if (reviews.length === 0) return 0;
  const total = reviews.reduce((sum, review) => sum + review.rating, 0);
  return Math.round((total / reviews.length) * 10) / 10;
};

const formatRatingValue = (value: number) => value.toFixed(1);

const activityDot = (type: string) => {
  switch (type) {
    case "verification_approved":
    case "verification_restored":
    case "booking_completed":
      return "var(--success-solid)";
    case "verification_rejected":
    case "booking_cancelled":
      return "var(--danger-solid)";
    case "verification_archived":
    case "tradesperson_reverify":
    case "booking_under_review":
      return "var(--warning-solid)";
    default:
      return "var(--info-solid)";
  }
};

// ─────────────────────────────────────────────────────────────────
// MOCK DATA
// ─────────────────────────────────────────────────────────────────
const TRADESMEN_DATA: Tradesman[] = [
  { id: "t1", initials: "MR", color: "linear-gradient(135deg,#1560B0,#2E82D8)", name: "Marco Reyes",      email: "marco.r@gmail.com",   category: "⚡ Electrical",     license: "ELEC-2024-00847", credentialUrl: "", joined: "Jan 2025", jobs: 0,  status: "Pending"  },
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

const REPORTS_DATA: ReportEntry[] = [
  {
    id: "r1",
    targetType: "Tradesman",
    targetName: "Marco Reyes",
    targetEmail: "marco.r@gmail.com",
    reporterName: "Sofia Mendoza",
    reporterRole: "Homeowner",
    reason: "No-show appointment",
    details: "The booked repair schedule passed without any arrival or update from the tradesman.",
    status: "Open",
    submittedAt: "2026-03-29T09:30:00Z",
  },
  {
    id: "r2",
    targetType: "Homeowner",
    targetName: "Ben Torres",
    targetEmail: "bentorres@yahoo.com",
    reporterName: "Jake Cruz",
    reporterRole: "Tradesman",
    reason: "Unpaid completed job",
    details: "The service was completed but the payment marked in chat was not sent after follow-up.",
    status: "Reviewing",
    submittedAt: "2026-03-28T14:20:00Z",
  },
  {
    id: "r3",
    targetType: "Tradesman",
    targetName: "Ana Lim",
    targetEmail: "ana.lim@gmail.com",
    reporterName: "Maria Garcia",
    reporterRole: "Homeowner",
    reason: "Unprofessional conduct",
    details: "The homeowner reported rude behavior during an on-site visit and requested admin review.",
    status: "Resolved",
    submittedAt: "2026-03-26T07:15:00Z",
  },
  {
    id: "r4",
    targetType: "Homeowner",
    targetName: "Karl Santos",
    targetEmail: "karlsantos99@gmail.com",
    reporterName: "Pedro Villarta",
    reporterRole: "Tradesman",
    reason: "Repeated cancellation",
    details: "The project was cancelled multiple times after material preparation was already confirmed.",
    status: "Open",
    submittedAt: "2026-03-25T11:05:00Z",
  },
  {
    id: "r5",
    targetType: "Tradesman",
    targetName: "Ramon Dela Cruz",
    targetEmail: "ramon.dc@gmail.com",
    reporterName: "Liza Villanueva",
    reporterRole: "Homeowner",
    reason: "Quoted price dispute",
    details: "The final amount requested was higher than the estimate shown in the app conversation.",
    status: "Reviewing",
    submittedAt: "2026-03-24T17:40:00Z",
  },
];

const SAMPLE_TRADESMAN_REVIEW_TEMPLATES = [
  {
    reviewerName: "Sofia Mendoza",
    reviewerRole: "Homeowner" as const,
    rating: 5,
    jobType: "Electrical outlet repair",
    comment: "Arrived on time, explained the work clearly, and left the area clean after finishing the repair.",
    verifiedBooking: true,
  },
  {
    reviewerName: "Ben Torres",
    reviewerRole: "Homeowner" as const,
    rating: 4,
    jobType: "Leak inspection",
    comment: "The repair quality was solid and communication was smooth, though the visit started a little later than expected.",
    verifiedBooking: true,
  },
  {
    reviewerName: "Karl Santos",
    reviewerRole: "Homeowner" as const,
    rating: 5,
    jobType: "Aircon maintenance",
    comment: "Professional from start to finish and gave helpful maintenance tips after the service.",
    verifiedBooking: true,
  },
  {
    reviewerName: "Maria Garcia",
    reviewerRole: "Homeowner" as const,
    rating: 3,
    jobType: "Interior repainting",
    comment: "Work was completed well, but there were some delays in updates while materials were being sourced.",
    verifiedBooking: true,
  },
  {
    reviewerName: "Liza Villanueva",
    reviewerRole: "Homeowner" as const,
    rating: 4,
    jobType: "Appliance diagnosis",
    comment: "Very courteous and easy to talk to. I would book again for follow-up work.",
    verifiedBooking: true,
  },
  {
    reviewerName: "Jose Ramos",
    reviewerRole: "Homeowner" as const,
    rating: 5,
    jobType: "Bathroom fixture replacement",
    comment: "Fast turnaround and the finished installation looked neat and secure.",
    verifiedBooking: true,
  },
];

const SERVICE_BOOKINGS_DATA: ServiceBookingSlice[] = [
  { id: "electrical", label: "Electrical", count: 42, color: "#2348B8" },
  { id: "plumbing", label: "Plumbing", count: 35, color: "#17A88E" },
  { id: "hvac", label: "HVAC", count: 24, color: "#FF7A1A" },
  { id: "carpentry", label: "Carpentry", count: 18, color: "#8B5CF6" },
  { id: "painting", label: "Painting", count: 14, color: "#E25937" },
  { id: "appliance", label: "Appliance Repair", count: 20, color: "#0F766E" },
];

// ─────────────────────────────────────────────────────────────────
// SHARED MINI-COMPONENTS
// ─────────────────────────────────────────────────────────────────

// Avatar circle
const Avatar = ({ initials, color, size = 40 }: { initials: string; color: string; size?: number }) => (
  <div style={{
    width: size, height: size, borderRadius: size * 0.28,
    background: color, display: "flex", alignItems: "center", justifyContent: "center",
    fontSize: size * 0.33, fontWeight: 800, color: "var(--on-solid)", flexShrink: 0,
  }}>
    {initials}
  </div>
);

// Status badge
const Badge = ({ status }: { status: string }) => {
  const styles: Record<string, { bg: string; color: string; border: string }> = {
    Pending:  { bg: "var(--warning-bg)", color: "var(--warning-text)", border: "1px solid var(--warning-border)" },
    Verified: { bg: "var(--info-bg)", color: "var(--info-text)", border: "1px solid var(--info-border)"  },
    Approved: { bg: "var(--info-bg)", color: "var(--info-text)", border: "1px solid var(--info-border)"  },
    Active:   { bg: "var(--info-bg)", color: "var(--info-text)", border: "1px solid var(--success-border)"  },
    Inactive: { bg: "var(--danger-bg)", color: "var(--danger-text)", border: "1px solid var(--danger-border)"  },
    Rejected: { bg: "var(--danger-bg)", color: "var(--danger-text)", border: "1px solid var(--danger-border)"  },
    Suspended:{ bg: "var(--danger-bg)", color: "var(--danger-text)", border: "1px solid var(--danger-border)"  },
    Archived: { bg: "var(--neutral-bg)", color: "var(--neutral-text)", border: "1px solid var(--neutral-border)" },
    Open:     { bg: "var(--warning-bg)", color: "var(--warning-text)", border: "1px solid var(--warning-border)" },
    Reviewing:{ bg: "var(--info-bg)", color: "var(--info-text)", border: "1px solid var(--info-border)" },
    Resolved: { bg: "var(--success-bg)", color: "var(--success-text)", border: "1px solid var(--success-border)" },
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

const StarRating = ({ value, size = 14 }: { value: number; size?: number }) => (
  <div style={{ display: "inline-flex", alignItems: "center", gap: 3 }}>
    {Array.from({ length: 5 }, (_, index) => {
      const filled = value >= index + 1;
      return (
        <svg
          key={index}
          width={size}
          height={size}
          viewBox="0 0 24 24"
          fill={filled ? "var(--accent)" : "none"}
          stroke={filled ? "var(--accent)" : "var(--border)"}
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <polygon points="12 2 15.1 8.6 22 9.3 17 14.1 18.3 21 12 17.4 5.7 21 7 14.1 2 9.3 8.9 8.6 12 2" />
        </svg>
      );
    })}
  </div>
);

// Small button
const Btn = ({
  children, variant = "default", onClick, disabled,
}: {
  children: ReactNode; variant?: "approve" | "reject" | "view" | "default" | "navy";
  onClick?: () => void; disabled?: boolean;
}) => {
  const [hov, setHov] = useState(false);
  const base: Record<string, { bg: string; color: string; border: string; hovBg: string; hovColor: string }> = {
    approve: { bg: "var(--success-bg)", color: "var(--success-text)", border: "1.5px solid var(--success-border)",  hovBg: "var(--success-solid)", hovColor: "var(--on-solid)" },
    reject:  { bg: "var(--danger-bg)", color: "var(--danger-text)", border: "1.5px solid var(--danger-border)", hovBg: "var(--danger-solid)", hovColor: "var(--on-solid)" },
    view:    { bg: "var(--info-bg)", color: "var(--info-text-soft)", border: "1.5px solid var(--info-border)",  hovBg: "var(--info-solid)", hovColor: "var(--on-solid)" },
    navy:    { bg: "var(--info-bg)", color: "var(--info-text)", border: "1.5px solid var(--info-border)",  hovBg: "var(--info-solid)", hovColor: "var(--on-solid)" },
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
        boxShadow: "none",
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
          background: "var(--surface)",
          transform: checked ? "translateX(20px)" : "translateX(0px)",
          transition: "transform .2s",
        }}
      />
    </button>
  </div>
);

// Sidebar logo
function SidebarShield() {
  return (
    <img
      src="/fixit_logo.png"
      alt="Fix It logo"
      width={58}
      height={58}
      style={{
        objectFit: "contain",
        display: "block",
        flexShrink: 0,
        filter: "brightness(0) invert(1) drop-shadow(0 4px 10px rgba(255,255,255,0.16))",
      }}
    />
  );
}

// Toast component
const Toast = ({ msg, type, show }: { msg: string; type: ToastType; show: boolean }) => {
  const colors = { success: "var(--success-solid)", error: "var(--danger-solid)", info: "var(--info-solid)" };
  return (
    <div style={{
      position: "fixed", top: 20, left: "50%",
      transform: `translateX(-50%) translateY(${show ? "0" : "-90px"})`,
      background: colors[type], color: "var(--on-solid)",
      padding: "11px 20px", borderRadius: 8, fontSize: 13, fontWeight: 600,
      zIndex: 9999, display: "flex", alignItems: "center", gap: 8,
      boxShadow: "var(--elevated-shadow)",
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
  open, onClose, title, hero, rows, actions,
}: {
  open: boolean; onClose: () => void; title: string;
  hero?: ReactNode;
  rows: { label: string; value: string; highlight?: boolean }[];
  actions?: ReactNode;
}) => {
  if (!open) return null;
  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed", inset: 0, background: "var(--overlay)",
        backdropFilter: "blur(4px)", zIndex: 200,
        display: "flex", alignItems: "center", justifyContent: "center",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: "var(--surface)", borderRadius: 16, padding: 28,
          width: "100%", maxWidth: 440,
          boxShadow: "var(--elevated-shadow)",
          animation: "mIn .3s cubic-bezier(.16,1,.3,1)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 22 }}>
          <h3 style={{ fontSize: 18, fontWeight: 800, color: "var(--text)", margin: 0 }}>{title}</h3>
          <button onClick={onClose} style={{ width: 32, height: 32, borderRadius: 8, background: "var(--surface-2)", border: "1.5px solid var(--border)", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", color: "var(--muted)" }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
          </button>
        </div>
        {hero && (
          <div style={{ marginBottom: 18 }}>
            {hero}
          </div>
        )}
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
          fontFamily: "inherit", fontSize: 14, fontWeight: 800, color: "var(--on-solid)",
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
        background: "var(--overlay)",
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
          boxShadow: "var(--elevated-shadow)",
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
        position: "fixed", inset: 0, background: "var(--overlay)",
        backdropFilter: "blur(4px)", zIndex: 220,
        display: "flex", alignItems: "center", justifyContent: "center",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: "var(--surface)", borderRadius: 16, padding: 24,
          width: "100%", maxWidth: 640,
          boxShadow: "var(--elevated-shadow)",
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
              style={{ display: "block", width: "100%", height: 520, border: "none", borderRadius: 8, background: "var(--surface)" }}
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
          fontFamily: "inherit", fontSize: 14, fontWeight: 800, color: "var(--on-solid)",
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

const ProfileEditorModal = ({
  open,
  mode,
  saving,
  currentName,
  fullName,
  currentEmail,
  email,
  currentPassword,
  newPassword,
  confirmPassword,
  onClose,
  onChange,
  onSubmit,
}: {
  open: boolean;
  mode: ProfileEditorMode | null;
  saving: boolean;
  currentName: string;
  fullName: string;
  currentEmail: string;
  email: string;
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
  onClose: () => void;
  onChange: (patch: Partial<{
    fullName: string;
    email: string;
    currentPassword: string;
    newPassword: string;
    confirmPassword: string;
  }>) => void;
  onSubmit: () => void;
}) => {
  if (!open || !mode) return null;

  const config = {
    name: {
      title: "Update Name",
      subtitle: "Change the admin display name shown across the dashboard.",
      action: "Save Name",
    },
    email: {
      title: "Update Email",
      subtitle: "Change the admin login email used for this account.",
      action: "Save Email",
    },
    password: {
      title: "Update Password",
      subtitle: "Set a new password for the active admin account.",
      action: "Save Password",
    },
  }[mode];

  const inputStyle: React.CSSProperties = {
    width: "100%",
    padding: "12px 14px",
    background: "var(--surface-2)",
    border: "1.5px solid var(--border)",
    borderRadius: 10,
    fontFamily: "inherit",
    fontSize: 14,
    color: "var(--text)",
    outline: "none",
  };

  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed",
        inset: 0,
        background: "var(--overlay)",
        backdropFilter: "blur(4px)",
        zIndex: 230,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 16,
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: "var(--surface)",
          borderRadius: 18,
          width: "100%",
          maxWidth: 480,
          boxShadow: "var(--elevated-shadow)",
          border: "1px solid var(--border)",
          animation: "mIn .3s cubic-bezier(.16,1,.3,1)",
        }}
      >
        <div style={{ padding: "22px 24px 16px", borderBottom: "1px solid var(--border)" }}>
          <div style={{ fontSize: 18, fontWeight: 800, color: "var(--text)", marginBottom: 6 }}>{config.title}</div>
          <div style={{ fontSize: 13, color: "var(--muted)", lineHeight: 1.55 }}>{config.subtitle}</div>
        </div>

        <div style={{ padding: 24, display: "grid", gap: 16 }}>
          {mode === "name" && (
            <>
              <div>
                <div style={{ fontSize: 12, fontWeight: 700, color: "var(--muted)", marginBottom: 8 }}>Current Name</div>
                <div style={{ ...inputStyle, cursor: "default" }}>{currentName}</div>
              </div>
              <div>
                <label style={{ display: "block", fontSize: 12, fontWeight: 700, color: "var(--muted)", marginBottom: 8 }}>New Name</label>
                <input
                  type="text"
                  value={fullName}
                  onChange={(e) => onChange({ fullName: e.target.value })}
                  placeholder="Enter the admin name"
                  style={inputStyle}
                />
              </div>
            </>
          )}

          {mode === "email" && (
            <>
              <div>
                <div style={{ fontSize: 12, fontWeight: 700, color: "var(--muted)", marginBottom: 8 }}>Current Email</div>
                <div style={{ ...inputStyle, cursor: "default" }}>{currentEmail}</div>
              </div>
              <div>
                <label style={{ display: "block", fontSize: 12, fontWeight: 700, color: "var(--muted)", marginBottom: 8 }}>New Email</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => onChange({ email: e.target.value })}
                  placeholder="Enter a new admin email"
                  style={inputStyle}
                />
              </div>
              <div>
                <label style={{ display: "block", fontSize: 12, fontWeight: 700, color: "var(--muted)", marginBottom: 8 }}>Current Password</label>
                <input
                  type="password"
                  value={currentPassword}
                  onChange={(e) => onChange({ currentPassword: e.target.value })}
                  placeholder="Confirm your current password"
                  style={inputStyle}
                />
              </div>
            </>
          )}

          {mode === "password" && (
            <>
              <div>
                <label style={{ display: "block", fontSize: 12, fontWeight: 700, color: "var(--muted)", marginBottom: 8 }}>Current Password</label>
                <input
                  type="password"
                  value={currentPassword}
                  onChange={(e) => onChange({ currentPassword: e.target.value })}
                  placeholder="Enter your current password"
                  style={inputStyle}
                />
              </div>
              <div>
                <label style={{ display: "block", fontSize: 12, fontWeight: 700, color: "var(--muted)", marginBottom: 8 }}>New Password</label>
                <input
                  type="password"
                  value={newPassword}
                  onChange={(e) => onChange({ newPassword: e.target.value })}
                  placeholder="Use at least 8 characters"
                  style={inputStyle}
                />
              </div>
              <div>
                <label style={{ display: "block", fontSize: 12, fontWeight: 700, color: "var(--muted)", marginBottom: 8 }}>Confirm New Password</label>
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => onChange({ confirmPassword: e.target.value })}
                  placeholder="Re-enter the new password"
                  style={inputStyle}
                />
              </div>
            </>
          )}

        </div>

        <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, padding: "0 24px 24px" }}>
          <button
            onClick={onClose}
            disabled={saving}
            style={{
              padding: "10px 14px",
              background: "var(--surface-2)",
              border: "1.5px solid var(--border)",
              borderRadius: 8,
              fontFamily: "inherit",
              fontSize: 13,
              fontWeight: 700,
              color: "var(--text)",
              cursor: saving ? "not-allowed" : "pointer",
              opacity: saving ? 0.65 : 1,
            }}
          >
            Cancel
          </button>
          <Btn variant="navy" onClick={onSubmit} disabled={saving}>
            {saving ? "Saving..." : config.action}
          </Btn>
        </div>
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
}) => {
  const [filtersOpen, setFiltersOpen] = useState(false);
  const filterMenuRef = useRef<HTMLDivElement | null>(null);
  const activeFilterCount = filterValues.filter(Boolean).length;

  useEffect(() => {
    if (!filtersOpen) return;

    const handleClick = (event: MouseEvent) => {
      const target = event.target as Node;
      if (filterMenuRef.current?.contains(target)) return;
      setFiltersOpen(false);
    };

    const handleKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") setFiltersOpen(false);
    };

    document.addEventListener("mousedown", handleClick);
    document.addEventListener("keydown", handleKey);
    return () => {
      document.removeEventListener("mousedown", handleClick);
      document.removeEventListener("keydown", handleKey);
    };
  }, [filtersOpen]);

  return (
    <div style={{ padding: "14px 24px", borderBottom: "1px solid var(--border)", background: "var(--surface-2)", position: "relative", zIndex: 5 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 12, flexWrap: "nowrap" }}>
        <div style={{ flex: 1, minWidth: 0, display: "flex", alignItems: "center", gap: 8, padding: "9px 14px", background: "var(--surface)", border: "1.5px solid var(--border)", borderRadius: 8 }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>
          <input
            type="text"
            placeholder={placeholder}
            value={searchValue}
            onChange={(e) => onSearchChange(e.target.value)}
            style={{ border: "none", outline: "none", background: "transparent", fontFamily: "inherit", fontSize: 13, color: "var(--text)", width: "100%" }}
          />
        </div>

        <div ref={filterMenuRef} style={{ position: "relative", flexShrink: 0 }}>
          <button
            type="button"
            onClick={() => setFiltersOpen((prev) => !prev)}
            aria-label="Open filters"
            aria-expanded={filtersOpen}
            style={{
              width: 42,
              height: 42,
              borderRadius: 10,
              border: `1.5px solid ${filtersOpen ? "var(--accent)" : "var(--border)"}`,
              background: filtersOpen || activeFilterCount > 0 ? "var(--accent-soft)" : "var(--surface)",
              color: filtersOpen || activeFilterCount > 0 ? "var(--accent)" : "var(--muted)",
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              position: "relative",
              transition: "all .2s",
            }}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
              <line x1="5" y1="7" x2="19" y2="7" />
              <line x1="8" y1="12" x2="19" y2="12" />
              <line x1="11" y1="17" x2="19" y2="17" />
            </svg>
            {activeFilterCount > 0 && (
              <span style={{
                position: "absolute",
                top: -5,
                right: -5,
                minWidth: 18,
                height: 18,
                padding: "0 5px",
                borderRadius: 999,
                background: "var(--accent)",
                color: "var(--on-solid)",
                fontSize: 10,
                fontWeight: 800,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                border: "2px solid var(--surface-2)",
              }}>
                {activeFilterCount}
              </span>
            )}
          </button>

          {filtersOpen && (
            <div style={{
              position: "absolute",
              top: "calc(100% + 10px)",
              right: 0,
              zIndex: 30,
              width: 260,
              padding: 14,
              borderRadius: 14,
              background: "var(--surface)",
              border: "1.5px solid var(--border)",
              boxShadow: "var(--elevated-shadow)",
              display: "grid",
              gap: 10,
            }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12, marginBottom: 2 }}>
                <div style={{ fontSize: 13, fontWeight: 800, color: "var(--text)" }}>Filters</div>
                {activeFilterCount > 0 && (
                  <button
                    type="button"
                    onClick={() => {
                      filterValues.forEach((_, index) => onFilterChange(index, ""));
                    }}
                    style={{
                      border: "none",
                      background: "transparent",
                      color: "var(--accent)",
                      fontSize: 12,
                      fontWeight: 700,
                      fontFamily: "inherit",
                      cursor: "pointer",
                      padding: 0,
                    }}
                  >
                    Clear all
                  </button>
                )}
              </div>
              {filters.map((opts, i) => (
                <div key={i} style={{ display: "grid", gap: 6 }}>
                  <div style={{ fontSize: 11, fontWeight: 700, color: "var(--muted)", letterSpacing: "0.5px", textTransform: "uppercase" }}>
                    {opts[0]}
                  </div>
                  <select
                    value={filterValues[i] ?? ""}
                    onChange={(e) => onFilterChange(i, e.target.value)}
                    style={{ padding: "10px 12px", background: "var(--surface-2)", border: "1.5px solid var(--border)", borderRadius: 8, fontFamily: "inherit", fontSize: 13, fontWeight: 600, color: "var(--text)", outline: "none", cursor: "pointer", width: "100%" }}
                  >
                    {opts.map((o) => <option key={o} value={o === opts[0] ? "" : o}>{o}</option>)}
                  </select>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

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
  num: number | string; label: string; trend: string; trendType: "up" | "warn" | "down";
}) => {
  const [hov, setHov] = useState(false);
  const trendStyles = {
    up: {
      background: "var(--success-bg)",
      color: "var(--success-text)",
    },
    warn: {
      background: "var(--warning-bg)",
      color: "var(--warning-text)",
    },
    down: {
      background: "var(--danger-bg)",
      color: "var(--danger-text)",
    },
  }[trendType];
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
          background: trendStyles.background,
          color: trendStyles.color,
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
  style = {},
  bookings = [],
}: {
  style?: React.CSSProperties;
  bookings?: RequestAnalyticsBooking[];
}) => {
  const [range, setRange] = useState<AnalyticsRange>("month");
  const [hoveredPointIndex, setHoveredPointIndex] = useState<number | null>(null);
  const points = buildMergedRequestAnalyticsData(range, bookings);
  const hasData = points.some((point) => point.total > 0);
  const totalInRange = points.reduce((sum, point) => sum + point.total, 0);
  const completedCount = points.reduce((sum, point) => sum + point.completed, 0);
  const cancelledCount = points.reduce((sum, point) => sum + point.cancelled, 0);
  const averagePerBucket = (totalInRange / Math.max(points.length, 1)).toFixed(range === "today" ? 1 : 0);
  const peakPoint = points.reduce((best, point) => (point.total > best.total ? point : best), points[0]);
  const completionRate = totalInRange > 0 ? Math.round((completedCount / totalInRange) * 100) : 0;
  const maxValue = Math.max(...points.map((point) => Math.max(point.total, point.completed, point.cancelled)), 1);
  const chartWidth = 640;
  const chartHeight = 260;
  const padding = { top: 16, right: 16, bottom: 30, left: 32 };
  const innerWidth = chartWidth - padding.left - padding.right;
  const innerHeight = chartHeight - padding.top - padding.bottom;
  const denominator = Math.max(points.length - 1, 1);
  const yTicks = 4;
  const rangeLabel = range === "today" ? "Today" : range === "week" ? "This Week" : "This Month";
  const averageLabel = range === "today" ? "Avg / Hour" : "Avg / Day";
  const peakLabel = range === "today" ? "Peak Hour" : "Peak Day";
  const shouldShowTick = (index: number) => {
    if (range === "today") return index % 3 === 0 || index === points.length - 1;
    if (range === "week") return true;
    return index % 5 === 0 || index === points.length - 1;
  };
  const pointCoords = points.map((point, index) => ({
    ...point,
    x: padding.left + (index / denominator) * innerWidth,
    totalY: padding.top + innerHeight - (point.total / maxValue) * innerHeight,
    completedY: padding.top + innerHeight - (point.completed / maxValue) * innerHeight,
    cancelledY: padding.top + innerHeight - (point.cancelled / maxValue) * innerHeight,
  }));
  const linePath = (selector: (point: typeof pointCoords[number]) => number) =>
    pointCoords
      .map((point, index) => `${index === 0 ? "M" : "L"} ${point.x.toFixed(2)} ${selector(point).toFixed(2)}`)
      .join(" ");
  const totalLinePath = linePath((point) => point.totalY);
  const completedLinePath = linePath((point) => point.completedY);
  const cancelledLinePath = linePath((point) => point.cancelledY);
  const createAreaPath = (linePath: string) =>
    linePath
      ? `${linePath} L ${pointCoords[pointCoords.length - 1]?.x ?? padding.left} ${padding.top + innerHeight} L ${pointCoords[0]?.x ?? padding.left} ${padding.top + innerHeight} Z`
      : "";
  const totalAreaPath = createAreaPath(totalLinePath);
  const completedAreaPath = createAreaPath(completedLinePath);
  const cancelledAreaPath = createAreaPath(cancelledLinePath);
  const hoverStep = pointCoords.length > 1 ? pointCoords[1].x - pointCoords[0].x : innerWidth;
  const hoveredPoint = hoveredPointIndex !== null ? pointCoords[hoveredPointIndex] : null;
  const tooltipWidth = 148;
  const tooltipHeight = 76;
  const tooltipX = hoveredPoint
    ? Math.min(
        Math.max(hoveredPoint.x - tooltipWidth / 2, padding.left),
        chartWidth - padding.right - tooltipWidth
      )
    : 0;
  const tooltipAnchorY = hoveredPoint
    ? Math.min(hoveredPoint.totalY, hoveredPoint.completedY, hoveredPoint.cancelledY)
    : 0;
  const tooltipY = hoveredPoint
    ? Math.max(padding.top + 8, tooltipAnchorY - tooltipHeight - 14)
    : 0;

  useEffect(() => {
    setHoveredPointIndex(null);
  }, [range]);

  return (
    <Card style={{ marginBottom: 28, ...style }}>
      <CardHead
        title="Request Over Time"
        right={
          <div style={{ display: "inline-flex", padding: 4, borderRadius: 999, background: "var(--surface-2)", border: "1px solid var(--border)", gap: 4 }}>
            {[
              { key: "today", label: "Today" },
              { key: "week", label: "This Week" },
              { key: "month", label: "This Month" },
            ].map((option) => {
              const active = range === option.key;
              return (
                <button
                  key={option.key}
                  type="button"
                  onClick={() => setRange(option.key as AnalyticsRange)}
                  style={{
                    padding: "6px 12px",
                    borderRadius: 999,
                    border: "none",
                    background: active ? "var(--info-solid)" : "transparent",
                    color: active ? "var(--on-solid)" : "var(--muted)",
                    fontSize: 12,
                    fontWeight: 800,
                    cursor: "pointer",
                    fontFamily: "inherit",
                    transition: "all .2s",
                  }}
                >
                  {option.label}
                </button>
              );
            })}
          </div>
        }
      />
      <div style={{ padding: "24px", display: "grid", gridTemplateColumns: "minmax(0,1.35fr) minmax(260px,0.95fr)", gap: 24, alignItems: "stretch" }}>
        <div>
          {hasData ? (
            <div style={{ minHeight: 260, display: "grid", gap: 18, alignContent: "start" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
                {[
                  { label: "Total", color: "#1DA1FF" },
                  { label: "Completed", color: "#F59E0B" },
                  { label: "Cancelled", color: "#FF5E57" },
                ].map((item) => (
                  <div key={item.label} style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12, fontWeight: 700, color: "var(--muted)" }}>
                    <span style={{ width: 18, height: 10, borderRadius: 2, border: `2px solid ${item.color}`, background: "transparent" }} />
                    {item.label}
                  </div>
                ))}
              </div>
              <div style={{ border: "1px solid var(--chart-panel-border)", borderRadius: 18, background: "var(--chart-panel-bg)", padding: "16px 18px", boxShadow: "var(--chart-panel-shadow)" }}>
                <svg
                  viewBox={`0 0 ${chartWidth} ${chartHeight}`}
                  style={{ width: "100%", height: 280 }}
                  aria-label={`${rangeLabel} request analytics line chart`}
                  onMouseLeave={() => setHoveredPointIndex(null)}
                >
                  <defs>
                    <linearGradient id="request-total-fill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#1DA1FF" stopOpacity="0.32" />
                      <stop offset="100%" stopColor="#1DA1FF" stopOpacity="0.03" />
                    </linearGradient>
                    <linearGradient id="request-completed-fill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#F59E0B" stopOpacity="0.26" />
                      <stop offset="100%" stopColor="#F59E0B" stopOpacity="0.02" />
                    </linearGradient>
                    <linearGradient id="request-cancelled-fill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#FF5E57" stopOpacity="0.22" />
                      <stop offset="100%" stopColor="#FF5E57" stopOpacity="0.02" />
                    </linearGradient>
                  </defs>
                  {Array.from({ length: yTicks + 1 }, (_, index) => {
                    const value = (maxValue / yTicks) * index;
                    const y = padding.top + innerHeight - (value / maxValue) * innerHeight;
                    return (
                      <g key={index}>
                        <line
                          x1={padding.left}
                          x2={chartWidth - padding.right}
                          y1={y}
                          y2={y}
                          stroke="var(--chart-panel-grid)"
                          strokeDasharray="0"
                        />
                        <text x={padding.left - 10} y={y + 4} textAnchor="end" fill="var(--chart-panel-label)" fontSize="11" fontWeight="700">
                          {Math.round(value)}
                        </text>
                      </g>
                    );
                  })}
                  {pointCoords.map((point, index) => (
                    shouldShowTick(index) ? (
                      <line
                        key={`v-${point.key}`}
                        x1={point.x}
                        x2={point.x}
                        y1={padding.top}
                        y2={padding.top + innerHeight}
                        stroke="var(--chart-panel-grid-soft)"
                      />
                    ) : null
                  ))}
                  {totalAreaPath && <path d={totalAreaPath} fill="url(#request-total-fill)" />}
                  {completedAreaPath && <path d={completedAreaPath} fill="url(#request-completed-fill)" />}
                  {cancelledAreaPath && <path d={cancelledAreaPath} fill="url(#request-cancelled-fill)" />}
                  <path d={totalLinePath} fill="none" stroke="#1DA1FF" strokeWidth="3.25" strokeLinecap="round" strokeLinejoin="round" />
                  <path d={completedLinePath} fill="none" stroke="#F59E0B" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
                  <path d={cancelledLinePath} fill="none" stroke="#FF5E57" strokeWidth="2.8" strokeLinecap="round" strokeLinejoin="round" />
                  {pointCoords.map((point, index) => (
                    <rect
                      key={`hover-${point.key}`}
                      x={index === 0 ? padding.left : point.x - hoverStep / 2}
                      y={padding.top}
                      width={index === pointCoords.length - 1 ? chartWidth - padding.right - (point.x - hoverStep / 2) : hoverStep}
                      height={innerHeight}
                      fill="transparent"
                      onMouseEnter={() => setHoveredPointIndex(index)}
                    />
                  ))}
                  {hoveredPoint && (
                    <>
                      <line
                        x1={hoveredPoint.x}
                        x2={hoveredPoint.x}
                        y1={padding.top}
                        y2={padding.top + innerHeight}
                        stroke="var(--chart-panel-label)"
                        strokeDasharray="4 4"
                      />
                      <circle cx={hoveredPoint.x} cy={hoveredPoint.totalY} r="4.5" fill="#1DA1FF" stroke="var(--chart-panel-bg)" strokeWidth="2" />
                      <circle cx={hoveredPoint.x} cy={hoveredPoint.completedY} r="4.5" fill="#F59E0B" stroke="var(--chart-panel-bg)" strokeWidth="2" />
                      <circle cx={hoveredPoint.x} cy={hoveredPoint.cancelledY} r="4.5" fill="#FF5E57" stroke="var(--chart-panel-bg)" strokeWidth="2" />
                      <g>
                        <rect
                          x={tooltipX}
                          y={tooltipY}
                          width={tooltipWidth}
                          height={tooltipHeight}
                          rx="12"
                          fill="var(--surface)"
                          stroke="var(--border)"
                        />
                        <text x={tooltipX + 12} y={tooltipY + 18} fill="var(--text)" fontSize="12" fontWeight="800">
                          {hoveredPoint.label}
                        </text>
                        <text x={tooltipX + 12} y={tooltipY + 38} fill="#1DA1FF" fontSize="11" fontWeight="700">
                          Total: {hoveredPoint.total}
                        </text>
                        <text x={tooltipX + 12} y={tooltipY + 54} fill="#F59E0B" fontSize="11" fontWeight="700">
                          Completed: {hoveredPoint.completed}
                        </text>
                        <text x={tooltipX + 12} y={tooltipY + 70} fill="#FF5E57" fontSize="11" fontWeight="700">
                          Cancelled: {hoveredPoint.cancelled}
                        </text>
                      </g>
                    </>
                  )}
                  {pointCoords.map((point, index) => (
                    <g key={point.key}>
                      {shouldShowTick(index) && (
                        <text x={point.x} y={chartHeight - 6} textAnchor="middle" fill="var(--chart-panel-label-soft)" fontSize="11" fontWeight="700">
                          {point.label}
                        </text>
                      )}
                    </g>
                  ))}
                </svg>
              </div>
            </div>
          ) : (
            <div style={{ minHeight: 260, borderRadius: 16, border: "1.5px dashed var(--border)", background: "var(--surface-2)", display: "flex", alignItems: "center", justifyContent: "center", textAlign: "center", padding: "24px" }}>
              <div>
                <div style={{ fontSize: 15, fontWeight: 800, color: "var(--text)", marginBottom: 6 }}>No request data yet</div>
                <div style={{ fontSize: 12, color: "var(--muted)" }}>This chart is ready for request analytics once backend data is available.</div>
              </div>
            </div>
          )}
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(2, minmax(0,1fr))", gap: 12, alignContent: "start" }}>
          {[
            { label: `${rangeLabel} Total`, value: totalInRange, caption: "All requests", tone: "var(--text)", bg: "var(--info-bg)" },
            { label: "Completed", value: completedCount, caption: `Within ${rangeLabel.toLowerCase()}`, tone: "var(--success-text)", bg: "var(--success-bg)" },
            { label: "Cancelled", value: cancelledCount, caption: `Within ${rangeLabel.toLowerCase()}`, tone: "var(--danger-text)", bg: "var(--danger-bg)" },
            { label: peakLabel, value: peakPoint?.total ?? 0, caption: peakPoint?.total ? peakPoint.label : "No requests", tone: "var(--text)", bg: "var(--info-bg)" },
            { label: averageLabel, value: averagePerBucket, caption: "Smoothed request average", tone: "var(--text)", bg: "var(--info-bg)" },
            { label: "Completion Rate", value: `${completionRate}%`, caption: "Completed out of total requests", tone: "var(--success-text)", bg: "var(--success-bg)" },
          ].map((item) => (
            <div key={item.label} style={{ border: "1px solid var(--border)", borderRadius: 14, padding: "16px 18px", background: "var(--surface-2)", minWidth: 0 }}>
              <div style={{ display: "inline-flex", padding: "5px 10px", borderRadius: 999, background: item.bg, color: item.tone, fontSize: 11, fontWeight: 800, marginBottom: 12 }}>
                {item.label}
              </div>
              <div style={{ fontSize: 28, lineHeight: 1, fontWeight: 800, color: "var(--text)", letterSpacing: -1 }}>{item.value}</div>
              <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 10 }}>{item.caption}</div>
            </div>
          ))}
        </div>
      </div>
    </Card>
  );
};

const ServiceBookingsChart = ({ style = {} }: { style?: React.CSSProperties }) => {
  const totalBookings = SERVICE_BOOKINGS_DATA.reduce((sum, item) => sum + item.count, 0);
  const radius = 78;
  const circumference = 2 * Math.PI * radius;

  let offsetAccumulator = 0;
  const slices = SERVICE_BOOKINGS_DATA.map((item) => {
    const length = totalBookings > 0 ? (item.count / totalBookings) * circumference : 0;
    const slice = {
      ...item,
      length,
      offset: offsetAccumulator,
      percent: totalBookings > 0 ? Math.round((item.count / totalBookings) * 100) : 0,
    };
    offsetAccumulator += length;
    return slice;
  });
  const topSlice = slices.reduce((best, slice) => (slice.count > best.count ? slice : best), slices[0]);

  return (
    <Card style={{ marginBottom: 28, ...style }}>
      <CardHead
        title="Service Bookings"
        subtitle="Mock booking breakdown by field of work"
        right={<Pill color="navy">{totalBookings} bookings</Pill>}
      />
      <div style={{ padding: 24 }}>
        <div style={{ borderRadius: 20, background: "var(--chart-panel-bg)", border: "1px solid var(--chart-panel-border-soft)", padding: "22px 20px 16px", boxShadow: "var(--chart-panel-shadow)" }}>
          <div style={{ display: "grid", justifyItems: "center", gap: 18 }}>
            <div style={{ position: "relative", width: 220, height: 220, display: "grid", placeItems: "center" }}>
              <svg viewBox="0 0 220 220" width="220" height="220" aria-label="Service bookings donut chart">
                <defs>
                  {slices.map((slice, index) => (
                    <linearGradient key={slice.id} id={`booking-slice-${index}`} x1="0%" y1="0%" x2="100%" y2="100%">
                      <stop offset="0%" stopColor={slice.color} stopOpacity="1" />
                      <stop offset="100%" stopColor={slice.color} stopOpacity="0.78" />
                    </linearGradient>
                  ))}
                </defs>
                <circle cx="110" cy="110" r={radius} fill="none" stroke="var(--chart-panel-grid)" strokeWidth="18" />
                <circle cx="110" cy="110" r={radius + 11} fill="none" stroke="var(--chart-panel-text)" strokeWidth="1.2" />
                <circle cx="110" cy="110" r={radius - 11} fill="none" stroke="var(--chart-panel-grid-soft)" strokeWidth="1.2" />
                <g transform="rotate(-90 110 110)">
                  {slices.map((slice, index) => (
                    <circle
                      key={slice.id}
                      cx="110"
                      cy="110"
                      r={radius}
                      fill="none"
                      stroke={`url(#booking-slice-${index})`}
                      strokeWidth="18"
                      strokeLinecap="round"
                      strokeDasharray={`${slice.length} ${Math.max(circumference - slice.length, 0)}`}
                      strokeDashoffset={-slice.offset}
                    />
                  ))}
                </g>
              </svg>
              <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", textAlign: "center", padding: 40 }}>
                <div>
                  <div style={{ fontSize: 38, lineHeight: 1, fontWeight: 800, color: "var(--chart-panel-text)", letterSpacing: -1.4 }}>
                    {topSlice.percent}%
                  </div>
                  <div style={{ fontSize: 12, fontWeight: 800, color: "var(--chart-panel-text-soft)", marginTop: 8 }}>
                    Top Field
                  </div>
                  <div style={{ fontSize: 12, color: "var(--chart-panel-muted)", marginTop: 6 }}>
                    {topSlice.label}
                  </div>
                </div>
              </div>
            </div>

            <div style={{ width: "100%", display: "grid", gap: 10 }}>
              {slices.map((slice) => (
                <div key={slice.id} style={{ display: "grid", gridTemplateColumns: "auto minmax(0,1fr) auto auto", gap: 12, alignItems: "center", padding: "2px 0" }}>
                  <span style={{ width: 9, height: 9, borderRadius: "50%", border: `2px solid ${slice.color}`, background: "transparent", flexShrink: 0 }} />
                  <div style={{ minWidth: 0, fontSize: 14, fontWeight: 700, color: "var(--chart-panel-text-soft)" }}>
                    {slice.label}
                  </div>
                  <div style={{ fontSize: 13, fontWeight: 700, color: "var(--chart-panel-muted)", minWidth: 36, textAlign: "right" }}>
                    {slice.count}
                  </div>
                  <div style={{ fontSize: 13, fontWeight: 800, color: "var(--chart-panel-text)", minWidth: 42, textAlign: "right" }}>
                    {slice.percent}%
                  </div>
                </div>
              ))}
            </div>

            <div style={{ width: "100%", marginTop: 2, paddingTop: 14, borderTop: "1px solid var(--chart-panel-divider)", display: "grid", gridTemplateColumns: "repeat(3, minmax(0,1fr))", gap: 12 }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: "0.7px", textTransform: "uppercase", color: "var(--chart-panel-label)", marginBottom: 8 }}>Total</div>
                <div style={{ fontSize: 24, lineHeight: 1, fontWeight: 800, color: "var(--chart-panel-text)" }}>{totalBookings}</div>
              </div>
              <div>
                <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: "0.7px", textTransform: "uppercase", color: "var(--chart-panel-label)", marginBottom: 8 }}>Leading</div>
                <div style={{ fontSize: 15, lineHeight: 1.2, fontWeight: 800, color: "var(--chart-panel-text)" }}>{topSlice.label}</div>
              </div>
              <div>
                <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: "0.7px", textTransform: "uppercase", color: "var(--chart-panel-label)", marginBottom: 8 }}>Share</div>
                <div style={{ fontSize: 24, lineHeight: 1, fontWeight: 800, color: "var(--chart-panel-text)" }}>{topSlice.percent}%</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Card>
  );
};

const FailedBookingsChart = ({ style = {} }: { style?: React.CSSProperties }) => {
  const [range, setRange] = useState<AnalyticsRange>("month");
  const points = buildMockFailedBookingsData(range);
  const totalFailed = points.reduce((sum, point) => sum + point.totalFailed, 0);
  const homeownerCancelledTotal = points.reduce((sum, point) => sum + point.homeownerCancelled, 0);
  const tradesmanRejectedTotal = points.reduce((sum, point) => sum + point.tradesmanRejected, 0);
  const peakPoint = points.reduce((best, point) => (point.totalFailed > best.totalFailed ? point : best), points[0]);
  const averageFailed = (totalFailed / Math.max(points.length, 1)).toFixed(range === "today" ? 1 : 0);
  const maxValue = Math.max(...points.map((point) => Math.max(point.homeownerCancelled, point.tradesmanRejected, point.totalFailed)), 1);
  const chartWidth = 860;
  const chartHeight = 300;
  const padding = { top: 20, right: 24, bottom: 36, left: 38 };
  const innerWidth = chartWidth - padding.left - padding.right;
  const innerHeight = chartHeight - padding.top - padding.bottom;
  const groupWidth = innerWidth / Math.max(points.length, 1);
  const barWidth = Math.max(Math.min(groupWidth * 0.24, 22), 12);
  const rangeLabel = range === "today" ? "Today" : range === "week" ? "This Week" : "This Month";
  const peakLabel = range === "today" ? "Peak Hour" : "Peak Day";
  const averageLabel = range === "today" ? "Avg / Hour" : "Avg / Day";
  const shouldShowTick = (index: number) => {
    if (range === "today") return index % 2 === 0 || index === points.length - 1;
    if (range === "week") return true;
    return index % 2 === 0 || index === points.length - 1;
  };
  const pointCoords = points.map((point, index) => {
    const centerX = padding.left + ((index + 0.5) / points.length) * innerWidth;
    const homeownerHeight = (point.homeownerCancelled / maxValue) * innerHeight;
    const tradesmanHeight = (point.tradesmanRejected / maxValue) * innerHeight;
    const homeownerY = padding.top + innerHeight - homeownerHeight;
    const tradesmanY = padding.top + innerHeight - tradesmanHeight;
    return {
      ...point,
      centerX,
      homeownerX: centerX - barWidth - 4,
      tradesmanX: centerX + 4,
      homeownerHeight,
      tradesmanHeight,
      homeownerY,
      tradesmanY,
    };
  });

  return (
    <Card style={{ marginBottom: 28, ...style }}>
      <CardHead
        title="Failed Bookings"
        subtitle="Mock stack bar chart showing homeowner cancellations and tradesman rejections"
        right={
          <div style={{ display: "inline-flex", padding: 4, borderRadius: 999, background: "var(--surface-2)", border: "1px solid var(--border)", gap: 4 }}>
            {[
              { key: "today", label: "Today" },
              { key: "week", label: "This Week" },
              { key: "month", label: "This Month" },
            ].map((option) => {
              const active = range === option.key;
              return (
                <button
                  key={option.key}
                  type="button"
                  onClick={() => setRange(option.key as AnalyticsRange)}
                  style={{
                    padding: "6px 12px",
                    borderRadius: 999,
                    border: "none",
                    background: active ? "var(--info-solid)" : "transparent",
                    color: active ? "var(--on-solid)" : "var(--muted)",
                    fontSize: 12,
                    fontWeight: 800,
                    cursor: "pointer",
                    fontFamily: "inherit",
                    transition: "all .2s",
                  }}
                >
                  {option.label}
                </button>
              );
            })}
          </div>
        }
      />
      <div style={{ padding: 24, display: "grid", gap: 18 }}>
        <div style={{ display: "grid", gap: 16, alignContent: "start" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
            {[
              { label: "Homeowner Cancelled", color: "#F59E0B" },
              { label: "Tradesman Rejected", color: "#1DA1FF" },
            ].map((item) => (
              <div key={item.label} style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12, fontWeight: 700, color: "var(--muted)" }}>
                <span style={{ width: 18, height: 10, borderRadius: 2, background: item.color }} />
                {item.label}
              </div>
            ))}
          </div>

          <div style={{ border: "1px solid var(--chart-panel-border)", borderRadius: 18, background: "var(--chart-panel-bg)", padding: "16px 18px", boxShadow: "var(--chart-panel-shadow)" }}>
            <svg viewBox={`0 0 ${chartWidth} ${chartHeight}`} style={{ width: "100%", height: 310 }} aria-label={`${rangeLabel} failed bookings grouped bar chart`}>
              {Array.from({ length: 5 }, (_, index) => {
                const value = (maxValue / 4) * index;
                const y = padding.top + innerHeight - (value / maxValue) * innerHeight;
                return (
                  <g key={index}>
                    <line
                      x1={padding.left}
                      x2={chartWidth - padding.right}
                      y1={y}
                      y2={y}
                      stroke="var(--chart-panel-grid)"
                    />
                    <text x={padding.left - 10} y={y + 4} textAnchor="end" fill="var(--chart-panel-label)" fontSize="11" fontWeight="700">
                      {Math.round(value)}
                    </text>
                  </g>
                );
              })}

              {pointCoords.map((point, index) => (
                <g key={point.key}>
                  {shouldShowTick(index) && (
                    <line
                      x1={point.centerX}
                      x2={point.centerX}
                      y1={padding.top}
                      y2={padding.top + innerHeight}
                      stroke="var(--chart-panel-grid-soft)"
                    />
                  )}
                  <rect
                    x={point.homeownerX}
                    y={point.homeownerY}
                    width={barWidth}
                    height={Math.max(point.homeownerHeight, 0)}
                    rx={8}
                    fill="#F59E0B"
                  />
                  <rect
                    x={point.tradesmanX}
                    y={point.tradesmanY}
                    width={barWidth}
                    height={Math.max(point.tradesmanHeight, 0)}
                    rx={8}
                    fill="#1DA1FF"
                  />
                  <text
                    x={point.centerX}
                    y={Math.max(Math.min(point.homeownerY, point.tradesmanY) - 8, padding.top + 10)}
                    textAnchor="middle"
                    fill="var(--chart-panel-text)"
                    fontSize="11"
                    fontWeight="800"
                  >
                    {point.totalFailed}
                  </text>
                  {shouldShowTick(index) && (
                    <text x={point.centerX} y={chartHeight - 8} textAnchor="middle" fill="var(--chart-panel-label-soft)" fontSize="11" fontWeight="700">
                      {point.label}
                    </text>
                  )}
                </g>
              ))}
            </svg>
          </div>
        </div>

        <div style={{ border: "1px solid var(--chart-panel-border-soft)", borderRadius: 18, background: "var(--chart-panel-bg)", boxShadow: "var(--chart-panel-shadow)", padding: "16px 18px" }}>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, minmax(0,1fr))", gap: 18, alignItems: "center" }}>
            <div style={{ display: "grid", gridTemplateColumns: "56px minmax(0,1fr)", gap: 14, alignItems: "center" }}>
              <div style={{ width: 56, height: 56, borderRadius: "50%", border: "6px solid #F59E0B", borderRightColor: "var(--chart-panel-grid)", borderBottomColor: "var(--chart-panel-grid)", transform: "rotate(-35deg)" }} />
              <div>
                <div style={{ fontSize: 12, fontWeight: 800, color: "var(--chart-panel-text-soft)", marginBottom: 6 }}>Homeowner Cancelled</div>
                <div style={{ fontSize: 20, lineHeight: 1, fontWeight: 800, color: "var(--chart-panel-text)" }}>{homeownerCancelledTotal}</div>
                <div style={{ fontSize: 12, color: "var(--chart-panel-muted)", marginTop: 8 }}>{rangeLabel}</div>
              </div>
            </div>

            <div style={{ height: "100%", width: 1, justifySelf: "center", background: "var(--chart-panel-divider)" }} />

            <div style={{ display: "grid", gridTemplateColumns: "56px minmax(0,1fr)", gap: 14, alignItems: "center" }}>
              <div style={{ width: 56, height: 56, borderRadius: "50%", border: "6px solid #1DA1FF", borderRightColor: "var(--chart-panel-grid)", borderBottomColor: "var(--chart-panel-grid)", transform: "rotate(-25deg)" }} />
              <div>
                <div style={{ fontSize: 12, fontWeight: 800, color: "var(--chart-panel-text-soft)", marginBottom: 6 }}>Tradesman Rejected</div>
                <div style={{ fontSize: 20, lineHeight: 1, fontWeight: 800, color: "var(--chart-panel-text)" }}>{tradesmanRejectedTotal}</div>
                <div style={{ fontSize: 12, color: "var(--chart-panel-muted)", marginTop: 8 }}>{rangeLabel}</div>
              </div>
            </div>
          </div>

          <div style={{ marginTop: 16, paddingTop: 14, borderTop: "1px solid var(--chart-panel-divider)", display: "grid", gridTemplateColumns: "repeat(3, minmax(0,1fr))", gap: 14 }}>
            <div>
              <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: "0.7px", textTransform: "uppercase", color: "var(--chart-panel-label)", marginBottom: 8 }}>Failed Bookings</div>
              <div style={{ fontSize: 24, lineHeight: 1, fontWeight: 800, color: "var(--chart-panel-text)" }}>{totalFailed}</div>
            </div>
            <div>
              <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: "0.7px", textTransform: "uppercase", color: "var(--chart-panel-label)", marginBottom: 8 }}>{peakLabel}</div>
              <div style={{ fontSize: 20, lineHeight: 1, fontWeight: 800, color: "var(--chart-panel-text)" }}>{peakPoint?.totalFailed ?? 0}</div>
              <div style={{ fontSize: 12, color: "var(--chart-panel-muted)", marginTop: 8 }}>{peakPoint?.label ?? "No failed bookings"}</div>
            </div>
            <div>
              <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: "0.7px", textTransform: "uppercase", color: "var(--chart-panel-label)", marginBottom: 8 }}>{averageLabel}</div>
              <div style={{ fontSize: 24, lineHeight: 1, fontWeight: 800, color: "var(--chart-panel-text)" }}>{averageFailed}</div>
              <div style={{ fontSize: 12, color: "var(--chart-panel-muted)", marginTop: 8 }}>Average failed bookings</div>
            </div>
          </div>
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
        <Btn variant="view" onClick={onView}>{icons.license} View Details</Btn>
        <Btn variant="reject" onClick={onArchive}>{icons.x} Archive</Btn>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────
// SIDEBAR NAV ITEM
// ─────────────────────────────────────────────────────────────────
const NavItem = ({
  icon, label, active, badge, onClick, collapsed = false,
}: {
  icon: ReactNode; label: string; active?: boolean; badge?: number; onClick: () => void; collapsed?: boolean;
}) => {
  const [hov, setHov] = useState(false);
  return (
    <button
      title={label}
      onClick={onClick}
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        display: "flex", alignItems: "center", justifyContent: collapsed ? "center" : "flex-start", gap: collapsed ? 0 : 14,
        padding: collapsed ? "12px 0" : "12px 14px", borderRadius: 14, width: "100%",
        fontFamily: "inherit", border: "none", textAlign: "left", cursor: "pointer",
        marginBottom: 6,
        background: active ? "var(--sidebar-accent)" : hov ? "var(--sidebar-hover)" : "transparent",
        boxShadow: active ? "inset 0 0 0 1px var(--sidebar-divider), 0 10px 22px rgba(12,24,54,.18)" : "none",
        transition: "all .2s ease",
        position: "relative",
      }}
    >
      <span style={{ color: active ? "var(--sidebar-active-text)" : "var(--sidebar-muted)", flexShrink: 0, display: "flex" }}>
        {icon}
      </span>
      {!collapsed && (
        <span style={{ fontSize: 14, fontWeight: 700, color: active ? "var(--sidebar-active-text)" : "var(--sidebar-text)", flex: 1 }}>
          {label}
        </span>
      )}
      {badge !== undefined && badge > 0 && (
        <span style={{
          background: active ? "var(--sidebar-badge-active-bg)" : "var(--accent)",
          color: active ? "var(--sidebar-active-text)" : "var(--on-solid)",
          fontSize: collapsed ? 9 : 11,
          fontWeight: 800,
          padding: collapsed ? "0 4px" : "4px 8px",
          borderRadius: 999,
          minWidth: collapsed ? 16 : 24,
          height: collapsed ? 16 : "auto",
          textAlign: "center",
          position: collapsed ? "absolute" : "static",
          top: collapsed ? 6 : undefined,
          right: collapsed ? 8 : undefined,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}>
          {collapsed && badge > 9 ? "9+" : badge}
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
  flag:    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 22V4"/><path d="M4 4h11l-1.5 4L15 12H4"/></svg>,
  settings:<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>,
  star:    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.1 8.6 22 9.3 17 14.1 18.3 21 12 17.4 5.7 21 7 14.1 2 9.3 8.9 8.6 12 2"/></svg>,
  menu:    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><line x1="4" y1="7" x2="20" y2="7"/><line x1="4" y1="12" x2="20" y2="12"/><line x1="4" y1="17" x2="20" y2="17"/></svg>,
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
  const [adminProfile, setAdminProfile] = useState<AdminProfile | null>(null);
  const [profileLoading, setProfileLoading] = useState(false);
  const [profileEditor, setProfileEditor] = useState<{
    open: boolean;
    mode: ProfileEditorMode | null;
    fullName: string;
    email: string;
    currentPassword: string;
    newPassword: string;
    confirmPassword: string;
    saving: boolean;
  }>({
    open: false,
    mode: null,
    fullName: "",
    email: "",
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
    saving: false,
  });
  const [authToken, setAuthToken] = useState<string | null>(null);
  const [isDark, setIsDark] = useState(false);
  const [toast, setToast]           = useState({ show: false, msg: "", type: "success" as ToastType });
  const [modal, setModal]           = useState<{ open: boolean; title: string; hero?: ReactNode; rows: { label: string; value: string; highlight?: boolean }[]; actions?: ReactNode }>({ open: false, title: "", rows: [] });
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
  const [searchReports, setSearchReports] = useState("");
  const [searchRatings, setSearchRatings] = useState("");
  const [searchDashboard, setSearchDashboard] = useState("");
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [selectedRatingsTradesmanId, setSelectedRatingsTradesmanId] = useState("");
  const [selectedReviewStarFilter, setSelectedReviewStarFilter] = useState("");
  const [showArchivedOnly, setShowArchivedOnly] = useState(false);
  const [verificationFilters, setVerificationFilters] = useState<string[]>(["", ""]);
  const [tradesmenFilters, setTradesmenFilters] = useState<string[]>(["", ""]);
  const [homeownerFilters, setHomeownerFilters] = useState<string[]>(["", ""]);
  const [ratingsFilters, setRatingsFilters] = useState<string[]>(["", ""]);
  const [reportStatusFilter, setReportStatusFilter] = useState("");
  const [reportTab, setReportTab] = useState<ReportTab>("all");
  const [activity, setActivity] = useState<ActivityEntry[]>([]);
  const [requestAnalyticsBookings, setRequestAnalyticsBookings] = useState<RequestAnalyticsBooking[]>([]);
  const [bellOpen, setBellOpen] = useState(false);
  const bellButtonRef = useRef<HTMLButtonElement | null>(null);
  const bellPanelRef = useRef<HTMLDivElement | null>(null);
  const reports = REPORTS_DATA;

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
        "--bg": "#071225",
        "--surface": "#0D1730",
        "--surface-2": "#101E3F",
        "--border": "#20335B",
        "--text": "#EEF4FF",
        "--muted": "#9BACCC",
        "--shadow": "0 1px 3px rgba(0,0,0,.35)",
        "--elevated-shadow": "0 12px 40px rgba(15,25,35,.2)",
        "--overlay": "rgba(15,25,35,.5)",
        "--sidebar": "#102A72",
        "--sidebar-accent": "#FF7A1A",
        "--sidebar-text": "#F7FAFF",
        "--sidebar-muted": "rgba(228,237,255,0.78)",
        "--sidebar-section": "rgba(228,237,255,0.58)",
        "--sidebar-divider": "rgba(255,153,82,0.38)",
        "--sidebar-brand": "#FFFFFF",
        "--sidebar-active-text": "#FFFFFF",
        "--sidebar-brand-muted": "rgba(228,237,255,0.84)",
        "--sidebar-brand-soft": "rgba(255,255,255,0.16)",
        "--sidebar-brand-soft-2": "rgba(255,255,255,0.12)",
        "--sidebar-badge-active-bg": "rgba(255,255,255,0.18)",
        "--sidebar-edge": "rgba(3,8,22,0.52)",
        "--sidebar-panel-shadow": "14px 0 36px rgba(2,8,24,0.45)",
        "--sidebar-signout-bg": "rgba(255,255,255,0.08)",
        "--sidebar-signout-border": "rgba(255,255,255,0.14)",
        "--sidebar-signout-text": "#FFE3D5",
        "--sidebar-signout-hover-bg": "#FF7A1A",
        "--sidebar-signout-hover-text": "#FFFFFF",
        "--table-head": "#0F172A",
        "--accent": "#FF7A1A",
        "--accent-hover": "#FF9443",
        "--accent-soft": "rgba(255,122,26,0.18)",
        "--success-bg": "rgba(34,197,94,0.16)",
        "--success-text": "#6EE7B7",
        "--success-border": "rgba(34,197,94,0.35)",
        "--success-solid": "#22C55E",
        "--warning-bg": "rgba(255,122,26,0.18)",
        "--warning-text": "#FFB37A",
        "--warning-border": "rgba(255,122,26,0.35)",
        "--warning-solid": "#FF7A1A",
        "--danger-bg": "rgba(239,68,68,0.16)",
        "--danger-text": "#FCA5A5",
        "--danger-border": "rgba(239,68,68,0.35)",
        "--danger-solid": "#EF4444",
        "--info-bg": "rgba(96,165,250,0.18)",
        "--info-text": "#C7DBFF",
        "--info-border": "rgba(96,165,250,0.32)",
        "--info-solid": "#4A7CFF",
        "--neutral-bg": "rgba(148,163,184,0.18)",
        "--neutral-text": "#CBD5E1",
        "--neutral-border": "rgba(148,163,184,0.35)",
        "--neutral-solid": "#94A3B8",
        "--row-hover": "rgba(148,163,184,0.12)",
        "--chart-panel-bg": "#10181F",
        "--chart-panel-border": "rgba(15,23,32,0.24)",
        "--chart-panel-shadow": "inset 0 1px 0 rgba(255,255,255,0.02)",
        "--chart-panel-grid": "rgba(255,255,255,0.06)",
        "--chart-panel-grid-soft": "rgba(255,255,255,0.03)",
        "--chart-panel-label": "rgba(203,213,225,0.48)",
        "--chart-panel-label-soft": "rgba(203,213,225,0.46)",
        "--chart-panel-text": "#F8FAFC",
        "--chart-panel-text-soft": "rgba(226,232,240,0.84)",
        "--chart-panel-muted": "rgba(203,213,225,0.58)",
        "--chart-panel-border-soft": "rgba(255,255,255,0.05)",
        "--chart-panel-divider": "rgba(255,255,255,0.06)",
        "--primary-bg": "#2348B8",
        "--primary-bg-hover": "#2D56CF",
        "--sidebar-hover": "rgba(255,255,255,0.08)",
        "--on-solid": "#FFFFFF",
        "--scrollbar": "#475569",
        "--scrollbar-hover": "#64748B",
      }
    : {
        "--bg": "#F3F7FF",
        "--surface": "#FFFFFF",
        "--surface-2": "#EEF4FF",
        "--border": "#D6E2FF",
        "--text": "#0F1923",
        "--muted": "#8B97AE",
        "--shadow": "0 1px 3px rgba(15,25,35,.06)",
        "--elevated-shadow": "0 12px 40px rgba(15,25,35,.14)",
        "--overlay": "rgba(15,25,35,.38)",
        "--sidebar": "#2348B8",
        "--sidebar-accent": "#FF7A1A",
        "--sidebar-text": "#F7FAFF",
        "--sidebar-muted": "rgba(228,237,255,0.78)",
        "--sidebar-section": "rgba(228,237,255,0.58)",
        "--sidebar-divider": "rgba(255,153,82,0.36)",
        "--sidebar-brand": "#FFFFFF",
        "--sidebar-active-text": "#FFFFFF",
        "--sidebar-brand-muted": "rgba(228,237,255,0.84)",
        "--sidebar-brand-soft": "rgba(255,255,255,0.16)",
        "--sidebar-brand-soft-2": "rgba(255,255,255,0.12)",
        "--sidebar-badge-active-bg": "rgba(255,255,255,0.18)",
        "--sidebar-edge": "rgba(13,25,58,0.22)",
        "--sidebar-panel-shadow": "14px 0 32px rgba(16,32,86,0.16)",
        "--sidebar-signout-bg": "rgba(255,255,255,0.96)",
        "--sidebar-signout-border": "rgba(255,255,255,0.45)",
        "--sidebar-signout-text": "#E25937",
        "--sidebar-signout-hover-bg": "#FFF1EA",
        "--sidebar-signout-hover-text": "#E25937",
        "--table-head": "#F6F9FF",
        "--accent": "#FF7A1A",
        "--accent-hover": "#FF9443",
        "--accent-soft": "#FFF0E3",
        "--success-bg": "#E6F5EE",
        "--success-text": "#1A7A4A",
        "--success-border": "rgba(26,122,74,0.2)",
        "--success-solid": "#1A7A4A",
        "--warning-bg": "#FFF1E4",
        "--warning-text": "#D96A0D",
        "--warning-border": "rgba(255,122,26,0.24)",
        "--warning-solid": "#FF7A1A",
        "--danger-bg": "#FFF0F1",
        "--danger-text": "#DC3545",
        "--danger-border": "rgba(220,53,69,0.2)",
        "--danger-solid": "#DC3545",
        "--info-bg": "#E8F0FF",
        "--info-text": "#2348B8",
        "--info-border": "rgba(35,72,184,0.18)",
        "--info-solid": "#2348B8",
        "--neutral-bg": "#EEF4FF",
        "--neutral-text": "#4A5568",
        "--neutral-border": "rgba(74,85,104,0.25)",
        "--neutral-solid": "#4A5568",
        "--row-hover": "#F7FAFF",
        "--chart-panel-bg": "#F8FBFF",
        "--chart-panel-border": "rgba(35,72,184,0.12)",
        "--chart-panel-shadow": "inset 0 1px 0 rgba(255,255,255,0.7)",
        "--chart-panel-grid": "rgba(35,72,184,0.10)",
        "--chart-panel-grid-soft": "rgba(35,72,184,0.06)",
        "--chart-panel-label": "rgba(74,85,104,0.7)",
        "--chart-panel-label-soft": "rgba(74,85,104,0.62)",
        "--chart-panel-text": "#0F1923",
        "--chart-panel-text-soft": "#23415F",
        "--chart-panel-muted": "#6B7A90",
        "--chart-panel-border-soft": "rgba(35,72,184,0.1)",
        "--chart-panel-divider": "rgba(35,72,184,0.08)",
        "--primary-bg": "#2348B8",
        "--primary-bg-hover": "#2E56CF",
        "--sidebar-hover": "rgba(255,255,255,0.1)",
        "--on-solid": "#FFFFFF",
        "--scrollbar": "#64748B",
        "--scrollbar-hover": "#94A3B8",
      };

  const pendingCount  = verifications.filter((v) => v.status === "pending").length;
  const archivedCount = verifications.filter((v) => v.status === "archived").length;
  const verifiedCount = tradesmen.filter((t) => t.status === "Verified").length;
  const pendingHomeownerIds = homeowners.filter((h) => h.idStatus === "Pending").length;
  const notificationCount = activity.length;
  const openReportsCount = reports.filter((report) => report.status !== "Resolved").length;
  const userGrowthData = buildUserGrowthData(homeowners, tradesmen);
  const latestGrowthPoint = userGrowthData[userGrowthData.length - 1];
  const previousGrowthPoint = userGrowthData[userGrowthData.length - 2];
  const pendingHomeownerVerifications = verifications.filter((v) => v.status === "pending" && v.type === "homeowner_id").length;
  const pendingTradesmanVerifications = verifications.filter((v) => v.status === "pending" && v.type === "tradesperson_license").length;
  const homeownerTrend = formatMonthlyTrend(latestGrowthPoint?.homeowners ?? 0, previousGrowthPoint?.homeowners ?? 0);
  const tradesmanTrend = formatMonthlyTrend(latestGrowthPoint?.tradesmen ?? 0, previousGrowthPoint?.tradesmen ?? 0);
  const pendingTrend = formatPendingVerificationTrend(pendingHomeownerVerifications, pendingTradesmanVerifications);
  const verifiedTradesmanTrend = formatVerifiedTradesmanTrend(verifiedCount, tradesmen.length);
  const homeownerTrendType = trendDirectionFromDelta(latestGrowthPoint?.homeowners ?? 0, previousGrowthPoint?.homeowners ?? 0);
  const tradesmanTrendType = trendDirectionFromDelta(latestGrowthPoint?.tradesmen ?? 0, previousGrowthPoint?.tradesmen ?? 0);

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

  const filteredVerifications = sortVerifications(
    baseVerifications.filter((v) => {
      const statusLabel = toTitle(v.status);
      const typeLabel = verificationTypeLabel(v.type);
      return (
        matchesQuery(searchVerification, [v.userId, v.id, statusLabel, typeLabel, getVerificationUserName(v)]) &&
        matchesExactFilter(statusFilter, statusLabel) &&
        matchesExactFilter(verificationFilters[1] ?? "", typeLabel)
      );
    })
  );

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

  const filteredReports = reports.filter((report) => {
    const matchesTab =
      reportTab === "all" ||
      (reportTab === "homeowner" && report.targetType === "Homeowner") ||
      (reportTab === "tradesman" && report.targetType === "Tradesman");

    return (
      matchesTab &&
      matchesQuery(searchReports, [
        report.targetName,
        report.targetEmail,
        report.reporterName,
        report.reporterRole,
        report.reason,
        report.details,
        report.status,
        report.id,
      ]) &&
      matchesExactFilter(reportStatusFilter, report.status)
    );
  });

  const ratingsSourceTradesmen = tradesmen.length > 0 ? tradesmen : TRADESMEN_DATA;
  const ratingsReviews: TradesmanReview[] = ratingsSourceTradesmen.flatMap((tradesman, tradesmanIndex) =>
    Array.from({ length: 3 }, (_, reviewIndex) => {
      const template = SAMPLE_TRADESMAN_REVIEW_TEMPLATES[
        (tradesmanIndex * 3 + reviewIndex) % SAMPLE_TRADESMAN_REVIEW_TEMPLATES.length
      ];
      const submittedAt = new Date(
        Date.now() - (tradesmanIndex * 3 + reviewIndex + 1) * 24 * 60 * 60 * 1000
      ).toISOString();
      return {
        id: `rating-${tradesman.id || tradesmanIndex}-${reviewIndex}`,
        tradesmanId: tradesman.id,
        tradesmanEmail: tradesman.email,
        tradesmanName: tradesman.name,
        reviewerName: template.reviewerName,
        reviewerRole: template.reviewerRole,
        rating: template.rating,
        jobType: template.jobType,
        comment: template.comment,
        submittedAt,
        verifiedBooking: template.verifiedBooking,
      };
    })
  );
  const totalRatingsCount = ratingsReviews.length;

  const tradesmanRatings = ratingsSourceTradesmen.map((tradesman) => {
    const reviews = ratingsReviews.filter(
      (review) =>
        review.tradesmanId === tradesman.id ||
        review.tradesmanEmail.toLowerCase() === tradesman.email.toLowerCase()
    );
    const average = averageRating(reviews);
    const fiveStarCount = reviews.filter((review) => review.rating === 5).length;
    const recommendationRate = reviews.length > 0 ? Math.round((reviews.filter((review) => review.rating >= 4).length / reviews.length) * 100) : 0;
    return {
      tradesman,
      reviews,
      average,
      fiveStarCount,
      recommendationRate,
    };
  });

  const filteredTradesmanRatings = tradesmanRatings.filter(({ tradesman, reviews, average }) => {
    const matchesSearch =
      !searchRatings.trim() ||
      matchesQuery(searchRatings, [tradesman.name, tradesman.email, tradesman.category, tradesman.license, tradesman.status]);

    const matchesCategory = matchesLooseFilter(ratingsFilters[0] ?? "", tradesman.category);
    const minimumRating =
       ratingsFilters[1] === "4+ Stars"
         ? 4
          : ratingsFilters[1] === "4.5+ Stars"
            ? 4.5
            : ratingsFilters[1] === "5 Stars"
              ? 5
              : 0;
    const matchesMinimumRating = !minimumRating || average >= minimumRating;

    return matchesSearch && matchesCategory && matchesMinimumRating;
  });

  const selectedTradesmanRating =
    filteredTradesmanRatings.find(({ tradesman }) => tradesman.id === selectedRatingsTradesmanId);

  useEffect(() => {
    if (
      selectedRatingsTradesmanId &&
      !filteredTradesmanRatings.some(({ tradesman }) => tradesman.id === selectedRatingsTradesmanId)
    ) {
      setSelectedRatingsTradesmanId("");
    }
  }, [filteredTradesmanRatings, selectedRatingsTradesmanId]);

  useEffect(() => {
    setSelectedReviewStarFilter("");
  }, [selectedRatingsTradesmanId]);

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

  const loadAdminProfile = async () => {
    if (!authToken) return;
    setProfileLoading(true);
    try {
      const res = await fetch(`${apiBase}/api/profile/me`, {
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }
        showToast("Failed to load admin profile.", "error");
        return;
      }

      const data = await res.json();
      const user = data?.user ?? {};
      setAdminProfile({
        id: String(user.id ?? user.ID ?? "—"),
        fullName: String(user.full_name ?? user.FullName ?? "").trim(),
        email: String(user.email ?? user.Email ?? "admin@fixit.com"),
        role: String(user.role ?? user.Role ?? "admin"),
        isActive: Boolean(user.is_active ?? user.IsActive ?? true),
        updatedAt: user.updated_at ?? user.UpdatedAt,
      });
    } catch {
      showToast("Failed to load admin profile.", "error");
    } finally {
      setProfileLoading(false);
    }
  };

  const openProfileEditor = (mode: ProfileEditorMode) => {
    setProfileEditor({
      open: true,
      mode,
      fullName: mode === "name" ? adminProfile?.fullName ?? "" : "",
      email: mode === "email" ? adminProfile?.email ?? "" : "",
      currentPassword: "",
      newPassword: "",
      confirmPassword: "",
      saving: false,
    });
  };

  const closeProfileEditor = () => {
    setProfileEditor((prev) => (prev.saving ? prev : {
      open: false,
      mode: null,
      fullName: "",
      email: "",
      currentPassword: "",
      newPassword: "",
      confirmPassword: "",
      saving: false,
    }));
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

  const loadActivity = async (silent = false) => {
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
        if (!silent) showToast("Failed to load activity.", "error");
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
      if (!silent) showToast("Failed to load activity.", "error");
    }
  };

  const loadRequestAnalyticsBookings = async (silent = false) => {
    if (!authToken) return;
    try {
      const res = await fetch(`${apiBase}/api/bookings`, {
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }
        if (!silent) showToast("Failed to load request analytics.", "error");
        return;
      }

      const data = await res.json();
      const list = Array.isArray(data)
        ? data
        : Array.isArray(data?.bookings)
          ? data.bookings
          : [];
      const mapped = list.map((booking) => ({
        id: String(booking.id ?? booking.ID ?? ""),
        status: String(booking.status ?? booking.Status ?? ""),
        createdAt: booking.created_at ?? booking.CreatedAt,
        updatedAt: booking.updated_at ?? booking.UpdatedAt,
        completedAt: booking.completed_at ?? booking.CompletedAt,
      })) as RequestAnalyticsBooking[];
      setRequestAnalyticsBookings(mapped);
    } catch {
      if (!silent) showToast("Failed to load request analytics.", "error");
    }
  };

  useEffect(() => {
    if (!authToken) return;
    loadUsers();
    loadActivity();
    loadRequestAnalyticsBookings();
    loadAdminProfile();
    const intervalId = window.setInterval(() => {
      loadActivity(true);
      loadRequestAnalyticsBookings(true);
    }, 15000);
    return () => window.clearInterval(intervalId);
  }, [authToken, apiBase, router]);

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
      setTradesmen((prev) => prev.map((t) => (t.id === id ? { ...t, status: "Suspended" } : t)));
      showToast(`${name} suspended`, "error");
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
      open: true,
      title: "Homeowner Details",
      hero: (
        <div style={{ display: "flex", alignItems: "center", gap: 14, padding: "2px 0 6px" }}>
          <Avatar initials={h.initials} color={h.color} size={52} />
          <div style={{ minWidth: 0, flex: 1 }}>
            <div style={{ fontSize: 17, fontWeight: 800, color: "var(--text)" }}>{h.name}</div>
            <div style={{ fontSize: 13, color: "var(--muted)", marginTop: 3, overflowWrap: "anywhere", wordBreak: "break-word" }}>{h.email}</div>
          </div>
        </div>
      ),
      rows: [
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
      open: true,
      title: "Tradesman Details",
      hero: (
        <div style={{ display: "flex", alignItems: "center", gap: 14, padding: "2px 0 6px" }}>
          <Avatar initials={t.initials} color={t.color} size={52} />
          <div style={{ minWidth: 0, flex: 1 }}>
            <div style={{ fontSize: 17, fontWeight: 800, color: "var(--text)" }}>{t.name}</div>
            <div style={{ fontSize: 13, color: "var(--muted)", marginTop: 3, overflowWrap: "anywhere", wordBreak: "break-word" }}>{t.email}</div>
          </div>
        </div>
      ),
      rows: [
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
  const openVerificationDetails = (v: Verification) => {
    const userId = String(v.userId ?? "");
    if (v.type === "homeowner_id") {
      const homeowner = homeowners.find((h) => h.userId === userId || h.id === userId);
      if (homeowner) {
        openHOModal(homeowner);
        return;
      }
    }
    if (v.type === "tradesperson_license") {
      const tradesman = tradesmen.find((t) => t.userId === userId || t.id === userId);
      if (tradesman) {
        openTMModal(tradesman);
        return;
      }
    }

    setModal({
      open: true,
      title: getVerificationUserName(v) || `User #${v.userId}`,
      rows: [
        { label: "User ID", value: String(v.userId) },
        { label: "Verification Type", value: verificationTypeLabel(v.type) },
        { label: "Submitted", value: v.createdAt ? new Date(v.createdAt).toLocaleDateString() : "—" },
        { label: "Status", value: toTitle(v.status), highlight: v.status === "approved" },
        { label: "Document", value: v.documentUrl ? "Uploaded" : "Missing", highlight: Boolean(v.documentUrl) },
      ],
      actions: (
        <Btn
          variant="view"
          onClick={() => openDocumentModal(`User #${v.userId}`, v.documentUrl || `${apiBase}/api/admin/documents/${v.id}/file`)}
        >
          {icons.license} View Uploaded Document
        </Btn>
      ),
    });
  };

  const saveProfileEditor = async () => {
    if (!authToken || !profileEditor.mode) {
      showToast("Please sign in again.", "error");
      return;
    }

    let endpoint = "";
    let payload: Record<string, string | boolean> = {};

    if (profileEditor.mode === "name") {
      const trimmedName = profileEditor.fullName.trim();
      if (!trimmedName) {
        showToast("Please enter the admin name.", "error");
        return;
      }
      endpoint = "/api/profile/me/name";
      payload = {
        full_name: trimmedName,
      };
    }

    if (profileEditor.mode === "email") {
      if (!profileEditor.email.trim()) {
        showToast("Please enter a new email.", "error");
        return;
      }
      if (!profileEditor.currentPassword) {
        showToast("Please enter your current password.", "error");
        return;
      }
      endpoint = "/api/profile/me/email";
      payload = {
        email: profileEditor.email.trim(),
        current_password: profileEditor.currentPassword,
      };
    }

    if (profileEditor.mode === "password") {
      if (!profileEditor.currentPassword || !profileEditor.newPassword || !profileEditor.confirmPassword) {
        showToast("Please complete the password form.", "error");
        return;
      }
      if (profileEditor.newPassword.length < 8) {
        showToast("New password must be at least 8 characters.", "error");
        return;
      }
      if (profileEditor.newPassword !== profileEditor.confirmPassword) {
        showToast("New passwords do not match.", "error");
        return;
      }
      endpoint = "/api/profile/me/password";
      payload = {
        current_password: profileEditor.currentPassword,
        new_password: profileEditor.newPassword,
      };
    }

    setProfileEditor((prev) => ({ ...prev, saving: true }));
    try {
      const res = await fetch(`${apiBase}${endpoint}`, {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${authToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem("admin_token");
          router.push("/login");
          return;
        }

        let message = "Unable to update profile.";
        try {
          const data = await res.json();
          message = String(data?.message ?? message);
        } catch {}
        showToast(message, "error");
        return;
      }

      const successMessage =
        profileEditor.mode === "name"
          ? "Admin name updated successfully."
          : profileEditor.mode === "email"
          ? "Email updated successfully."
          : "Password updated successfully.";

      if (profileEditor.mode === "name") {
        setAdminProfile((prev) =>
          prev
            ? { ...prev, fullName: profileEditor.fullName.trim() }
            : prev
        );
      }

      if (profileEditor.mode === "email") {
        setAdminProfile((prev) =>
          prev
            ? { ...prev, email: profileEditor.email.trim() }
            : prev
        );
      }

      closeProfileEditor();
      showToast(successMessage, "success");
    } catch {
      showToast("Unable to update profile.", "error");
    } finally {
      setProfileEditor((prev) => ({ ...prev, saving: false }));
    }
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
    ratings:      "Ratings",
    reports:      "Reports",
    profile:      "Profile",
    settings:     "Settings",
  };
  const sidebarWidth = sidebarOpen ? 260 : 84;

  // ── PAGES ──────────────────────────────────────────────────────

  const PageDashboard = () => (
    <div style={{ animation: "fadeUp .35s ease both" }}>
      {/* Stats */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 16, marginBottom: 28 }}>
        <StatCard iconBg="var(--info-bg)" iconColor="var(--info-text)" num={homeowners.length} label="Total Homeowners" trend={homeownerTrend} trendType={homeownerTrendType}
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>}
        />
        <StatCard iconBg="var(--info-bg)" iconColor="var(--info-text)" num={tradesmen.length} label="Total Tradesmen" trend={tradesmanTrend} trendType={tradesmanTrendType}
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>}
        />
        <StatCard iconBg="var(--warning-bg)" iconColor="var(--warning-text)" num={pendingCount} label="Pending Verifications" trend={pendingTrend} trendType="warn"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>}
        />
        <StatCard iconBg="var(--success-bg)" iconColor="var(--success-text)" num={verifiedCount} label="Verified Tradesmen" trend={verifiedTradesmanTrend} trendType="up"
          icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>}
        />
      </div>

      {/* Request analytics */}
      <div style={{ marginBottom: 28 }}>
        <UserGrowthChart style={{ marginBottom: 0 }} bookings={requestAnalyticsBookings} />
      </div>

      {/* Service bookings + failed bookings */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 2fr", gap: 20 }}>
        <ServiceBookingsChart style={{ marginBottom: 0 }} />

        <FailedBookingsChart style={{ marginBottom: 0 }} />
      </div>

    </div>
  );

  const PageVerification = () => (
    <div style={{ animation: "fadeUp .35s ease both" }}>
      <Card style={{ overflow: "visible" }}>
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
                  color: showArchivedOnly ? "var(--on-solid)" : "var(--info-text)",
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
                          <Btn variant="view" onClick={() => openVerificationDetails(v)}>{icons.license} View Details</Btn>
                        </>
                      ) : (
                        <>
                          <Btn disabled>{icons.check} {toTitle(v.status)}</Btn>
                          <Btn variant="view" onClick={() => openVerificationDetails(v)}>{icons.license} View Details</Btn>
                        </>
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
      <Card style={{ overflow: "visible" }}>
        <CardHead title="All Tradesmen" subtitle={`${tradesmen.length} registered tradesmen`} right={<Pill color="navy">{tradesmen.length} Total</Pill>} />
        <Toolbar
          placeholder="Search tradesmen…"
          filters={[["All Categories","Electrical","Plumbing","HVAC","Carpentry","Painter","Appliance Repair"],["All Status","Verified","Pending"]]}
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
                  <div>
                    <div style={{ fontWeight: 700, fontSize: 13 }}>{t.name}</div>
                    <div style={{ fontSize: 12, color: "var(--muted)" }}>{t.email}</div>
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
                            message: "This will suspend the tradesman account and block app login.",
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

  const PageRatings = () => {
    const analyticsReviews = filteredTradesmanRatings.flatMap(({ reviews }) => reviews);
    const analyticsAverageRating = averageRating(analyticsReviews);
    const analyticsTradesmenCount = filteredTradesmanRatings.filter(({ reviews }) => reviews.length > 0).length;
    const filteredSelectedTradesmanReviews = selectedTradesmanRating
      ? selectedTradesmanRating.reviews.filter((review) =>
          !selectedReviewStarFilter || review.rating === Number(selectedReviewStarFilter)
        )
      : [];
    const ratingBreakdown = [5, 4, 3, 2, 1].map((stars) => {
      const count = analyticsReviews.filter((review) => review.rating === stars).length;
      const percent = analyticsReviews.length > 0 ? Math.round((count / analyticsReviews.length) * 100) : 0;
      return { stars, count, percent };
    });
    const maxBreakdownCount = Math.max(...ratingBreakdown.map((item) => item.count), 1);
    const recommendedReviews = analyticsReviews.filter((review) => review.rating >= 4).length;
    const recommendationRate = analyticsReviews.length > 0 ? Math.round((recommendedReviews / analyticsReviews.length) * 100) : 0;
    const verifiedReviewRate = analyticsReviews.length > 0
      ? Math.round((analyticsReviews.filter((review) => review.verifiedBooking).length / analyticsReviews.length) * 100)
      : 0;
    const averageReviewsPerTradesman = analyticsTradesmenCount > 0
      ? (analyticsReviews.length / analyticsTradesmenCount).toFixed(1)
      : "0.0";
    const hasAnalyticsData = analyticsReviews.length > 0;

    return (
      <div style={{ animation: "fadeUp .35s ease both" }}>
        <Card style={{ marginBottom: 20 }}>
          <CardHead
            title="Ratings Analytics"
            subtitle="Track review quality, recommendation rate, and score distribution across the current ratings results"
            right={
              <>
                <Pill color="orange">{formatRatingValue(analyticsAverageRating)} avg</Pill>
                <Pill color="navy">{analyticsReviews.length} reviews</Pill>
              </>
            }
          />
          <div style={{ padding: 24, display: "grid", gridTemplateColumns: "minmax(0,1.35fr) minmax(260px,0.95fr)", gap: 24, alignItems: "start" }}>
            {hasAnalyticsData ? (
              <>
                <div style={{ display: "grid", gap: 14 }}>
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 800, color: "var(--text)" }}>Rating Distribution</div>
                    <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 4 }}>See how many reviews fall into each star tier.</div>
                  </div>
                  {ratingBreakdown.map((item) => (
                    <div key={item.stars} style={{ display: "grid", gridTemplateColumns: "56px minmax(0,1fr) auto", gap: 12, alignItems: "center" }}>
                      <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 13, fontWeight: 800, color: "var(--text)" }}>
                        <span>{item.stars}.0</span>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="var(--accent)" stroke="var(--accent)" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                          <polygon points="12 2 15.1 8.6 22 9.3 17 14.1 18.3 21 12 17.4 5.7 21 7 14.1 2 9.3 8.9 8.6 12 2" />
                        </svg>
                      </div>
                      <div style={{ height: 12, borderRadius: 999, background: "var(--surface-2)", overflow: "hidden", border: "1px solid var(--border)" }}>
                        <div
                          style={{
                            width: `${(item.count / maxBreakdownCount) * 100}%`,
                            height: "100%",
                            borderRadius: 999,
                            background: item.stars >= 4 ? "linear-gradient(90deg, var(--accent), #FFB262)" : "linear-gradient(90deg, #94A3B8, #CBD5E1)",
                          }}
                        />
                      </div>
                      <div style={{ minWidth: 56, textAlign: "right", fontSize: 12, color: "var(--muted)", fontWeight: 700 }}>
                        {item.count} · {item.percent}%
                      </div>
                    </div>
                  ))}
                </div>

                <div style={{ display: "grid", gridTemplateColumns: "repeat(2, minmax(0,1fr))", gap: 12, alignContent: "start" }}>
                  {[
                    { label: "Recommendation Rate", value: `${recommendationRate}%`, caption: "Reviews with 4 to 5 stars", tone: "var(--success-text)", bg: "var(--success-bg)" },
                    { label: "Reviewed Tradesmen", value: String(analyticsTradesmenCount), caption: "Shown in current results", tone: "var(--info-text)", bg: "var(--info-bg)" },
                    { label: "Verified Reviews", value: `${verifiedReviewRate}%`, caption: "Marked as verified bookings", tone: "var(--warning-text)", bg: "var(--warning-bg)" },
                    { label: "Avg / Tradesman", value: averageReviewsPerTradesman, caption: "Average review count each", tone: "var(--text)", bg: "var(--surface-2)" },
                  ].map((item) => (
                    <div key={item.label} style={{ border: "1px solid var(--border)", borderRadius: 16, background: "var(--surface-2)", padding: "16px 18px" }}>
                      <div style={{ display: "inline-flex", padding: "5px 10px", borderRadius: 999, background: item.bg, color: item.tone, fontSize: 11, fontWeight: 800, marginBottom: 12 }}>
                        {item.label}
                      </div>
                      <div style={{ fontSize: 28, lineHeight: 1, fontWeight: 800, color: "var(--text)", letterSpacing: -1, marginBottom: 8 }}>
                        {item.value}
                      </div>
                      <div style={{ fontSize: 12, color: "var(--muted)" }}>{item.caption}</div>
                    </div>
                  ))}
                </div>
              </>
            ) : (
              <div style={{ gridColumn: "1 / -1", borderRadius: 18, border: "1.5px dashed var(--border)", background: "var(--surface-2)", padding: "36px 24px", textAlign: "center" }}>
                <div style={{ fontSize: 15, fontWeight: 800, color: "var(--text)", marginBottom: 8 }}>No analytics match the current filters</div>
                <div style={{ fontSize: 12, color: "var(--muted)" }}>Try widening the category, rating, or search filters to see ratings insights again.</div>
              </div>
            )}
          </div>
        </Card>

        <Card style={{ marginBottom: 20, overflow: "visible" }}>
          <CardHead
            title="All Tradesmen"
            subtitle="Click a tradesman's name to expand their reviews directly below their row"
            right={<Pill color="navy">{filteredTradesmanRatings.length} Listed</Pill>}
          />
          <Toolbar
            placeholder="Search tradesmen…"
            filters={[["All Categories","Electrical","Plumbing","HVAC","Carpentry","Painter","Appliance Repair"],["All Ratings","4+ Stars","4.5+ Stars","5 Stars"]]}
            searchValue={searchRatings}
            onSearchChange={setSearchRatings}
            filterValues={ratingsFilters}
            onFilterChange={(index, value) => setRatingsFilters((prev) => {
              const next = [...prev];
              next[index] = value;
              return next;
            })}
          />
          <Table>
            <thead>
              <tr>
                <Th>Tradesman</Th>
                <Th>Category</Th>
                <Th>Average</Th>
                <Th>Reviews</Th>
                <Th>Recommend</Th>
                <Th>Status</Th>
              </tr>
            </thead>
            <tbody>
              {filteredTradesmanRatings.length > 0 ? (
                filteredTradesmanRatings.map(({ tradesman, reviews, average, recommendationRate }) => {
                  const active = selectedTradesmanRating?.tradesman.id === tradesman.id;
                  return (
                    <Fragment key={tradesman.id}>
                      <tr
                        style={{ background: active ? "var(--accent-soft)" : "transparent" }}
                      >
                        <Td>
                          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                            <Avatar initials={tradesman.initials} color={tradesman.color} size={42} />
                            <div style={{ minWidth: 0 }}>
                              <button
                                type="button"
                                onClick={() => setSelectedRatingsTradesmanId((current) => current === tradesman.id ? "" : tradesman.id)}
                                style={{
                                  padding: 0,
                                  border: "none",
                                  background: "transparent",
                                  color: active ? "var(--accent)" : "var(--text)",
                                  fontFamily: "inherit",
                                  fontSize: 14,
                                  fontWeight: 800,
                                  cursor: "pointer",
                                  textAlign: "left",
                                }}
                              >
                                {tradesman.name}
                              </button>
                              <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 4 }}>{tradesman.email}</div>
                            </div>
                          </div>
                        </Td>
                        <Td>{tradesman.category}</Td>
                        <Td>
                          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                            <StarRating value={Math.round(average)} />
                            <span style={{ fontSize: 13, fontWeight: 800, color: "var(--text)" }}>{formatRatingValue(average)}</span>
                          </div>
                        </Td>
                        <Td>{reviews.length}</Td>
                        <Td>{recommendationRate}%</Td>
                        <Td><Badge status={tradesman.status} /></Td>
                      </tr>

                      {active && (
                        <tr>
                          <Td colSpan={6} style={{ background: "var(--surface-2)", padding: 0 }}>
                            <div style={{ padding: 22, display: "grid", gap: 18 }}>
                              <div style={{ display: "grid", gridTemplateColumns: "minmax(0,1.2fr) repeat(3, minmax(120px,1fr))", gap: 14 }}>
                                <div style={{ border: "1px solid var(--border)", borderRadius: 18, background: "var(--surface)", padding: "18px 18px", display: "flex", alignItems: "center", gap: 14 }}>
                                  <Avatar initials={selectedTradesmanRating.tradesman.initials} color={selectedTradesmanRating.tradesman.color} size={60} />
                                  <div style={{ minWidth: 0, flex: 1 }}>
                                    <div style={{ fontSize: 17, fontWeight: 800, color: "var(--text)" }}>{selectedTradesmanRating.tradesman.name}</div>
                                    <div style={{ fontSize: 13, color: "var(--muted)", marginTop: 4, overflowWrap: "anywhere", wordBreak: "break-word" }}>{selectedTradesmanRating.tradesman.email}</div>
                                    <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 6 }}>{selectedTradesmanRating.tradesman.category}</div>
                                  </div>
                                </div>
                                {[
                                  { label: "Average", value: formatRatingValue(selectedTradesmanRating.average), caption: "Overall review score" },
                                  { label: "Reviews", value: String(selectedTradesmanRating.reviews.length), caption: "Visible in admin" },
                                  { label: "Jobs Done", value: String(selectedTradesmanRating.tradesman.jobs), caption: "Completed jobs" },
                                ].map((item) => (
                                  <div key={item.label} style={{ border: "1px solid var(--border)", borderRadius: 18, background: "var(--surface)", padding: "18px 18px" }}>
                                    <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: "0.7px", textTransform: "uppercase", color: "var(--muted)", marginBottom: 10 }}>{item.label}</div>
                                    <div style={{ fontSize: 28, lineHeight: 1, fontWeight: 800, color: "var(--text)", letterSpacing: -1 }}>{item.value}</div>
                                    <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 10 }}>{item.caption}</div>
                                  </div>
                                ))}
                              </div>

                              <div style={{ display: "grid", gap: 14 }}>
                                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 14, flexWrap: "wrap" }}>
                                  <div style={{ fontSize: 12, fontWeight: 700, color: "var(--muted)", letterSpacing: "0.7px", textTransform: "uppercase" }}>
                                    Filter Reviews By Stars
                                  </div>
                                  <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
                                    {[
                                      { label: "All", value: "" },
                                      { label: "5 Star", value: "5" },
                                      { label: "4 Star", value: "4" },
                                      { label: "3 Star", value: "3" },
                                      { label: "2 Star", value: "2" },
                                      { label: "1 Star", value: "1" },
                                    ].map((option) => {
                                      const starActive = selectedReviewStarFilter === option.value;
                                      return (
                                        <button
                                          key={option.label}
                                          type="button"
                                          onClick={() => setSelectedReviewStarFilter(option.value)}
                                          style={{
                                            padding: "8px 12px",
                                            borderRadius: 999,
                                            border: `1px solid ${starActive ? "var(--accent)" : "var(--border)"}`,
                                            background: starActive ? "var(--accent-soft)" : "var(--surface)",
                                            color: starActive ? "var(--accent)" : "var(--muted)",
                                            fontSize: 12,
                                            fontWeight: 800,
                                            fontFamily: "inherit",
                                            cursor: "pointer",
                                            transition: "all .2s ease",
                                          }}
                                        >
                                          {option.label}
                                        </button>
                                      );
                                    })}
                                  </div>
                                </div>

                                {filteredSelectedTradesmanReviews.length > 0 ? (
                                  filteredSelectedTradesmanReviews.map((review) => (
                                    <div key={review.id} style={{ border: "1px solid var(--border)", borderRadius: 18, background: "var(--surface)", padding: "18px 18px" }}>
                                      <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 16, marginBottom: 12 }}>
                                        <div>
                                          <div style={{ fontSize: 14, fontWeight: 800, color: "var(--text)" }}>{review.reviewerName}</div>
                                          <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 4 }}>
                                            {review.reviewerRole} · {review.jobType}
                                          </div>
                                        </div>
                                        <div style={{ textAlign: "right" }}>
                                          <div style={{ display: "flex", alignItems: "center", justifyContent: "flex-end", gap: 8 }}>
                                            <StarRating value={review.rating} />
                                            <span style={{ fontSize: 13, fontWeight: 800, color: "var(--text)" }}>{formatRatingValue(review.rating)}</span>
                                          </div>
                                          <div style={{ fontSize: 11, color: "var(--muted)", marginTop: 6 }}>{formatDate(review.submittedAt)}</div>
                                        </div>
                                      </div>
                                      <div style={{ fontSize: 13, lineHeight: 1.7, color: "var(--text)", marginBottom: 12 }}>
                                        {review.comment}
                                      </div>
                                      <div style={{ display: "flex", alignItems: "center", gap: 10, flexWrap: "wrap" }}>
                                        <Pill color="navy">{review.jobType}</Pill>
                                        {review.verifiedBooking && <Pill color="green">Verified booking</Pill>}
                                      </div>
                                    </div>
                                  ))
                                ) : (
                                  <div style={{ border: "1.5px dashed var(--border)", borderRadius: 18, background: "var(--surface)", padding: "28px 24px", textAlign: "center" }}>
                                    <div style={{ fontSize: 15, fontWeight: 800, color: "var(--text)", marginBottom: 8 }}>No {selectedReviewStarFilter || "matching"} reviews found</div>
                                    <div style={{ fontSize: 12, color: "var(--muted)" }}>
                                      {selectedReviewStarFilter
                                        ? `This tradesman has no ${selectedReviewStarFilter}-star reviews in the current selection.`
                                        : "No reviews are available for this tradesman."}
                                    </div>
                                  </div>
                                )}
                              </div>
                            </div>
                          </Td>
                        </tr>
                      )}
                    </Fragment>
                  );
                })
              ) : (
                <tr>
                  <Td style={{ textAlign: "center", color: "var(--muted)" }} colSpan={6}>
                    No tradesmen match the current search or filters.
                  </Td>
                </tr>
              )}
            </tbody>
          </Table>
        </Card>
      </div>
    );
  };

  const PageHomeowners = () => (
    <div style={{ animation: "fadeUp .35s ease both" }}>
      <Card style={{ overflow: "visible" }}>
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
                  <div>
                    <div style={{ fontWeight: 700, fontSize: 13 }}>{h.name}</div>
                    <div style={{ fontSize: 12, color: "var(--muted)" }}>{h.email}</div>
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
                            message: "This will suspend the homeowner account and block app login.",
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

  const PageReports = () => {
    const tabs: Array<{ id: ReportTab; label: string; count: number }> = [
      { id: "all", label: "All Reports", count: reports.length },
      { id: "homeowner", label: "Homeowner Reports", count: reports.filter((report) => report.targetType === "Homeowner").length },
      { id: "tradesman", label: "Tradesman Reports", count: reports.filter((report) => report.targetType === "Tradesman").length },
    ];

    return (
      <div style={{ animation: "fadeUp .35s ease both" }}>
        <Card>
          <CardHead
            title="User Reports"
            subtitle="Review reports submitted against homeowners and tradesmen"
            right={<Pill color="orange">{openReportsCount} Open</Pill>}
          />
          <div style={{ padding: "18px 24px 0", display: "flex", gap: 10, flexWrap: "wrap" }}>
            {tabs.map((tab) => {
              const active = reportTab === tab.id;
              return (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => setReportTab(tab.id)}
                  style={{
                    padding: "9px 14px",
                    borderRadius: 999,
                    border: `1.5px solid ${active ? "var(--info-border)" : "var(--border)"}`,
                    background: active ? "var(--info-bg)" : "var(--surface-2)",
                    color: active ? "var(--info-text)" : "var(--text)",
                    fontFamily: "inherit",
                    fontSize: 12,
                    fontWeight: 800,
                    cursor: "pointer",
                    boxShadow: "none",
                    transition: "all .2s",
                  }}
                >
                  {tab.label} ({tab.count})
                </button>
              );
            })}
          </div>
          <div style={{ padding: "14px 24px", borderBottom: "1px solid var(--border)", background: "var(--surface-2)", display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap", marginTop: 16 }}>
            <div style={{ flex: 1, minWidth: 220, display: "flex", alignItems: "center", gap: 8, padding: "9px 14px", background: "var(--surface)", border: "1.5px solid var(--border)", borderRadius: 8 }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>
              <input
                type="text"
                placeholder="Search reports…"
                value={searchReports}
                onChange={(e) => setSearchReports(e.target.value)}
                style={{ border: "none", outline: "none", background: "transparent", fontFamily: "inherit", fontSize: 13, color: "var(--text)", width: "100%" }}
              />
            </div>
            <select
              value={reportStatusFilter}
              onChange={(e) => setReportStatusFilter(e.target.value)}
              style={{ padding: "9px 14px", background: "var(--surface)", border: "1.5px solid var(--border)", borderRadius: 8, fontFamily: "inherit", fontSize: 13, fontWeight: 600, color: "var(--text)", outline: "none", cursor: "pointer", minWidth: 160 }}
            >
              <option value="">All Status</option>
              <option value="Open">Open</option>
              <option value="Reviewing">Reviewing</option>
              <option value="Resolved">Resolved</option>
            </select>
          </div>
          <Table>
            <thead><tr><Th>Reported User</Th><Th>Type</Th><Th>Reporter</Th><Th>Reason</Th><Th>Submitted</Th><Th>Status</Th><Th>Actions</Th></tr></thead>
            <tbody>
              {filteredReports.map((report) => (
                <tr
                  key={report.id}
                  onMouseEnter={(e) => (e.currentTarget.style.background = "var(--row-hover)")}
                  onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                  style={{ transition: "background .15s" }}
                >
                  <Td>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 13 }}>{report.targetName}</div>
                      <div style={{ fontSize: 12, color: "var(--muted)" }}>{report.targetEmail}</div>
                    </div>
                  </Td>
                  <Td>
                    <span style={{
                      display: "inline-flex",
                      padding: "5px 10px",
                      borderRadius: 999,
                      fontSize: 11,
                      fontWeight: 800,
                      background: report.targetType === "Homeowner" ? "var(--info-bg)" : "var(--accent-soft)",
                      color: report.targetType === "Homeowner" ? "var(--info-text)" : "var(--accent)",
                    }}>
                      {report.targetType}
                    </span>
                  </Td>
                  <Td>
                    <div style={{ fontWeight: 700, fontSize: 13 }}>{report.reporterName}</div>
                    <div style={{ fontSize: 12, color: "var(--muted)" }}>{report.reporterRole}</div>
                  </Td>
                  <Td>{report.reason}</Td>
                  <Td>{formatDate(report.submittedAt)}</Td>
                  <Td><Badge status={report.status} /></Td>
                  <Td>
                    <Btn
                      variant="view"
                      onClick={() =>
                        setModal({
                          open: true,
                          title: `${report.targetName} · ${report.targetType} Report`,
                          rows: [
                            { label: "Report ID", value: report.id },
                            { label: "Reported User", value: report.targetName },
                            { label: "Reported Email", value: report.targetEmail },
                            { label: "Reporter", value: `${report.reporterName} (${report.reporterRole})` },
                            { label: "Reason", value: report.reason },
                            { label: "Details", value: report.details },
                            { label: "Submitted", value: formatDate(report.submittedAt) },
                            { label: "Status", value: report.status, highlight: report.status === "Resolved" },
                          ],
                        })
                      }
                    >
                      View Report
                    </Btn>
                  </Td>
                </tr>
              ))}
              {filteredReports.length === 0 && (
                <tr>
                  <Td style={{ textAlign: "center", color: "var(--muted)" }} colSpan={7}>No reports match the current filters.</Td>
                </tr>
              )}
            </tbody>
          </Table>
        </Card>
      </div>
    );
  };

  const PageSettings = () => {
    const adminEmail = adminProfile?.email ?? "admin@fixit.com";
    const adminName = adminProfile?.fullName?.trim() || adminDisplayNameFromEmail(adminEmail);

    return (
      <div style={{ display: "grid", gap: 20, animation: "fadeUp .35s ease both" }}>
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
          </div>
        </Card>

        <Card>
          <CardHead title="Account Settings" subtitle="Update your admin account details" />
          {[
            { icon: icons.user, label: "Name", sub: adminName, mode: "name" as ProfileEditorMode },
            { icon: icons.bell, label: "Email", sub: adminEmail, mode: "email" as ProfileEditorMode },
            { icon: icons.shield, label: "Password", sub: "Change your admin password", mode: "password" as ProfileEditorMode },
          ].map((item, i, arr) => (
            <div
              key={item.label}
              onClick={() => openProfileEditor(item.mode)}
              style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "15px 20px", borderBottom: i < arr.length - 1 ? "1px solid var(--border)" : "none", cursor: "pointer", transition: "background .15s" }}
              onMouseEnter={(e) => (e.currentTarget.style.background = "var(--surface-2)")}
              onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
            >
              <div style={{ display: "flex", alignItems: "center", gap: 12, minWidth: 0, flex: 1 }}>
                <div style={{ width: 36, height: 36, borderRadius: 9, background: "var(--accent-soft)", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--accent)" }}>{item.icon}</div>
                <div style={{ minWidth: 0, flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 700, color: "var(--text)" }}>{item.label}</div>
                  <div style={{ fontSize: 11, color: "var(--muted)", marginTop: 1, overflowWrap: "anywhere", wordBreak: "break-word" }}>{item.sub}</div>
                </div>
              </div>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--muted)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 18 15 12 9 6"/></svg>
            </div>
          ))}
        </Card>
      </div>
    );
  };

  const PageProfile = () => {
    const adminEmail = adminProfile?.email ?? "admin@fixit.com";
    const adminName = adminProfile?.fullName?.trim() || adminDisplayNameFromEmail(adminEmail);
    const adminRole = humanizeRole(adminProfile?.role);

    return (
      <div style={{ animation: "fadeUp .35s ease both" }}>
        <Card style={{ marginBottom: 20 }}>
          <CardHead
            title="Account Details"
            subtitle="View the active admin account"
          />
          <div style={{ padding: 24, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
            {[
              ["Full Name", adminName],
              ["Role", adminRole],
              ["Email", adminEmail],
              ["Account Status", adminProfile?.isActive ? "Active" : "Inactive"],
              ["Last Updated", formatDateTime(adminProfile?.updatedAt)],
            ].map(([l, v]) => (
              <div key={l}>
                <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.8px", textTransform: "uppercase", color: "var(--muted)", marginBottom: 6 }}>{l}</div>
                <div style={{ fontSize: 14, fontWeight: 700, color: "var(--text)", overflowWrap: "anywhere" }}>{v}</div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    );
  };

  // ── RENDER ─────────────────────────────────────────────────────
  return (
    <div style={{ ...themeVars, display: "flex", minHeight: "100vh", fontFamily: "'Plus Jakarta Sans', sans-serif", background: "var(--bg)", color: "var(--text)" }}>

      {/* SIDEBAR */}
      <nav
        style={{
          width: sidebarWidth,
          flexShrink: 0,
          background: "var(--sidebar)",
          borderRight: "1px solid var(--sidebar-edge)",
          display: "flex",
          flexDirection: "column",
          position: "fixed",
          top: 0,
          left: 0,
          bottom: 0,
          zIndex: 50,
          boxShadow: "var(--sidebar-panel-shadow)",
          overflowX: "hidden",
          overflowY: "auto",
          transition: "width .24s ease",
        }}
      >
        {/* Logo */}
        <div style={{ padding: sidebarOpen ? "22px 22px 18px" : "22px 13px 18px", borderBottom: "1px solid var(--sidebar-divider)", display: "flex", alignItems: "center", justifyContent: sidebarOpen ? "flex-start" : "center", gap: sidebarOpen ? 14 : 0 }}>
          <SidebarShield />
          {sidebarOpen && (
            <div>
              <div style={{ fontSize: 21, fontWeight: 800, color: "var(--sidebar-brand)", letterSpacing: -0.4 }}>Fix It</div>
              <div style={{ fontSize: 15, color: "var(--sidebar-brand-muted)", fontWeight: 600, letterSpacing: 0.2 }}>Marketplace</div>
            </div>
          )}
        </div>

        {/* Nav */}
        <div style={{ flex: 1, padding: sidebarOpen ? "18px 14px 10px" : "18px 10px 10px" }}>
          {[
            { label: "Main" },
            { icon: icons.grid,     label: "Dashboard",     page: "dashboard" as Page },
            { icon: icons.shield,   label: "Verifications", page: "verification" as Page, badge: pendingCount },
            { label: "Users" },
            { icon: icons.wrench,   label: "Tradesmen",     page: "tradesmen" as Page },
            { icon: icons.home,     label: "Homeowners",    page: "homeowners" as Page },
            { icon: icons.star,     label: "Ratings",       page: "ratings" as Page, badge: totalRatingsCount },
            { icon: icons.flag,     label: "Reports",       page: "reports" as Page, badge: openReportsCount },
            { label: "System" },
            { icon: icons.user,     label: "Profile",       page: "profile" as Page },
            { icon: icons.settings, label: "Settings",      page: "settings" as Page },
          ].map((item, i) =>
            !item.icon ? (
              sidebarOpen ? (
                <div key={i} style={{ fontSize: 11, fontWeight: 800, letterSpacing: "1.7px", textTransform: "uppercase", color: "var(--sidebar-section)", padding: i === 0 ? "2px 10px 10px" : "18px 10px 10px" }}>{item.label}</div>
              ) : (
                <div key={i} style={{ height: i === 0 ? 12 : 18 }} />
              )
            ) : (
              <NavItem
                key={i}
                icon={item.icon}
                label={item.label}
                active={item.page === activePage}
                badge={item.badge}
                collapsed={!sidebarOpen}
                onClick={() => item.page ? setActivePage(item.page) : showToast(`${item.label} opened`, "info")}
              />
            )
          )}
        </div>

        {/* Sign out */}
        <div style={{ padding: sidebarOpen ? "16px 16px 24px" : "16px 10px 24px", borderTop: "1px solid var(--sidebar-divider)", background: "linear-gradient(180deg, rgba(255,255,255,0.02), rgba(255,255,255,0.08))" }}>
          <button onClick={handleLogout}
            title="Sign Out"
            style={{ display: "flex", alignItems: "center", justifyContent: sidebarOpen ? "flex-start" : "center", gap: sidebarOpen ? 10 : 0, padding: sidebarOpen ? "12px 14px" : "12px 0", borderRadius: 14, background: "var(--sidebar-signout-bg)", border: "1px solid var(--sidebar-signout-border)", cursor: "pointer", width: "100%", fontFamily: "inherit", transition: "all .2s ease", color: "var(--sidebar-signout-text)", boxShadow: "0 10px 24px rgba(10,20,48,.14)" }}
            onMouseEnter={(e) => { e.currentTarget.style.background = "var(--sidebar-signout-hover-bg)"; e.currentTarget.style.color = "var(--sidebar-signout-hover-text)"; e.currentTarget.style.transform = "translateY(-1px)"; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = "var(--sidebar-signout-bg)"; e.currentTarget.style.color = "var(--sidebar-signout-text)"; e.currentTarget.style.transform = "translateY(0)"; }}>
            <span style={{ display: "flex" }}>{icons.logout}</span>
            {sidebarOpen && <span style={{ fontSize: 14, fontWeight: 800 }}>Sign Out</span>}
          </button>
        </div>
      </nav>

      {/* MAIN */}
      <div style={{ marginLeft: sidebarWidth, flex: 1, display: "flex", flexDirection: "column", minHeight: "100vh", transition: "margin-left .24s ease" }}>
        {/* Topbar */}
        <div style={{ background: "var(--surface)", height: 99, borderBottom: "1px solid var(--border)", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 32px", position: "sticky", top: 0, zIndex: 40, boxShadow: "var(--shadow)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <button
              type="button"
              onClick={() => setSidebarOpen((prev) => !prev)}
              aria-label={sidebarOpen ? "Hide sidebar" : "Show sidebar"}
              aria-pressed={sidebarOpen}
              style={{
                width: 42,
                height: 42,
                borderRadius: 10,
                border: "1.5px solid var(--border)",
                background: sidebarOpen ? "var(--accent-soft)" : "var(--surface-2)",
                color: sidebarOpen ? "var(--accent)" : "var(--muted)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                cursor: "pointer",
                transition: "all .2s ease",
                flexShrink: 0,
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = "var(--accent)";
                e.currentTarget.style.background = "var(--accent-soft)";
                e.currentTarget.style.color = "var(--accent)";
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = "var(--border)";
                e.currentTarget.style.background = sidebarOpen ? "var(--accent-soft)" : "var(--surface-2)";
                e.currentTarget.style.color = sidebarOpen ? "var(--accent)" : "var(--muted)";
              }}
            >
              {icons.menu}
            </button>
            <div>
              <div style={{ fontSize: 18, fontWeight: 800, color: "var(--text)", letterSpacing: -0.3 }}>{pageTitles[activePage]}</div>
              <div style={{ fontSize: 12, color: "var(--muted)", fontWeight: 500, marginTop: 1 }}>Fix It Marketplace › Admin Portal › {pageTitles[activePage]}</div>
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
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
                  <span style={{ position: "absolute", top: 6, right: 6, minWidth: 16, height: 16, padding: "0 4px", background: "var(--accent)", borderRadius: 100, border: "1.5px solid var(--surface)", color: "var(--on-solid)", fontSize: 9, fontWeight: 800, display: "flex", alignItems: "center", justifyContent: "center" }}>
                    {notificationCount > 9 ? "9+" : notificationCount}
                  </span>
                )}
              </button>
              {bellOpen && (
                <div
                  ref={bellPanelRef}
                  style={{
                    position: "fixed",
                    right: 24,
                    bottom: 24,
                    width: 340,
                    maxWidth: "calc(100vw - 32px)",
                    background: "var(--surface)",
                    border: "1.5px solid var(--border)",
                    borderRadius: 16,
                    boxShadow: "var(--elevated-shadow)",
                    zIndex: 120,
                    overflow: "hidden",
                    animation: "mIn .24s cubic-bezier(.16,1,.3,1)",
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
                    onClick={() => setBellOpen(false)}
                    style={{ width: "100%", padding: "10px 14px", borderTop: "1px solid var(--border)", border: "none", background: "var(--surface-2)", fontSize: 12, fontWeight: 700, color: "var(--text)", cursor: "pointer" }}
                    onMouseEnter={(e) => { e.currentTarget.style.background = "var(--accent-soft)"; }}
                    onMouseLeave={(e) => { e.currentTarget.style.background = "var(--surface-2)"; }}
                  >
                    Close
                  </button>
                </div>
              )}
            </div>
            {/* Avatar */}
            <div onClick={() => setActivePage("profile")}
              style={{ width: 38, height: 38, borderRadius: 9, background: "var(--accent)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 800, color: "var(--on-solid)", cursor: "pointer" }}>
              AD
            </div>
          </div>
        </div>

        {/* Page content */}
        <div style={{ padding: "28px 32px", flex: 1 }}>
          {activePage === "dashboard"    && PageDashboard()}
          {activePage === "verification" && PageVerification()}
          {activePage === "tradesmen"    && PageTradesmen()}
          {activePage === "homeowners"   && PageHomeowners()}
          {activePage === "ratings"      && PageRatings()}
          {activePage === "reports"      && PageReports()}
          {activePage === "profile"      && PageProfile()}
          {activePage === "settings"     && PageSettings()}
        </div>
      </div>

      {/* Toast */}
      <Toast msg={toast.msg} type={toast.type} show={toast.show} />

      {/* Modal */}
      <Modal open={modal.open} onClose={() => setModal((m) => ({ ...m, open: false }))} title={modal.title} hero={modal.hero} rows={modal.rows} actions={modal.actions} />
      <ProfileEditorModal
        open={profileEditor.open}
        mode={profileEditor.mode}
        saving={profileEditor.saving}
        currentName={adminProfile?.fullName?.trim() || adminDisplayNameFromEmail(adminProfile?.email ?? "admin@fixit.com")}
        fullName={profileEditor.fullName}
        currentEmail={adminProfile?.email ?? "admin@fixit.com"}
        email={profileEditor.email}
        currentPassword={profileEditor.currentPassword}
        newPassword={profileEditor.newPassword}
        confirmPassword={profileEditor.confirmPassword}
        onClose={closeProfileEditor}
        onChange={(patch) => setProfileEditor((prev) => ({ ...prev, ...patch }))}
        onSubmit={saveProfileEditor}
      />
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
