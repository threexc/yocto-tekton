## sstate

The YAML files can be modified and used manually to create an http
server deployment serving up a PersistentVolume and
PersistentVolumeClaim provisioned for storing the output of a bitbake
build that will in turn be used as an SSTATE_MIRROR for build pipelines
such as the meta-python example. Alternatively, you can use the Helm
tool for k8s to deploy it quickly and easily in your cluster, using the
following command:

`helm install <deployment_name> --namespace tekton-pipelines yocto-sstate/`

Where <deployment_name> can be whatever you'd like (meta-python expects
it to be "yocto-sstate" by default).

### Notes/Lessons Learned

- Helm doesn't like "generateName" fields:
  https://github.com/helm/helm/issues/3348
