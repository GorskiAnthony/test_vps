# Étape 1 : Build client + server
FROM node:20-alpine AS build

WORKDIR /app

# Installer les dépendances
COPY client/package*.json ./client/
COPY server/package*.json ./server/

RUN cd client && npm install
RUN cd server && npm install

# Copier les sources
COPY client ./client
COPY server ./server

# Build du client
RUN cd client && npm run build

# Build du serveur
RUN cd server && npm run build

# Étape 2 : Image finale
FROM node:20-alpine

WORKDIR /app

# Copier le serveur tel quel
COPY --from=build /app/server ./server

# Copier aussi le dossier client (avec dist dedans)
COPY --from=build /app/client ./client

# Installer les deps dans server
WORKDIR /app/server
RUN npm install --omit=dev

EXPOSE 3310

CMD ["npm", "run", "start"]
