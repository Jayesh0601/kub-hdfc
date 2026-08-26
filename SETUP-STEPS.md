# HDFC Bank Website - Complete Setup Steps

This file explains exactly:
- which machine to use,
- which file to run,
- when to run it,
- and why we run it.

---

# 1. Create AWS EC2 Instances

Create TWO EC2 instances.

## EC2 1 - Master

Name:

```text
k8s-master
```

OS:

```text
Amazon Linux 2023
```

Recommended for learning:

```text
2 vCPU
4 GB RAM
```

## EC2 2 - Worker

Name:

```text
k8s-worker
```

OS:

```text
Amazon Linux 2023
```

Recommended:

```text
2 vCPU
4 GB RAM
```

### Why?

The Master controls Kubernetes.

The Worker runs our website Pods.

---

# 2. Security Group

Attach the same Security Group to both EC2 instances.

Allow:

```text
22
```

For SSH.

Allow:

```text
6443
```

For Kubernetes API communication.

Allow the Kubernetes internal traffic between Master and Worker using the same Security Group.

For learning, allow the NodePort range:

```text
30000-32767
```

Do not expose every Kubernetes internal port to the whole internet in production.

---

# 3. Connect to Master

From Windows PowerShell:

```bash
ssh -i your-key.pem ec2-user@MASTER_PUBLIC_IP
```

---

# 4. Connect to Worker

Open another PowerShell window:

```bash
ssh -i your-key.pem ec2-user@WORKER_PUBLIC_IP
```

Keep both terminals open.

---

# 5. Common Setup - BOTH EC2s

File:

```text
scripts/01-common-setup.sh
```

Run this file on:

```text
MASTER
WORKER
```

Run:

```bash
chmod +x scripts/01-common-setup.sh
sudo ./scripts/01-common-setup.sh
```

If the repository is not cloned yet, copy the file to the EC2 or clone the GitHub repository first.

### Why?

This file prepares both machines.

It:

- updates Amazon Linux,
- installs basic tools,
- disables swap,
- loads Kubernetes kernel modules,
- enables IP forwarding,
- installs containerd,
- configures containerd,
- installs kubeadm,
- installs kubelet,
- installs kubectl.

---

# 6. Master Initialization - MASTER ONLY

File:

```text
scripts/02-master-init.sh
```

Run ONLY on:

```text
k8s-master
```

Before running it, check:

```bash
hostname -I
```

The script asks for the Master private IP.

Run:

```bash
chmod +x scripts/02-master-init.sh
sudo ./scripts/02-master-init.sh
```

### Why?

This creates the Kubernetes Control Plane.

The Master becomes the controller of the cluster.

At the end, kubeadm prints a command similar to:

```bash
sudo kubeadm join 10.0.1.10:6443 --token XXXXX --discovery-token-ca-cert-hash sha256:XXXXX
```

COPY THIS COMMAND.

You will run it on the Worker.

---

# 7. Configure kubectl - MASTER ONLY

The Master initialization script also configures kubectl.

Check:

```bash
kubectl get nodes
```

The Master may initially show:

```text
NotReady
```

This is normal until the Pod network is installed.

---

# 8. Install Pod Network - MASTER ONLY

The Master initialization script installs Flannel.

Check:

```bash
kubectl get pods -A
```

Then:

```bash
kubectl get nodes
```

The Master should eventually become:

```text
Ready
```

---

# 9. Join Worker - WORKER ONLY

Go to:

```text
k8s-worker
```

Run the exact `kubeadm join ...` command printed by the Master.

Example:

```bash
sudo kubeadm join 10.0.1.10:6443 \
  --token XXXXX.XXXXXXXX \
  --discovery-token-ca-cert-hash sha256:XXXXXXXX
```

Do not type the example values. Use your real command.

---

# 10. Verify Worker - MASTER

Go back to Master.

Run:

```bash
kubectl get nodes
```

Expected:

```text
NAME          STATUS   ROLES
k8s-master    Ready    control-plane
k8s-worker    Ready    <none>
```

You now have a working Kubernetes cluster.

---

# 11. Website Docker Image

The Dockerfile is:

```text
docker/Dockerfile
```

This file is NOT a Kubernetes YAML file.

It is used to create the website Docker image.

The Docker image contains NGINX and the HTML website.

Expected website structure:

```text
insurance/index.html
internetbanking/index.html
loans/index.html
mobilebanking/index.html
```

The Dockerfile copies these folders into NGINX.

---

# 12. Build Docker Image

Build the image on any machine that has Docker installed.

This can be:

- your local Windows PC,
- a build server,
- or an EC2 instance with Docker.

It does NOT have to be the Kubernetes Master.

Go to the project root.

Example:

```bash
docker build -f docker/Dockerfile -t YOUR_DOCKERHUB_USERNAME/hdfc-bank:1.0 .
```

Replace:

```text
YOUR_DOCKERHUB_USERNAME
```

with your Docker Hub username.

---

# 13. Push Image to Docker Hub

Login:

```bash
docker login
```

Push:

```bash
docker push YOUR_DOCKERHUB_USERNAME/hdfc-bank:1.0
```

Why?

The Kubernetes Worker needs to download the image.

Flow:

```text
Your PC
   |
   v
Docker Build
   |
   v
Docker Hub
   |
   v
Kubernetes Worker
   |
   v
Pod
```

---

# 14. Update Deployment Image

File:

```text
k8s/deployment.yaml
```

Find:

```text
YOUR_DOCKERHUB_USERNAME/hdfc-bank:1.0
```

Replace the username with your Docker Hub username.

Example:

```text
nitishkr/hdfc-bank:1.0
```

---

# 15. Deploy Website - MASTER ONLY

Go to:

```text
k8s-master
```

