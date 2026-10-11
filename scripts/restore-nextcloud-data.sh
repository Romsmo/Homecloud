#!/bin/bash
# Restore-Script: Nextcloud-Nutzerdaten aus dem Backup wiederherstellen
# Gegenstück zu backup-nextcloud-data.sh
# Quelle:  /mnt/nextcloud-backup/nextcloud-data-backup/
# Ziel:    /mnt/nextcloud-data/data/

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

BACKUP_DIR="/mnt/nextcloud-backup/nextcloud-data-backup/"
DATA_DIR="/mnt/nextcloud-data/data/"
LOGFILE="/var/log/nextcloud-restore.log"
CONTAINER="nextcloud-app"

# ─── Sicherheitsabfrage ──────────────────────────────────────────
echo "⚠️  ACHTUNG: Dieses Script überschreibt alle Nutzerdaten in:"
echo "    $DATA_DIR"
echo "mit dem Stand des Backups aus:"
echo "    $BACKUP_DIR"
echo ""
read -p "Wirklich fortfahren? (ja/nein): " ANSWER
if [ "$ANSWER" != "ja" ]; then
    echo "Abgebrochen."
    exit 1
fi

# ─── Prüfen, ob das Backup existiert und nicht leer ist ──────────
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR")" ]; then
    echo "❌ FEHLER: Backup-Verzeichnis fehlt oder ist leer: $BACKUP_DIR"
    exit 1
fi

echo "========== RESTORE $(date) ==========" >> "$LOGFILE"

# ─── 1. Wartungsmodus aktivieren ─────────────────────────────────
echo "→ Wartungsmodus AN..."
/usr/bin/docker exec "$CONTAINER" php /var/www/html/occ maintenance:mode --on >> "$LOGFILE" 2>&1

# ─── 2. Daten aus dem Backup zurückspielen ───────────────────────
echo "→ Stelle Daten wieder her (rsync)..."
/usr/bin/rsync -avh --delete "$BACKUP_DIR" "$DATA_DIR" >> "$LOGFILE" 2>&1
RSYNC_EXIT=$?

if [ $RSYNC_EXIT -ne 0 ]; then
    echo "❌ rsync-Fehler (Exit-Code $RSYNC_EXIT) – siehe $LOGFILE"
    echo "RESTORE FEHLGESCHLAGEN (rsync Exit $RSYNC_EXIT)" >> "$LOGFILE"
    # Wartungsmodus trotzdem wieder ausschalten
    /usr/bin/docker exec "$CONTAINER" php /var/www/html/occ maintenance:mode --off >> "$LOGFILE" 2>&1
    exit 1
fi

# ─── 3. Dateirechte korrigieren ──────────────────────────────────
echo "→ Setze Dateirechte (www-data)..."
chown -R www-data:www-data "$DATA_DIR" >> "$LOGFILE" 2>&1

# ─── 4. Nextcloud-Dateiindex neu einlesen ────────────────────────
echo "→ Scanne Dateien in Nextcloud ein (kann dauern)..."
/usr/bin/docker exec -u www-data "$CONTAINER" php /var/www/html/occ files:scan --all >> "$LOGFILE" 2>&1

# ─── 5. Wartungsmodus deaktivieren ───────────────────────────────
echo "→ Wartungsmodus AUS..."
/usr/bin/docker exec "$CONTAINER" php /var/www/html/occ maintenance:mode --off >> "$LOGFILE" 2>&1

echo "Restore abgeschlossen." >> "$LOGFILE"
echo "" >> "$LOGFILE"
echo "✅ Restore abgeschlossen. Details: $LOGFILE"
