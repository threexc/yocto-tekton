## Yocto Dev Day/Summit Talk

### To Do

1. General cleanup of yocto-tekton
2. Helm chart for sstate deployment
   - Helm chart for meta-python pipelines if possible
3. Example using Tekton Triggers
4. Scheduler technique
   - Can be as simple as cron if other options too time-consuming to get
     ready
   - Current concept - deployment with pods running an image that
     contains a simple scheduler written in Go, takes queue requests
     (something based on [this](https://cloud.google.com/appengine/docs/standard/go111/taskqueue/push/example)?)
5. Look into recording for slide content
   - Screenshots may be simpler for some cases?
6. Figure out QEMU with kvm in Docker, add to build pipeline and run meta-python-ptest-image

### Presentation

- Slide count?

### Topics

1. Welcome
2. - Names, roles, companies, etc.
3. Yocto CI/CD Intro
4. - Autobuilder
5. - Other solutions in use by maintainers, users, etc.
6. K8S Overview
   - Links to tutorials?
   - Advantages over bare metal
7. Tekton Overview
   - Compare with other tools
8. The Single-Machine Kubernetes Cluster With kubeadm
   - Hardware Specifications Used
   - Underlying OS
   - Setup Instructions - Quick Peek
   - Notes about variety of options
   - Mention Flannel, CoreDNS, CNI plugins fix
9. Tekton in Action
   - Fast-forwarded video of meta-python pipeline (or screenshots)
10. Application to meta-python maintenance
    - Mention limitations, e.g. problems with commit message syntax,
      need to set up QEMU in container to add to pipeline (if this has
      not been completed)
    - Show Dashboard Contents
11. Thoughts on Other Layers
    - poky as a whole should be easy
    - Figure out method for meta-oe, meta-networking if possible
12. Faster Builds - The Shared State Deployment
    - Performance on small/low power systems with a Full Shared State
      Cache
    - Explain PV, PVC
13. AWS Usage?
14. Useful Tools
    - k9s
    - Helm
15. Future Plans
16. - Benchmark compilation like Openbenchmarking, KernelCI Dashboard, etc.
17. Where to Find Content
    - GitHub source
18. Questions?
