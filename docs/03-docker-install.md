# 3. Docker-Installation

Wir installieren Docker Engine über das **offizielle Docker-APT-Repository** – nicht das
distributionseigene `docker.io`-Paket, das oft veraltet ist.

## 3.1 Alte Versionen entfernen

```bash
sudo apt remove docker docker-engine docker.io containerd runc
```

## 3.2 Abhängigkeiten installieren

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
```

## 3.3 Docker GPG-Key hinzufügen

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

## 3.4 Docker-Repository einrichten

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
```

## 3.5 Docker Engine + Compose-Plugin installieren

```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## 3.6 Installation prüfen

```bash
sudo docker run hello-world
docker compose version
```

## 3.7 Docker ohne sudo nutzen (optional, empfohlen)

```bash
sudo usermod -aG docker $USER
```

Danach aus- und wieder einloggen (oder `newgrp docker`), damit die Gruppenmitgliedschaft aktiv wird.

## Bekannte Stolpersteine

- Verwende **`docker compose`** (mit Leerzeichen, Compose-Plugin v2), nicht das alte,
  eigenständige `docker-compose` (Bindestrich, v1) – die YAML-Syntax und Fehlermeldungen können
  sich leicht unterscheiden.
- Siehe [Kapitel 10 – Troubleshooting](10-troubleshooting.md) für häufige YAML-Fehler in
  Compose-Dateien (`environment` falsch geschrieben, `volumes:` falsch eingerückt, etc.).
