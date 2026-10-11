# 7. Backup & Restore

Backup und Restore arbeiten ausschließlich auf dem in Kapitel 4 eingerichteten Daten- bzw.
Backup-Laufwerk (`/mnt/nextcloud-data/data` → `/mnt/nextcloud-backup/nextcloud-data-backup`).
Beide Skripte wrappen den eigentlichen `rsync`-Vorgang in Nextclouds Wartungsmodus, damit während
des Kopiervorgangs keine Datei-Inkonsistenzen durch gleichzeitige Schreibzugriffe entstehen.

## 7.1 Voraussetzung: `rsync` installieren

```bash
sudo apt install -y rsync
```

(auf dem Host, **nicht** im Container – rsync arbeitet direkt auf den gemounteten Verzeichnissen)

## 7.2 Backup-Skript

Datei: [`scripts/backup-nextcloud-data.sh`](../scripts/backup-nextcloud-data.sh)

```bash
sudo cp scripts/backup-nextcloud-data.sh /root/backup-nextcloud-data.sh
sudo chmod +x /root/backup-nextcloud-data.sh
```

Was es macht: Wartungsmodus AN → `rsync -avh --delete` von `/mnt/nextcloud-data/data/` nach
`/mnt/nextcloud-backup/nextcloud-data-backup/` → Wartungsmodus AUS → Protokollierung in
`/var/log/nextcloud-backup.log`.

Manuell testen:

```bash
sudo /root/backup-nextcloud-data.sh
cat /var/log/nextcloud-backup.log
```

## 7.3 Automatisierung per Cron

```bash
sudo crontab -e
```

Eintragen (täglich um 3 Uhr):

```
0 3 * * * /root/backup-nextcloud-data.sh
```

Prüfen, dass der Cron-Dienst läuft:

```bash
sudo systemctl status cron
sudo systemctl enable --now cron   # falls nicht aktiv
```

## 7.4 Restore-Skript

Datei: [`scripts/restore-nextcloud-data.sh`](../scripts/restore-nextcloud-data.sh)

```bash
sudo cp scripts/restore-nextcloud-data.sh /root/restore-nextcloud-data.sh
sudo chmod +x /root/restore-nextcloud-data.sh
```

Was es macht:

1. Interaktive Sicherheitsabfrage (`ja`/`nein`) – ein Restore überschreibt alle aktuellen
   Nutzerdaten und darf nicht versehentlich ausgelöst werden
2. Prüft, ob das Backup-Verzeichnis existiert und nicht leer ist
3. Wartungsmodus AN → `rsync -avh --delete` vom Backup zurück ins Datenverzeichnis
4. Dateirechte auf `www-data:www-data` korrigieren
5. `occ files:scan --all` – **entscheidender Schritt**, ohne den zurückgespielte Dateien in der
   Weboberfläche unsichtbar bleiben
6. Wartungsmodus AUS
7. Vollständiges Logging nach `/var/log/nextcloud-restore.log`

Ausführen (immer mit `sudo`, wegen `chown`):

```bash
sudo /root/restore-nextcloud-data.sh
```

> **Wichtig:** Das Restore-Skript läuft bewusst **nicht** per Cron, sondern ausschließlich manuell
> – ein automatisiertes, ungeprüftes Überschreiben aller Nutzerdaten wäre riskant.

> **Gemessen:** Ein Testlauf des Restore-Skripts in der zugrunde liegenden Seminararbeit zeigte
> eine Wiederherstellungszeit von rund drei Minuten bis zur nutzbaren Nextcloud-Instanz; die
> tatsächliche Dauer skaliert mit der Menge der zu übertragenden Daten.

> **Ehrlicher Hinweis zur 3-2-1-Regel:** Dieses Setup erfüllt die 3-2-1-Backup-Regel (drei Kopien,
> zwei Medientypen, eine davon räumlich getrennt) **nicht vollständig** – es fehlt eine räumlich
> getrennte Kopie. Ergänze dafür z. B. eine extern gelagerte Festplatte, die du periodisch
> anschließt, oder einen verschlüsselten Cloud-Backup-Zielort. Ohne räumliche Trennung schützt
> dich dieses Backup nicht gegen Diebstahl, Brand oder Wasserschaden am Serverstandort.

## 7.5 Restore testen (empfohlen)

Ein einfacher End-to-End-Test des gesamten Backup/Restore-Zyklus:

1. Lege eine Testdatei über die Nextcloud-Weboberfläche an
2. Führe ein manuelles Backup aus (`sudo /root/backup-nextcloud-data.sh`)
3. Lösche die Testdatei über die Weboberfläche
4. Führe das Restore-Skript aus (`sudo /root/restore-nextcloud-data.sh`)
5. Prüfe, ob die Testdatei wieder sichtbar ist

## Bekannte Stolpersteine

- **Cron-Job feuert nicht**: prüfe `sudo crontab -l` (ist der Eintrag gespeichert?),
  `sudo systemctl status cron` (läuft der Dienst?). Zwei häufige Ursachen:
  - `~` wird von Cron nicht zuverlässig expandiert → in Crontab-Einträgen und im Skript immer
    absolute Pfade verwenden.
  - Cron nutzt einen minimalen `PATH`, der `docker`/`rsync` oft nicht enthält → deshalb setzt das
    Skript `PATH=...` ganz oben selbst und ruft `docker`/`rsync` über ihre vollen Pfade
    (`/usr/bin/docker`, `/usr/bin/rsync`) auf.
- **`rsync: command not found`**: `rsync` fehlt auf dem Host → `sudo apt install rsync -y`
  (siehe 7.1).
