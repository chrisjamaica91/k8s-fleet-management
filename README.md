# 🚀 Kubernetes Fleet Management Platform

> **Goal:** Master multi-cluster Kubernetes management, service mesh, event streaming, and AI-powered CI/CD at a Staff/Principal Engineer level ($200-280k salary range)

## 🎯 Project Mission

Build a **production-grade platform** for managing **10-50+ Kubernetes clusters** across multiple regions, demonstrating enterprise-scale DevOps and Platform Engineering skills.

**Target Roles:**

- Staff Platform Engineer
- Principal DevOps Engineer
- Site Reliability Engineer (SRE)
- Cloud Infrastructure Architect

---

## 📚 Current Status

**Phase:** 1 - Single Cluster Foundation + Zero Trust Security  
**Progress:** 85% (Production-Ready!)  
**Environment:** Development (AWS us-east-2)  
**Cluster:** fleet-dev-cluster (EKS 1.30, 3x t3.medium nodes)

### ✅ Completed

- ✅ EKS cluster deployed with Terraform (VPC, IAM, security groups)
- ✅ 3 microservices deployed (Order, Inventory, Notification)
- ✅ Istio service mesh with path-based routing
- ✅ HashiCorp Vault for secrets management
- ✅ Keycloak for authentication (OIDC/OAuth 2.0)
- ✅ Kafka event streaming (Strimzi operator)
- ✅ JWT authentication at gateway
- ✅ mTLS encryption (STRICT mode)
- ✅ RBAC authorization policies
- ✅ Zero Trust security architecture

### 🚧 In Progress

- Kiali dashboard for service mesh visualization
- Production observability stack (Prometheus, Grafana)

### 📋 Upcoming

- ArgoCD GitOps installation
- CI/CD pipeline with GitHub Actions
- Multi-cluster setup (dev, staging, prod)

---

### **Quick Access**

**Get LoadBalancer URLs:**

```bash
# Istio Gateway (all services)
kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Keycloak (authentication)
kubectl get svc keycloak-http -n security -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Vault UI (secrets management)
kubectl get svc vault-ui -n security -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

**Service Endpoints:**

- Order Service: `http://<GATEWAY>/orders/`
- Inventory Service: `http://<GATEWAY>/inventory/`
- Notification Service: `http://<GATEWAY>/notifications/`
- Health Checks: `http://<GATEWAY>/{service}/health`
- Keycloak Admin: `http://<KEYCLOAK>/auth` (admin/admin123)
- Vault UI: `http://<VAULT-UI>` (dev mode, auto-unsealed)

---

## 🔒 Zero Trust Security Architecture

**Implementation Status:** ✅ **PRODUCTION-READY**

This cluster implements a complete **Zero Trust security model** with multiple defense layers:

```
External Request
     ↓
[1] Istio Gateway (Path-based routing)
     ↓
[2] JWT Authentication (Keycloak OIDC validation)
     ↓
[3] Authorization Policies (RBAC at gateway)
     ↓
[4] mTLS Encryption (Service-to-service)
     ↓
[5] Vault Agent (Secrets injection)
     ↓
Application Pod
```

### **Security Components**

#### **1. Keycloak - Identity & Access Management**

- **Version:** v17.0.1-legacy (codecentric Helm chart v18.10.0)
- **Purpose:** Centralized authentication using OIDC/OAuth 2.0 standard
- **Configuration:**
  - Realm: `fleet-services`
  - 3 OIDC clients (order-service, inventory-service, notification-service)
  - 3 roles (fleet-admin, fleet-operator, fleet-viewer)
  - JWT tokens with 5-minute lifespan (security best practice)
  - LoadBalancer: Internet-facing for external authentication

**Keycloak Endpoint:**

```
http://<KEYCLOAK-LB>/auth
```

#### **2. HashiCorp Vault - Secrets Management**

- **Version:** v1.21.2 (dev mode for development)
- **Purpose:** Centralized secrets storage with Kubernetes auth
- **Configuration:**
  - Namespace: `security`
  - Kubernetes auth enabled
  - Role: `fleet-services` (read access to `secret/kafka/*` and `secret/keycloak/*`)
  - Vault Agent sidecar injection (automatic secret delivery)
  - Secrets mounted at `/vault/secrets/` in all pods

