# Étape 1 : build des apps dans un conteneur temporaire
FROM node:18-alpine AS build

WORKDIR /app

# 1. Copie et installe le client
COPY client ./client
RUN cd client && npm install && npm run build

# 2. Copie et installe le server
COPY server ./server
RUN cd server && npm install && npm run build

# 3. Copie le frontend compilé dans le dossier public du server
RUN rm -rf server/public && mkdir -p server/public && cp -r client/dist/* server/public/

# Étape 2 : Image finale minimale
FROM node:18-alpine

WORKDIR /app

# Copier le code backend (avec frontend intégré)
COPY --from=build /app/server .

# Installer uniquement les dépendances de prod
RUN npm install

EXPOSE 3000

CMD ["npm", "run", "start"]
