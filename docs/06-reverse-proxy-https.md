# 6. Reverse Proxy & HTTPS

Das in der Seminararbeit gemessene System terminiert HTTPS direkt auf demselben Host wie
Nextcloud, über einen Docker-basierten Reverse Proxy mit automatisch verwalteten
Let's-Encrypt-Zertifikaten. Dieses Tutorial verwendet dafür **Nginx Proxy Manager (NPM)**.

> Die Arbeit selbst nennt den eingesetzten Reverse Proxy bewusst nicht als Untersuchungsgegenstand
> ("der Proxy ist nicht Untersuchungsgegenstand") – es kommt nur auf TLS-Terminierung mit
> Let's-Encrypt-Zertifikat an, nicht auf das konkrete Produkt. NPM ist eine gängige, einfach zu
> bedienende Docker-Lösung dafür und wird deshalb hier als Referenzweg verwendet.

## 6.1 DNS

Lege einen A-Record für deine Subdomain an, der auf deine öffentliche IP zeigt, z. B.:

```
cloud.example.com.   A   <deine öffentliche IP>
```

Richte am Router eine Portweiterleitung für Port 80 und 443 auf die LAN-IP deines Hosts ein
(Port 80 wird für die Let's-Encrypt-HTTP-01-Validierung benötigt).

## 6.2 Nginx Proxy Manager starten

```bash
cd compose/nginx-proxy-manager
docker compose up -d
```

Admin-Oberfläche: `http://<LAN-IP-deines-Hosts>:81`. Standard-Login siehe offizielle
NPM-Dokumentation – **sofort nach dem ersten Login ändern**.

## 6.3 Proxy Host für Nextcloud anlegen

In der NPM-Oberfläche: *Proxy Hosts → Add Proxy Host*

| Feld | Wert |
|---|---|
| Domain Names | `cloud.example.com` |
| Scheme | `http` |
| Forward Hostname/IP | `127.0.0.1` (Nextcloud läuft auf demselben Host, Port 8080) |
| Forward Port | `8080` |
| Block Common Exploits | aktivieren |
| Websockets Support | aktivieren |

Im Tab *SSL*: **Request a new SSL Certificate** (Let's Encrypt), *Force SSL* und *HTTP/2 Support*
aktivieren, Nutzungsbedingungen akzeptieren, speichern.

## 6.4 `trusted_domains` prüfen

Stelle sicher, dass `cloud.example.com` in Nextclouds `trusted_domains` eingetragen ist (siehe
Kapitel 5.5), sonst blockiert Nextcloud den Zugriff mit einer Fehlermeldung.

## 6.5 Ergebnis prüfen

Rufe `https://cloud.example.com` auf. Ein TLS-Check (z. B. SSL Labs) sollte danach eine gute
Bewertung liefern – im Testsystem der zugrunde liegenden Arbeit wurde **A+** erreicht (TLS 1.2/1.3,
Perfect Forward Secrecy, kein Heartbleed/POODLE/ROBOT).

---

## Alternative: Apache als Reverse Proxy auf einem zweiten Server

Falls du bereits einen separaten Server mit laufendem Apache und eigener Domain betreibst und
Nextcloud auf einem **anderen** Host (reiner Docker-Host ohne eigene Domain) laufen lassen willst,
funktioniert auch folgende Variante – sie wurde in der Praxis erprobt, ist aber **nicht** die in
der Seminararbeit gemessene Konfiguration:

- Server A: bestehender Apache-Server mit eigener Domain, fungiert als Reverse Proxy
- Server B: separater Docker-Host, auf dem nur Nextcloud+MariaDB läuft, erreichbar aus dem LAN
  von Server A (z. B. `192.168.1.20:8080`)

### Benötigte Apache-Module aktivieren (auf Server A)

```bash
sudo a2enmod proxy proxy_http headers ssl rewrite
sudo systemctl restart apache2
```

### vHost anlegen

Kopiere [`config-examples/apache-reverse-proxy-cloud.conf`](../config-examples/apache-reverse-proxy-cloud.conf)
nach `/etc/apache2/sites-available/cloud.example.com.conf`, passe Domain und LAN-IP von Server B an:

```bash
sudo a2ensite cloud.example.com.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### HTTPS-Zertifikat mit Certbot

```bash
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d cloud.example.com
```

> **Portkonflikt beachten:** Läuft auf demselben Host bereits ein Apache auf Port 443, kannst du
> NPM auf diesem Host **nicht zusätzlich** auf Port 443 betreiben ("address already in use").
> Entweder Apache direkt als Proxy nutzen (wie hier beschrieben) oder NPM auf einem Host ohne
> bestehenden Webserver einsetzen.

## Bekannte Stolpersteine

- **HSTS-Fehler im Browser** ("Kein Verbindungsversuch unternommen: Mögliches Sicherheitsproblem"):
  tritt auf, wenn du versuchst, die Subdomain per HTTP statt HTTPS aufzurufen, nachdem der Browser
  bereits einen HSTS-Eintrag für die Domain gespeichert hat. Lösung: sicherstellen, dass ein
  gültiges Let's-Encrypt-Zertifikat aktiv ist und die Seite ausschließlich über `https://`
  aufrufen.
- **Port 443/80 bereits belegt**: wenn ein zweiter Dienst auf demselben Host denselben Port
  beansprucht. Nur ein Reverse Proxy pro Host/Port-Paar.
