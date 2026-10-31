# Cynbit Backend Technical Audit

Backend-focused technical audit of Cynbit's website (https://www.cynbit.in), covering observable API behaviour, backend architecture, security, performance, authentication, data handling and recommended improvements.

Submitted for the **Backend Developer Intern** task at Cynbit Technologies.

**Author:** Maloth Bhavsingh · **Observed on:** 31 October 2026

## Deliverables

| Deliverable | Where |
|-------------|-------|
| Backend Technical Audit Report: observable backend behaviour, API structure, payloads | [Report §3](docs/BACKEND_AUDIT_REPORT.md#3-backend-technical-audit-observed-architecture) |
| Security & Performance Findings: categorised by security, performance, data validation, authentication | [Report §4](docs/BACKEND_AUDIT_REPORT.md#4-security-and-performance-findings) |
| Recommended Improvements: technical recommendations with code snippets | [Report §5–7](docs/BACKEND_AUDIT_REPORT.md#5-recommended-improvements-with-code) |
| Full report as PDF | [docs/Cynbit_Backend_Audit_Report.pdf](docs/Cynbit_Backend_Audit_Report.pdf) |
| Script to re-run the passive checks | [scripts/passive-checks.sh](scripts/passive-checks.sh) |

## Testing approach

Only passive testing was used:

- Ordinary `GET` requests to public pages, the same requests a browser makes
- Reading the public JavaScript bundles the site already sends to every visitor
- Public DNS lookups

I did not submit any form, call any Server Action directly, visit `/admin` or `/portal`, fuzz paths, or run load tests. In total this was roughly a hundred requests, spread over several minutes.

## Observed architecture (summary)

- **Framework and hosting:** Next.js App Router on Vercel, served from the Mumbai (`bom1`) edge.
- **Page rendering:** most pages are prerendered and edge-cached. Careers, blog and diaries are rendered on every request.
- **Forms:** the contact and newsletter forms use Next.js Server Actions (`submitInquiry`, `subscribeToNewsletter`), not REST endpoints.
- **Third parties:** Google Analytics 4, Google Fonts, and remote images from pravatar.cc and Unsplash.

## Findings at a glance

| # | Area | Finding | Severity |
|---|------|---------|----------|
| F1 | Security | No CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy or Permissions-Policy headers | Medium |
| F2 | Security / Data | Server Actions have no visible bot protection and no input length limits | Medium |
| F3 | Error handling | Contact form has no `try/catch`, so a failed request leaves the button stuck loading | Medium |
| F4 | Performance | `/careers`, `/blog/[slug]`, `/diaries` rendered per request (`no-store`), ~3–4× slower than cached pages | Medium |
| F5 | Performance / SEO | `sitemap.xml` regenerated per request with `lastmod` = current time | Low |
| F6 | Architecture / SEO | Apex → www is a temporary `307`; sitemap and metadata use the apex; no canonical tag | Low |
| F7 | Privacy / Compliance | Google Analytics loads before any consent | Medium |
| F8 | Data / Dependencies | Third-party placeholder images proxied through the image optimiser | Low |
| F9 | Email deliverability | SPF does not authorise Microsoft 365 (the MX); DMARC `p=none` without reports | Medium |
| F10 | Security hygiene | `robots.txt` advertises `/admin/` and `/portal/`; no `security.txt` | Low / Info |
| F11 | Transport | HSTS without `includeSubDomains`/`preload`; `Access-Control-Allow-Origin: *` on HTML | Low / Info |

Nothing observed exposes private data. Severity is relative to a public marketing site.

## Re-running the checks

```bash
bash scripts/passive-checks.sh
```

The script uses only `curl` and `nslookup`, and makes a small number of `GET` requests and DNS lookups.
