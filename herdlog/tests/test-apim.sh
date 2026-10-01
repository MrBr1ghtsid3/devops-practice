#!/usr/bin/env bash
# HerdLog lab - Step 7 + 9 tests: calls through APIM.
#
# Before running, in the SAME terminal, set two FRESH tokens (under 1 hour old):
#   export FARMER='eyJ...'
#   export VET='eyJ...'
# Run from herdlog/:   bash tests/test-apim.sh

set -u

URL=$(terraform -chdir=infra output -raw apim_herds_url)
SUBKEY=$(terraform -chdir=infra output -raw apim_subscription_key)
export TID=$(terraform -chdir=infra output -raw external_tenant_id)
export AUD=$(terraform -chdir=infra output -raw api_client_id)

# A hand-made token that CLAIMS to be a vet: correct aud, iss, scope, role,
# future expiry - but signed by nobody. The old Function-only setup would
# have believed it.
FAKE=$(python3 - <<'PY'
import base64, json, os, time
b64 = lambda d: base64.urlsafe_b64encode(json.dumps(d).encode()).decode().rstrip("=")
tid = os.environ["TID"]
header  = {"alg": "RS256", "typ": "JWT"}
payload = {"aud": os.environ["AUD"],
           "iss": f"https://{tid}.ciamlogin.com/{tid}/v2.0",
           "scp": "Herds.Read", "roles": ["Vet"], "name": "Mr Forger",
           "exp": int(time.time()) + 3600}
print(f"{b64(header)}.{b64(payload)}.bm90LWEtcmVhbC1zaWduYXR1cmU")
PY
)

call() {  # $1 = label, rest = extra curl args
  label=$1; shift
  printf '\n== %s ==\n' "$label"
  curl -s -w "\nHTTP %{http_code}\n" "$@" "$URL"
}

call "1. No subscription key          (expect 401)"
call "2. Key, no token                (expect 401)" -H "Ocp-Apim-Subscription-Key: $SUBKEY"
call "3. Key + FORGED vet token       (expect 401)" -H "Ocp-Apim-Subscription-Key: $SUBKEY" -H "Authorization: Bearer $FAKE"
call "4. Key + farmer token           (expect 200, Farmer)" -H "Ocp-Apim-Subscription-Key: $SUBKEY" -H "Authorization: Bearer $FARMER"
call "5. Key + vet token              (expect 200, Vet)" -H "Ocp-Apim-Subscription-Key: $SUBKEY" -H "Authorization: Bearer $VET"

# Step 9: HSTS must be on APIM's own error answers too, not only on 200s.
printf '\n== 6. HSTS header (expect "present" twice) ==\n'
ROOT="${URL%%/herdlog/*}/"
for u in "$URL" "$ROOT"; do   # $URL with no key -> 401;  root -> 404 (no API there)
  code=$(curl -s -o /dev/null -w "%{http_code}" "$u")
  if curl -s -D - -o /dev/null "$u" | grep -qi '^strict-transport-security:'; then
    echo "present  (HTTP $code)  $u"
  else
    echo "MISSING  (HTTP $code)  $u"
  fi
done

printf '\n== 7. Rate limit: 12 fast calls (expect some 200s, then 429) ==\n'
for i in $(seq 1 12); do
  curl -s -o /dev/null -w "%{http_code} " \
    -H "Ocp-Apim-Subscription-Key: $SUBKEY" -H "Authorization: Bearer $VET" "$URL"
done
echo
