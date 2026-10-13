#!/bin/bash
# Creates agent@ and tester@kim.localtest.me with random passwords on the running
# kim-prosody container and writes them to accounts.local.json (git-ignored).
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
umask 077
agent_password="$(openssl rand -hex 8)"
tester_password="$(openssl rand -hex 8)"
for pair in "agent $agent_password" "tester $tester_password"; do
    user="${pair%% *}"
    password="${pair##* }"
    printf '%s\n%s\n' "$password" "$password" \
        | docker exec -i kim-prosody prosodyctl adduser "$user@kim.localtest.me" >/dev/null
    echo "Created $user@kim.localtest.me"
done
cat > "$dir/accounts.local.json" <<EOF
{
  "agent":  {"jid": "agent@kim.localtest.me",  "password": "$agent_password"},
  "tester": {"jid": "tester@kim.localtest.me", "password": "$tester_password"}
}
EOF
echo "Passwords written to $dir/accounts.local.json"
