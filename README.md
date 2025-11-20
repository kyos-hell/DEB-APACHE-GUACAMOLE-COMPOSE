# 🚀 DEB-APACHE-GUACAMOLE-COMPOSE

![Docker](https://img.shields.io/badge/Docker-24.0-blue?logo=docker)
![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2.x-blue?logo=docker)
![Debian](https://img.shields.io/badge/Debian-12-red)

A **personal implementation of Apache Guacamole** on Debian using Docker Compose.  
This project provides a **remote access bastion** to centralize and secure access to your services and VMs.  
Designed for **learning, experimentation, and DevOps/IaC practice**.

---

## Project Structure

```text
DEB-APACHE-GUACAMOLE-COMPOSE/
│
├─ guacamole-tomcat/
│  ├─ Dockerfile
│  └─ docker-entrypoint.sh
│
├─ guacd/
│  ├─ Dockerfile
│  └─ docker-entrypoint.sh
│
├─ mariadb-guacamole/
│  ├─ Dockerfile
│  ├─ docker-entrypoint.sh
│  └─ init/
│     ├─ 000-create-table.sql
│     ├─ 001-create-schema.sql
│     └─ 002-create-admin-user.sql
│
├─ docker-compose.yml
└─ instruction.txt

---

## 🎯 Project Goals

- Deploy a **complete Guacamole bastion** (Tomcat + guacd + MariaDB) on Debian via Docker Compose.
- Learn **Dockerfile creation and hardening**.
- Structure a project for **IaC and DevOps best practices**.
- Document and version for **sharing on GitHub**.

---

## 🛠️ Roadmap / Improvements

### Security

- Automatic Docker image updates  
- Secure passwords and environment variables  
- Reduce container permissions
- add https  

### Dockerfile Optimization

- Reduce image size  
- Minimize unnecessary layers  
- Optimize build times  
- Multi stage integration

### Automation / CI-CD

- Integrate with GitHub Actions or GitLab CI  
- Build & container startup tests  
- Auto-deploy to a sandbox environment  

### Documentation & Readability

- Network & architecture diagrams  
- Step-by-step deployment instructions  
- Multi-environment configuration examples

---

## ⚡ Installation

1. Clone the repository:

```bash
git clone https://github.com/YOUR-USERNAME/DEB-APACHE-GUACAMOLE-COMPOSE.git
cd DEB-APACHE-GUACAMOLE-COMPOSE

```

2. Build and start the containers:

```bash
docker-compose up -d --build

```

3. Access Guacamole at: http://<your-ip>:8080/guacamole

## Prerequisites
 
- Docker >= 24.0
- Docker Compose >= 2.x
- Ports 8080 & 4822 available

## 🤝 Contributing

This project is **experimental (v1.0.0)** and mainly intended as a learning journey.  
Any suggestions, feedback, or contributions are **very welcome** to help me improve my skills, adopt best practices, and make the project better.  

Examples of contributions could include:

- Improving container security  
- Optimizing Dockerfiles and build processes  
- Adding automation scripts, tools, or helpful features  
- Sharing tips for better DevOps/IaC practices