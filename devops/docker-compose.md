---
titre: Docker Compose
theme: devops
date: 2026-10-19
niveau: intermédiaire
tags: [docker, compose, conteneurs, reseau, volumes, orchestration]
---

# Docker Compose

## TL;DR
Docker Compose décrit dans un fichier YAML **plusieurs conteneurs qui fonctionnent ensemble** (services, réseau, volumes, ordre de démarrage) et les pilote avec une seule commande : `docker compose up -d`. C'est la façon la plus simple de rendre une pile d'application reproductible, de ta machine au serveur.

## Pourquoi ça existe
Sans Compose, démarrer une app + un proxy demande une série de `docker network create`, `docker volume create`, `docker run` avec 15 options chacun, dans le bon ordre. Personne ne s'en souvient, chaque machine finit configurée différemment. Compose remplace ce script fragile par une **description déclarative** versionnée dans Git.

## Explication détaillée

### L'intuition : le plan d'une maison
Un `docker run` est une brique. `docker-compose.yml` est le **plan** : quelles pièces (services), quels couloirs entre elles (réseau), quelles portes donnent sur la rue (ports), quels placards survivent aux travaux (volumes).

### Services
Chaque entrée sous `services:` devient un ou plusieurs conteneurs, nommés `<projet>-<service>-<n>` (ex. `legalhelp-app-1`). Un service utilise soit `image:` (télécharger), soit `build:` (construire depuis un Dockerfile), ou les deux (build puis taggue avec ce nom).

### Réseau et DNS interne
Compose crée un **réseau privé** par projet et y branche tous les services. Un **DNS interne** résout le *nom du service* vers l'IP actuelle du conteneur : depuis `caddy`, `http://app:3000` fonctionne. Les IP changent à chaque recréation ; les noms, jamais.

### `ports` : la porte sur l'extérieur
`ports: ['443:443']` publie un port **de l'hôte** vers le conteneur (`HÔTE:CONTENEUR`). Un service sans `ports` reste joignable par les autres services du réseau, mais pas depuis l'extérieur.

### Volumes
Un conteneur est **jetable** : le recréer efface ses fichiers. Deux façons de persister/injecter des données :
- **bind mount** `./Caddyfile:/etc/caddy/Caddyfile:ro` : un fichier de l'hôte, monté dans le conteneur (`:ro` = lecture seule).
- **volume nommé** `caddy_data:/data` : un espace géré par Docker, qui survit à `docker compose down` (mais pas à `down -v`).

### `restart`, `depends_on`, variables
- `restart: unless-stopped` : redémarre après un crash ou un reboot du serveur, sauf si on l'a arrêté exprès.
- `depends_on` avec `condition: service_healthy` : attend que l'autre service soit **en bonne santé**, pas seulement lancé (voir [Health check](healthcheck.md)).
- `${VAR:-défaut}` : interpolation depuis l'environnement du shell ou d'un fichier `.env` à côté du compose.

### Fichiers multiples et `override`
Si `docker-compose.override.yml` (ou `compose.override.yaml`) existe à côté du fichier principal, Compose **le fusionne automatiquement**. On garde ainsi un fichier de base = production, et une surcouche locale. `docker compose config` affiche le résultat fusionné.

## Schéma
```
           Hôte (ta machine ou le VPS)
  ┌─────────────────────────────────────────────────┐
  │   :80  :443 ──┐                                 │
  │               ▼    réseau legalhelp_default     │
  │        ┌────────────┐   http://app:3000  ┌─────┐│
  │        │   caddy    │ ─────────────────► │ app ││
  │        └────────────┘   (DNS interne)    └─────┘│
  │          │      │                      pas de   │
  │   ./Caddyfile  caddy_data (volume)     ports :  │
  │   (bind, ro)   = certificats TLS       invisible│
  │                                        dehors   │
  └─────────────────────────────────────────────────┘
```

## Exemples

### Exemple 1 — le plus simple : un service
```yaml
# compose.yml
services:
  web:
    image: nginx:1.27-alpine
    ports:
      - '8080:80'      # http://localhost:8080 → port 80 du conteneur
```
```bash
docker compose up -d && curl -sI localhost:8080 | head -1
```
Sortie attendue :
```
HTTP/1.1 200 OK
```

### Exemple 2 — cas courant : deux services qui se parlent par leur nom
```yaml
services:
  api:
    image: hashicorp/http-echo:1.0
    command: ['-text=pong', '-listen=:5678']
    # pas de ports : invisible depuis l'hôte
  client:
    image: curlimages/curl:8.10.1
    depends_on: [api]
    command: ['curl', '-s', 'http://api:5678']   # "api" = nom du service
```
```bash
docker compose up client
```
Sortie attendue (extrait) :
```
client-1  | pong
```

