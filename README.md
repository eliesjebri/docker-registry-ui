# 📦 Docker Private Registry avec UI et Traefik (HTTP)

Ce projet met en place une **registry Docker privée** avec :

- 🔐 Authentification HTTP (via `htpasswd`)
- 🌐 Interface web [Joxit Docker Registry UI](https://github.com/Joxit/docker-registry-ui)
- 🔁 Reverse proxy [Traefik](https://doc.traefik.io/traefik/) configuré en HTTP (pas HTTPS)
- ✅ Support complet pour `docker login`, `push`, `pull`, `delete`
- 🌍 Routage par sous-domaines :
  - `local-registry.devops.lab` → accès à la registry
  - `registry-ui.devops.lab` → interface utilisateur web
  - `traefik.devops.lab` → dashboard Traefik

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
- Git installé
- Un user (jenkins) avec des droits sudo et membre du groupe `docker`
- Fichier `htpasswd` valide dans `./config/htpasswd`
- Entrées DNS ou `/etc/hosts` :

```txt
<host_IP>  local-registry.devops.lab registry-ui.devops.lab traefik.devops.lab traefik.devops.lab
```

### 2. Lancer l’environnement

#### Cloner le repo & lancer la stack

```bash
git clone https://github.com/eliesjebri/docker-registry-ui.git
cd docker-registry-ui/
docker compose up -d
```

Les services suivants seront lancés :

- `registry` → http://local-registry.devops.lab:8880 (API)
- `registry-ui` → http://registry-ui.devops.lab:8880
- `traefik` dashboard → http://traefik.devops.lab:8880 ou http://<IP>:8881/dashboard/

---

## 🔑 Authentification

Créer un fichier `htpasswd` :

```bash
docker run --rm --entrypoint htpasswd httpd:2 -Bbn jenkins password > ./config/htpasswd
```

Remplace `jenkins` et `password` avec tes propres identifiants.

Connexion à la registry :

```bash
docker login local-registry.devops.lab:8880
```

---

## 🧪 Test de push/pull

```bash
# Pull d’une image officielle
docker pull alpine

# Tag vers la registry privée
docker tag alpine local-registry.devops.lab:8880/test-alpine
OU
docker tag alpine local-registry:8880/test-alpine
# Push vers la registry
docker push local-registry.devops.lab/test-alpine
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

| Service           | URL                                     |
|-------------------|-----------------------------------------|
| Docker Registry   | http://local-registry.devops.lab:8880   |
| Registry UI       | http://registry-ui.devops.lab:8880      |
| Traefik Dashboard | http://traefik.devops.lab:8880          |
| Accès direct      | http://192.168.1.130:8880/dashboard/    |

---

## ⚙️ Configuration Docker (clients)

Pour permettre les `push` en HTTP, ajoute cette configuration dans le fichier /etc/docker/daemon.json sur **chaque client Docker** :
```bash
sudo nano /etc/docker/daemon.json
```
```json
{
  "insecure-registries": ["local-registry.devops.lab:8880",
                          "local-registry:8880"
]
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
