# Étape 1 : Build de l'app
FROM node:20-alpine AS builder

# Installation des outils nécessaires
RUN apk add --no-cache libc6-compat

WORKDIR /usr/src/app

# Copie ciblée pour profiter du cache Docker
COPY package*.json ./
RUN npm install

# Puis on copie le reste du code
COPY . .

# Build du projet (TypeScript, Vite, etc.)
RUN npm run build

# Étape 2 : Image de production propre
FROM node:20-alpine

# Dossier de travail
WORKDIR /usr/src/app

# Installer uniquement les dépendances de prod
COPY package*.json ./
RUN npm install --omit=dev

# Copier uniquement le résultat du build + tout ce qu’il faut pour exécuter
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/src ./src
COPY --from=builder /usr/src/app/.env .env