### Exemple 3 — cas réaliste : base de prod + surcouche locale
```yaml
# docker-compose.yml — la PRODUCTION
services:
  app:
    image: ghcr.io/moi/monapp:latest
    restart: unless-stopped
```
```yaml
# docker-compose.override.yml — uniquement sur ta machine
services:
  app:
    build: .               # ajouté par fusion : on construit localement
```
```bash
docker compose config | grep -A3 'app:'
```
Sortie attendue (extrait) :
```
  app:
    build:
      context: /chemin/du/projet
      dockerfile: Dockerfile
```
Sur le serveur, où l'override n'existe pas, le même `docker compose up -d` télécharge l'image.

## Pièges courants
- **`restart` après un changement de code** : le conteneur redémarre avec l'*ancienne* image. Il faut `docker compose up -d --build`.
- **`down -v`** : supprime aussi les volumes nommés → données perdues (pour Caddy : certificats TLS, avec risque de dépasser les quotas Let's Encrypt).
- **`localhost` dans un conteneur** : désigne le conteneur lui-même, pas l'hôte ni un autre service. Utiliser le nom du service (`app`).
- **Publier des ports « au cas où »** : `ports: ['3000:3000']` sur l'app permettrait de contourner le proxy (pas de HTTPS). Sur un VPS, Docker modifie iptables et ce port peut être ouvert **même si le pare-feu ufw dit le contraire**.
- **`depends_on` sans condition** : n'attend que le *démarrage* du conteneur, pas que l'app soit prête.
- **Indentation YAML** : une tabulation ou un décalage d'espace change la structure ; `docker compose config` valide le fichier.
- **Override copié sur le serveur par erreur** : le serveur se mettrait à builder au lieu de tirer l'image publiée.

## Vu dans le projet
- **Projet** : `/Users/yohan.h/Projet_perso/legalhelp`
- **Fichier** : `docker-compose.yml:39-58`
```yaml
  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '443:443/udp'
    environment:
      SITE_ADDRESS: ${SITE_ADDRESS:-localhost}
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      app:
        condition: service_healthy
```
- `image: caddy:2-alpine` : image officielle, tag de version majeure 2.
- `restart: unless-stopped` : survit aux crashs et aux reboots du VPS.
- `ports` : **seul** service à exposer des ports. `443/udp` sert à HTTP/3 (QUIC). `app` n'a volontairement aucun `ports`.
- `SITE_ADDRESS: ${SITE_ADDRESS:-localhost}` : prend la variable du shell/`.env`, sinon `localhost`.
- `./Caddyfile:…:ro` : bind mount en lecture seule — modifier le Caddyfile ne demande qu'un `restart`, pas de rebuild.
- `caddy_data:/data` : volume nommé qui conserve les certificats TLS.
- `condition: service_healthy` : Caddy n'est lancé qu'une fois que le healthcheck de `app` répond OK.

Et `docker-compose.override.yml:9-12` ajoute `build: .` au service `app`, uniquement en local.

## Pour aller plus loin
- [Documentation Docker Compose](https://docs.docker.com/compose/)
- [Référence du fichier Compose](https://docs.docker.com/reference/compose-file/)
- [Fusion de plusieurs fichiers Compose](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/)
- [Réseau dans Compose](https://docs.docker.com/compose/how-tos/networking/)

## Voir aussi
- [GitOps](gitops.md)
- [Dockerfile multi-stage](dockerfile-multi-stage.md)
- [Health check](healthcheck.md)
- [Reverse proxy et HTTPS automatique avec Caddy](../reseaux/reverse-proxy-caddy.md)

## Quiz rapide
1. Pourquoi Caddy peut-il écrire `reverse_proxy app:3000` sans connaître l'IP du conteneur ?
<details><summary>Réponse</summary>

Compose branche les services sur un réseau commun doté d'un DNS interne qui résout le nom du service (`app`) vers l'IP courante du conteneur.
</details>

2. Quelle commande après avoir modifié `App.svelte`, et pourquoi pas `docker compose restart` ?
<details><summary>Réponse</summary>

`docker compose up -d --build`. Le code est copié *dans l'image* au build ; `restart` relance le conteneur avec l'ancienne image.
</details>

3. Comment un même `docker-compose.yml` peut-il builder en local et télécharger en production ?
<details><summary>Réponse</summary>

Le fichier de base contient `image:` ; `docker-compose.override.yml`, présent seulement en local, est fusionné automatiquement et ajoute `build: .`.
</details>
