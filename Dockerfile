# Étape 1 : Build du client
FROM node:20-alpine AS client-builder

WORKDIR /app

# Arguments de build pour la configuration du client
ARG VITE_API_URL
ARG NODE_ENV=production

# Installation des dépendances globales nécessaires
RUN npm install -g typescript@5.8.2 vite@6.2.4

# Création du répertoire de travail
WORKDIR /app/client

# Copie des fichiers package.json et tsconfig.json
COPY client/package*.json client/tsconfig*.json ./

# Installation des dépendances avec types React
RUN echo "Installing dependencies..." && \
    npm install --legacy-peer-deps && \
    npm install --save-dev @types/react @types/react-dom && \
    echo "Dependencies installed successfully"

# Copie des fichiers sources
COPY client/ ./

# Création du fichier de déclaration pour jsx-runtime
RUN echo 'declare module "react/jsx-runtime" { export { jsx, jsxs, Fragment } from "react" }' > src/jsx-runtime.d.ts

# Build direct avec Vite (qui inclut la vérification TypeScript)
RUN echo "Starting Vite build..." && \
    npx vite build && \
    echo "Build completed successfully" && \
    echo "Build output:" && \
    ls -la dist/

# Étape 2 : Build du serveur
FROM node:20-alpine AS server-builder

WORKDIR /app

# Installation des dépendances globales nécessaires
RUN npm install -g typescript tsx

# Copie des fichiers du serveur
COPY server/package*.json ./
RUN npm install

COPY server/ ./

# Build du serveur avec debug
RUN echo "Building server..." && \
    npm run build || (echo "Build failed" && ls -la && exit 1)

# Étape 3 : Image finale
FROM node:20-alpine

# Création d'un utilisateur non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Installation des outils de diagnostic
RUN apk add --no-cache curl

# Copie des fichiers nécessaires
COPY --from=server-builder /app/dist ./dist
COPY --from=server-builder /app/package*.json ./
COPY --from=server-builder /app/node_modules ./node_modules

# Copie des fichiers statiques du client
RUN mkdir -p public
COPY --from=client-builder /app/dist ./public

# Installation de tsx pour le runtime
RUN npm install -g tsx

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
CMD ["tsx", "./dist/main.js"]
