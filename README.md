# Self-Hosted Home Cloud – Installationstutorial

Dieses Repository ist eine vollständige, nachvollziehbare Schritt-für-Schritt-Anleitung, um ein
selbst gehostetes Home-Cloud-System nachzubauen, wie es in der Seminararbeit
*"IT-Sicherheit in selbst gehosteten Home-Clouds"* beschrieben und praktisch umgesetzt wurde.

Es handelt sich **nicht** um ein automatisches Installationsskript, sondern um eine dokumentierte,
reproduzierbare Anleitung samt fertiger Docker-Compose-Dateien, Konfigurationsbeispielen und
Backup-/Restore-Skripten.

## Architekturüberblick

Dieses Tutorial baut die Anwendungsebene des in der Seminararbeit untersuchten Systems nach und
läuft auf **einem einzigen Host**:

- Minimale, headless betriebene Debian-Installation (laut Systemspezifikation der Arbeit: ein
  Laptop mit Debian 13 und Docker 29.2.1)
- Alle Anwendungsdienste als Docker-Container: Nextcloud + MariaDB, optional Home Assistant,
  openHAB, Portainer
- Zugriff ausschließlich **im LAN**, direkt über den vom jeweiligen Dienst verwendeten Port
  (z. B. `http://<LAN-IP-des-Hosts>:8080` für Nextcloud) – dieses Tutorial richtet **keinen
  Reverse Proxy und keine HTTPS-Terminierung** ein
- Der Host liegt in einem eigenen Netzsegment direkt am Internet-Router; das übrige Heimnetz
  hängt an einem zweiten Router mit eigener Firewall (siehe Kapitel 7.13) – dadurch bleibt ein
  kompromittierter Server vom restlichen Heimnetz isoliert, ohne dass du dafür ein VLAN brauchst

```
LAN ──HTTP (8080 u. a.)──▶ [ Ein Host, Debian + Docker ]
                              ├─ Nextcloud + MariaDB (Docker)
                              └─ optional: Home Assistant, openHAB, Portainer
```

> **Hinweis zur Seminararbeit:** Das am Testsystem der Arbeit tatsächlich gemessene System
> terminierte HTTPS zusätzlich über einen nativ installierten Apache-Reverse-Proxy mit
> Let's-Encrypt-Zertifikat, um von außerhalb des LAN erreichbar zu sein. Diese Reverse-Proxy-/
> HTTPS-Schicht ist **nicht Teil dieses Tutorials** und wird hier bewusst nicht reproduziert.
> Die in Kapitel 7 zitierten TLS- und Security-Header-Messwerte beziehen sich auf das
> externe, so konfigurierte Testsystem der Arbeit, nicht auf das in diesem Repository
> aufgebaute, LAN-interne Setup. Möchtest du denselben öffentlichen, HTTPS-gesicherten Zugriff
> wie im Testsystem der Arbeit, musst du selbst einen Reverse Proxy mit TLS-Terminierung
> vorschalten – das ist mit jedem gängigen Reverse Proxy (z. B. Apache, nginx, Caddy, Traefik)
> möglich, aber bewusst nicht Teil dieser Anleitung.

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
Restore-Dauer) des Testsystems der Arbeit, statt pauschal zu behaupten, jede Maßnahme sei perfekt
umgesetzt. Details und offene Restrisiken (z. B. Container laufen weiterhin mit Root-Rechten und
der Docker-Bench-Score sank sogar von 5/117 auf 3/117, die LUKS-Verschlüsselung entsperrt
automatisch beim Boot, kein vollständiges 3-2-1-Backup) stehen in
[Kapitel 7](docs/07-security-hardening.md).

## Inhaltsverzeichnis

1. [Übersicht & Architektur](docs/01-overview.md)
2. [Voraussetzungen](docs/02-prerequisites.md)
3. [Docker-Installation](docs/03-docker-install.md)
4. [Speicher-Setup (3-Laufwerk-Architektur)](docs/04-storage-setup.md)
5. [Nextcloud + MariaDB Setup](docs/05-nextcloud-setup.md)
6. [Backup & Restore](docs/06-backup-restore.md)
7. [Security-Härtung](docs/07-security-hardening.md)
8. [Optionale Dienste (Home Assistant, openHAB, Portainer)](docs/08-optional-services.md)
9. [Troubleshooting / bekannte Fehler](docs/09-troubleshooting.md)

## Wichtiger Hinweis zu Platzhaltern

Alle IP-Adressen, Benutzernamen und Passwörter in diesem Repository sind **Platzhalter**.
Ersetze sie durch eigene, sichere Werte. Verwende niemals einfache oder in Tutorials sichtbare
Passwörter für produktive Systeme. Empfehlung: Passwort-Manager + generiertes Passwort (≥20
Zeichen) + 2FA (siehe Kapitel 7).

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
