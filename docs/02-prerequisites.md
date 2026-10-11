# 2. Voraussetzungen

## Hardware

- Ein Host (physisch oder VM): mind. 2 CPU-Kerne, 4 GB RAM empfohlen (das Testsystem der
  zugrunde liegenden Arbeit lief sogar mit einem Intel Core i3-4100M und 3,8 GiB RAM). Ein
  Debian-fähiger Mini-PC, NAS-Server, alter Laptop oder Raspberry Pi (64-bit) reicht.
- Drei separate Laufwerke/Datenträger für System, Storage und Backup (siehe Kapitel 4) – im
  Testsystem der Arbeit eine interne SSD plus zwei externe USB-Datenträger.

## Software / Zugänge

- Debian 13 (oder vergleichbar aktuelles Debian/Ubuntu), Root- bzw. sudo-Zugriff
- Eine Domain, bei der du eine Subdomain (z. B. `cloud.deine-domain.de`) per DNS-A-Record auf
  deine öffentliche IP zeigen lassen kannst
- SSH-Zugang zum Host
- Grundkenntnisse: Linux-Kommandozeile, `systemd`, einfache YAML-Syntax

## Netzwerk

- Der Host muss aus dem Internet auf Port 80/443 erreichbar sein (Portweiterleitung am Router,
  für Let's-Encrypt-Validierung und HTTPS)
- Empfehlung: der Host bekommt eine feste (statische) IP im LAN, z. B. per DHCP-Reservierung im
  Router
- Empfohlene Netzarchitektur (siehe Kapitel 8.8): der Host hängt in einem eigenen Netzsegment
  direkt am Internet-Router; das übrige Heimnetz hängt an einem zweiten Router mit eigener
  Firewall. Das trennt den Server im Kompromittierungsfall wirksam vom restlichen Heimnetz, ohne
  dass du dafür ein eigenes VLAN einrichten musst.

## Namenskonventionen in diesem Tutorial (Platzhalter)

| Platzhalter | Bedeutung | Beispiel |
|---|---|---|
| `cloud.example.com` | öffentliche Subdomain für Nextcloud | `cloud.deine-domain.de` |
| `192.168.1.20` | LAN-IP des Hosts | passe an dein Netz an |
| `admin` / `CHANGE_ME_STRONG_PASSWORD` | Nextcloud-Admin-Zugangsdaten | durch echte, starke Werte ersetzen |
| `/mnt/nextcloud-data` | Mountpoint Storage-Laufwerk | siehe Kapitel 4 |
| `/mnt/nextcloud-backup` | Mountpoint Backup-Laufwerk | siehe Kapitel 4 |

Ersetze diese Platzhalter konsequent in allen Befehlen und Konfigurationsdateien durch deine eigenen
Werte.