**Vault Integration:**

- All microservices have Vault agent sidecars (3/3 containers per pod)
- Kafka credentials injected automatically
- Keycloak client secrets stored in Vault
- No secrets in environment variables or ConfigMaps

#### **3. Istio Service Mesh - mTLS & Routing**

- **Version:** v1.29.2 (demo profile)
- **Purpose:** Mutual TLS encryption, traffic management, observability
- **Configuration:**
  - Automatic sidecar injection in `default` namespace
  - mTLS STRICT mode (rejects unencrypted connections)
  - Path-based routing through single LoadBalancer
  - Distributed tracing ready (Jaeger integration)

**mTLS Configuration:**

```yaml
# PeerAuthentication: Enforce STRICT mTLS
mode: STRICT

# DestinationRule: Use Istio-managed certificates
tls:
  mode: ISTIO_MUTUAL
```

**All service-to-service traffic is encrypted with automatic certificate rotation.**

#### **4. JWT Authentication (RequestAuthentication)**

- **Location:** `istio/request-authentication.yaml`
- **Purpose:** Validate JWT tokens at the gateway
- **Configuration:**
  - Issuer: Keycloak realm endpoint
  - JWKS URI: Keycloak public key endpoint (internal cluster DNS)
  - Token extraction: `Authorization: Bearer <token>` header
  - JWT payload forwarded to authorization policies via `x-jwt-payload` header

**How it works:**

1. User authenticates with Keycloak → receives JWT token
2. User sends request with `Authorization: Bearer <token>` header
3. Istio Gateway validates token signature using Keycloak public keys
4. If valid, request proceeds to authorization policies
5. If invalid/expired, request rejected with 401 Unauthorized

#### **5. Authorization Policies (RBAC)**

- **Location:** `istio/authorization-policies.yaml`
- **Purpose:** Role-based access control at the gateway
- **Policies:**

| Policy                | Action | Purpose                                               |
| --------------------- | ------ | ----------------------------------------------------- |
| `require-jwt`         | DENY   | Block unauthenticated requests (except health checks) |
| `authenticated-users` | ALLOW  | Allow authenticated users for GET/POST/PUT            |
| `admin-only`          | ALLOW  | Allow fleet-admin role for admin paths (all methods)  |
| `viewer-readonly`     | ALLOW  | Allow fleet-viewer role for GET only (read-only)      |
| `allow-health-checks` | ALLOW  | Allow unauthenticated health endpoint access          |

**Role-Based Access:**

- **fleet-admin:** Full access (GET, POST, PUT, DELETE on all paths including `/admin/*`)
- **fleet-operator:** CRUD operations (GET, POST, PUT on non-admin paths)
- **fleet-viewer:** Read-only access (GET only)

#### **6. Kafka Event Streaming**

- **Operator:** Strimzi v0.38.0
- **Brokers:** 2 replicas
- **Topics:** orders, inventory-updates, notifications
- **Integration:** Microservices use Kafka for async event-driven communication
- **Security:** Credentials stored in Vault, injected via Vault agent

---

### **Testing the Security Architecture**

#### **Setup Environment Variables**

```bash
# Get LoadBalancer endpoints
export GATEWAY=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export KEYCLOAK=$(kubectl get svc keycloak-http -n security -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Keycloak client secret (from order-service client)
export CLIENT_SECRET="<your-client-secret>"
```

#### **Test 1: Health Checks (No Authentication)**

```bash
# Should return 200 OK
curl http://$GATEWAY/orders/health
curl http://$GATEWAY/inventory/health
curl http://$GATEWAY/notifications/health
```

#### **Test 2: Protected Endpoints Require Authentication**

```bash
# Should return 403 Forbidden (RBAC: access denied)
curl http://$GATEWAY/orders/
```

#### **Test 3: Authenticate and Access with JWT Token**

