#!/bin/bash

set -euxo pipefail

# ============================================================
# Ubuntu 24.04 LTS - DevSecOps Jump Host Bootstrap
# ============================================================

exec > >(tee -a /var/log/install-tools.log) 2>&1

echo "=================================================="
echo "Starting DevSecOps Jump Host Bootstrap"
echo "Started at: $(date)"
echo "=================================================="

export DEBIAN_FRONTEND=noninteractive

# ============================================================
# 1. Update system
# ============================================================

echo "===== Updating system ====="

apt-get update

# ============================================================
# 2. Basic packages
# ============================================================

echo "===== Installing basic packages ====="

apt-get install -y \
    git \
    wget \
    curl \
    unzip \
    zip \
    tar \
    jq \
    vim \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    build-essential \
    python3 \
    python3-pip \
    python3-venv

git --version
python3 --version

# ============================================================
# 3. Java 21
# ============================================================

echo "===== Installing Java 21 ====="

apt-get install -y openjdk-21-jdk

java -version

JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

export JAVA_HOME

update-alternatives --set java "$JAVA_HOME/bin/java"

cat > /etc/profile.d/java.sh <<EOF
export JAVA_HOME=$JAVA_HOME
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

chmod 644 /etc/profile.d/java.sh

echo "JAVA_HOME=$JAVA_HOME"

# ============================================================
# 4. Node.js 22
# ============================================================

echo "===== Installing Node.js 22 ====="

curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

apt-get install -y nodejs

node --version
npm --version

# ============================================================
# Jenkins
# ============================================================

echo "===== Installing Jenkins ====="

install -m 0755 -d /etc/apt/keyrings

curl -fsSL \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    -o /etc/apt/keyrings/jenkins-keyring.asc

chmod 644 /etc/apt/keyrings/jenkins-keyring.asc

cat > /etc/apt/sources.list.d/jenkins.list <<EOF
deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/
EOF

apt-get update

apt-get install -y jenkins

mkdir -p /etc/systemd/system/jenkins.service.d

cat > /etc/systemd/system/jenkins.service.d/java.conf <<EOF
[Service]
Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
Environment="PATH=/usr/lib/jvm/java-21-openjdk-amd64/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
EOF

systemctl daemon-reload
systemctl enable jenkins
systemctl restart jenkins

sleep 15

systemctl --no-pager --full status jenkins || true

jenkins --version || true

# ============================================================
# 6. Docker Engine
# ============================================================

echo "===== Installing Docker ====="

install -m 0755 -d /etc/apt/keyrings

curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${VERSION_CODENAME}") stable
EOF

apt-get update

apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

systemctl enable docker
systemctl start docker

# Wait for Docker
echo "Waiting for Docker..."

for i in {1..30}; do
    if docker info >/dev/null 2>&1; then
        echo "Docker is ready"
        break
    fi

    echo "Waiting for Docker... attempt $i"
    sleep 2
done

usermod -aG docker ubuntu || true
usermod -aG docker jenkins || true

docker --version
docker compose version

# Restart Jenkins so it gets Docker group membership
systemctl restart jenkins

sleep 10

systemctl --no-pager --full status jenkins || true

# ============================================================
# 7. Terraform + Vault
# ============================================================

echo "===== Installing HashiCorp tools ====="

mkdir -p /etc/apt/keyrings

curl -fsSL \
    https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor \
    | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

chmod 644 /usr/share/keyrings/hashicorp-archive-keyring.gpg

cat > /etc/apt/sources.list.d/hashicorp.list <<EOF
deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main
EOF

apt-get update

apt-get install -y \
    terraform \
    vault

terraform version
vault version

# ============================================================
# 8. Maven
# ============================================================

echo "===== Installing Maven ====="

apt-get install -y maven

mvn --version

# ============================================================
# 9. Ansible
# ============================================================

echo "===== Installing Ansible ====="

apt-get install -y ansible

ansible --version

# ============================================================
# 10. AWS CLI v2
# ============================================================

echo "===== Installing AWS CLI v2 ====="

curl -fsSL \
    https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    -o /tmp/awscliv2.zip

rm -rf /tmp/aws

unzip -q /tmp/awscliv2.zip -d /tmp

/tmp/aws/install --update

rm -rf /tmp/aws
rm -f /tmp/awscliv2.zip

aws --version

# ============================================================
# 11. Trivy
# ============================================================

echo "===== Installing Trivy ====="

curl -fsSL \
    https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | gpg --dearmor \
    | tee /usr/share/keyrings/trivy.gpg > /dev/null

chmod 644 /usr/share/keyrings/trivy.gpg

cat > /etc/apt/sources.list.d/trivy.list <<EOF
deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main
EOF

apt-get update

apt-get install -y trivy

trivy --version

# ============================================================
# 12. MariaDB
# ============================================================

echo "===== Installing MariaDB ====="

apt-get install -y \
    mariadb-server \
    mariadb-client

systemctl enable mariadb
systemctl start mariadb

mysql --version

# ============================================================
# 13. PostgreSQL
# ============================================================

echo "===== Installing PostgreSQL ====="

apt-get install -y \
    postgresql \
    postgresql-contrib

systemctl enable postgresql
systemctl start postgresql

psql --version

# ============================================================
# 14. SonarQube
# ============================================================

echo "===== Installing SonarQube ====="

docker pull sonarqube:lts-community

docker rm -f sonar 2>/dev/null || true

docker run -d \
    --name sonar \
    --restart unless-stopped \
    -p 9000:9000 \
    sonarqube:lts-community

sleep 15

echo "===== SonarQube container ====="

docker ps --filter name=sonar

# ============================================================
# 15. Final Verification
# ============================================================

echo ""
echo "=================================================="
echo "INSTALLATION VERIFICATION"
echo "=================================================="

echo ""
echo "--- OS ---"
cat /etc/os-release

echo ""
echo "--- Java ---"
java -version

echo ""
echo "--- JAVA_HOME ---"
echo "$JAVA_HOME"

echo ""
echo "--- Jenkins ---"
jenkins --version || true
systemctl is-enabled jenkins || true
systemctl is-active jenkins || true

echo ""
echo "--- Jenkins Port ---"
ss -lntp | grep 8080 || true

echo ""
echo "--- Git ---"
git --version

echo ""
echo "--- Node ---"
node --version

echo ""
echo "--- npm ---"
npm --version

echo ""
echo "--- Docker ---"
docker --version

echo ""
echo "--- Docker Compose ---"
docker compose version

echo ""
echo "--- Terraform ---"
terraform version

echo ""
echo "--- Ansible ---"
ansible --version

echo ""
echo "--- Maven ---"
mvn --version

echo ""
echo "--- AWS CLI ---"
aws --version

echo ""
echo "--- Vault ---"
vault version

echo ""
echo "--- Trivy ---"
trivy --version

echo ""
echo "--- MariaDB ---"
mysql --version

echo ""
echo "--- PostgreSQL ---"
psql --version

echo ""
echo "--- SonarQube ---"
docker ps --filter name=sonar

echo ""
echo "=================================================="
echo "BOOTSTRAP COMPLETED SUCCESSFULLY"
echo "Completed at: $(date)"
echo "Log: /var/log/install-tools.log"
echo "=================================================="