# 7. Security-Härtung

Dieses Kapitel setzt die in der Seminararbeit (Kapitel 3, "Erforderliche Sicherheitsmaßnahmen")
hergeleiteten Maßnahmen um – in der **Prioritätsreihenfolge**, die die finale Fassung der Arbeit
in Kapitel 5.2 aus dem Verhältnis von Schutzwirkung zu Aufwand ableitet. Zu jeder Maßnahme sind,
soweit verfügbar, die **real am Testsystem gemessenen Vorher-/Nachher-Werte** aus Kapitel 4
angegeben – als realistischer Maßstab, nicht als Garantie, dass dein eigenes System exakt
dieselben Werte erreicht. Maßnahme 1 und 7 beziehen sich dabei, wie dort vermerkt, auf die
optionale HTTPS-/Reverse-Proxy-Schicht des Testsystems der Arbeit (Beispielkonfiguration in
Maßnahme 1; siehe auch Kapitel 1).

| # | Maßnahme | Schutzziel | Wirksamkeit | Aufwand |
|---|---|---|---|---|
| 1 | HTTPS/TLS | Vertraulichkeit | hoch | niedrig |
| 2 | Zwei-Faktor-Authentifizierung | Vertraulichkeit | hoch | niedrig |
| 3 | Passwortrichtlinie + HIBP-Check | Vertraulichkeit | hoch | niedrig |
| 4 | Automatisierte Updates | alle | hoch | niedrig |
| 5 | Getestetes Backup (3-2-1) | Verfügbarkeit | hoch | mittel |
| 6 | Restriktive Firewall / Portreduktion | Vertraulichkeit | mittel | niedrig |
| 7 | Sicherheitsrelevante HTTP-Header | Vertraulichkeit | mittel | niedrig |
| 8 | Brute-Force-Schutz | Vertraulichkeit | mittel | niedrig |
| 9 | Integritäts-/Schwachstellenüberwachung | Integrität | mittel | mittel |
| 10 | Container-/Serverhärtung (CIS-Benchmark) | alle | mittel | hoch |
| 11 | Verschlüsselung ruhender Daten + Backups | Vertraulichkeit | hoch | mittel |
| 12 | FIDO2/WebAuthn statt reinem TOTP | Vertraulichkeit | hoch | mittel |
| 13 | Netzwerksegmentierung / Server-Isolation | Vertraulichkeit/Integrität Dritter | hoch | mittel–hoch |

Die Arbeit kommt zum Schluss, dass bereits die ersten vier bis fünf Maßnahmen (HTTPS, 2FA,
Updates, Backup) den größten Teil der Risikoreduktion bei vergleichsweise geringem Aufwand
bringen, während die hinteren Maßnahmen einen abnehmenden Grenznutzen haben. Dieses Kapitel ist
entsprechend sortiert.

## 1. HTTPS/TLS

**Optional – im Testsystem der Arbeit eingesetzt und für den Zugriff von außerhalb des LAN
erforderlich.** Das Basissystem aus den Kapiteln 3–6 ist nur im LAN per HTTP erreichbar. Im
Testsystem der zugrunde liegenden Arbeit lief auf demselben Host zusätzlich **nativ** (nicht als
separater Server) ein Apache-Reverse-Proxy, der HTTPS per Let's-Encrypt-Zertifikat (automatisiert
erneuert über Certbot) terminierte (siehe Kapitel 1). Der Proxy wurde gezielt dafür eingesetzt,
weil das eingesetzte Nextcloud-Container-Image selbst keine automatisiert erneuerbaren,
vertrauenswürdigen TLS-Zertifikate bereitstellt – TLS-Terminierung am Proxy ist dabei reine
Transportebene und verändert nicht die Anwendungssicherheit von Nextcloud selbst. Die folgenden
Schritte bilden diese Schicht als **Beispielkonfiguration** nach; Domain, IP-Adressen und Pfade
sind Platzhalter und an dein System anzupassen. **Gemessen (Testsystem der Arbeit, mit Reverse
Proxy):** SSL-Labs-Bewertung **A+** (TLS 1.2/1.3, Perfect Forward Secrecy, kein
Heartbleed/POODLE/ROBOT) im gehärteten Zustand, gegenüber keiner TLS-Verschlüsselung im
Ausgangszustand.

