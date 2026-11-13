# Test T13: ModSecurity + OWASP CRS

Data: 13/11/2026
Ambiente: EC2 di test (Ubuntu 24.04, t3.small), VPC di default, Juice Shop in Docker sulla stessa istanza.
Ruolo testato: `ansible/roles/modsecurity` (playbook `site-waf.yml`), branch `main`. Modalità: `waf_mode=blocking` (il default attuale è `off`, vedi `docs/client-documentation.md`).

## Risultati

| Test | Atteso | Ottenuto |
| --- | --- | --- |
| `GET /` | Juice Shop via WAF | 200 (dopo aver impostato `modsec_backend_url=http://127.0.0.1:3000`) |
| `GET /?q=<script>alert(1)</script>` | Bloccato | 403, regole 941100, 941110, 941160 |
| `POST /rest/user/login` con SQL injection | Bloccato | 403, regola 942100 (libinjection) |
| `SecRuleEngine` | On | `Engine-Mode: ENABLED` |

Gli eventi sono nel log `/var/log/apache2/modsec_audit.log`.

## Note

- Il valore di default del backend (`10.10.2.10:3000`) vale per l'ambiente Terraform, ma sul test ha causato 503.
- Il playbook è idempotente: la seconda esecuzione ha cambiato solo il virtual host.

## Da verificare sull'ambiente reale

- Backend `10.10.2.10:3000` raggiungibile dal WAF (`vm-waf`).
- Accesso via Elastic IP.
- Invio dei log a Wazuh (T14).

## Esito

Criterio "Done when" di T13: soddisfatto nel test. Da riverificare sull'ambiente Terraform.