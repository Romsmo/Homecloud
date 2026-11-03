# 1. Übersicht & Architektur

## Ziel

Dieses Tutorial baut die Anwendungsebene des Home-Cloud-Systems nach, das in der Seminararbeit
*"IT-Sicherheit in selbst gehosteten Home-Clouds"* (finale Fassung) als Untersuchungsgegenstand
beschrieben und getestet wurde. Es deckt ab:

- Eine Nextcloud-Instanz mit MariaDB, erreichbar im LAN über den Docker-Port des Hosts
- Datenhaltung getrennt auf drei physisch getrennten Laufwerken (System/Storage/Backup)
- Ein rsync-basiertes, geloggtes Backup mit getestetem Restore
- Die in der Arbeit priorisierte Security-Härtung (Kapitel 7), inklusive der tatsächlich
  gemessenen Vorher-Nachher-Werte als Realitäts-Check
- Optional: Home Assistant, openHAB, Portainer

Die Einrichtung eines Reverse Proxy mit HTTPS-Terminierung ist optional und in Kapitel 7,
Maßnahme 1 beschrieben – siehe auch den Hinweis im nächsten Abschnitt.

## Architektur: Ein Host, Docker-Dienste im LAN

Dieses Tutorial läuft auf **einem einzigen Host** (Stand 27.10.2026: Debian GNU/Linux 13 „Trixie",
Version 13.7, mit Docker 29.8.2) – kein
zweiter, separater Server.
Dieser eine Host:

- ist eine minimale, headless betriebene Debian-Installation
- hostet die Anwendungsdienste (Nextcloud, MariaDB, optional weitere) als Docker-Container
- macht diese Dienste direkt über ihre jeweiligen Ports im LAN erreichbar (z. B.
  `http://<LAN-IP-des-Hosts>:8080` für Nextcloud) – zunächst ohne Reverse Proxy und
  HTTPS-Terminierung (optional nachrüstbar, Kapitel 7, Maßnahme 1)
- liegt in einem eigenen Netzsegment direkt am Internet-Router; das übrige Heimnetz hängt an
  einem zweiten Router mit eigener Firewall, sodass der Server nicht ungehindert ins Heimnetz
  vordringen kann (siehe Kapitel 7.13)

```
LAN ──HTTP (8080 u. a.)──▶ [ Ein Host, Debian + Docker ]
                              ├─ Nextcloud + MariaDB (Docker)
                              └─ optional: Home Assistant, openHAB, Portainer
```

> **Abweichung von der Seminararbeit:** Das Testsystem der Arbeit bestand aus genau diesem einen Host –
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
Erwartungshaltung hast: TLS-Bewertung A+, Security-Header B→A (dabei blieb der
Apache-Versions-Header auch nach der Härtung sichtbar) – beide Werte beziehen sich, wie oben
beschrieben, auf das über den nativen Reverse Proxy von außerhalb des LAN erreichbare Testsystem
der Arbeit, nicht auf das LAN-interne Basissetup ohne die optionale Proxy-Schicht (Kapitel 7, Maßnahme 1). Unabhängig davon gilt für beide Systeme gleichermaßen:
Docker-Container laufen weiterhin mit Root-Rechten und ohne Ressourcenlimits
(Docker-Bench-Nettowert änderte sich von 5 auf 3, bei 117 Kontrollpunkten), die Verschlüsselung
ruhender Daten (LUKS) ist zwar eingerichtet,
aber durch automatische Entsperrung beim Systemstart gegen Diebstahl des laufenden Systems nur
eingeschränkt wirksam, und das Backup erfüllt im Testsystem nicht die vollständige 3-2-1-Regel
(keine räumlich getrennte Kopie). Details dazu in [Kapitel 7](07-security-hardening.md).

## Inhaltsverzeichnis

1. [Übersicht & Architektur](01-overview.md)
2. [Voraussetzungen](02-prerequisites.md)
3. [Docker-Installation](03-docker-install.md)
4. [Speicher-Setup (3-Laufwerk-Architektur)](04-storage-setup.md)
5. [Nextcloud + MariaDB Setup](05-nextcloud-setup.md)
6. [Backup & Restore](06-backup-restore.md)
7. [Security-Härtung (mit Messwerten aus der Arbeit)](07-security-hardening.md)
8. [Optionale Dienste (Home Assistant, openHAB, Portainer)](08-optional-services.md)
9. [Troubleshooting / bekannte Fehler](09-troubleshooting.md)
