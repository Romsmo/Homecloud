# 6. Reverse Proxy & HTTPS

Das in der Seminararbeit gemessene System terminiert HTTPS direkt auf demselben Host wie
Nextcloud, über einen **nativ auf dem Host installierten Apache** (`mod_proxy`, nicht
containerisiert) mit einem automatisch verwalteten Let's-Encrypt-Zertifikat per Certbot. Das ist
der in Kapitel 4/8 der Arbeit tatsächlich gemessene Weg (u. a. erkennbar am
Apache-Versions-Header in den Messungen).

## 6.1 DNS

Lege einen A-Record für deine Subdomain an, der auf deine öffentliche IP zeigt, z. B.:

```
cloud.example.com.   A   <deine öffentliche IP>
```

Richte am Router eine Portweiterleitung für Port 80 und 443 auf die LAN-IP deines Hosts ein
(Port 80 wird für die Let's-Encrypt-HTTP-01-Validierung benötigt).

## 6.2 Apache installieren und Module aktivieren

```bash
sudo apt install -y apache2
sudo a2enmod proxy proxy_http headers ssl rewrite
sudo systemctl restart apache2
```

## 6.3 vHost anlegen

Kopiere [`config-examples/apache-reverse-proxy-cloud.conf`](../config-examples/apache-reverse-proxy-cloud.conf)
nach `/etc/apache2/sites-available/cloud.example.com.conf` und passe mindestens die Domain an. Der
`ProxyPass`/`ProxyPassReverse` zeigt auf `127.0.0.1:8080`, weil Nextcloud als Docker-Container auf
**demselben Host** läuft (kein separater zweiter Server):

```bash
sudo a2ensite cloud.example.com.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

## 6.4 HTTPS-Zertifikat mit Certbot

```bash
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d cloud.example.com
```

Certbot trägt die Zertifikatspfade automatisch in den vHost ein und richtet die automatische
Erneuerung ein.

## 6.5 `trusted_domains` prüfen

Stelle sicher, dass `cloud.example.com` in Nextclouds `trusted_domains` eingetragen ist (siehe
Kapitel 5.5), sonst blockiert Nextcloud den Zugriff mit einer Fehlermeldung.

## 6.6 Ergebnis prüfen

Rufe `https://cloud.example.com` auf. Ein TLS-Check (z. B. SSL Labs) sollte danach eine gute
Bewertung liefern – im Testsystem der zugrunde liegenden Arbeit wurde **A+** erreicht (TLS 1.2/1.3,
Perfect Forward Secrecy, kein Heartbleed/POODLE/ROBOT).

> **Ehrlicher Befund aus der Arbeit:** Der Apache-Versions-Header (`Server: Apache/2.4.x`) blieb
> sowohl vor als auch nach der Security-Härtung sichtbar – `ServerTokens`/`ServerSignature` allein
> genügen in der Praxis nicht immer, um ihn vollständig zu unterdrücken (siehe
> [Kapitel 8, Maßnahme 7](08-security-hardening.md#7-sicherheitsrelevante-http-header)).

---

## Alternative: Nginx Proxy Manager (Docker-basiert, in der Arbeit nicht gemessen)

Falls du statt der nativen Apache-Installation einen Docker-basierten, über eine Weboberfläche
bedienbaren Reverse Proxy bevorzugst, funktioniert auch **Nginx Proxy Manager (NPM)** – diese
Variante wurde für dieses Tutorial separat aufgebaut und getestet, ist aber **nicht** die in der
Seminararbeit gemessene Konfiguration. Die in Kapitel 4/8 der Arbeit erhobenen Messwerte (TLS-
Bewertung, Security-Header, Apache-Versions-Header) beziehen sich ausschließlich auf den nativen
Apache-Weg oben.

```bash
cd compose/nginx-proxy-manager
docker compose up -d
```

Admin-Oberfläche: `http://<LAN-IP-deines-Hosts>:81`. Standard-Login siehe offizielle
NPM-Dokumentation – **sofort nach dem ersten Login ändern**.

### Proxy Host für Nextcloud anlegen

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

> **Portkonflikt beachten:** Läuft auf demselben Host bereits der native Apache aus Kapitel 6.2–6.4
> auf Port 443, kannst du NPM auf diesem Host **nicht zusätzlich** auf Port 443 betreiben ("address
> already in use"). Setze entweder nur einen der beiden Wege ein, oder betreibe NPM auf einem Host
> ohne bestehenden Webserver.

## Bekannte Stolpersteine

- **HSTS-Fehler im Browser** ("Kein Verbindungsversuch unternommen: Mögliches Sicherheitsproblem"):
  tritt auf, wenn du versuchst, die Subdomain per HTTP statt HTTPS aufzurufen, nachdem der Browser
  bereits einen HSTS-Eintrag für die Domain gespeichert hat. Lösung: sicherstellen, dass ein
  gültiges Let's-Encrypt-Zertifikat aktiv ist und die Seite ausschließlich über `https://`
  aufrufen.
- **Port 443/80 bereits belegt**: wenn ein zweiter Dienst auf demselben Host denselben Port
  beansprucht. Nur ein Reverse Proxy pro Host/Port-Paar.
