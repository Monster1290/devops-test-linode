# DevOps test with linode provider
Educational purpose repo. Contains:
1. Simple python flask app with Prometheus exporter
2. Tests for simple module "buzz generator"
3. Simple dockerfile to build image
4. Terraform infrastructure description for Linode provider
5. Ansible playbook to setup Jenkins slave nodes
6. Jenkins multibranch pipline.
   1. Build and test on each push for every branch
   2. On manual execution for given branch launches app on a staging node
   3. On push to main branch makes artifact (image), pushes artifact to registry and starts new canary rollout with that artifact

Repo contains 4 branches:
1. main - aka release branch
2. jenkins - jenkins related branch with pipline and scripts
3. infrastructure - infrastructure related branch with terraform and ansible configs
4. feature-branch - aka development branch