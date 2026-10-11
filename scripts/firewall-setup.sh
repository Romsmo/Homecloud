#!/bin/bash
# Grundlegende Firewall-Haertung (Default-Deny) fuer den Docker-Host
# Nur als Vorlage gedacht - vor dem Ausfuehren Regeln an die eigene
# Netzwerkumgebung anpassen (SSH-Port, LAN-Subnetz, ggf. abweichende Docker-Netz-Ranges).
#
# WICHTIG: Stelle sicher, dass Regel fuer SSH VOR dem Aktivieren von UFW gesetzt ist,
# sonst sperrst du dich selbst aus!

set -e

SSH_PORT=22
LAN_SUBNET="192.168.1.0/24"   # an dein LAN anpassen

sudo apt install -y ufw

# Default-Deny: eingehend blockieren, ausgehend erlauben
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH erlauben (zuerst!)
sudo ufw allow "${SSH_PORT}/tcp" comment 'SSH'

# Nextcloud-Port nur aus dem LAN erlauben, nicht global
sudo ufw allow from "$LAN_SUBNET" to any port 8080 proto tcp comment 'Nextcloud - nur LAN'

# Optional: Portainer nur aus dem LAN
sudo ufw allow from "$LAN_SUBNET" to any port 9000 proto tcp comment 'Portainer - nur LAN'

# Firewall aktivieren
sudo ufw --force enable

# Status pruefen
sudo ufw status verbose
