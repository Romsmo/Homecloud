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

## Architektur: Ein Host, Docker-interner Reverse Proxy

Anders als in einem früheren Entwurf dieses Tutorials beschrieben, läuft das in der Arbeit
untersuchte System auf **einem einzigen Host** – kein zweiter, separater Apache-Server. Dieser
eine Server:

- ist eine minimale, headless betriebene Debian-Installation
- hostet alle Anwendungsdienste (Nextcloud, MariaDB, optional weitere) als Docker-Container
- terminiert HTTPS selbst, über einen Docker-basierten Reverse Proxy (**Nginx Proxy Manager**)
  mit Let's-Encrypt-Zertifikat
- liegt in einem eigenen Netzsegment direkt am Internet-Router; das übrige Heimnetz hängt an
  einem zweiten Router mit eigener Firewall, sodass der Server nicht ungehindert ins Heimnetz
  vordringen kann (siehe Kapitel 8.8)

```
Internet ──HTTPS(443)──▶ [ Ein Host, Debian + Docker ]
                            ├─ Nginx Proxy Manager (Reverse Proxy + Let's Encrypt)
                            ├─ Nextcloud + MariaDB
                            └─ optional: Home Assistant, openHAB, Portainer
```

> **Hast du bereits einen separaten Server mit laufendem Apache, über den du den Zugriff leiten
> willst** (z. B. weil du Nextcloud auf einem reinen Docker-Host ohne eigene Domain betreibst)?
> Kapitel 6 enthält diese Variante weiterhin als dokumentierte Alternative. Der in der Arbeit
> getestete und mit den Messwerten in Kapitel 8 belegte Weg ist aber der Docker-interne Reverse
> Proxy auf demselben Host.

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
**real gemessenen Ergebnisse** aus der finalen Fassung der Arbeit (Kapitel 4), damit du eine
realistische Erwartungshaltung hast: TLS-Bewertung A+, Security-Header B→A (nicht F→A),
Docker-Container laufen weiterhin mit Root-Rechten und ohne Ressourcenlimits (bewusst nicht
behobenes Restrisiko), und das Backup erfüllt im Testsystem nicht die vollständige 3-2-1-Regel
(keine räumlich getrennte Kopie). Details dazu in [Kapitel 8](08-security-hardening.md).

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
