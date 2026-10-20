# 10. Troubleshooting / bekannte Fehler

Eine Sammlung von Fehlern, die während des Aufbaus des Referenzsystems tatsächlich aufgetreten sind
– inklusive Ursache und Lösung.

## Docker Compose YAML-Syntax

| Fehler | Ursache | Lösung |
|---|---|---|
| `additional properties 'enviroment' not allowed` | Tippfehler im Schlüssel | Korrekt: `environment:` (nicht `enviroment`) |
| `services.volumes additional properties ... not allowed` | `volumes:` fälschlich unter `services:` verschachtelt | `volumes:` muss ein Top-Level-Schlüssel auf derselben Einrückungsebene wie `services:` sein |
| `services.container_name must be a mapping` | Falsche Einrückung | `container_name:` muss direkt unter dem jeweiligen Service-Block stehen, gleiche Einrückung wie `image:`, `restart:` etc. |

## Container-Images

| Fehler | Ursache | Lösung |
|---|---|---|
| `error from registry: denied` beim Pull von `ghcr.io/home-assistant/home-assistant:stable` | Image unter dieser Registry nicht (mehr) verfügbar/zugänglich | Docker-Hub-Image `homeassistant/home-assistant:stable` verwenden |
| Port 443 "address already in use" beim Start von Nginx Proxy Manager | Auf demselben Host läuft bereits der native Apache-Reverse-Proxy (Kapitel 6) auf Port 443 | Entweder nur den nativen Apache als Reverse Proxy nutzen (Kapitel 6, primärer/gemessener Weg) statt NPM, oder NPM auf einem Host ohne bestehenden Webserver betreiben |

## Nextcloud-Konfiguration

| Fehler | Ursache | Lösung |
|---|---|---|
| `trusted_domains`-Änderung über Compose/Env wirkungslos | `NEXTCLOUD_TRUSTED_DOMAINS` wird nur beim allerersten Containerstart ausgewertet | Änderung über `occ config:system:set trusted_domains ...` vornehmen (siehe Kapitel 5.5) |
| `there are no commands defined in the config:system namespace` | `occ`-Befehl per `docker exec -u www-data ... occ ...` direkt aufgerufen, ohne vorheriges `su` + `cd` | Erst `docker exec -it nextcloud-app bash`, dann `su -s /bin/bash www-data`, dann `cd /var/www/html`, erst dann `php occ ...` ausführen |
| `nano: command not found` im Nextcloud-Container | `nano` ist im offiziellen Image nicht enthalten | `occ`-CLI-Befehle statt manuellem Editieren verwenden, oder Datei gezielt mit `docker cp` bearbeiten |
| `Configuration was not read or initialized correctly, not overwriting ...` nach `docker cp` von `config.php` | Besitzrechte-Mismatch (root statt www-data) nach dem Kopieren | `config.php` nicht direkt per `docker cp` bearbeiten; stattdessen `occ`-Befehle nutzen |
| Entfernter `X-Powered-By`-Header taucht nach einem Image-Update wieder auf | Härtungs-/Konfigurationsänderungen, die nicht dauerhaft außerhalb des Images gespeichert sind (z. B. nur zur Laufzeit im Container gesetzt), gehen bei `docker compose pull && up -d` verloren | Header-Konfiguration als Teil deiner persistenten Konfiguration (z. B. `occ`-Einstellungen oder Reverse-Proxy-Konfiguration, nicht im Container selbst) pflegen und nach jedem Update mit `curl -I` erneut prüfen |

## HTTPS / Browser

| Fehler | Ursache | Lösung |
|---|---|---|
| "Kein Verbindungsversuch unternommen: Mögliches Sicherheitsproblem" beim Aufruf über HTTP | Der Browser hat für die Domain bereits einen HSTS-Eintrag gespeichert und verweigert jeden HTTP-Fallback | Gültiges Let's-Encrypt-Zertifikat einrichten (Kapitel 6.4) und die Seite ausschließlich über `https://` aufrufen |

## Backup / Cron

| Fehler | Ursache | Lösung |
|---|---|---|
| Cron-Job feuert nicht zur geplanten Zeit | (a) `~` wird von Cron nicht zuverlässig expandiert; (b) Crons minimaler `PATH` enthält `docker`/`rsync` nicht | (a) Absolute Pfade in Crontab und Skript verwenden; (b) `PATH=...` explizit am Skriptanfang setzen und Programme über volle Pfade aufrufen (`/usr/bin/docker`, `/usr/bin/rsync`). Zusätzlich prüfen: `crontab -l` (Eintrag vorhanden?), `systemctl status cron` (Dienst aktiv?) |
| `rsync: command not found` | `rsync` ist auf dem Host nicht installiert | `sudo apt install rsync -y` (auf dem Host, nicht im Container) |

## Allgemeines Vorgehen bei Problemen

1. Container-Logs prüfen: `docker compose logs -f <service>`
2. Container-Status prüfen: `docker compose ps`
3. Bei `occ`-Problemen: interaktiv in den Container wechseln (`docker exec -it nextcloud-app bash`)
   statt Einzelbefehle "blind" abzusetzen
4. Bei Problemen zwischen Reverse Proxy und Nextcloud: Erreichbarkeit direkt auf dem Host testen
   mit `curl -v http://127.0.0.1:8080` (Nextcloud läuft als Docker-Container auf demselben Host
   wie der native Apache-Reverse-Proxy aus Kapitel 6, nur lokal gebunden)
