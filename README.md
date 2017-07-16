#docker-proxy
Proxy for home1-oss infrastructure services

## Why do we need proxy server like this?

Nexus3 played many roles in home1-oss:
1. maven repositories
2. maven site
3. file server
4. docker mirror
5. docker registry

Original nexus3 service port/contextPath:
```
- nexus3.local
|- 28081/nexus/repository/maven-*/: maven repositories
|- 28081/nexus/repository/files/  : file server
|- 28081/nexus/repository/mvnsite/: maven site
|- 5001/                          : docker mirror
|- 5000/                          : docker registry
```

We want to keep flexibility, for example, using nginx to replace nexus3 as maven site 
or using official docker registry to replace nexus3 as docker mirror/registry.
We also want to omit port and context path in our scripts.
We need multiple host names, but one container has only one host name.

## How does it work

docker-proxy containers
```
        Host network        |  docker network (docker network create oss-network)

                            |---> 80 port on oss-network of nexus.local          (randomPort:80)
                            |---> 80 port on oss-network of fileserver.local     (randomPort:80)
 docker-proxy.local(80:80) -|---> 80 port on oss-network of mvnsite.local        (randomPort:80)
                            |---> 80 port on oss-network of mirror.docker.local  (randomPort:80)
                            |---> 80 port on oss-network of registry.docker.local(randomPort:80)
```

nexus3 behind docker-proxy containers
```
                               docker network (docker network create oss-network)
 nexus.local           -- proxy 28081/nexus/repository/maven-*/ of ---|
 fileserver.local      -- proxy 28081/nexus/repository/files/   of ---|
 mvnsite.local         -- proxy 28081/nexus/repository/mvnsite/ of    |-> nexus3.local
 mirror.docker.local   -- proxy 5001/                           of ---|
 registry.docker.local -- proxy 5000/                           of ---|
```

Gitlab-ci runner or jenkins worker uses nexus.local, mvnsite.local ...

Man uses docker-proxy.local to browse http://nexus.local/nexus/, http://mvnsite.local.
