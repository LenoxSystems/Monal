# Local XMPP test server

A local Prosody 13 server for testing the iOS app in the simulator without client
staging accounts. Domain `kim.localtest.me` and all of its subdomains resolve to
127.0.0.1 in public DNS, so the simulator reaches the container directly.

## Setup

```sh
bash make-certs.sh              # throwaway test CA + server certificate in certs/
docker compose up -d            # starts kim-prosody on 127.0.0.1:5222 and :5281
bash create-accounts.sh         # agent@ and tester@kim.localtest.me
xcrun simctl keychain booted add-root-cert certs/test-ca.crt
```

Restart the app after trusting the CA, then log in as `tester@kim.localtest.me`
with the password from `accounts.local.json`.

## Simulated agent

Requires `pip install slixmpp aiohttp` (slixmpp 1.17+).

```sh
python agent-sim.py links            # link-rendering test messages
python agent-sim.py react 👍          # react to the tester's next message (XEP-0444)
python agent-sim.py say "hello"      # one plain message
python agent-sim.py file photo.jpg   # upload and send a file (image, .m4a voice note)
python agent-sim.py listen           # print incoming messages and reactions; run in a foreground terminal
```

`certs/` and `accounts.local.json` are git-ignored. Stop with `docker compose down`;
add `-v` to also delete accounts and message history.
