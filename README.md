# Self-Hosted Home Cloud – Installationstutorial

Dieses Repository ist eine vollständige, nachvollziehbare Schritt-für-Schritt-Anleitung, um ein
selbst gehostetes Home-Cloud-System nachzubauen, wie es in der Seminararbeit
*"IT-Sicherheit in selbst gehosteten Home-Clouds"* beschrieben und praktisch umgesetzt wurde.

Es handelt sich **nicht** um ein automatisches Installationsskript, sondern um eine dokumentierte,
reproduzierbare Anleitung samt fertiger Docker-Compose-Dateien, Konfigurationsbeispielen und
Backup-/Restore-Skripten.

## Architekturüberblick

Das in der Seminararbeit (finale Fassung) untersuchte und gemessene System läuft auf **einem
einzigen Host**:

- Minimale, headless betriebene Debian-Installation
- Alle Anwendungsdienste als Docker-Container: Nextcloud + MariaDB, optional Home Assistant,
  openHAB, Portainer
- HTTPS wird direkt auf diesem Host terminiert, über einen Docker-basierten Reverse Proxy
  (Nginx Proxy Manager) mit Let's-Encrypt-Zertifikat
- Der Host liegt in einem eigenen Netzsegment direkt am Internet-Router; das übrige Heimnetz
  hängt an einem zweiten Router mit eigener Firewall (siehe Kapitel 8.8) – dadurch bleibt ein
  kompromittierter Server vom restlichen Heimnetz isoliert, ohne dass du dafür ein VLAN brauchst

```
Internet ──HTTPS(443)──▶ [ Ein Host, Debian + Docker ]
                            ├─ Nginx Proxy Manager (Reverse Proxy + Let's Encrypt)
                            ├─ Nextcloud + MariaDB
                            └─ optional: Home Assistant, openHAB, Portainer
```

*(Eine Variante mit separatem Apache-Reverse-Proxy auf einem zweiten Server ist in Kapitel 6 als
Alternative dokumentiert, falls du bereits so einen Server betreibst – das ist aber nicht die in
der Arbeit gemessene Konfiguration.)*

Speicherarchitektur: **drei getrennte physische Laufwerke** (bewusst kein RAID – Wiederherstellbarkeit
hat Vorrang vor Verfügbarkeit):

| Laufwerk | Zweck | Mountpoint | Beispiel im Testsystem der Arbeit |
|---|---|---|---|
| System-Laufwerk | Betriebssystem, Docker, Container-Volumes (App/Config) | `/` | SSD, 223,6 GB |
| Storage-Laufwerk | Nextcloud-Nutzdaten (`data/`-Unterordner, per Bind-Mount) | `/mnt/nextcloud-data` | USB-Datenträger, 29,3 GB |
| Backup-Laufwerk | Rsync-Backups der Nutzdaten | `/mnt/nextcloud-backup` | USB-Datenträger, 29,3 GB |

## Realitäts-Check

Dieses Tutorial übernimmt an den relevanten Stellen die real in der Arbeit gemessenen
Vorher-Nachher-Werte (TLS-Bewertung, Security-Header-Note, Docker-Bench-Score, Trivy-Funde,
Restore-Dauer), statt pauschal zu behaupten, jede Maßnahme sei perfekt umgesetzt. Details und
offene Restrisiken (z. B. Container laufen weiterhin mit Root-Rechten, kein vollständiges
3-2-1-Backup) stehen in [Kapitel 8](docs/08-security-hardening.md).

## Inhaltsverzeichnis

1. [Übersicht & Architektur](docs/01-overview.md)
2. [Voraussetzungen](docs/02-prerequisites.md)
3. [Docker-Installation](docs/03-docker-install.md)
4. [Speicher-Setup (3-Laufwerk-Architektur)](docs/04-storage-setup.md)
5. [Nextcloud + MariaDB Setup](docs/05-nextcloud-setup.md)
6. [Reverse Proxy & HTTPS](docs/06-reverse-proxy-https.md)
7. [Backup & Restore](docs/07-backup-restore.md)
8. [Security-Härtung](docs/08-security-hardening.md)
9. [Optionale Dienste (Home Assistant, openHAB, Portainer)](docs/09-optional-services.md)
10. [Troubleshooting / bekannte Fehler](docs/10-troubleshooting.md)

## Wichtiger Hinweis zu Platzhaltern

Alle IP-Adressen, Domains, Benutzernamen und Passwörter in diesem Repository sind **Platzhalter**.
Ersetze sie durch eigene, sichere Werte. Verwende niemals einfache oder in Tutorials sichtbare
Passwörter für produktive Systeme. Empfehlung: Passwort-Manager + generiertes Passwort (≥20
Zeichen) + 2FA (siehe Kapitel 8).

## Lizenz

Siehe [LICENSE](LICENSE). Dieses Tutorial dient Bildungszwecken im Rahmen der zugrunde liegenden
Seminararbeit.
