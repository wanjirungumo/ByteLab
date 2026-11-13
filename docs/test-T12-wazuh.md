# Test T12: Wazuh server

Data: 13/11/2026
Ambiente: EC2 di test (Ubuntu 24.04, t3.large, 50 GB), VPC di default.
Ruolo testato: `ansible/roles/wazuh_server` (playbook `site-wazuh.yml`), branch `main`.

## Risultati

| Test | Atteso | Ottenuto |
| --- | --- | --- |
| Playbook | Nessun errore | `ok=6 changed=4 failed=0 skipped=1` |
| Installazione all-in-one | Indexer, manager e dashboard installati | Completata in meno di 40 minuti (async del ruolo) |
| Servizi | Attivi | `wazuh-indexer`, `wazuh-manager`, `wazuh-dashboard`: active |
| Dashboard | Raggiungibile su HTTPS | Login con utente admin riuscito (certificato autofirmato) |

## Note

- Il task della password admin viene saltato perché `wazuh_admin_password` è definita solo nei file generati da Terraform. Nel test vale la password autogenerata, che si trova in `/opt/wazuh-install/wazuh-install-files.tar`.
- Il default di `wazuh_manager_ip` nel ruolo `wazuh_agent` era `10.0.2.20`, mentre `interfaces.md` indica `10.10.2.20`.

## Da verificare sull'ambiente reale

- Dashboard raggiungibile tramite il jump host (`vm-waf`).
- Porte 1514 e 1515 aperte da `vm-waf` e `vm-juiceshop`.
- Enrolment degli agent (T14) e log del WAF visibili in Wazuh.
- Password admin impostata da Terraform.

## Esito

Criterio "Done when" di T12: soddisfatto nel test (accesso alla dashboard). Da riverificare sull'ambiente Terraform.