**Voraussetzungen:** eine Domain (`<DOMAIN>`, z. B. `cloud.example.org`) mit DNS-A-Record auf deine
öffentliche IP, im Router eine Portweiterleitung von 80/tcp und 443/tcp auf den Host (Port 80
wird für die Zertifikatsausstellung benötigt) sowie – falls du die Firewall aus Maßnahme 6
nutzt – freigegebene Ports 80/tcp und 443/tcp. Setze diesen Schritt erst um, wenn 2FA
(Maßnahme 2), Passwortrichtlinie (Maßnahme 3) und Brute-Force-Schutz (Maßnahme 8) aktiv sind,
weil der Dienst danach aus dem Internet erreichbar ist.

**Schritt 1 – Apache und Certbot installieren und die benötigten Module aktivieren:**

```bash
sudo apt update
sudo apt install -y apache2 certbot python3-certbot-apache
sudo a2enmod proxy proxy_http headers rewrite ssl
```

**Schritt 2 – einen einfachen HTTP-vHost anlegen** (`/etc/apache2/sites-available/nextcloud.conf`),
damit Certbot die Domain validieren kann, und aktivieren:

```apache
<VirtualHost *:80>
    ServerName <DOMAIN>
</VirtualHost>
```

```bash
sudo a2ensite nextcloud && sudo systemctl reload apache2
```

**Schritt 3 – Zertifikat ausstellen.** Certbot richtet die automatische Erneuerung selbst ein
(systemd-Timer); mit dem Dry-Run prüfst du sie:

```bash
sudo certbot certonly --apache -d <DOMAIN>
sudo certbot renew --dry-run
```

**Schritt 4 – den vHost durch die endgültige Fassung ersetzen** (HTTP leitet auf HTTPS um, HTTPS
reicht intern an den Nextcloud-Container auf Port 8080 weiter; die Header aus Maßnahme 7 kommen in
den 443-Block):

```apache
<VirtualHost *:80>
    ServerName <DOMAIN>
    RewriteEngine On
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>

<VirtualHost *:443>
    ServerName <DOMAIN>
    SSLEngine On
    SSLCertificateFile /etc/letsencrypt/live/<DOMAIN>/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/<DOMAIN>/privkey.pem
    SSLProtocol -all +TLSv1.2 +TLSv1.3
    ProxyPreserveHost On
    RequestHeader set X-Forwarded-Proto "https"
    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/
    # Security-Header: siehe Maßnahme 7
</VirtualHost>
```

```bash
sudo apache2ctl configtest && sudo systemctl reload apache2
```

**Schritt 5 – Nextcloud mitteilen, dass es hinter einem Reverse Proxy läuft** (die Domain
zusätzlich zur LAN-IP in `trusted_domains`, siehe 5.5). `<PROXY-IP>` ist die Adresse, mit der der
Proxy aus Sicht des Containers ankommt; bei Docker ist das meist das Gateway des Bridge-Netzes
(z. B. `172.18.0.1`, prüfbar mit `docker network inspect`):

```bash
docker exec -u www-data nextcloud-app php occ config:system:set trusted_domains 2 --value=<DOMAIN>
docker exec -u www-data nextcloud-app php occ config:system:set trusted_proxies 0 --value=<PROXY-IP>
docker exec -u www-data nextcloud-app php occ config:system:set forwarded_for_headers 0 --value=HTTP_X_FORWARDED_FOR
docker exec -u www-data nextcloud-app php occ config:system:set overwriteprotocol --value=https
docker exec -u www-data nextcloud-app php occ config:system:set overwrite.cli.url --value=https://<DOMAIN>
```

