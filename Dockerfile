# Étape 1 : Build du client
FROM node:20-alpine AS client-builder

WORKDIR /app/client

# Arguments de build pour la configuration du client
ARG VITE_API_URL
ARG NODE_ENV=production

# Installation des dépendances globales nécessaires
RUN npm install -g pnpm

# Copie et installation des dépendances du client
COPY client/package*.json ./
RUN pnpm install --no-frozen-lockfile

# Copie du reste des fichiers du client
COPY client/ ./

# Build du client
RUN echo "Building client..." && \
    pnpm build && \
    echo "Client build completed successfully"

# Étape 2 : Build du serveur
FROM node:20-alpine AS server-builder

WORKDIR /app/server

# Copie des fichiers de configuration du serveur
COPY server/package*.json ./

# Installation des dépendances
RUN npm install

# Copie de tous les fichiers source du serveur
COPY server/src ./src
COPY server/database ./database
COPY server/bin ./bin
COPY server/tsconfig.json ./

# Configuration TypeScript pour le build
RUN echo '{"compilerOptions":{"target":"es2022","module":"commonjs","outDir":"./dist","baseUrl":".","paths":{"../../../database/*":["database/*"]},"strict":true,"esModuleInterop":true,"skipLibCheck":true},"include":["src/**/*","database/**/*"]}' > ./tsconfig.json

# Build du serveur
RUN echo "Building server..." && \
    npx tsc && \
    echo "Server build completed successfully"

# Étape 3 : Image finale
FROM node:20-alpine

WORKDIR /app

# Installation des outils nécessaires
RUN apk add --no-cache curl && \
    npm install -g tsx

# Copie des fichiers du serveur
COPY --from=server-builder /app/server/dist ./dist
COPY --from=server-builder /app/server/bin ./bin
COPY --from=server-builder /app/server/database ./database
COPY --from=server-builder /app/server/package.json ./
RUN npm install --omit=dev

# Copie des fichiers statiques du client
COPY --from=client-builder /app/client/dist ./public

# Création d'un utilisateur non-root
RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    chown -R appuser:appgroup /app

USER appuser

# Healthcheck pour Traefik
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3310/health || exit 1

# Configuration finale
EXPOSE 3310
ENV NODE_ENV=production \
    PORT=3310

CMD ["/bin/sh", "-c", "tsx ./bin/migrate.ts && tsx ./dist/main.js"]
