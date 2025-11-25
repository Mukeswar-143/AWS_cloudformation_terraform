# Demo CI/CD: Deploy to EC2

This repository includes a GitHub Actions CI/CD pipeline that builds the app artifact and deploys it to an EC2 instance via SSH.

Files of interest:
- `.github/workflows/deploy-ec2.yml` — CI/CD workflow that packages `app/` and deploys it to an EC2 host using SSH.
- `scripts/ec2-bootstrap.sh` — helper script to bootstrap an EC2 instance (installs Python and creates a sample systemd service).
- `scripts/demo-app.service` — example systemd unit to run the app on the host.

Required GitHub secrets for the deploy job (add under repository Settings → Secrets -> Actions):

- `SSH_PRIVATE_KEY` — the private SSH key (PEM format) used to connect to your EC2 instance. Keep this private.
- `EC2_HOST` — host or public IP of the target EC2 instance (e.g., 3.12.34.56 or ec2-3-12-34-56.compute-1.amazonaws.com)
- `EC2_USER` — username to SSH as (e.g., `ec2-user` for Amazon Linux / `ubuntu` for Ubuntu)
- `SSH_PORT` — (optional) SSH port; default is `22` when not set
- `DEPLOY_PATH` — remote path on the EC2 instance where the artifact will be copied (e.g., `/opt/demo-app`)
- `DEPLOY_SERVICE_NAME` — (optional) a systemd service name the workflow will attempt to restart after deployment (e.g., `demo-app`)

How the workflow works (high-level):

1. On push to `main`, the workflow packages the `app/` folder into an archive.
2. It stores the archive as a workflow artifact, then uses `scp` to copy the artifact to the EC2 host.
3. The workflow SSHs into the EC2 instance, extracts the archive into `DEPLOY_PATH`, installs Python requirements (if present), and attempts to restart the configured systemd service (if configured).

Preparing the EC2 host:

1. Upload your public SSH key to the EC2 instance (or use an AMI's default key).
2. Run the bootstrap script (or copy it to the instance and run as sudo):

```bash
# On the EC2 instance
sudo bash -x ec2-bootstrap.sh /opt/demo-app
```

3. Drop the artifact `artifact.tar.gz` in the `DEPLOY_PATH` and test service restart:

```bash
cd /opt/demo-app
tar -xzf artifact.tar.gz -C .
sudo systemctl restart demo-app
sudo journalctl -u demo-app -f
```

If you'd like, I can:
- add ECR-based Docker deployment instead (build image, push to ECR from CI, pull on EC2), or
 - add ECR-based Docker deployment instead (build image, push to ECR from CI, pull on EC2), or
- extend the workflow to use a blue/green or rolling deploy pattern.
 
ECR / App Runner CI/CD
----------------------

This repo now contains a workflow to build a container, push it to ECR and deploy to App Runner.

Required repository secrets for ECR/App Runner flow:
- `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` with permissions to manage ECR & App Runner
- `AWS_REGION` — region for ECR/App Runner operations (e.g. us-east-1)
- `ECR_REPOSITORY` — optional, repository name to push to. If not set the workflow uses a default.
- `APPRUNNER_SERVICE_NAME` — optional, name of the App Runner service. If provided, the workflow will create or update the service.

Workflow file: `.github/workflows/build-and-deploy-ecr-apprunner.yml`

