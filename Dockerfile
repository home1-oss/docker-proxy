
# see: https://github.com/nginxinc/docker-nginx/blob/3e8a6ee0603bf6c9cd8846c5fa43e96b13b0f44b/mainline/alpine/Dockerfile

FROM nginx:1.10.2-alpine

COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/render.sh /render.sh
COPY docker/proxy.conf_tpl /proxy.conf_tpl
COPY docker/reverse_proxy.conf_tpl /reverse_proxy.conf_tpl

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
