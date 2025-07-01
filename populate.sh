#!/bin/bash

# Variables
REGISTRY=local-registry.master01.devops.lab
IMAGES=("alpine" "busybox" "hello-world")

# Connexion interactive
read -p "👤 Nom d'utilisateur : " USERNAME
read -s -p "🔒 Mot de passe : " PASSWORD
echo
echo "$PASSWORD" | docker login "$REGISTRY" -u "$USERNAME" --password-stdin

# Boucle sur les images
for img in "${IMAGES[@]}"; do
  echo "📦 Pull $img"
  docker pull $img
  echo "🏷️ Tag vers la registry"
  docker tag $img $REGISTRY/demo/$img:latest
  echo "📤 Push vers $REGISTRY/demo/$img:latest"
  docker push $REGISTRY/demo/$img:latest
done

echo "✅ Terminé !"