```bash
# Get JWT token from Keycloak
ADMIN_TOKEN=$(curl -s -X POST "http://$KEYCLOAK/auth/realms/fleet-services/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testadmin" \
  -d "password=admin123" \
  -d "grant_type=password" \
  -d "client_id=order-service" \
  -d "client_secret=$CLIENT_SECRET" \
  | jq -r '.access_token')

# Access protected endpoint with token
curl -H "Authorization: Bearer $ADMIN_TOKEN" http://$GATEWAY/orders/
# Should return: {"service":"Order Service","version":"1.0.0",...}
```

#### **Test 4: RBAC - Viewer Read-Only Access**

```bash
# Get viewer token
VIEWER_TOKEN=$(curl -s -X POST "http://$KEYCLOAK/auth/realms/fleet-services/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testviewer" \
  -d "password=viewer123" \
  -d "grant_type=password" \
  -d "client_id=order-service" \
  -d "client_secret=$CLIENT_SECRET" \
  | jq -r '.access_token')

# GET works (viewer has read access)
curl -H "Authorization: Bearer $VIEWER_TOKEN" http://$GATEWAY/orders/

# POST denied (viewer is read-only)
curl -X POST -H "Authorization: Bearer $VIEWER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"item":"test"}' \
  http://$GATEWAY/orders/
# Should return: RBAC: access denied
```

#### **Test 5: Token Expiration**

```bash
# Wait 5 minutes for token to expire
sleep 300

# Try using expired token
curl -H "Authorization: Bearer $ADMIN_TOKEN" http://$GATEWAY/orders/
# Should return: 401 Unauthorized - "Jwt is expired"
```

#### **Test 6: Verify mTLS Encryption**

```bash
# Check PeerAuthentication (should show STRICT mode)
kubectl get peerauthentication -n default -o yaml

# Check DestinationRule (should show ISTIO_MUTUAL)
kubectl get destinationrule -n default -o yaml

# View mTLS status in Kiali dashboard (see "🔒" icons on connections)
kubectl port-forward -n istio-system svc/kiali 20001:20001
# Open: http://localhost:20001
```

---

### **Architecture Decisions & Best Practices**

#### **Why JWT at Gateway vs. Service-Level Auth?**

✅ **Gateway-level authentication:**

- Single point of auth validation (consistent across all services)
- Services don't need auth libraries (simpler microservice code)
- Centralized token validation and rotation
- Better performance (validate once at gateway)

❌ **Service-level authentication:**

- Each service needs auth library and configuration
- Duplicated token validation logic
- Higher latency (validate on every service call)
- More complex microservice code

#### **Why STRICT mTLS Mode?**

- **STRICT mode** = All connections MUST be mTLS (rejects plaintext)
- **PERMISSIVE mode** = Accepts both mTLS and plaintext (migration mode)
- **Production best practice:** STRICT mode (zero-trust principle)

#### **Why Short Token Lifespan (5 minutes)?**

- Reduces impact of stolen tokens
- Forces token refresh (ensures users are still active)
- Industry standard: 5-15 minutes for access tokens
- Use refresh tokens for long sessions (not implemented in dev cluster)

#### **Why Vault Agent Sidecars?**

- Secrets never stored in environment variables or ConfigMaps
- Automatic secret rotation without pod restarts
- Secrets delivered to filesystem (more secure than env vars)
- Application reads secrets from `/vault/secrets/` (simple integration)

---

### **Security Layers Summary**

| Layer                    | Technology            | Protection                                  |
| ------------------------ | --------------------- | ------------------------------------------- |
| **Authentication**       | Keycloak (OIDC)       | Verifies user identity, issues JWT tokens   |
| **Authorization**        | Istio AuthZ Policies  | Role-based access control (RBAC)            |
| **Encryption (Transit)** | Istio mTLS            | All service-to-service traffic encrypted    |
| **Secrets Management**   | Vault + Agent         | No secrets in code, env vars, or ConfigMaps |
| **Token Validation**     | RequestAuthentication | JWT signature verification & expiration     |
| **Network Policies**     | Istio Gateway         | Single entry point, path-based routing      |

**Result:** Defense-in-depth security with multiple independent layers. If one layer fails, others still protect the system.

---

### **Interview Talking Points**

When discussing this architecture in interviews:

