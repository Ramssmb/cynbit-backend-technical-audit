#!/usr/bin/env bash
# Passive checks behind the Cynbit backend audit.
# Only GET requests to public pages and public DNS lookups. No forms are submitted.
set -u

SITE="https://www.cynbit.in"

section() { printf '\n=== %s ===\n' "$1"; }

section "Home page headers"
curl -sS -o /dev/null -D - "$SITE/"

section "Redirect chain"
for u in http://cynbit.in/ https://cynbit.in/ http://www.cynbit.in/; do
  printf '%-25s ' "$u"
  curl -sS -o /dev/null -w '%{http_code} -> %{redirect_url}\n' "$u"
done

section "Caching and time to first byte per route"
for p in "" contact careers blog/ai-agents-business-operations diaries sitemap.xml; do
  printf '%-38s ' "/$p"
  hdrs=$(curl -sS -o /dev/null -D - -w 'TTFB=%{time_starttransfer}s' "$SITE/$p")
  echo "$hdrs" | grep -iE '^(cache-control|x-vercel-cache):' | tr -d '\r' | tr '\n' ' '
  echo "$hdrs" | tail -n 1
done

section "Status codes"
for p in this-page-does-not-exist blog/no-such-post .well-known/security.txt; do
  printf '%-38s ' "/$p"
  curl -sS -o /dev/null -w '%{http_code}\n' "$SITE/$p"
done

section "robots.txt"
curl -sS "$SITE/robots.txt"

section "sitemap lastmod (two requests)"
for i in 1 2; do
  curl -sS "$SITE/sitemap.xml" | grep -m1 -o '<lastmod>[^<]*'
  sleep 2
done

section "Canonical tag on home page"
curl -sS "$SITE/" | grep -o '<link rel="canonical"[^>]*>' || echo "none found"

section "Email DNS"
nslookup -type=MX cynbit.in
nslookup -type=TXT cynbit.in
nslookup -type=TXT _dmarc.cynbit.in
