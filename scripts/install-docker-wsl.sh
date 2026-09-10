#!/bin/bash
# Installation de Docker Engine dans WSL Ubuntu (pas Docker Desktop).
# A lancer manuellement dans le terminal Ubuntu : bash install-docker-wsl.sh
set -euo pipefail

echo "=== Suppression d'anciens paquets docker eventuels ==="
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt-get remove -y $pkg 2>/dev/null || true
done

echo "=== Prerequis ==="
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg

echo "=== Cle GPG et repo officiel Docker ==="
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== Installation Docker Engine ==="
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Autoriser l'utilisateur courant a utiliser docker sans sudo ==="
sudo usermod -aG docker "$USER"

echo "=== Demarrage du service Docker (WSL n'a pas de systemd actif par defaut) ==="
sudo service docker start

echo "=== Verification ==="
sudo docker run --rm hello-world

cat <<'EOF'

Installation terminee.

IMPORTANT :
- Pour utiliser `docker` sans sudo, ferme ce terminal et rouvre-en un
  nouveau (ou lance `newgrp docker`) pour que l'appartenance au groupe
  "docker" soit prise en compte.
- WSL ne demarre pas Docker automatiquement au boot. A chaque nouvelle
  session WSL, lancer : sudo service docker start
  (ou l'ajouter a ~/.bashrc pour l'automatiser)
EOF
