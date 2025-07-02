# 📦 Docker Private Registry avec UI et Traefik (HTTP)

Ce projet met en place une **registry Docker privée** avec :

- 🔐 Authentification HTTP (via `htpasswd`)
- 🌐 Interface web [Joxit Docker Registry UI](https://github.com/Joxit/docker-registry-ui)
- 🔁 Reverse proxy [Traefik](https://doc.traefik.io/traefik/) configuré en HTTP (pas HTTPS)
- ✅ Support complet pour `docker login`, `push`, `pull`, `delete`
- 🌍 Routage par sous-domaines :
  - `local-registry.master01.devops.lab` → accès à la registry
  - `registry-ui.master01.devops.lab` → interface utilisateur web
  - `traefik.master01.devops.lab` → dashboard Traefik

---

## 📁 Structure du projet

```bash
.
├── config/
│   ├── config.yml          # Configuration Docker registry (delete: true, auth)
│   └── htpasswd            # Utilisateurs et mots de passe
├── registry-data/          # Données persistantes de la registry
├── docker-compose.yml      # Déploiement complet (registry, Traefik, UI)
└── README.md               # Ce fichier
```

---

## 🚀 Déploiement

### 1. Prérequis

- Docker + Docker Compose installés
- Fichier `htpasswd` valide dans `./config/htpasswd`
- Entrées DNS ou `/etc/hosts` :

```txt
192.168.1.130  local-registry.master01.devops.lab registry-ui.master01.devops.lab traefik.master01.devops.lab
```

### 2. Lancer l’environnement

```bash
docker compose up -d
```

Les services suivants seront lancés :

- `registry` → http://local-registry.master01.devops.lab
- `registry-ui` → http://registry-ui.master01.devops.lab
- `traefik` dashboard → http://traefik.master01.devops.lab ou http://<IP>:8080/dashboard/

---

## 🔑 Authentification

Créer un fichier `htpasswd` :

```bash
docker run --rm --entrypoint htpasswd httpd:2 -Bbn jenkins password > ./config/htpasswd
```

Remplace `jenkins` et `password` avec tes propres identifiants.

Connexion à la registry :

```bash
docker login local-registry.master01.devops.lab
```

---

## 🧪 Test de push/pull

```bash
# Pull d’une image officielle
docker pull alpine

# Tag vers la registry privée
docker tag alpine local-registry.master01.devops.lab/test-alpine

# Push vers la registry
docker push local-registry.master01.devops.lab/test-alpine
```

Supprimer l’image via l’interface UI, puis exécuter le garbage collect (voir ci-dessous).

---

## 🧹 Nettoyage (Garbage Collect)

> La suppression via l’UI ne libère pas immédiatement l’espace disque.
> Il faut exécuter manuellement le garbage collector.

### 1. Méthode en ligne :

```bash
docker exec -it registry /bin/sh
registry garbage-collect /etc/docker/registry/config.yml
```

### 2. Méthode à froid (optionnel) :

```bash
docker-compose down
docker run --rm \
  -v "$(pwd)/registry-data:/var/lib/registry" \
  -v "$(pwd)/config/config.yml:/etc/docker/registry/config.yml" \
  registry:2.7 garbage-collect /etc/docker/registry/config.yml
docker-compose up -d
```

---

## 🔍 Accès aux interfaces

| Service           | URL                                         |
|-------------------|---------------------------------------------|
| Docker Registry   | http://local-registry.master01.devops.lab   |
| Registry UI       | http://registry-ui.master01.devops.lab      |
| Traefik Dashboard | http://traefik.master01.devops.lab          |
| Accès direct      | http://192.168.1.130:8080/dashboard/        |

---

## ⚙️ Configuration Docker (clients)

Pour permettre les `push` en HTTP, ajoute cette configuration dans le fichier /etc/docker/daemon.json sur **chaque client Docker** :
```bash
sudo nano /etc/docker/daemon.json
```
```json
{
  "insecure-registries": ["local-registry.master01.devops.lab"]
}
```

Puis redémarre le démon Docker :

```bash
sudo systemctl daemon-reexec
sudo systemctl restart docker
```

Vérifie avec :

```bash
docker info | grep -i 'Insecure'
```
