# Étape 1 : build des apps dans un conteneur temporaire
FROM node:18-alpine AS build

WORKDIR /app

# 1. Copier et installer client
COPY client ./client
RUN cd client && npm install && npm run build

# 2. Copier et installer server
COPY server ./server
RUN cd server && npm install && npm run build

# 3. Copier le front compilé dans le dossier public du backend
RUN rm -rf server/public && mkdir -p server/public && cp -r client/dist/* server/public/

# Étape 2 : Image finale minimale
FROM node:18-alpine

WORKDIR /app

# Copier le code backend (avec frontend intégré)
COPY --from=build /app/server .

# Installer uniquement les dépendances de prod
RUN npm install --omit=dev

EXPOSE 3000

CMD ["npm", "run", "start"]