Run:

```bash
kubectl apply -f k8s/deployment.yaml
```

Check:

```bash
kubectl get deployments
```

Check Pods:

```bash
kubectl get pods
```

You should have two Pods because:

```text
replicas: 2
```

Why two Pods?

If one Pod fails, another Pod can continue serving the website.

---

# 16. Create Service - MASTER ONLY

File:

```text
k8s/service.yaml
```

Run:

```bash
kubectl apply -f k8s/service.yaml
```

Check:

```bash
kubectl get svc
```

Why?

A Service gives a stable way to access the Pods.

Flow:

```text
Service
   |
   +--- Pod 1
   |
   +--- Pod 2
```

---

# 17. Install Ingress Controller - MASTER ONLY

File:

```text
scripts/04-install-ingress.sh
```

Run:

```bash
chmod +x scripts/04-install-ingress.sh
sudo ./scripts/04-install-ingress.sh
```

Check:

```bash
kubectl get pods -n ingress-nginx
```

Then:

```bash
kubectl get svc -n ingress-nginx
```

Find the HTTP NodePort.

Example:

```text
80:30080/TCP
```

Your actual NodePort may be different.

---

# 18. Create Ingress Rules - MASTER ONLY

File:

```text
k8s/ingress.yaml
```

Run:

```bash
kubectl apply -f k8s/ingress.yaml
```

Check:

```bash
kubectl get ingress
```

Ingress routes:

```text
/internetbanking
/insurance
/loans
/mobilebanking
```

to the HDFC Service.

---

# 19. Open Website

Find the Ingress NodePort:

```bash
kubectl get svc -n ingress-nginx
```

Suppose it shows:

```text
80:30080/TCP
```

Open:

```text
http://WORKER_PUBLIC_IP:30080/internetbanking/
```

Other pages:

```text
http://WORKER_PUBLIC_IP:30080/insurance/
http://WORKER_PUBLIC_IP:30080/loans/
http://WORKER_PUBLIC_IP:30080/mobilebanking/
```

---

# 20. Final Request Flow

```text
Browser
   |
   v
Worker Public IP
   |
   v
Ingress Controller
   |
   v
HDFC Service
   |
   +--------+--------+
   |                 |
   v                 v
 Pod 1             Pod 2
 NGINX             NGINX
   |                 |
   +--------+--------+
            |
            v
       HTML Website
```

---

# 21. Important Commands

Check Nodes:

```bash
kubectl get nodes
```

Check Pods:

```bash
kubectl get pods
```

Check all Pods:

```bash
kubectl get pods -A
```

Check Deployments:

```bash
kubectl get deployments
```

Check Services:

```bash
kubectl get svc
```

Check Ingress:

```bash
kubectl get ingress
```

Check Ingress Controller:

```bash
kubectl get pods -n ingress-nginx
```

Check Ingress Service:

```bash
kubectl get svc -n ingress-nginx
```

Pod logs:

```bash
kubectl logs POD_NAME
```

Pod details:

```bash
kubectl describe pod POD_NAME
```

---

# 22. Which File Runs Where?

| File | Machine | Why |
|---|---|---|
| `scripts/01-common-setup.sh` | Master + Worker | Common Kubernetes setup |
| `scripts/02-master-init.sh` | Master only | Create Control Plane |
| `scripts/03-worker-check.sh` | Worker | Check Worker services |
| `scripts/04-install-ingress.sh` | Master only | Install Ingress Controller |
| `docker/Dockerfile` | Build machine | Build website image |
| `docker/build-and-push.sh` | Build machine | Build and push image |
| `k8s/deployment.yaml` | Master | Create Pods |
| `k8s/service.yaml` | Master | Create Service |
| `k8s/ingress.yaml` | Master | Create routing rules |

---

# 23. Important Rule

Do not run all files everywhere.

Use this simple rule:

```text
MASTER:
- 01-common-setup.sh
- 02-master-init.sh
- 04-install-ingress.sh
- deployment.yaml
- service.yaml
- ingress.yaml

WORKER:
- 01-common-setup.sh
- kubeadm join command
- 03-worker-check.sh

BUILD MACHINE:
- Dockerfile
- build-and-push.sh
```

---

# 24. If Worker Does Not Join

On Worker:

```bash
sudo systemctl status kubelet
```

```bash
sudo systemctl status containerd
```

On Master:

```bash
kubectl get nodes
```

If the join token has expired, generate a new command on Master:

```bash
kubeadm token create --print-join-command
```

Then run the generated command on Worker.

---

# 25. If Website Pod Is Not Running

On Master:

```bash
kubectl get pods
```

Then:

```bash
kubectl describe pod POD_NAME
```

And:

```bash
kubectl logs POD_NAME
```

Common causes:

- Wrong Docker Hub username.
- Wrong image tag.
- Image was not pushed.
- Worker cannot pull image.
- Website files are missing.

---

# 26. If Website Does Not Open

Check:

```bash
kubectl get pods
```

```bash
kubectl get svc
```

```bash
kubectl get ingress
```

```bash
kubectl get svc -n ingress-nginx
```

Then check AWS Security Group.

If NodePort is:

```text
30080
```

allow TCP `30080` from the internet for learning.

Then open:

```text
http://WORKER_PUBLIC_IP:30080/internetbanking/
```

---

# 27. Production Next Steps

After the basic setup works, improve it with:

1. Route 53 domain.
2. AWS Load Balancer.
3. Ingress.
4. HTTPS/SSL.
5. Cert-Manager.
6. Kubernetes Secrets.
7. Resource limits.
8. Health checks.
9. Monitoring.
10. CI/CD from GitHub Actions.

The current repository is intentionally kept simple for learning the Kubernetes basics.
