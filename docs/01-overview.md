# 1. Übersicht & Architektur

## Ziel

Dieses Tutorial baut das Home-Cloud-System nach, das in der Seminararbeit *"IT-Sicherheit in
selbst gehosteten Home-Clouds"* (finale Fassung) als Untersuchungsgegenstand beschrieben und
getestet wurde. Es deckt ab:

- Eine Nextcloud-Instanz mit MariaDB, erreichbar über eine eigene Subdomain per HTTPS
- Datenhaltung getrennt auf drei physisch getrennten Laufwerken (System/Storage/Backup)
- Ein rsync-basiertes, geloggtes Backup mit getestetem Restore
- Die in der Arbeit priorisierte Security-Härtung (Kapitel 8), inklusive der tatsächlich
  gemessenen Vorher-Nachher-Werte als Realitäts-Check
- Optional: Home Assistant, openHAB, Portainer

## Architektur: Ein Host, nativer Apache-Reverse-Proxy

Das in der Arbeit untersuchte System läuft auf **einem einzigen Host** (laut Systemspezifikation
der Arbeit: ein Laptop mit Debian 13 und Docker 29.2.1) – kein zweiter, separater Server. Dieser
eine Host:

- ist eine minimale, headless betriebene Debian-Installation
- hostet die Anwendungsdienste (Nextcloud, MariaDB, optional weitere) als Docker-Container
- terminiert HTTPS selbst, über einen **nativ auf dem Host installierten Apache** (nicht
  containerisiert) mit `mod_proxy` und einem Let's-Encrypt-Zertifikat per Certbot – das ist der in
  der Arbeit tatsächlich gemessene Weg (u. a. erkennbar am Apache-Versions-Header in den
  Messungen aus Kapitel 4/8)
- liegt in einem eigenen Netzsegment direkt am Internet-Router; das übrige Heimnetz hängt an
  einem zweiten Router mit eigener Firewall, sodass der Server nicht ungehindert ins Heimnetz
  vordringen kann (siehe Kapitel 8.8)

```
Internet ──HTTPS(443)──▶ [ Ein Host, Debian + Docker ]
                            ├─ Apache (nativ, Reverse Proxy + Let's Encrypt/Certbot)
                            ├─ Nextcloud + MariaDB (Docker, nur auf 127.0.0.1:8080)
                            └─ optional: Home Assistant, openHAB, Portainer
```

> **Bevorzugst du einen Docker-basierten, UI-gestützten Reverse Proxy statt der nativen
> Apache-Installation?** Kapitel 6 enthält **Nginx Proxy Manager (NPM)** als dokumentierte
> Alternative. Diese Variante wurde für dieses Tutorial aufgebaut und getestet, ist aber **nicht**
> die in der Seminararbeit selbst gemessene Konfiguration – die dort erhobenen Werte (Kapitel 8)
> beziehen sich auf den nativen Apache-Weg.

## Speicherarchitektur

Bewusst **kein RAID**: Ziel ist nicht maximale Verfügbarkeit, sondern maximale Wiederherstellbarkeit
im Fehlerfall. Drei physisch getrennte Laufwerke/Datenträger:

| Laufwerk | Zweck | Beispiel im Testsystem der Arbeit |
|---|---|---|
| System-Laufwerk | Betriebssystem, Docker, Container-Volumes (App/Config) | SSD, 223,6 GB |
| Storage-Laufwerk | Nextcloud-Nutzdaten (`data/`-Unterordner, per Bind-Mount) | USB-Datenträger, 29,3 GB |
| Backup-Laufwerk | Rsync-Backups der Nutzdaten | USB-Datenträger, 29,3 GB |

Das Testsystem der Arbeit lief auf vergleichsweise bescheidener Hardware (Laptop, Intel Core
i3-4100M, 3,8 GiB RAM) – die Architektur ist also bewusst auch auf schwacher Hardware
reproduzierbar, nicht nur auf einem dedizierten Server.

## Realitäts-Check: was die Arbeit tatsächlich gemessen hat

Dieses Tutorial übernimmt nicht nur die Maßnahmen, sondern an den relevanten Stellen auch die
**real gemessenen Ergebnisse** aus der Arbeit (Kapitel 4), damit du eine realistische
Erwartungshaltung hast: TLS-Bewertung A+, Security-Header B→A (dabei bleibt der
Apache-Versions-Header auch nach der Härtung sichtbar), Docker-Container laufen weiterhin mit
Root-Rechten und ohne Ressourcenlimits (Docker-Bench-Score sank sogar von 5/117 auf 3/117), die
Verschlüsselung ruhender Daten (LUKS) ist zwar eingerichtet, aber durch automatische Entsperrung
beim Systemstart gegen Diebstahl des laufenden Systems nur eingeschränkt wirksam, und das Backup
erfüllt im Testsystem nicht die vollständige 3-2-1-Regel (keine räumlich getrennte Kopie). Details
dazu in [Kapitel 8](08-security-hardening.md).

## Inhaltsverzeichnis

1. [Übersicht & Architektur](01-overview.md)
2. [Voraussetzungen](02-prerequisites.md)
3. [Docker-Installation](03-docker-install.md)
4. [Speicher-Setup (3-Laufwerk-Architektur)](04-storage-setup.md)
5. [Nextcloud + MariaDB Setup](05-nextcloud-setup.md)
6. [Reverse Proxy & HTTPS](06-reverse-proxy-https.md)
7. [Backup & Restore](07-backup-restore.md)
8. [Security-Härtung (mit Messwerten aus der Arbeit)](08-security-hardening.md)
9. [Optionale Dienste (Home Assistant, openHAB, Portainer)](09-optional-services.md)
10. [Troubleshooting / bekannte Fehler](10-troubleshooting.md)