**Schritt 6 – prüfen:** Aufruf von `https://<DOMAIN>` im Browser, die Weiterleitung von HTTP auf HTTPS
(`curl -I http://<DOMAIN>`) und anschließend die TLS-Bewertung bei SSL Labs sowie die Header-Bewertung
bei securityheaders.com, wie in der Arbeit gemessen. Die Trusted-Proxy-Einstellungen wurden in der
Arbeit für die Brute-Force-Drosselung gesetzt (die IP des Angreifers statt die des Proxys soll
erfasst werden); ihre Wirkung wurde dort nicht gesondert getestet.

## 2. Zwei-Faktor-Authentifizierung (2FA)

Nextcloud bringt TOTP-basierte 2FA als App mit:

```bash
docker exec -u www-data nextcloud-app php occ app:enable twofactor_totp
```

Jeder Nutzer aktiviert 2FA individuell unter *Einstellungen → Sicherheit* (QR-Code mit einer
Authenticator-App wie Aegis oder FreeOTP scannen). Im Testsystem der Arbeit war **ausschließlich
TOTP** im Einsatz (kein FIDO2/WebAuthn) – siehe Maßnahme 12 für die Einordnung dieses Restrisikos.

Backup-Codes für den Fall eines verlorenen Geräts solltest du zusätzlich aktivieren:

```bash
docker exec -u www-data nextcloud-app php occ app:enable twofactor_backupcodes
```

## 3. Passwortrichtlinie mit Datenleck-Abgleich

Die mitgelieferte App "Password Policy" erzwingt eine Mindestlänge, verbietet gängige/bekannte
Passwörter und kann neue Passwörter zusätzlich gegen bekannte Datenlecks prüfen
(Have-I-Been-Pwned-Abgleich). Im Testsystem der Arbeit war die Mindestlänge auf **10 Zeichen**
gesetzt, häufige Passwörter waren verboten und der HIBP-Abgleich war aktiv; zusätzlich waren
Anforderungen an Groß-/Kleinschreibung, Ziffern und Sonderzeichen aktiviert (in den
Admin-Einstellungen; die folgenden `occ`-Befehle setzen nur Mindestlänge und HIBP-Abgleich):

```bash
docker exec -u www-data nextcloud-app php occ app:enable password_policy
docker exec -u www-data nextcloud-app php occ config:app:set password_policy minLength --value=10
docker exec -u www-data nextcloud-app php occ config:app:set password_policy enforceHaveIBeenPwned --value=1
```

> **Hinweis:** Passe `minLength` und die weiteren Optionen in den Admin-Einstellungen
> (*Einstellungen → Sicherheit*) bzw. per `occ config:app:set password_policy ...` an deine eigenen
> Anforderungen an. Eine höhere Mindestlänge erhöht die Sicherheit weiter und war im Testsystem der
> Arbeit nicht gesetzt (Mindestlänge 10); die Komplexitätsanforderungen (Groß-/Kleinschreibung,
> Ziffern, Sonderzeichen) waren dort aktiviert.

## 4. Automatisierte Updates

Betriebssystem-Sicherheitsupdates automatisieren:

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Docker-Images regelmäßig aktualisieren (nicht vollautomatisch, da Kompatibilitätsprobleme
auftreten können):

```bash
cd compose/nextcloud
docker compose pull
docker compose up -d
docker exec -u www-data nextcloud-app php occ upgrade
```

**Gemessen:** Die Arbeit vergleicht in Abbildung 6 ein älteres gegen ein aktuelleres
Nextcloud-Image per Trivy-Scan: Das ältere Image wies **1.310 HIGH + 77 CRITICAL = 1.387**
Schwachstellen auf, das zum Messzeitpunkt aktuelle Image nur noch **285 HIGH + 4 CRITICAL = 289**
(siehe auch Maßnahme 9). Ein zusätzliches, konkretes Beispiel aus der Arbeit (am dortigen, per
Apache-Reverse-Proxy terminierten Testsystem): Nach einem Image-Update stieg die im
Response-Header offengelegte Apache-Version von 2.4.65 auf 2.4.68 – der Header blieb dabei
weiterhin sichtbar (siehe Maßnahme 7). Kontinuierliches Update-Management ist damit keine
Formsache, sondern eine der wirksamsten Einzelmaßnahmen: allein der Versionsunterschied zwischen
den beiden gemessenen Images bedeutet einen Unterschied von rund 1.100 Schwachstellen mit
hohem/kritischem Schweregrad.

