# Étape 1 : Build du client
FROM node:20-alpine AS client-builder

WORKDIR /app/client

# Arguments de build pour la configuration du client
ARG VITE_API_URL
ARG NODE_ENV=production

# Installation des dépendances du client
COPY client/package*.json ./
RUN npm install

# Build du client
COPY client/ ./
RUN npm run build

# Étape 2 : Build du serveur
FROM node:20-alpine AS server-builder

WORKDIR /app/server

# Arguments de build pour la configuration du serveur
ARG NODE_ENV=production

# Installation des dépendances du serveur
COPY server/package*.json ./
RUN npm install

# Build du serveur
COPY server/ ./
RUN npm run build

# Étape 3 : Image finale
FROM node:20-alpine

# Création d'un utilisateur non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Installation des outils de diagnostic si nécessaire
RUN apk add --no-cache curl

# Copie des fichiers du serveur buildé
COPY --from=server-builder /app/server/dist ./dist
COPY --from=server-builder /app/server/package*.json ./

# Installation des dépendances de production uniquement
RUN npm install --omit=dev && npm cache clean --force

# Création et copie des fichiers statiques du client
RUN mkdir -p public
COPY --from=client-builder /app/client/dist ./client/dist

# Configuration des permissions
RUN chown -R appuser:appgroup /app

# Utilisateur non-root pour la sécurité
USER appuser

# Healthcheck pour Traefik
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3310/health || exit 1

# Exposition du port
EXPOSE 3310

# Variables d'environnement par défaut
ENV NODE_ENV=production \
    PORT=3310

# Démarrage de l'application
CMD ["npm", "run", "start"]
