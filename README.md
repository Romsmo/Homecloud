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

- Minimale, headless betriebene Debian-Installation (laut Systemspezifikation der Arbeit: ein
  Laptop mit Debian 13 und Docker 29.2.1)
- Alle Anwendungsdienste als Docker-Container: Nextcloud + MariaDB, optional Home Assistant,
  openHAB, Portainer
- HTTPS wird direkt auf diesem Host terminiert, über einen **nativ installierten Apache**
  (nicht containerisiert, `mod_proxy`) mit Let's-Encrypt-Zertifikat per Certbot – das ist der in
  der Arbeit tatsächlich gemessene Weg
- Der Host liegt in einem eigenen Netzsegment direkt am Internet-Router; das übrige Heimnetz
  hängt an einem zweiten Router mit eigener Firewall (siehe Kapitel 8.8) – dadurch bleibt ein
  kompromittierter Server vom restlichen Heimnetz isoliert, ohne dass du dafür ein VLAN brauchst

```
Internet ──HTTPS(443)──▶ [ Ein Host, Debian + Docker ]
                            ├─ Apache (nativ, Reverse Proxy + Let's Encrypt/Certbot)
                            ├─ Nextcloud + MariaDB (Docker, nur auf 127.0.0.1:8080)
                            └─ optional: Home Assistant, openHAB, Portainer
```

*(Eine Docker-basierte Alternative mit Nginx Proxy Manager auf demselben Host ist in Kapitel 6
dokumentiert, falls du einen UI-gestützten Reverse Proxy bevorzugst – das ist aber nicht die in
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
offene Restrisiken (z. B. Container laufen weiterhin mit Root-Rechten und der Docker-Bench-Score
sank sogar von 5/117 auf 3/117, die LUKS-Verschlüsselung entsperrt automatisch beim Boot, kein
vollständiges 3-2-1-Backup, Apache-Versions-Header bleibt sichtbar) stehen in
[Kapitel 8](docs/08-security-hardening.md).

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

## Auf GitHub hochladen

Dieses Repository liegt lokal vor und wurde nicht automatisch veröffentlicht. So lädst du es selbst
zu GitHub hoch:

1. Leeres Repository auf GitHub anlegen (ohne README/License/​.gitignore, da diese hier bereits
   vorhanden sind)
2. In diesem Ordner:

```bash
git init
git add .
git commit -m "Initial commit: Home-Cloud-Installationstutorial"
git branch -M main
git remote add origin https://github.com/<dein-benutzername>/<dein-repo-name>.git
git push -u origin main
```

> **Sicherheitshinweis:** `.env`-Dateien mit echten Passwörtern sind über `.gitignore` bereits vom
> Commit ausgeschlossen. Prüfe vor dem `git add .` trotzdem mit `git status`, dass keine Datei mit
> echten Zugangsdaten versehentlich mit hochgeladen wird.