## 5. Getestetes Backup

Siehe [Kapitel 6](06-backup-restore.md) für die Skripte. **Gemessen:** Ein Testlauf des
Restore-Skripts zeigte eine Wiederherstellungszeit von rund drei Minuten bis zur nutzbaren
Nextcloud-Instanz (die tatsächliche Dauer skaliert mit der Datenmenge).

> **Ehrlicher Hinweis:** Im Testsystem der Arbeit erfüllte das Backup die 3-2-1-Regel **nicht
> vollständig** – es fehlte eine räumlich getrennte Kopie (z. B. extern gelagerte Festplatte oder
> Cloud-Backup). Richte dir, wenn möglich, zusätzlich eine externe/räumlich getrennte Kopie ein,
> um diese Lücke zu schließen.

## 6. Restriktive Firewall und Portreduktion

```bash
sudo bash scripts/firewall-setup.sh
```

Passe `LAN_SUBNET` und `SSH_PORT` im Skript vor der Ausführung an deine Umgebung an. Das Skript
lässt eingehenden Zugriff auf den Nextcloud-Port (8080) bewusst nur aus dem LAN zu – das
Basissystem dieses Tutorials exponiert, anders als das Testsystem der Arbeit, keinen Port
öffentlich ins Internet; erst mit dem optionalen Reverse Proxy (Maßnahme 1) kommen 80/tcp und
443/tcp hinzu, die du dann in der Firewall und im Router freigibst. **Gemessen (am
öffentlich per Reverse Proxy erreichbaren Testsystem der Arbeit):** Ein externer Portscan
(`nmap -p- --min-rate 2000`) fand im gehärteten Zustand genau zwei dem System zuzuordnende offene
Ports: 80/TCP und 443/TCP (gegenüber nur 80/TCP, unverschlüsselt, im Ausgangszustand). Das zeigt:
Portreduktion bedeutet dort vor allem "nur HTTP(S) nach außen", nicht "möglichst viele Ports
schließen" – sobald du den Reverse Proxy ergänzt, gilt dieselbe Überlegung auch für dein
System.

## 7. Sicherheitsrelevante HTTP-Header

Diese Header setzt der optionale Reverse Proxy aus Maßnahme 1; ohne Proxy entfällt diese
Maßnahme im LAN-Basissystem. Im Testsystem der Arbeit wurden die folgenden Header **in der vHost-Konfiguration des nativen Apache-Reverse-Proxys gesetzt – nicht in
Nextcloud selbst**:

```apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set Referrer-Policy "no-referrer"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
```

Trage die Direktiven in den 443-Block des vHosts aus Maßnahme 1 ein, lade Apache neu und prüfe
sie mit `curl -I https://<DOMAIN>` (bei Apache wie oben, bei nginx z. B. über `add_header ... always;`,
bei Caddy/Traefik über die jeweilige Header-Middleware).

> **Wichtig – scheinbarer Widerspruch, real gemessen:** Die `Permissions-Policy`-Direktive oben
> **war** in der realen vHost-Konfiguration des Testsystems genauso gesetzt wie hier gezeigt – und
> der Header kam trotzdem messbar nicht beim Client an. Das ist kein Dokumentationsfehler, sondern
> exakt der in der Arbeit gemessene Befund: eine gesetzte Direktive garantiert nicht automatisch,
> dass der Header tatsächlich ausgeliefert wird (z. B. wegen Modul-Reihenfolge, Caching oder
> Overrides durch die Anwendung). Die Direktive bleibt hier trotzdem als Teil der realen,
> gemessenen Konfiguration abgebildet.