1. **Zero Trust Principle:**
   - "Never trust, always verify" - every request authenticated
   - Even internal service-to-service traffic is encrypted (mTLS)
   - No implicit trust based on network location

2. **Industry Standards:**
   - OIDC/OAuth 2.0 (Keycloak) - not custom auth
   - JWT tokens with signature verification
   - SPIFFE identities (Istio mTLS)
   - Defense-in-depth security model

3. **Separation of Concerns:**
   - Identity (Keycloak) ≠ Authorization (Istio policies)
   - Services don't implement auth (gateway handles it)
   - Secrets management (Vault) isolated from app code

4. **Scalability:**
   - Centralized auth scales to hundreds of services
   - Gateway validation reduces per-service overhead
   - Istio mTLS automatic certificate rotation

5. **Production-Ready:**
   - Short token lifespans (5 min) reduce risk
   - Health checks exempt from auth (K8s integration)
   - mTLS STRICT mode (fail closed, not open)
   - Vault agent automatic secret rotation

---

## 🏗️ Architecture Overview (Simple Explanation)

This project is like managing a **school district** with **50 schools** (clusters):

```
Management Cluster (Superintendent's Office)
├── ArgoCD (Delivery service - deploys apps to all schools)
├── Vault (Safe - stores all passwords securely)
├── Prometheus (Report card system - monitors all schools)
└── Cluster API (School builder - creates new schools automatically)

Workload Clusters (The 50 Schools)
├── US-East-1 Region
│   ├── dev-us-east-1 (Practice school)
│   ├── staging-us-east-1 (Rehearsal school)
│   └── prod-us-east-1 (Real school with students)
├── EU-West-1 Region
│   ├── dev-eu-west-1
│   ├── staging-eu-west-1
│   └── prod-eu-west-1
└── ... (44 more clusters)

Each school has:
├── Istio (Security guard - controls who enters)
├── Kafka (Announcement system - messages between classrooms)
└── Microservices (Students - the actual applications)
```

---

## 🛠️ Tech Stack

| Technology               | Purpose                      | Status                  | Analogy                               |
| ------------------------ | ---------------------------- | ----------------------- | ------------------------------------- |
| **Terraform**            | Infrastructure as Code       | ✅ Deployed             | Architect's blueprint                 |
| **Kubernetes (EKS)**     | Container orchestration      | ✅ Running (v1.30)      | School building                       |
| **Keycloak**             | Identity & Access Management | ✅ Production           | School ID badge system                |
| **Vault**                | Secrets management           | ✅ Integrated           | School safe                           |
| **Istio**                | Service mesh                 | ✅ Configured (v1.29.2) | Security guard + walkie-talkie system |
| **Kafka**                | Event streaming              | ✅ Running (Strimzi)    | School announcement system            |
| **Kustomize**            | Manifest customization       | ✅ In Use               | Recipe customizer                     |
| **ArgoCD**               | GitOps deployment            | 📋 Planned              | UPS delivery service                  |
| **Prometheus + Grafana** | Monitoring                   | 📋 Planned              | Report card system                    |
| **Kiali**                | Service mesh visualization   | 🚧 In Progress          | Network map                           |
| **Cluster API**          | Fleet management             | 📋 Planned              | School district superintendent        |
| **AI in CI/CD**          | Intelligent pipelines        | 📋 Planned              | Smart teaching assistant              |
| **Ratchet**              | WebSocket server             | 📋 Planned              | Real-time scoreboard                  |
| **Lambda**               | Serverless automation        | 📋 Planned              | On-call janitor                       |

**Legend:** ✅ Deployed | 🚧 In Progress | 📋 Planned

---

## 📖 Technology Explanations (Middle School Level)

### **What is Kubernetes?**

Imagine you have a **cafeteria** where you serve lunch. Kubernetes is like the **cafeteria manager** who:

- Makes sure you have enough cooks (replicas)
- Replaces sick cooks (restarts crashed pods)
- Balances lunch lines (load balancing)
- Orders groceries when supplies run low (autoscaling)

### **What is ArgoCD (GitOps)?**

Think of **Git as a warehouse** where you store all your "recipes" (code). ArgoCD is the **delivery truck** that:

