# 📘 Monorepo CI Pipeline – Jenkins



## 🧩 Overview
This project demonstrates how to build a **smart, efficient, and modular CI pipeline** for a monorepo containing multiple microservices written in different languages (Node.js, Python, Go).  
The goal was to create a Jenkins pipeline that automatically understands what changed, runs only the relevant checks, performs linting, testing, security scanning, builds Docker images, and sends notifications — all in a clean and automated workflow.

To simplify the idea, you can think of the pipeline as a **smart garage**:  
instead of inspecting every car every time, it only checks the one that actually came in for service.  
The same applies here — only the services that were modified go through the full CI process.



---

## 📦 Repository Structure

root/
├── user-service/              # Node.js microservice
│   ├── Dockerfile
│   └── ...
├── transaction-service/       # Python (FastAPI)
│   ├── Dockerfile
│   └── ...
├── notification-service/      # Go
│   ├── Dockerfile
│   └── ...
├── Jenkinsfile                # Main CI pipeline
└── shared/
└── ci/
├── lint.sh
├── test.sh
└── scan.sh



---

## 🎯 CI Goals

### ✔ 1. Trigger Conditions
- Runs on every push or PR to `main` or `develop`
- Performs a clean checkout from the repository

### ✔ 2. Detect Changed Services
- Automatically identifies which microservices were modified using `git diff`
- Runs CI stages **only** for the affected services

### ✔ 3. Lint & Code Quality
- Node.js → ESLint  
- Python → flake8 / pylint  
- Go → go vet  
- Executes in parallel per service

### ✔ 4. Unit Testing
- Runs language‑specific unit tests (npm test / pytest / go test)
- Can be extended to publish JUnit reports and coverage

### ✔ 5. Security Scans
- Secrets detection → gitleaks  
- SAST:
  - Node → npm audit  
  - Python → bandit  
  - Go → go vet  

### ✔ 6. Docker Build
- Builds Docker images for each modified service
- Tags images using: `ci-<short_sha>`
- Pushes to DockerHub

### ✔ 7. Notifications
- Sends Slack notifications on success or failure
- Uses Jenkins credentials securely

### ✔ 8. Manual Approval
- Stops before deployment  
- Allows future extension into a full CD pipeline

---

## 🔧 Pipeline Flow (High-Level)

```mermaid
flowchart TD

A[Checkout] --> B[Detect Changed Services]
B -->|No changes| Z[End]
B -->|Changes detected| C[Secrets Scan]
C --> D[Lint]
D --> E[Unit Tests]
E --> F[Security Scans]
F --> G[Docker Build & Push]
G --> H[Manual Approval]
H --> I[Slack Notification]




🧠 How It Works
1. Detecting Changes
The pipeline compares HEAD~1 with HEAD to determine which service directories were modified.
If nothing changed — heavy stages are skipped.

2. Parallel Execution
Each service runs in its own parallel stage, reducing overall build time.

3. Fail‑Fast
If linting, testing, or scanning fails — the pipeline stops immediately.

4. Docker Build
Each modified service gets its own Docker image, tagged with the commit SHA.

5. Slack Notifications
At the end of the pipeline, a Slack message is sent summarizing the result.





🧪 CI Scripts (shared/ci)
lint.sh
Runs language‑specific linting and code quality checks.

test.sh
Executes unit tests for each service.

scan.sh
Runs basic security scans.

Keeping these scripts separate makes the pipeline easier to maintain and extend.





🚀 How to Run
The pipeline triggers automatically on:

Push to main

Push to develop

Pull requests targeting these branches

You can also run it manually from Jenkins.




📣 Slack Notifications
At the end of the pipeline, a message is sent to Slack:

✅ CI SUCCESS for monorepo-ci

❌ CI FAILED for monorepo-ci

The webhook is stored securely in Jenkins credentials.




🔐 Security
No secrets are stored in the repository

All sensitive values are handled via Jenkins credentials

gitleaks scans for exposed secrets

bandit / npm audit / go vet provide SAST coverage




📝 Summary
This project delivers a complete, production‑grade CI pipeline for a monorepo.
It intelligently detects changes, runs only the necessary stages, performs linting, testing, security scanning, builds Docker images, and sends notifications — all in a clean, modular, and efficient workflow.

The result is a CI system that behaves like real‑world pipelines used in modern engineering teams.
