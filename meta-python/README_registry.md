# registry

The contents are based on the instructions here:

https://www.linuxtechi.com/setup-private-docker-registry-kubernetes/

The reason for making this registry is so that the meta-python pipeline
(and others) can push their test images somewhere for use by the
pipeline without relying on Docker Hub or other services.

Before applying any of this, make sure that you create the directories
/opt/certs and /opt/registry, and generate certs for the registry:

`cd /opt`
`sudo openssl req -newkey rsa:4096 -nodes -sha256 -keyout \
 ./certs/registry.key -x509 -days 365 -out ./certs/registry.crt`

 The registry name should match the master node's name, e.g.
 yow-tgamblin-fedora2:31320 or 192.168.0.128:31320. The build-and-push-ptest-container
 and run-ptest tasks will also need to be updated with your chosen IP/hostname.

 Note that if you are running a cluster with multiple nodes, you will
 need to perform some extra steps (such as the NFS suggestion in the
 above article).
