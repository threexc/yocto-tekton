## sstate

### Automatic Shared State

The contents of the `automated` directory will configure a cronjob and
eventlistener to rebuild the core-image-\* group of images in a directory
once per day (similar to the contents of `meta-python`), which can then
be used in the `SSTATE_MIRROR` variable in builds. The deployment.yaml,
service.yaml, pv.yaml, and pvc.yaml are used to provision that build
space and also to serve it as a browsable web interface in an httpd
container.

### Helm Chart

An example of a Helm chart that can be used to deploy the httpd server
portion is in the `helm-chart` directory. It can be installed with the
following command:

`helm install <deployment_name> --namespace tekton-pipelines helm-chart/`

Where <deployment_name> can be whatever you'd like (meta-python expects
it to be "yocto-sstate" by default).

### Notes/Lessons Learned

- Helm doesn't like "generateName" fields (making adding the Tekton
  parts to the chart difficult):
  https://github.com/helm/helm/issues/3348
