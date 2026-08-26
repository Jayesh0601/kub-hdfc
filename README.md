# HDFC Bank Static Website - Kubernetes Deployment

This repository contains a simple Kubernetes setup for deploying a static HTML website on AWS EC2 using Amazon Linux 2023.

## Project

The website has pages like:

- `/insurance/`
- `/internetbanking/`
- `/loans/`
- `/mobilebanking/`

## Architecture

```text
Internet
   |
   v
AWS EC2 Worker Public IP
   |
   v
Ingress Controller
   |
   v
Kubernetes Service
   |
   +---------+---------+
   |                   |
   v                   v
 Pod 1                Pod 2
 NGINX                NGINX
   |                   |
   +---------+---------+
             |
             v
        Static HTML
```

## Files

```text
HDFC-Kubernetes-Deployment/
|
|-- README.md
|-- SETUP-STEPS.md
|
|-- scripts/
|   |-- 01-common-setup.sh
|   |-- 02-master-init.sh
|   |-- 03-worker-check.sh
|   |-- 04-install-ingress.sh
|
|-- k8s/
|   |-- deployment.yaml
|   |-- service.yaml
|   |-- ingress.yaml
|
|-- docker/
|   |-- Dockerfile
|   |-- build-and-push.sh
|
`-- website/
    |-- insurance/
    |   `-- index.html
    |-- internetbanking/
    |   `-- index.html
    |-- loans/
    |   `-- index.html
    `-- mobilebanking/
        `-- index.html
```

Your existing HTML folders can be kept in the same repository. If they already exist, do not create duplicate folders.

## EC2 Setup

Use two EC2 instances:

### Master
- Amazon Linux 2023
- 2 vCPU or more
- 4 GB RAM recommended for learning
- Hostname: `k8s-master`

### Worker
- Amazon Linux 2023
- 2 vCPU or more
- 4 GB RAM recommended for learning
- Hostname: `k8s-worker`

## Basic order

1. Create Master and Worker EC2.
2. Configure the Security Group.
3. Run `scripts/01-common-setup.sh` on BOTH EC2s.
4. Run `scripts/02-master-init.sh` ONLY on Master.
5. Copy the `kubeadm join` command printed by Master.
6. Run that join command on Worker.
7. Run `scripts/03-worker-check.sh` on Worker if needed.
8. Build and push the website Docker image from a machine with Docker.
9. Update the image name in `k8s/deployment.yaml`.
10. Run the Kubernetes YAML files on Master.
11. Install Ingress.
12. Open the website using the Worker Public IP and the Ingress NodePort.

See `SETUP-STEPS.md` for the complete sequence.