**Gemessen (Testsystem der Arbeit, mit Reverse Proxy):** securityheaders.com bewertete den
Ausgangszustand mit **B** und den gehärteten Zustand mit **A**. Auch nach der Härtung fehlte in
der Arbeit weiterhin ausschließlich der Permissions-Policy-Header vollständig – trotz gesetzter
Direktive (siehe Hinweis oben). Realistischerweise bekommst du nicht ohne Weiteres eine perfekte
Bewertung, und das ist kein Zeichen eines gescheiterten Setups.

> **Hinweis aus der Arbeit:** Nach einem Image-Update verschwand ein zuvor entfernter
> `X-Powered-By`-Header wieder, weil die Einstellung nicht dauerhaft außerhalb des Images
> gespeichert war. Prüfe Header-Einstellungen nach jedem größeren Update erneut (z. B. mit `curl -I`
> oder securityheaders.com).
>
> **Zweiter, eigenständiger Befund:** Unabhängig davon blieb der **Apache-Versions-Header**
> (`Server: Apache/2.4.x`) sowohl vor als auch nach der Härtung sichtbar: `ServerTokens` und
> `ServerSignature` wurden bewusst auf dem Apache-Standard belassen, weil der Header als
> unwesentlich eingestuft wurde. Nach einem Image-Update zeigte er die neue Versionsnummer
> (2.4.65 → 2.4.68) an. Plane diesen Header als bekannte, bewusst nicht behobene Einschränkung
> ein, getrennt vom `X-Powered-By`-Problem oben.

## 8. Brute-Force-Schutz

Nextcloud bringt einen **eingebauten** Brute-Force-Schutz mit (kein separates `fail2ban` nötig):
wiederholte Fehlanmeldungen derselben IP-Adresse werden progressiv verzögert. **Gemessen:** im
Testsystem der Arbeit stieg die Verzögerung nach mehreren Fehlversuchen auf bis zu 30 Sekunden pro
Versuch. Du kannst das Verhalten prüfen (nicht destruktiv, nur wenige Fehlversuche):

```bash
# ein paar absichtliche Fehlanmeldungen über die Login-Seite, dann:
docker exec -u www-data nextcloud-app php occ security:bruteforce:reset <deine-test-ip>
```

## 9. Integritäts- und Schwachstellenüberwachung

```bash
docker exec -u www-data nextcloud-app php occ integrity:check-core
```

Regelmäßig per Cron ausführen und protokollieren:

```bash
0 4 * * 0 /usr/bin/docker exec -u www-data nextcloud-app php occ integrity:check-core >> /var/log/nextcloud-integrity.log 2>&1
```

Für Container-Images zusätzlich Trivy einsetzen:

```bash
trivy image nextcloud:latest
```

**Gemessen:** Trivy fand am **zum Messzeitpunkt aktuellen** Nextcloud-Image 289 Schwachstellen mit
hohem/kritischem Schweregrad (285 HIGH, 4 CRITICAL) – überwiegend in mitgelieferten
Betriebssystempaketen, nicht in der Anwendungslogik selbst. Dieser Wert bezieht sich auf das
jeweils aktuelle Image, nicht auf die Summe über alle in diesem Setup eingesetzten Images. Ein
separater Wert "nach" weiteren Maßnahmen wurde in der Arbeit nicht gemessen; der quantitative
Alters-Effekt (älteres vs. aktuelleres Image: 1.387 vs. 289 Schwachstellen) ist stattdessen über
Abbildung 6 dokumentiert (siehe Maßnahme 4). Das relativiert sich zwar durch Maßnahme 4
(Update-Management), verschwindet aber nicht vollständig.

## 10. Container-/Serverhärtung nach CIS-Benchmark

```bash
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -v /var/lib:/var/lib:ro -v /var/run/docker.sock:/var/run/docker.sock:ro \
  docker/docker-bench-security
```

