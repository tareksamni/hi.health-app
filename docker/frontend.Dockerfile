ARG NGINX_IMAGE_TAG=latest

FROM nginx:${NGINX_IMAGE_TAG}

COPY ./frontend/index.html /usr/share/nginx/html

COPY ./frontend/scripts/generate-config.sh /docker-entrypoint.d/generate-config.sh

RUN chmod +x /docker-entrypoint.d/generate-config.sh

EXPOSE 80
