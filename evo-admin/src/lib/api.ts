// Auto-retry fetch wrapper — handles Render cold start gracefully
export async function apiFetch(url: string, options: RequestInit = {}, retries = 3): Promise<Response> {
  const token = typeof window !== 'undefined' ? localStorage.getItem("evo_admin_token") || "" : "";
  
  const mergedHeaders: Record<string, string> = {
    "Bypass-Tunnel-Reminder": "true",
    ...((options.headers as Record<string, string>) || {}),
  };
  if (token) mergedHeaders["Authorization"] = `Bearer ${token}`;

  for (let i = 0; i < retries; i++) {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 20000);
      const res = await fetch(url, { ...options, headers: mergedHeaders, signal: controller.signal });
      clearTimeout(timeout);
      return res;
    } catch (err) {
      if (i === retries - 1) throw err;
      await new Promise(r => setTimeout(r, 2000));
    }
  }
  throw new Error('API unreachable');
}