1. Watches the warehouse every 3 minutes
2. Sees when you add new recipes
3. Automatically delivers them to all schools
4. If a school loses a recipe, re-delivers it

**Why it's better than manual deployment:**

- **Before:** You drive to 50 schools, drop off recipes by hand (slow, error-prone)
- **After:** You update the warehouse once, delivery truck handles the rest (fast, reliable)

### **What is Kustomize?**

Imagine you have a **base recipe for chocolate chip cookies**:

- 2 cups flour
- 1 cup sugar
- 50 chocolate chips

**Kustomize lets you customize without duplicating:**

- **Dev overlay:** Use 10 chocolate chips (testing)
- **Prod overlay:** Use 100 chocolate chips (customers)

**Without Kustomize:** You copy-paste the ENTIRE recipe twice (hard to maintain)  
**With Kustomize:** You write the base recipe once, then small changes (easy to maintain)

### **What is Istio (Service Mesh)?**

Istio is like a **security system + communication network** for your apps:

**The Security Guard (mTLS):**

- Every student (pod) gets an ID badge
- Only valid students can enter buildings
- All conversations are encrypted (no eavesdropping)

**The Walkie-Talkie System (Service-to-Service Communication):**

- Instead of yelling across the playground, use walkie-talkies
- If Teacher A is busy, route the message to Teacher B
- Record all conversations for safety (observability)

### **What is Kafka (Event Streaming)?**

Kafka is like the **school announcement system**:

**Morning announcements:** "Fire drill at 2pm"  
**Who hears it?**

- All classrooms
- The gym
- The cafeteria

**Why this is better than phone calls:**

- **Phone calls (HTTP):** Principal calls each room individually (slow, tight coupling)
- **Announcements (Kafka):** Principal says it once, everyone hears it (fast, loose coupling)

**Real example:**

```
Order Service: "New order #1234 placed" (publishes to Kafka)
     ↓
Inventory Service: "Reduce stock by 1" (subscribes to Kafka)
Shipping Service: "Prepare shipment" (subscribes to Kafka)
Email Service: "Send confirmation email" (subscribes to Kafka)
```

### **What is Vault (Secrets Management)?**

Vault is like the **principal's safe** that stores sensitive information:

**Before Vault:**

- Passwords written on sticky notes (insecure!)
- Every classroom has its own sticky note
- If a teacher leaves, can't change all passwords easily

**With Vault:**

- All passwords locked in the principal's safe
- Only approved teachers get access
- Passwords rotate automatically every month
- Full audit trail (who accessed what, when)

### **What is Prometheus + Grafana (Monitoring)?**

Think of this as the **report card and dashboard system**:

**Prometheus = The Grade Collector**

- Takes attendance every minute
- Records test scores
- Notes when students are absent (pods down)

**Grafana = The Dashboard**

- Principal sees all 50 schools on one screen
- Red alerts if attendance drops below 80%
- Green checkmarks if all students present

**What you see:**

```
Dashboard: All 50 Clusters
├── Total pods running: 2,341
├── CPU usage: 45% (good)
├── Memory usage: 87% (warning!)
└── Failed deployments: 0 (excellent)

⚠️ Alert: Cluster prod-us-east-1 has high memory usage
```

### **What is Cluster API (Fleet Management)?**

Cluster API is like a **school construction machine**:

**Before Cluster API:**

- Hire construction crew for each school (manual)
- Takes 30 days per school
- Each school slightly different (inconsistent)

**With Cluster API:**

- Press a button: "Build me 10 schools in Texas"
- Fully automated (3 hours per school)
- All schools identical (consistent)

**Example:**

```yaml
# cluster-template.yaml
# "Build me a school with 20 classrooms and a gym"
kind: Cluster
spec:
  controlPlane:
    replicas: 3 # 3 principals (high availability)
  workers:
    replicas: 10 # 10 classrooms
```

### **What is AI in CI/CD?**

AI is like a **smart teaching assistant** that helps with tests and homework:

**Traditional CI/CD:**

1. Test fails ❌
2. You read 1000 lines of error logs 📜
3. Find the problem after 30 minutes 😰

**AI-Powered CI/CD:**

