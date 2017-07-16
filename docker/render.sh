#!/usr/bin/env sh

target_directory="$1"

if [ ! -z "${BACKEND_HOST}" ]; then
    # reverse_proxy mode
    echo "BACKEND_HOST not blank, reverse_proxy mode."
    if [ -z "${BACKEND_PORT}" ]; then export BACKEND_PORT="8081"; fi
    if [ -z "${BACKEND_PROTOCOL}" ]; then export BACKEND_PROTOCOL="http"; fi
    BACKEND_HOST_PORT="${BACKEND_HOST}:${BACKEND_PORT}"

    BASIC_AUTH_HEADER=""
    if [ ! -z "${BASIC_AUTH_PASS}" ] && [ ! -z "${BASIC_AUTH_USER}" ]; then
        BASIC_AUTH_HEADER="'Basic $(echo -ne "${BASIC_AUTH_USER}:${BASIC_AUTH_PASS}" | base64)'"
    fi

    if [ -z "${SERVER_LOCATION}" ]; then export SERVER_LOCATION="/"; fi
    if [ -z "${SERVER_NAME}" ]; then export SERVER_NAME="nexus.local"; fi
    SERVER_PROXY_PASS="${BACKEND_PROTOCOL}://backend"
    if [ ! -z "${SERVER_PROXY_PASS_CONTEXT}" ]; then export SERVER_PROXY_PASS="${SERVER_PROXY_PASS}${SERVER_PROXY_PASS_CONTEXT}"; fi

    sed "s#<BACKEND_HOST_PORT>#${BACKEND_HOST_PORT}#; s#<SERVER_LOCATION>#${SERVER_LOCATION}#" reverse_proxy.conf_tpl | \
        sed "s#<SERVER_PROXY_PASS>#${SERVER_PROXY_PASS}#" > ${target_directory}/proxy.conf

    # replace
    #    <BASIC_AUTH_SETTING>
    # to
    #    # add basic auth header
    #    set $authorization $http_authorization;
    #    if ($authorization = '') {
    #      set $authorization ${BASIC_AUTH_HEADER};
    #    }
    #    proxy_set_header Authorization $authorization;
    # if BASIC_AUTH_HEADER present
    if [ ! -z "${BASIC_AUTH_HEADER}" ]; then
        sed -i "s|<BASIC_AUTH_SETTING>|# add basic auth header\\n    set \$authorization \$http_authorization;\\n    if (\$authorization = '') {\\n      set \$authorization ${BASIC_AUTH_HEADER};\\n    }\\n    proxy_set_header Authorization \$authorization;|" ${target_directory}/proxy.conf
    else
        sed -i "s|<BASIC_AUTH_SETTING>|# no basic auth header|" ${target_directory}/proxy.conf
    fi
else
    # proxy mode
    echo "BACKEND_HOST is blank, proxy mode."
    SERVER_RESOLVER=$(cat /etc/resolv.conf | grep -i nameserver | head -n1 | cut -d ' ' -f2)
    if [ -z "${SERVER_NAME}" ]; then export SERVER_NAME="*.local"; fi

    sed "s#<SERVER_RESOLVER>#${SERVER_RESOLVER}#" proxy.conf_tpl > ${target_directory}/proxy.conf
fi

sed -i "s#<SERVER_NAME>#${SERVER_NAME}#" ${target_directory}/proxy.conf

echo "${target_directory}/proxy.conf content:"
cat ${target_directory}/proxy.conf
