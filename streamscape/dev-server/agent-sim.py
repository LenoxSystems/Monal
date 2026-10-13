"""Simulated StreamScape agent for local Monal testing.

Logs in as agent@kim.localtest.me and sends test messages to the tester account.

  python agent-sim.py links          send the link-rendering test set
  python agent-sim.py react [emoji]  wait for the tester's next message, then react to it (XEP-0444)
  python agent-sim.py say "<text>"   send one plain message
"""
import asyncio
import json
import sys
from pathlib import Path

import slixmpp

HERE = Path(__file__).resolve().parent
ACCOUNTS = json.loads((HERE / "accounts.local.json").read_text())
TESTER = ACCOUNTS["tester"]["jid"]
REPORT_URL = "https://example.com/reports/42"

LINK_CASES = [
    f"{REPORT_URL} Your Q3 ops report is ready.",
    f"Your Q3 ops report is ready: {REPORT_URL}",
    f"[Q3 Ops Report]({REPORT_URL})",
    f"Dashboard: https://example.com/dash and alerts: https://example.org/alerts",
    REPORT_URL,
]
XHTML_NS = "http://jabber.org/protocol/xhtml-im"
XHTML_CASE = (
    "Q3 Ops Report (rich-text link)",
    f'<html xmlns="{XHTML_NS}"><body xmlns="http://www.w3.org/1999/xhtml">'
    f'<a href="{REPORT_URL}">Q3 Ops Report</a> (rich-text link)</body></html>',
)


class Agent(slixmpp.ClientXMPP):
    def __init__(self, mode, arg):
        super().__init__(ACCOUNTS["agent"]["jid"], ACCOUNTS["agent"]["password"])
        self.mode, self.arg = mode, arg
        self.ssl_context.load_verify_locations(str(HERE / "certs" / "test-ca.crt"))
        self.register_plugin("xep_0030")
        self.register_plugin("xep_0071")
        self.register_plugin("xep_0444")
        self.add_event_handler("session_start", self.start)
        self.add_event_handler("message", self.on_message)

    async def start(self, _event):
        self.send_presence()
        await self.get_roster()
        if self.mode == "links":
            for body in LINK_CASES:
                self.send_message(mto=TESTER, mbody=body, mtype="chat")
                await asyncio.sleep(1)
            msg = self.make_message(mto=TESTER, mbody=XHTML_CASE[0], mtype="chat")
            msg["html"]["body"] = XHTML_CASE[1]
            msg.send()
            await asyncio.sleep(1)
            self.disconnect()
        elif self.mode == "say":
            self.send_message(mto=TESTER, mbody=self.arg, mtype="chat")
            await asyncio.sleep(1)
            self.disconnect()
        else:
            print("Waiting for a message from the tester...", flush=True)

    def on_message(self, msg):
        if self.mode != "react" or msg["type"] not in ("chat", "normal") or not msg["body"]:
            return
        if msg["from"].bare != TESTER or not msg["id"]:
            return
        print(f"Reacting {self.arg} to: {msg['body']!r} (id {msg['id']})", flush=True)
        self.plugin["xep_0444"].send_reactions(TESTER, msg["id"], {self.arg}, store=True)
        self.loop.call_later(1, self.disconnect)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "links"
    arg = sys.argv[2] if len(sys.argv) > 2 else ("👍" if mode == "react" else "")
    agent = Agent(mode, arg)
    agent.connect(host="127.0.0.1", port=5222)
    asyncio.get_event_loop().run_until_complete(agent.disconnected)


if __name__ == "__main__":
    main()