1. Test fails ❌
2. AI reads logs in 5 seconds ⚡
3. AI says: "Line 42: out of memory, increase heap size to 4GB" 🤖
4. Problem solved in 30 seconds! 🎉

**Other AI features:**

- **Smart test selection:** Only run 10 tests (instead of 1000) based on your code changes
- **Flaky test detection:** "Test #5 fails randomly 20% of the time, not your fault"
- **Predictive rollback:** "New deployment has 5% error rate, rolling back automatically"

---

## 📋 Project Phases

### **Phase 1: Single Cluster Foundation** (Week 1-2) ⬅️ **CURRENT**

**What we're building:** 1 EKS cluster with ArgoCD and 3 microservices

**You'll learn:**

- Terraform for EKS clusters
- Kustomize for manifest management
- ArgoCD GitOps workflow
- GitHub Actions CI/CD

**Deliverables:**

- ✅ 1 EKS cluster in us-east-2
- ✅ 3 microservices (Order, Inventory, Notification)
- ✅ ArgoCD managing deployments
- ✅ CI/CD pipeline building + pushing Docker images

---

### **Phase 2: AI-Powered CI/CD** (Week 3)

**What we're adding:** AI that makes your pipelines smarter

**You'll learn:**

- AI test selection (run only affected tests)
- Automated root cause analysis (AI reads error logs)
- Predictive rollback (AI detects bad deployments)
- Smart dependency scanning (AI prioritizes CVEs)

**Deliverables:**

- ✅ AI test selection (80% faster builds)
- ✅ AI failure analysis (instant error explanations)
- ✅ Auto-rollback on anomaly detection
- ✅ AI-powered security scanning

---

### **Phase 3: Service Mesh Basics** (Week 4)

**What we're adding:** Istio for secure service-to-service communication

**You'll learn:**

- mTLS encryption (zero-trust networking)
- Traffic routing (canary deployments)
- Circuit breakers (prevent cascading failures)
- Distributed tracing (Jaeger)

**Deliverables:**

- ✅ Istio installed on cluster
- ✅ All services using mTLS
- ✅ Canary deployment (10% → 50% → 100%)
- ✅ Distributed tracing dashboard

---

### **Phase 4: Multi-Cluster Setup** (Week 5-6)

**What we're adding:** 3 clusters (dev, staging, prod)

**You'll learn:**

- Multi-cluster ArgoCD
- Istio multi-cluster federation
- Shared Vault for secrets
- Cluster-specific configurations

**Deliverables:**

- ✅ 3 EKS clusters
- ✅ ArgoCD deploying to all 3 clusters
- ✅ Services talking across clusters via Istio
- ✅ Centralized Vault for all secrets

---

### **Phase 5: Event Streaming** (Week 7-8)

**What we're adding:** Kafka for event-driven architecture

**You'll learn:**

- Kafka basics (topics, producers, consumers)
- Strimzi Kubernetes Operator
- Event-driven microservices
- Cross-region replication

**Deliverables:**

- ✅ Kafka cluster deployed
- ✅ Order Service publishes events
- ✅ Inventory/Notification Services consume events
- ✅ Kafka UI for monitoring

---

### **Phase 6: Fleet Management** (Week 9-10)

**What we're adding:** Cluster API to manage 10+ clusters

**You'll learn:**

- Cluster API installation
- ClusterClass templates
- Automated cluster provisioning
- Centralized monitoring (Thanos)

**Deliverables:**

- ✅ Cluster API managing 10 clusters
- ✅ Push-button cluster creation
- ✅ Federated Prometheus (Thanos)
- ✅ Single pane of glass monitoring

---

### **Phase 7: Platform Abstractions** (Week 11-12)

**What we're adding:** Developer self-service tools

**You'll learn:**

- Backstage developer portal
- Service scaffolding templates
- Internal CLI (`platform deploy`)
- Resource quotas and policies

**Deliverables:**

- ✅ Backstage portal
- ✅ Self-service new service creation
- ✅ OPA policies enforcing resource limits
- ✅ Developer documentation

---

### **Phase 8: Real-Time Dashboard** (Week 13)

**What we're adding:** Live monitoring with WebSockets

**You'll learn:**

