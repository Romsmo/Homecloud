# 8. Security-Härtung

Dieses Kapitel setzt die in der Seminararbeit (Kapitel 3, "Erforderliche Sicherheitsmaßnahmen")
hergeleiteten Maßnahmen um – in der **Prioritätsreihenfolge**, die die finale Fassung der Arbeit
in Kapitel 5.2 aus dem Verhältnis von Schutzwirkung zu Aufwand ableitet. Zu jeder Maßnahme sind,
soweit verfügbar, die **real am Testsystem gemessenen Vorher-/Nachher-Werte** aus Kapitel 4
angegeben – als realistischer Maßstab, nicht als Garantie, dass dein eigenes System exakt
dieselben Werte erreicht.

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

Bereits in [Kapitel 6](06-reverse-proxy-https.md) umgesetzt (Let's Encrypt über den nativen
Apache-Reverse-Proxy per Certbot; Nginx Proxy Manager steht dort als Docker-basierte, in der
Arbeit nicht gemessene Alternative). **Gemessen:** SSL-Labs-Bewertung **A+** (TLS 1.2/1.3, Perfect Forward
Secrecy, kein Heartbleed/POODLE/ROBOT) im gehärteten Zustand, gegenüber keiner TLS-Verschlüsselung
im Ausgangszustand.

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

Die mitgelieferte App "Password Policy" erzwingt Mindestlänge/-komplexität und prüft neue
Passwörter gegen bekannte Datenlecks (Have-I-Been-Pwned-Abgleich):

```bash
docker exec -u www-data nextcloud-app php occ app:enable password_policy
docker exec -u www-data nextcloud-app php occ config:app:set password_policy minLength --value=12
docker exec -u www-data nextcloud-app php occ config:app:set password_policy enforceHaveIBeenPwned --value=1
```

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

**Gemessen:** Die Arbeit vergleicht qualitativ (Abbildung 7) ein älteres gegen ein aktuelleres
Nextcloud-Image und zeigt den Effekt des Update-Alters deutlich, ohne für das ältere Image eine
exakte Schwachstellenzahl zu nennen. Konkret gemessen und beziffert wurde nur der aktuelle Stand
(siehe Maßnahme 9: 289 Schwachstellen mit hohem/kritischem Schweregrad). Ein zusätzliches,
konkretes Beispiel aus der Arbeit: Nach einem Image-Update stieg die im Response-Header
offengelegte Apache-Version von 2.4.65 auf 2.4.68 – der Header blieb dabei weiterhin sichtbar
(siehe Maßnahme 7). Kontinuierliches Update-Management ist damit keine Formsache, sondern eine der
wirksamsten Einzelmaßnahmen, auch wenn sich der exakte quantitative Effekt hier nicht pauschal
beziffern lässt.

## 5. Getestetes Backup

Siehe [Kapitel 7](07-backup-restore.md) für die Skripte. **Gemessen:** Ein Testlauf des
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

Passe `LAN_SUBNET` und `SSH_PORT` im Skript vor der Ausführung an deine Umgebung an. **Gemessen:**
Ein externer Portscan (`nmap -p- --min-rate 2000`) fand im gehärteten Zustand genau zwei dem
System zuzuordnende offene Ports: 80/TCP und 443/TCP (gegenüber nur 80/TCP, unverschlüsselt, im
Ausgangszustand). Das zeigt: Portreduktion bedeutet hier vor allem "nur HTTP(S) nach außen", nicht
"möglichst viele Ports schließen" – HTTP(S) muss offen bleiben, damit der Dienst erreichbar ist.

## 7. Sicherheitsrelevante HTTP-Header

Im nativen Apache aus Kapitel 6 in der vHost-Konfiguration ergänzen (siehe auch der
auskommentierte Block in
[`config-examples/apache-reverse-proxy-cloud.conf`](../config-examples/apache-reverse-proxy-cloud.conf)):

```apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set Referrer-Policy "no-referrer"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
ServerTokens Prod
ServerSignature Off
```