> **Ehrlicher Hinweis:** Diese Maßnahme wurde im Testsystem der Arbeit **nicht vollständig**
> umgesetzt (hoher Aufwand bei mittlerer Wirksamkeit, siehe Prioritätstabelle). Docker Bench for
> Security v1.6.0 weist 117 Prüfpunkte aus. Gemessen auf dem Testsystem (Laptop) der Arbeit ergab
> sich **vorher** ein Score von **5 (Netto)** und **nachher** nur noch **3 (Netto)** – der
> Nettowert (bestandene abzüglich nicht bestandener, sicherheitsrelevanter Kontrollpunkte)
> änderte sich also leicht; wegen des geteilten Hosts ist das kein belastbares Maß für die
> Container-Härtung (vgl. Tabelle 4 der Arbeit). Nextcloud- und Datenbank-Container liefen weiterhin
> mit Root-Rechten, ohne Ressourcenlimits, mit beschreibbarem Root-Dateisystem und ohne
> Healthcheck. Wenn du das verbessern willst, sind sinnvolle erste Schritte:
>
> - Ressourcenlimits setzen (`deploy.resources.limits` in der Compose-Datei, bzw. `mem_limit`/
>   `cpus` bei Compose v2 ohne Swarm)
> - `read_only: true` + gezielte `tmpfs`-Mounts für beschreibbare Pfade testen
> - `HEALTHCHECK`-Anweisungen für die verwendeten Images ergänzen
>
> Das ist bewusst nicht Teil der Standard-Compose-Dateien in diesem Repository, da es
> anwendungsspezifisches Tuning erfordert und leicht die Nextcloud-Funktionalität brechen kann,
> wenn es unvorsichtig umgesetzt wird.

## 11. Verschlüsselung ruhender Daten und der Backups

In der Arbeit als eigenständige, hochwirksame Maßnahme mit mittlerem Aufwand eingeordnet – und im
Testsystem auch tatsächlich **umgesetzt**: Storage- und Backup-Laufwerk waren per LUKS
(`cryptsetup`) vollständig verschlüsselt (siehe Anhang 1/Tabelle 5 der Arbeit).

> **Ehrliche Einschränkung aus der Arbeit:** Die Entsperrung der LUKS-Container erfolgte
> **automatisch beim Systemstart** (damit der Dienst ohne manuelles Eingreifen nach einem Reboot
> wieder verfügbar ist). Das bedeutet: Gegen den Diebstahl des **laufenden, eingeschalteten**
> Systems (bzw. mit Zugriff auf den gespeicherten Schlüssel) bietet LUKS hier **keinen** Schutz –
> wirksam ist es nur gegen den Diebstahl eines **ausgeschalteten** Datenträgers oder Geräts. Wäge
> für dein eigenes System ab, ob dir automatischer Neustart ohne manuelle Eingabe wichtiger ist als
> Schutz auch im eingeschalteten Zustand.

