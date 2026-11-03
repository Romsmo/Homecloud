# 2. Voraussetzungen

## Hardware

- Ein Host (physisch oder VM): mind. 2 CPU-Kerne, 4 GB RAM empfohlen (das Testsystem der
  zugrunde liegenden Arbeit lief sogar mit einem Intel Core i3-4100M und 3,8 GiB RAM). Ein
  Debian-fähiger Mini-PC, NAS-Server, alter Laptop oder Raspberry Pi (64-bit) reicht.
- Drei separate Laufwerke/Datenträger für System, Storage und Backup (siehe Kapitel 4) – im
  Testsystem der Arbeit eine interne SSD plus zwei externe USB-Datenträger.

## Software / Zugänge

- Debian 13 (oder vergleichbar aktuelles Debian/Ubuntu), Root- bzw. sudo-Zugriff
- SSH-Zugang zum Host
- Grundkenntnisse: Linux-Kommandozeile, `systemd`, einfache YAML-Syntax

## Netzwerk

- Das Basissystem dieses Tutorials ist ausschließlich **im LAN** erreichbar – dafür ist keine
  Portweiterleitung am Router und keine öffentliche Domain nötig (beides nur für den optionalen
  Reverse Proxy, Kapitel 7, Maßnahme 1)
- Empfehlung: der Host bekommt eine feste (statische) IP im LAN, z. B. per DHCP-Reservierung im
  Router – das hält `trusted_domains` (Kapitel 5.5) und die Firewall-Regeln (Kapitel 7) stabil
- Empfohlene Netzarchitektur (siehe Kapitel 7.13): der Host hängt in einem eigenen Netzsegment
  direkt am Internet-Router; das übrige Heimnetz hängt an einem zweiten Router mit eigener
  Firewall. Das trennt den Server im Kompromittierungsfall wirksam vom restlichen Heimnetz, ohne
  dass du dafür ein eigenes VLAN einrichten musst
- Möchtest du zusätzlich von außerhalb des LAN per HTTPS zugreifen (wie im Testsystem der
  zugrunde liegenden Arbeit), benötigst du dafür einen eigenen Reverse Proxy mit
  TLS-Zertifikat sowie eine Domain mit DNS-A-Record und eine Portweiterleitung für 80/443 –
  die Einrichtung ist optional in Kapitel 7, Maßnahme 1 beschrieben

## Namenskonventionen in diesem Tutorial (Platzhalter)

| Platzhalter | Bedeutung | Beispiel |
|---|---|---|
| `192.168.1.20` | LAN-IP des Hosts | passe an dein Netz an |
| `admin` / `CHANGE_ME_STRONG_PASSWORD` | Nextcloud-Admin-Zugangsdaten | durch echte, starke Werte ersetzen |
| `/mnt/nextcloud-data` | Mountpoint Storage-Laufwerk | siehe Kapitel 4 |
| `/mnt/nextcloud-backup` | Mountpoint Backup-Laufwerk | siehe Kapitel 4 |
| `<DOMAIN>` | Domain deines Servers (nur für den optionalen Reverse Proxy, Kapitel 7, Maßnahme 1) | z. B. `cloud.example.org`; DNS-A-Record auf deine öffentliche IP |
| `<PROXY-IP>` | Adresse des Reverse Proxys aus Sicht des Nextcloud-Containers (`trusted_proxies`) | meist das Gateway des Docker-Bridge-Netzes, z. B. `172.18.0.1` |

Ersetze diese Platzhalter konsequent in allen Befehlen und Konfigurationsdateien durch deine eigenen
Werte.
