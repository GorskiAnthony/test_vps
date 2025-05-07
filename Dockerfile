# Étape 1 : Build client + server
FROM node:20-alpine AS build

WORKDIR /app

# Copier les fichiers nécessaires pour le cache
COPY client/package*.json ./client/
COPY server/package*.json ./server/

RUN cd client && npm install
RUN cd server && npm install

# Copier tout le reste du projet
COPY . .

# Variables d’environnement pour le build front
ENV VITE_API_URL=http://localhost:3000

# Build du client
RUN cd client && npm run build

# Build du serveur
RUN cd server && npm run build

# Copier le build client dans le dossier public du serveur
RUN rm -rf server/public && mkdir -p server/public && cp -r client/dist/* server/public/


# Étape 2 : Image finale (runtime uniquement)
FROM node:20-alpine

WORKDIR /app

# Copier uniquement le dossier du serveur avec le build client déjà intégré
COPY --from=build /app/server .

# Installer les dépendances sans les devDependencies
RUN npm install --omit=dev

EXPOSE 3310

CMD ["npm", "run", "start"]
