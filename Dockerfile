# Étape 1 : Build du client
FROM node:20-alpine AS client-builder

WORKDIR /app/client

# Installation des dépendances du client
COPY client/package*.json ./
RUN npm install

# Build du client
COPY client/ ./
RUN npm run build

# Étape 2 : Build du serveur
FROM node:20-alpine AS server-builder

WORKDIR /app/server

# Installation des dépendances du serveur
COPY server/package*.json ./
RUN npm install

# Build du serveur
COPY server/ ./
RUN npm run build

# Étape 3 : Image finale
FROM node:20-alpine

WORKDIR /app

# Copie des fichiers du serveur buildé
COPY --from=server-builder /app/server/dist ./dist
COPY --from=server-builder /app/server/package*.json ./

# Installation des dépendances de production uniquement
RUN npm install --omit=dev

# Création et copie des fichiers statiques du client
RUN mkdir -p public
COPY --from=client-builder /app/client/dist ./public

# Exposition du port
EXPOSE 3310

# Démarrage de l'application
CMD ["npm", "run", "start"]
