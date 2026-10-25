# 4. Speicher-Setup (3-Laufwerk-Architektur)

Ziel: das Storage-Laufwerk und das Backup-Laufwerk werden formatiert, dauerhaft (über `/etc/fstab`,
per UUID) gemountet und stehen anschließend unter festen Pfaden zur Verfügung.

> Passe `/dev/sdX` in den folgenden Befehlen unbedingt an dein System an
> (`lsblk` zeigt die tatsächlichen Gerätenamen). Ein falsches Device zu formatieren löscht Daten
> unwiderruflich.

## 4.1 Laufwerke identifizieren

```bash
lsblk -f
```

Notiere dir, welches Gerät das Storage-Laufwerk (`sdb` im Beispiel) und welches das
Backup-Laufwerk (`sdc` im Beispiel) ist.

## 4.2 Formatieren (ext4)

```bash
sudo mkfs.ext4 /dev/sdb1   # Storage-Laufwerk
sudo mkfs.ext4 /dev/sdc1   # Backup-Laufwerk
```

## 4.3 Mountpoints anlegen

```bash
sudo mkdir -p /mnt/nextcloud-data
sudo mkdir -p /mnt/nextcloud-backup
```

## 4.4 UUIDs ermitteln

```bash
sudo blkid /dev/sdb1
sudo blkid /dev/sdc1
```

## 4.5 Automatisches Einbinden über `/etc/fstab`

```bash
sudo nano /etc/fstab
```

Am Ende ergänzen (UUIDs durch die tatsächlich ermittelten Werte ersetzen):

```
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /mnt/nextcloud-data     ext4  defaults  0  2
UUID=yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy  /mnt/nextcloud-backup   ext4  defaults  0  2
```

Danach:

```bash
sudo mount -a
df -h /mnt/nextcloud-data /mnt/nextcloud-backup
```

## 4.6 Zielordnerstruktur auf dem Storage-Laufwerk

Nextcloud selbst legt bei der Ersteinrichtung automatisch einen `data/`-Unterordner an. Damit
Docker diesen Unterordner direkt als Bind-Mount verwenden kann, legen wir ihn vorab an und setzen
die Besitzrechte auf die im Nextcloud-Container verwendete `www-data`-UID/GID (33:33):

```bash
sudo mkdir -p /mnt/nextcloud-data/data
sudo chown -R 33:33 /mnt/nextcloud-data/data
```

> **Wichtig:** Es wird bewusst **nur der `data/`-Unterordner** gemountet, nicht das gesamte
> Nextcloud-Verzeichnis. App-Code und Konfiguration bleiben in einem regulären Docker-Volume auf dem
> System-Laufwerk. Das hält die Trennung "Nutzdaten vs. Anwendung" sauber und macht Backups des
> Storage-Laufwerks eindeutig auf die Nutzdaten fokussiert.

Dieser Pfad (`/mnt/nextcloud-data/data`) wird in Kapitel 5 (Nextcloud-Compose-Datei) und in
Kapitel 6 (Backup-/Restore-Skripte) exakt so wiederverwendet.

## 4.7 Backup-Zielverzeichnis vorbereiten

```bash
sudo mkdir -p /mnt/nextcloud-backup/nextcloud-data
sudo chown -R $USER:$USER /mnt/nextcloud-backup
```
