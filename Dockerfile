# STAGE 1: Build
FROM node:20-alpine as build

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# STAGE 2: Runtime
FROM node:20-alpine

WORKDIR /usr/src/app

COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/package*.json ./
RUN npm ci --omit=dev

CMD ["npm", "run", "start"]