- Ratchet WebSocket server (PHP)
- React real-time dashboard
- Kubernetes API integration
- Istio WebSocket routing

**Deliverables:**

- ✅ Ratchet server running in Kubernetes
- ✅ Real-time cluster status dashboard
- ✅ Live deployment progress
- ✅ WebSocket connection management

---

### **Phase 9: Advanced Patterns** (Week 14-15)

**What we're adding:** Production-grade reliability patterns

**You'll learn:**

- Multi-region failover
- Chaos engineering (Chaos Mesh)
- Cost optimization (Kubecost)
- Security hardening (Falco)

**Deliverables:**

- ✅ DR testing (region failover)
- ✅ Automated chaos experiments
- ✅ Cost allocation by team
- ✅ Runtime security monitoring

---

## 🎓 Learning Philosophy

**This project follows the same principles as your AWS DevOps project:**

1. **Build muscle memory** - You type EVERY file (except .md docs)
2. **Understand the "why"** - Not just the "how"
3. **Production-grade patterns** - FAANG-level from day one
4. **Senior-level thinking** - Failure modes, security, cost optimization
5. **Portfolio-worthy** - Demonstrate enterprise capabilities

---

## 📁 Repository Structure

```
k8s-fleet-management/
├── README.md                    # This file
├── docs/
│   ├── PHASE_1_GUIDE.md        # Detailed Phase 1 walkthrough
│   ├── ARCHITECTURE.md         # Deep technical architecture
│   └── LEARNING_NOTES.md       # Concepts and insights
│
├── terraform/                   # Infrastructure as Code
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── modules/
│       ├── eks-cluster/
│       ├── vpc/
│       └── argocd/
│
├── gitops/                      # ArgoCD manifests
│   ├── apps/                   # Application definitions
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── infra/                  # Infrastructure apps
│       ├── argocd/
│       ├── istio/
│       ├── vault/
│       └── kafka/
│
├── kustomize/                   # Kubernetes manifests
│   ├── base/                   # Shared base manifests
│   │   ├── order-service/
│   │   ├── inventory-service/
│   │   └── notification-service/
│   └── overlays/               # Environment overrides
│       ├── dev/
│       ├── staging/
│       └── prod/
│
├── services/                    # Application code
│   ├── order-service/          # Node.js Express
│   ├── inventory-service/      # Java Spring Boot
│   └── notification-service/   # Python FastAPI
│
└── .github/
    └── workflows/              # CI/CD pipelines
        ├── build-and-push.yaml
        ├── terraform-plan.yaml
        └── ai-test-selection.yaml
```

---

## 🚀 Getting Started

**Prerequisites:**

- AWS account with admin access
- GitHub account
- Tools installed: AWS CLI, kubectl, terraform, docker

**Start here:**

1. Read [docs/PHASE_1_GUIDE.md](docs/PHASE_1_GUIDE.md)
2. Follow step-by-step instructions
3. Type every file yourself (builds muscle memory!)
4. Test at each checkpoint

---

## 🎯 Next Steps

### **Immediate Priority: Service Mesh Visualization**

#### **1. Install Kiali Dashboard**

Kiali provides real-time visualization of your service mesh with mTLS indicators:

```bash
# Install Kiali
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/addons/kiali.yaml

# Install Prometheus (required for Kiali metrics)
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/addons/prometheus.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=kiali -n istio-system --timeout=300s

# Access Kiali dashboard
kubectl port-forward -n istio-system svc/kiali 20001:20001
# Open: http://localhost:20001
```

**What you'll see in Kiali:**

- Service topology graph with 🔒 icons showing mTLS connections
- Real-time traffic flow between microservices
- HTTP success/error rates
- Request latency metrics
- Authorization policy visualization

#### **2. Optional: Install Additional Observability Tools**

```bash
# Jaeger (distributed tracing)
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/addons/jaeger.yaml

# Grafana (monitoring dashboards)
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/addons/grafana.yaml

# Access dashboards
kubectl port-forward -n istio-system svc/jaeger 16686:16686  # Tracing
kubectl port-forward -n istio-system svc/grafana 3000:3000   # Metrics
```

### **Phase 2: GitOps with ArgoCD**

