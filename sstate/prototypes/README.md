These don't work (and might not ever), but they need to be added 
to the repo as a reference and in case we ever figure out the 
issue. Helm will install them when they're added to 
yocto-sstate/templates, but sometimes the initial pipelinerun is
unable to locate the yocto-sstate-build task, and the subsequent
pipelineruns never seem to be correctly triggered (despite the
cronjob reporting that it has been successfully running), possibly
due to Helm's incompatibility with the metadata.generateName field
(which results in every pipelinerun having to have the same 
hard-coded name).
