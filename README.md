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

- Minimale, headless betriebene Debian-Installation (Stand 27.10.2026: Debian GNU/Linux 13
  „Trixie", Version 13.7, mit Docker 29.8.2; die Messungen in Kapitel 4 der zugrunde liegenden
  Arbeit wurden auf einem Laptop mit den zum Messzeitpunkt installierten Versionen 13.3/29.2.1
  durchgeführt)
- Alle Anwendungsdienste als Docker-Container: Nextcloud + MariaDB, optional Home Assistant,
  openHAB, Portainer
- Zugriff im **LAN** direkt über den vom jeweiligen Dienst verwendeten Port
  (z. B. `http://<LAN-IP-des-Hosts>:8080` für Nextcloud) – optional von außen über einen
  Apache-Reverse-Proxy mit HTTPS (Kapitel 7, Maßnahme 1)
- Der Host liegt in einem eigenen Netzsegment direkt am Internet-Router; das übrige Heimnetz
  hängt an einem zweiten Router mit eigener Firewall (siehe Kapitel 7.13) – dadurch bleibt ein
  kompromittierter Server vom restlichen Heimnetz isoliert, ohne dass du dafür ein VLAN brauchst

```
LAN ──HTTP (8080 u. a.)──▶ [ Ein Host, Debian + Docker ]
                              ├─ Nextcloud + MariaDB (Docker)
                              └─ optional: Home Assistant, openHAB, Portainer
```

> **Hinweis zur Seminararbeit:** Das Testsystem der Arbeit bestand aus genau diesem einen Host –
> zusätzlich lief dort **nativ auf demselben Host** (nicht als separater Server, nicht als eigener
> Container) ein Apache-Reverse-Proxy. Der Router leitete Port 80/443 per Portweiterleitung an
> diesen Host weiter; der native Apache-Proxy terminierte dort TLS und reichte die Anfrage intern
> an den Nextcloud-Container weiter. Eingesetzt wurde der Proxy gezielt, weil das eingesetzte
> Nextcloud-Container-Image selbst keine automatisiert erneuerbaren, vertrauenswürdigen
> TLS-Zertifikate bereitstellt: der Apache-Proxy holte dafür per Certbot ein
> Let's-Encrypt-Zertifikat und erneuerte es automatisiert, terminierte TLS und setzte zusätzlich
> die in Kapitel 7 beschriebenen Security-Header in seiner vHost-Konfiguration – **nicht** in
> Nextcloud selbst. Diese Reverse-Proxy-/HTTPS-Schicht ist als optionaler Schritt in Kapitel 7,
> Maßnahme 1 als Beispielkonfiguration beschrieben. Die in Kapitel 7 zitierten TLS- und
> Security-Header-Messwerte beziehen sich auf das über diesen Reverse Proxy von außerhalb des LAN
> erreichbare Testsystem der Arbeit, nicht auf das LAN-interne Basissetup ohne die optionale
> Proxy-Schicht. Willst du denselben öffentlichen, HTTPS-gesicherten Zugriff, richte die Schicht
> nach Kapitel 7, Maßnahme 1 ein (statt Apache sind auch nginx, Caddy oder Traefik möglich).

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
der Docker-Bench-Nettowert änderte sich von 5 auf 3 (bei 117 Kontrollpunkten), die
LUKS-Verschlüsselung entsperrt automatisch beim Boot, kein vollständiges 3-2-1-Backup) stehen in
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