Falls du stattdessen die Docker-basierte NPM-Alternative aus Kapitel 6 verwendest, trägst du die
entsprechenden `add_header`-Zeilen dort im Custom-Konfig-Snippet unter *Proxy Hosts → (dein Host)
→ Edit → Advanced* ein:

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header Referrer-Policy "no-referrer" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

**Gemessen:** securityheaders.com bewertete den Ausgangszustand mit **B** und den gehärteten
Zustand mit **A**. Auch nach der Härtung fehlte in der Arbeit weiterhin ausschließlich der
Permissions-Policy-Header vollständig – realistischerweise bekommst du nicht ohne Weiteres eine
perfekte Bewertung, und das ist kein Zeichen eines gescheiterten Setups.

> **Hinweis aus der Arbeit:** Nach einem Image-Update verschwand ein zuvor entfernter
> `X-Powered-By`-Header wieder, weil die Einstellung nicht dauerhaft außerhalb des Images
> gespeichert war. Prüfe Header-Einstellungen nach jedem größeren Update erneut (z. B. mit `curl -I`
> oder securityheaders.com).
>
> **Zweiter, eigenständiger Befund:** Unabhängig davon blieb der **Apache-Versions-Header**
> (`Server: Apache/2.4.x`) sowohl vor als auch nach der Härtung sichtbar, trotz `ServerTokens
> Prod`/`ServerSignature Off` – nach einem Image-Update zeigte er sogar die neue Versionsnummer
> (2.4.65 → 2.4.68) an, statt verschwunden zu bleiben. Plane diesen Header als bekannte,
> nicht vollständig behobene Einschränkung ein, getrennt vom `X-Powered-By`-Problem oben.

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

**Gemessen:** Trivy fand am Testsystem 289 Schwachstellen mit hohem/kritischem Schweregrad über
die eingesetzten Images (285 HIGH, 4 CRITICAL) – überwiegend in mitgelieferten
Betriebssystempaketen, nicht in der Anwendungslogik selbst. Ein separater Wert "nach" weiteren
Maßnahmen wurde in der Arbeit nicht gemessen; der qualitative Alters-Effekt (älteres vs.
aktuelleres Image) ist stattdessen über Abbildung 7 dokumentiert (siehe Maßnahme 4). Das relativiert
sich zwar durch Maßnahme 4 (Update-Management), verschwindet aber nicht vollständig.

## 10. Container-/Serverhärtung nach CIS-Benchmark

```bash
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -v /var/lib:/var/lib:ro -v /var/run/docker.sock:/var/run/docker.sock:ro \
  docker/docker-bench-security
```

> **Ehrlicher Hinweis:** Diese Maßnahme wurde im Testsystem der Arbeit **nicht vollständig**
> umgesetzt (hoher Aufwand bei mittlerer Wirksamkeit, siehe Prioritätstabelle). Docker Bench for
> Security bewertete das System **vorher** (getestet auf einem Raspberry Pi) mit **5 von möglichen
> Punkten bei 117 Kontrollpunkten** und **nachher** (getestet auf dem eigentlichen Testhost
> „hcloud") mit nur noch **3 von 117** – der Score sank also sogar leicht, statt sich zu
> verbessern. Nextcloud- und Datenbank-Container liefen weiterhin mit Root-Rechten, ohne
> Ressourcenlimits, mit beschreibbarem Root-Dateisystem und ohne Healthcheck. Wenn du das
> verbessern willst, sind sinnvolle erste Schritte:
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

**Gemessen:** Im Testsystem der Arbeit war diese Isolation bereits beim Ausgangstest wirksam –
weder der trennende Router noch ein PC im Heimnetz waren vom Server aus erreichbar, alle
geprüften Ports (inkl. Port 445/SMB) wurden von der Firewall verworfen. Ein zusätzlicher
Fix-Schritt war nicht nötig. Das zeigt: diese Maßnahme lohnt sich vor allem beim **Netzwerk-Design
im Vorfeld** (zwei Router statt einem gemeinsamen Netz), nicht bei einer nachträglichen
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
