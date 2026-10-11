#!/bin/bash
# Backup-Script: Nextcloud-Nutzerdaten sichern (Cron-tauglich)
# Quelle: /mnt/nextcloud-data/data/
# Ziel:   /mnt/nextcloud-backup/nextcloud-data-backup/

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

LOGFILE="/var/log/nextcloud-backup.log"

echo "========== $(date) ==========" >> $LOGFILE

/usr/bin/docker exec nextcloud-app php /var/www/html/occ maintenance:mode --on >> $LOGFILE 2>&1

/usr/bin/rsync -avh --delete /mnt/nextcloud-data/data/ /mnt/nextcloud-backup/nextcloud-data-backup/ >> $LOGFILE 2>&1

/usr/bin/docker exec nextcloud-app php /var/www/html/occ maintenance:mode --off >> $LOGFILE 2>&1

echo "Backup abgeschlossen." >> $LOGFILE
echo "" >> $LOGFILE