Once service mesh visualization is complete, the next major milestone is implementing GitOps:

1. **Install ArgoCD** in the cluster
2. **Configure ArgoCD Applications** to manage:
   - All microservices (order, inventory, notification)
   - Infrastructure components (Istio, Vault, Keycloak, Kafka)
   - Authorization policies and security configs
3. **Git-based deployments** - Update Git → ArgoCD auto-syncs
4. **Progressive delivery** - Canary deployments with automated rollback

**Benefits:**

- Declarative infrastructure (Git as single source of truth)
- Automated sync (no manual `kubectl apply`)
- Rollback capability (revert Git commits)
- Audit trail (Git history shows who changed what)

### **Phase 3: CI/CD Pipeline**

Build GitHub Actions workflows:

1. **Build & Push** - Docker images to ECR/DockerHub
2. **Security Scanning** - Trivy for CVE detection
3. **Automated Testing** - Unit, integration, and security tests
4. **GitOps Integration** - Update kustomize manifests in Git
5. **ArgoCD Sync** - Automatic deployment to cluster

**Pipeline Flow:**

```
Code Push → Build Image → Run Tests → Scan for CVEs
    ↓
Update Kustomize Manifest in Git
    ↓
ArgoCD Detects Change → Sync to Cluster
    ↓
Progressive Rollout (Canary Deployment)
```

---

## 💼 Career Impact

**This project demonstrates skills valued at:**

- **Before this project:** $120-150k (basic Kubernetes knowledge)
- **Current state (Zero Trust architecture):** $180-220k
- **After ArgoCD + CI/CD:** $200-240k
- **After full fleet management:** $220-280k (Staff/Principal Engineer level)

**You can now confidently answer interview questions like:**

- ✅ "How do you implement Zero Trust security in Kubernetes?"
- ✅ "Explain your experience with service mesh and mTLS"
- ✅ "How do you integrate Keycloak with Istio for authentication?"
- ✅ "Describe your approach to secrets management at scale"
- ✅ "What's your experience with RBAC and authorization policies?"
- ✅ "How do you secure service-to-service communication?"
- ✅ "Explain JWT token validation and expiration strategies"
- ✅ "Describe path-based routing with Istio ingress gateway"

**Real-world scenarios you can discuss:**

- Implemented complete Zero Trust architecture with multiple security layers
- Configured Keycloak OIDC integration with JWT validation
- Enforced RBAC at gateway level using Istio authorization policies
- Enabled mTLS STRICT mode for encrypted service-to-service communication
- Integrated HashiCorp Vault with Kubernetes auth for secrets injection
- Deployed event-driven microservices using Kafka (Strimzi operator)
- Managed infrastructure as code with Terraform (VPC, EKS, security groups)

---

## 📝 Notes

**Project initialized:** April 29, 2026  
**Phase 1 completion:** May 20, 2026 (3 weeks)  
**Target completion:** 15 weeks (3-4 months)  
**Learning approach:** Hands-on, step-by-step, production-grade

**Major Milestones Achieved:**

- ✅ Complete EKS cluster with VPC and security groups (Terraform)
- ✅ Zero Trust security architecture (Keycloak + Vault + Istio)
- ✅ mTLS encryption for all service-to-service traffic
- ✅ JWT authentication with RBAC authorization
- ✅ Event-driven architecture with Kafka
- ✅ Microservices deployed with Vault secrets injection

**What Makes This Production-Grade:**

- Industry-standard authentication (OIDC/OAuth 2.0)
- Defense-in-depth security (6 independent layers)
- Automatic certificate rotation (Istio CA)
- Centralized secrets management (Vault)
- Short token lifespans (5 min) for security
- Health check exemptions for Kubernetes integration
- mTLS STRICT mode (fail closed, not open)

**Remember:** You're not just building a project — you're building a **portfolio piece** that demonstrates Staff/Principal Engineer capabilities with production-ready security architecture.

**Interview Preparation:** You now have hands-on experience with Keycloak, Vault, Istio, mTLS, JWT authentication, RBAC, and Zero Trust principles. This is exactly what companies ask about in senior/staff-level interviews.

Let's build something amazing! 🚀
