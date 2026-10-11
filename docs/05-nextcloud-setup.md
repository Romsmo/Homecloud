# 5. Nextcloud + MariaDB Setup

## 5.1 Vorbereitung

Stelle sicher, dass Kapitel 3 (Docker) und Kapitel 4 (Speicher-Setup, insbesondere
`/mnt/nextcloud-data/data` mit `chown 33:33`) abgeschlossen sind.

## 5.2 Repository-Dateien vorbereiten

```bash
cd compose/nextcloud
cp .env.example .env
nano .env   # echte, starke Passwörter und deine Domain eintragen
```

## 5.3 Container starten

```bash
docker compose up -d
docker compose ps
```

Prüfe die Logs, falls etwas nicht startet:

```bash
docker compose logs -f app
docker compose logs -f db
```

## 5.4 Ersteinrichtung im Browser (innerhalb des LAN)

Öffne `http://<LAN-IP-des-Hosts>:8080` im Browser (z. B. `http://192.168.1.20:8080`). Nextcloud
übernimmt die Admin-Zugangsdaten und die Datenbankverbindung automatisch aus den Umgebungsvariablen.

## 5.5 `trusted_domains` korrekt konfigurieren

Die Umgebungsvariable `NEXTCLOUD_TRUSTED_DOMAINS` wird von Nextcloud **nur beim allerersten
Containerstart** ausgewertet. Willst du später eine Domain hinzufügen oder ändern, funktioniert das
nur über die `occ`-CLI – **nicht** durch bloßes Ändern der Compose-Datei und Neustarten.

Vorgehen, das zuverlässig funktioniert (wichtig: `su` + `cd` **vor** dem `occ`-Aufruf, ein direktes
`docker exec -u www-data ... occ ...` schlägt fehl mit
*"there are no commands defined in the config:system namespace"*):

```bash
docker exec -it nextcloud-app bash
su -s /bin/bash www-data
cd /var/www/html
php occ config:system:set trusted_domains 1 --value=192.168.1.20
php occ config:system:set trusted_domains 2 --value=cloud.example.com
php occ config:system:get trusted_domains
exit
exit
```

## 5.6 Integritätsprüfung

Nextcloud bietet eine eingebaute Prüfung, ob Core-Dateien seit der Installation verändert wurden
(z. B. durch Kompromittierung oder fehlerhafte Updates):

```bash
docker exec -u www-data nextcloud-app php occ integrity:check-core
```

Ein leeres Ergebnis bedeutet: keine Abweichungen gefunden. Details siehe
[Kapitel 8 – Security-Härtung](08-security-hardening.md).

## 5.7 Nützliche `occ`-Befehle

```bash
# Dateien nach manuellen Änderungen im Datenverzeichnis neu einlesen
docker exec -u www-data nextcloud-app php occ files:scan --all

# Wartungsmodus (wird auch in den Backup-/Restore-Skripten verwendet)
docker exec -u www-data nextcloud-app php occ maintenance:mode --on
docker exec -u www-data nextcloud-app php occ maintenance:mode --off
```

## Bekannte Stolpersteine

- `nano` ist im offiziellen Nextcloud-Image nicht vorinstalliert. Nutze stattdessen `occ`-Befehle
  oder editiere Dateien auf dem Host und kopiere sie gezielt (Vorsicht: Besitzrechte können dabei
  brechen, siehe Kapitel 10).
- Nach `docker cp` von `config.php` kann die Fehlermeldung *"Configuration was not read or
  initialized correctly, not overwriting..."* auftreten – Ursache ist ein Besitzrechte-Mismatch
  (root statt www-data). Vermeide das direkte Kopieren von `config.php`; nutze `occ`-Befehle.
