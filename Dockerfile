# Étape 1 : Build client + server
FROM node:20-alpine AS build

WORKDIR /app

# Copier séparément pour maximiser le cache
COPY client/package*.json ./client/
COPY server/package*.json ./server/

# Installer les deps séparément
RUN cd client && npm install
RUN cd server && npm install

# Copier le reste du code
COPY client ./client
COPY server ./server

# Variables d'environnement pour le build front
ENV VITE_API_URL=http://localhost:3000

# Build du client
RUN cd client && npm run build

# Build du serveur
RUN cd server && npm run build

# Copier le dossier client
RUN cp -r client server/

# Étape 2 : Image finale
FROM node:20-alpine

WORKDIR /app

# Copie des fichiers du serveur
COPY --from=build /app/server .

# Copie du build client
COPY --from=build /app/server/client ./client

RUN npm install --omit=dev

EXPOSE 3310
ENV NODE_ENV=production \
    PORT=3310 \
    DB_HOST=database-db \
    DB_PORT=3306

CMD ["npm", "run", "start"]
