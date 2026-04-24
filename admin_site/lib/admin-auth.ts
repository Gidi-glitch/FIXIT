export const ADMIN_TOKEN_STORAGE_KEY = "admin_token";
export const ADMIN_SESSION_COOKIE = "admin_session";

const DEFAULT_API_BASE_URL = "http://localhost:8080";

const isBrowser = () => typeof window !== "undefined";

export const getApiBaseUrl = () => {
  const configured = (process.env.NEXT_PUBLIC_API_BASE_URL ?? "").trim();
  const base = configured || DEFAULT_API_BASE_URL;
  return base.replace(/\/$/, "");
};

export const getAdminToken = () => {
  if (!isBrowser()) return null;
  const value = window.localStorage.getItem(ADMIN_TOKEN_STORAGE_KEY)?.trim();
  return value || null;
};

export const hasAdminSessionCookie = () => {
  if (!isBrowser()) return false;
  return document.cookie
    .split(";")
    .some((part) => part.trim().startsWith(`${ADMIN_SESSION_COOKIE}=`));
};

const isHttps = () => {
  if (!isBrowser()) return false;
  return window.location.protocol === "https:";
};

const writeSessionCookie = (value: string, remember: boolean) => {
  if (!isBrowser()) return;

  const attributes = [
    `${ADMIN_SESSION_COOKIE}=${value}`,
    "Path=/",
    "SameSite=Lax",
  ];

  if (remember) {
    const sevenDays = 60 * 60 * 24 * 7;
    attributes.push(`Max-Age=${sevenDays}`);
  }

  if (isHttps()) {
    attributes.push("Secure");
  }

  document.cookie = attributes.join("; ");
};

export const setAdminSession = (token: string, remember = false) => {
  if (!isBrowser()) return;
  window.localStorage.setItem(ADMIN_TOKEN_STORAGE_KEY, token);
  writeSessionCookie("1", remember);
};

export const clearAdminSession = () => {
  if (!isBrowser()) return;
  window.localStorage.removeItem(ADMIN_TOKEN_STORAGE_KEY);
  document.cookie = `${ADMIN_SESSION_COOKIE}=; Path=/; Max-Age=0; SameSite=Lax`;
};
