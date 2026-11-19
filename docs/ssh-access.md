# How to SSH into the ByteLab lab

You need three things from the team lead (Esther):
- the **soclab.pem** key file (shared via AirDrop/USB, never Slack or email)
- **today's WAF public IP** (it changes every time the lab is redeployed)
- your own public IP added to the allow-list (run `curl -s ifconfig.me` and send it to Esther)

## 1. Set up the key (once)
Put soclab.pem in a folder, open a terminal there, and lock its permissions:

    chmod 600 soclab.pem

SSH refuses to use a key others could read, so this step is required.

## 2. Connect to the WAF (the public box)

    ssh -i soclab.pem ubuntu@<WAF_IP>

First time it asks to confirm, type `yes`. You land on: ubuntu@ip-10-0-1-10

## 3. Connect to the private boxes (jump through the WAF)

    ssh -i soclab.pem -J ubuntu@<WAF_IP> ubuntu@10.0.2.10   # Juice Shop
    ssh -i soclab.pem -J ubuntu@<WAF_IP> ubuntu@10.0.2.20   # Wazuh

## 4. Open the Wazuh dashboard (SSH tunnel)

    ssh -i soclab.pem -L 8443:10.0.2.20:443 ubuntu@<WAF_IP>

Leave that terminal open, then browse to https://localhost:8443
(accept the cert warning). Log in as admin with the password from Esther.

## Troubleshooting
- Permission denied (publickey): wrong key path or you skipped chmod 600.
- Operation timed out: your IP isn't allowed. Run curl -s ifconfig.me, send it to Esther.
- Dashboard "site can't be reached": the tunnel terminal closed, re-run step 4.
- port 8443 in use: use 8444 instead (change both numbers, browse to :8444).
- Suddenly stops working: lab was redeployed, the WAF IP changed, ask Esther.

Note: the lab is destroyed at the end of each session and rebuilt next time,
so the WAF IP changes. Always get the current IP from Esther before connecting.
