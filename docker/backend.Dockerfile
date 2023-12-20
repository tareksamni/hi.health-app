ARG APP_PATH=/usr/src/app
ARG NODE_IMAGE_TAG=18.15.0-alpine3.17
ARG CERT_IMAGE_TAG=3.17

FROM node:${NODE_IMAGE_TAG} as dependencies

WORKDIR ${APP_PATH}

ADD backend/package.json backend/package-lock.json ./
RUN npm ci

FROM node:${NODE_IMAGE_TAG} as pruned-dependencies

WORKDIR ${APP_PATH}
COPY backend/package.json backend/package-lock.json ./
COPY --from=dependencies ${APP_PATH}/node_modules ./node_modules
RUN npm prune --omit=dev

FROM node:${NODE_IMAGE_TAG} as builder

WORKDIR ${APP_PATH}

ADD backend/package.json backend/package-lock.json backend/tsconfig.json ./
COPY --from=dependencies ${APP_PATH}/node_modules ./node_modules
ADD backend/src ./src

RUN npx tsc -p .

FROM alpine:${CERT_IMAGE_TAG} as cert

RUN wget -O /rds-global-bundle.crt https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

FROM node:${NODE_IMAGE_TAG}
RUN apk update && apk --no-cache upgrade

COPY --from=cert /rds-global-bundle.crt /usr/local/share/ca-certificates

ENV NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates

WORKDIR ${APP_PATH}
RUN chown node:node ./
USER node

COPY --from=pruned-dependencies ${APP_PATH}/node_modules ./node_modules
COPY --from=builder ${APP_PATH}/dist ./dist

# Start
CMD ["node", "dist/index.js"]

EXPOSE 3000