> **Reihenfolge beachten:** Richte LUKS **vor** Schritt 4.2 (Formatieren) in
> [Kapitel 4](04-storage-setup.md#42-formatieren-ext4) ein, nicht danach – in diesem Tutorial sind
> die Laufwerke in Kapitel 4 bereits regulär (unverschlüsselt) formatiert. Willst du LUKS
> einsetzen, wiederhole Kapitel 4 ab 4.2 auf Basis des hier geöffneten
> `/dev/mapper/...`-Geräts statt der Rohpartition.

So richtest du LUKS auf dem Storage- bzw. Backup-Laufwerk ein, bevor du es mountest und mit Daten
befüllst (⚠️ verschlüsselt/formatiert das gesamte Zielgerät):

```bash
sudo cryptsetup luksFormat /dev/sdX1
sudo cryptsetup open /dev/sdX1 nextcloud-storage
sudo mkfs.ext4 /dev/mapper/nextcloud-storage
```

Für die automatische Entsperrung beim Boot (mit der oben genannten Einschränkung) trägst du das
Gerät mit einer Keyfile in `/etc/crypttab` ein, statt die Passphrase interaktiv abzufragen.

Weitere mögliche Ansätze, die in der Arbeit nicht zum Einsatz kamen, aber als Ergänzung
sinnvoll sind:

- Manuelle Passphrase-Eingabe beim Boot statt automatischer Keyfile-Entsperrung (höhere
  Wirksamkeit gegen Diebstahl des laufenden Systems, aber kein automatischer Neustart ohne
  physischen Zugriff)
- Nextclouds serverseitige Verschlüsselung (`occ encryption:enable`) für ruhende Nutzdaten
- Ein vom LUKS-Schlüssel getrennt verwaltetes Backup-Laufwerk (z. B. extern gelagert, nicht
  dauerhaft eingebunden)

## 12. Phishing-resistente Verfahren (FIDO2/WebAuthn) statt reinem TOTP

Im Testsystem der Arbeit **nicht umgesetzt** – explizit als Empfehlung für künftige Arbeiten
benannt, nicht als bereits erprobte Maßnahme. TOTP entwertet den Diebstahl statischer
Zugangsdaten, bietet aber nur begrenzten Schutz gegen Echtzeit-Phishing (der zweite Faktor wird
dabei live an den Angreifer weitergeleitet). FIDO2/WebAuthn bindet die Authentifizierung
kryptografisch an die legitime Domain und ist damit phishing-resistent. Wenn du dieses Restrisiko
schließen willst:

```bash
docker exec -u www-data nextcloud-app php occ app:enable twofactor_webauthn
```

Benötigt einen Hardware-Sicherheitsschlüssel (z. B. YubiKey) oder einen Passkey-fähigen Browser/
OS.

## 13. Netzwerksegmentierung / Server-Isolation vom Heimnetz

Repliziere, wenn möglich, die Netzarchitektur aus der Arbeit: der Server hängt in einem eigenen
Netzsegment direkt am Internet-Router (Router 1); das übrige Heimnetz hängt an einem zweiten
Router (Router 2) mit eigener Firewall. Der gesamte Datenverkehr zwischen Server und Heimnetz
läuft dann ausschließlich über Router 1 und dessen Firewall.

**Gemessen:** Im Testsystem der Arbeit waren im Ausgangszustand alle Geräte im Netzwerk erreichbar
(Rohdaten aus Datenschutzgründen nicht aufbewahrt); nach der Absicherung waren weder der
trennende Router noch ein PC im Heimnetz vom Server aus erreichbar, alle geprüften Ports
(inkl. Port 445/SMB) wurden von der Firewall verworfen. Das zeigt: diese Maßnahme lohnt sich vor
allem beim **Netzwerk-Design im Vorfeld** (zwei Router statt einem gemeinsamen Netz), nicht bei einer nachträglichen
Software-Konfiguration auf dem Server selbst.

Prüfe die Wirksamkeit deiner eigenen Segmentierung bei Bedarf nicht-destruktiv per `ping`/`nmap`
vom Server aus in Richtung Heimnetz. Das ist eine Testmethodik und bewusst nicht Teil der
Installationsschritte in diesem Repository.

## Restrisiko: der menschliche Faktor

Auch nach vollständiger technischer Härtung bleibt laut Arbeit das größte verbleibende Risiko
menschlicher, nicht technischer Natur: Phishing und schwache oder mehrfach verwendete Passwörter.
Das lässt sich technisch nur begrenzen, nicht ausschließen (Maßnahme 12 reduziert es, beseitigt es
aber nicht vollständig). Empfehlungen:

- Passwort-Manager mit einzigartigen, langen Passwörtern je Dienst
- Wo möglich FIDO2/WebAuthn statt (oder zusätzlich zu) TOTP verwenden (Maßnahme 12)
- Keine Zugangsdaten oder 2FA-Codes auf Zuruf/Link weitergeben
