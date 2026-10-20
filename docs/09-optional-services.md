# 9. Optionale Dienste

Diese Dienste sind nicht Teil des Kernsystems (Nextcloud), erweitern die Home-Cloud aber sinnvoll.
Alle laufen als eigene Docker-Compose-Stacks und sind unabhängig voneinander installierbar.

## 9.1 Portainer – Docker-Web-Oberfläche

Vereinfacht die Verwaltung aller Container über eine Weboberfläche.

```bash
cd compose/portainer
docker compose up -d
```

Danach `http://<LAN-IP-des-Hosts>:9000` aufrufen und Admin-Account anlegen.

## 9.2 Home Assistant – Smart-Home-Zentrale

```bash
cd compose/homeassistant
docker compose up -d
```

Danach `http://<LAN-IP-des-Hosts>:8123` aufrufen.

> **Bekannter Stolperstein:** Das Image `ghcr.io/home-assistant/home-assistant:stable` lieferte in
> der Praxis *"error from registry: denied"*. Funktionierende Alternative (bereits in der
> Compose-Datei verwendet): `homeassistant/home-assistant:stable` von Docker Hub.

`network_mode: host` wird von Home Assistant für die automatische Geräte-Erkennung (mDNS/SSDP)
empfohlen – dadurch entfällt eine separate Portfreigabe, der Container teilt sich die Netzwerkkarte
des Hosts.

## 9.3 openHAB – Alternative Smart-Home-Zentrale

Falls du statt (oder zusätzlich zu) Home Assistant openHAB einsetzen möchtest:

```bash
cd compose/openhab
docker compose up -d
```

Danach `http://<LAN-IP-des-Hosts>:8080` aufrufen.

> **Achtung Portkonflikt:** openHAB nutzt standardmäßig ebenfalls Port 8080 – denselben Port, den
> in diesem Tutorial bereits Nextcloud belegt (Kapitel 5). Passe entweder den `HTTP_PORT` von
> openHAB an (Umgebungsvariable, siehe offizielle openHAB-Docker-Dokumentation) oder betreibe
> openHAB auf einem separaten Host/einer separaten VM.

## 9.4 Nginx Proxy Manager

Für Nextcloud selbst wird in diesem Tutorial primär der **native Apache-Reverse-Proxy** verwendet
(siehe [Kapitel 6](06-reverse-proxy-https.md)) – das ist der in der Arbeit tatsächlich gemessene
Weg. Nginx Proxy Manager (NPM) ist hier als optionaler, Docker-basierter Alternativ-Proxy
dokumentiert, der nicht Teil der in der Arbeit gemessenen Konfiguration ist. Du kannst ihn
trotzdem zusätzlich einsetzen, etwa um diese optionalen Dienste per eigener Subdomain und HTTPS
erreichbar zu machen, statt sie nur im LAN zu nutzen:

```bash
cd compose/nginx-proxy-manager
docker compose up -d
```

Admin-Oberfläche: `http://<LAN-IP-des-Hosts>:81` (Standard-Login siehe offizielle
NPM-Dokumentation, nach erstem Login sofort ändern).

## Firewall nicht vergessen

Für alle hier neu eröffneten Ports (8123, 8080/openHAB, 9000, 81) gilt dieselbe Empfehlung wie in
[Kapitel 8, Maßnahme 6](08-security-hardening.md#6-restriktive-firewall-und-portreduktion):
Zugriff nach Möglichkeit auf das LAN beschränken, nicht öffentlich exponieren.
