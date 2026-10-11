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

Bereits in [Kapitel 6](06-reverse-proxy-https.md) umgesetzt (Let's Encrypt über Nginx Proxy
Manager bzw. Certbot). **Gemessen:** SSL-Labs-Bewertung **A+** (TLS 1.2/1.3, Perfect Forward
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

**Gemessen:** Ein Vergleich zweier unterschiedlich alter Nextcloud-Images in der Arbeit zeigt den
Effekt sehr deutlich: Ein älteres Image (Debian-Basis 13.3) wies 1387 Schwachstellen mit hohem/
kritischem Schweregrad auf, ein zum Testzeitpunkt aktuelles Image (Debian-Basis 13.7) nur 289.
Kontinuierliches Update-Management ist damit keine Formsache, sondern eine der wirksamsten
Einzelmaßnahmen.

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

In Nginx Proxy Manager unter *Proxy Hosts → (dein Host) → Edit → Advanced* ein Custom-Konfig-Snippet
ergänzen (oder äquivalent in der Apache-Alternative aus Kapitel 6):

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

**Gemessen:** Trivy fand im Ausgangszustand 317 Schwachstellen mit hohem/kritischem Schweregrad
über die eingesetzten Images (312 HIGH, 5 CRITICAL) – überwiegend in mitgelieferten
Betriebssystempaketen, nicht in der Anwendungslogik selbst. Das relativiert sich zwar durch
Maßnahme 4 (Update-Management), verschwindet aber nicht vollständig.

## 10. Container-/Serverhärtung nach CIS-Benchmark

```bash
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -v /var/lib:/var/lib:ro -v /var/run/docker.sock:/var/run/docker.sock:ro \
  docker/docker-bench-security
```

> **Ehrlicher Hinweis:** Diese Maßnahme wurde im Testsystem der Arbeit **bewusst nicht**
> umgesetzt (hoher Aufwand bei mittlerer Wirksamkeit, siehe Prioritätstabelle). Docker Bench for
> Security bewertete das System mit einem Score von nur **3 von möglichen Punkten bei 117
> Kontrollpunkten** – Nextcloud- und Datenbank-Container liefen weiterhin mit Root-Rechten, ohne
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

In der Arbeit als eigenständige, hochwirksame Maßnahme mit mittlerem Aufwand eingeordnet – aber
mit einer wichtigen Einschränkung: Ist der Schlüssel zur automatischen Entsperrung auf demselben
Host gespeichert (z. B. für automatische Reboots), ist die Wirksamkeit gegen einen Angreifer mit
physischem Zugriff eingeschränkt. Mögliche Ansätze:

- Full-Disk-Encryption des Storage- und Backup-Laufwerks mit LUKS (manuelle Entschlüsselung beim
  Boot, höchste Wirksamkeit, aber kein automatischer Neustart ohne physischen Zugriff)
- Nextclouds serverseitige Verschlüsselung (`occ encryption:enable`) für ruhende Nutzdaten
- Verschlüsselte Backup-Container (z. B. `rsync` auf ein LUKS-verschlüsseltes Backup-Laufwerk)

Dieses Repository implementiert das nicht als Standardschritt, da die Abwägung
Automatisierung/Komfort vs. Schutzwirkung stark vom Einsatzzweck abhängt – plane es als bewusste
Erweiterung ein, wenn dein Bedrohungsmodell physischen Zugriff auf die Hardware einschließt.

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
