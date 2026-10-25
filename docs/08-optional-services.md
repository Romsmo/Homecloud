# 8. Optionale Dienste

Diese Dienste sind nicht Teil des Kernsystems (Nextcloud), erweitern die Home-Cloud aber sinnvoll.
Alle laufen als eigene Docker-Compose-Stacks und sind unabhängig voneinander installierbar. Wie
Nextcloud sind auch sie nur im LAN erreichbar – dieses Tutorial richtet für keinen dieser Dienste
einen Reverse Proxy oder HTTPS ein (siehe Kapitel 1).

## 8.1 Portainer – Docker-Web-Oberfläche

Vereinfacht die Verwaltung aller Container über eine Weboberfläche.

```bash
cd compose/portainer
docker compose up -d
```

Danach `http://<LAN-IP-des-Hosts>:9000` aufrufen und Admin-Account anlegen.

## 8.2 Home Assistant – Smart-Home-Zentrale

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

## 8.3 openHAB – Alternative Smart-Home-Zentrale

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

## Firewall nicht vergessen

Für alle hier neu eröffneten Ports (8123, 8080/openHAB, 9000) gilt dieselbe Empfehlung wie in
[Kapitel 7, Maßnahme 6](07-security-hardening.md#6-restriktive-firewall-und-portreduktion):
Zugriff nach Möglichkeit auf das LAN beschränken, nicht öffentlich exponieren.
