# AWS Networking — Real-World Architecture Diagrams & Flow Explanations

> Every diagram here represents how real companies build their AWS infrastructure. Explained from basic concepts to production-grade patterns so anyone — from day-1 fresher to experienced engineer — can follow along.

---

## Table of Contents

1. [Architecture 1 — Basic VPC (Single App, Two Subnets)](#architecture-1--basic-vpc-single-app-two-subnets)
2. [Architecture 2 — Three-Tier Web Application](#architecture-2--three-tier-web-application)
3. [Architecture 3 — Multi-AZ High Availability](#architecture-3--multi-az-high-availability)
4. [Architecture 4 — VPC with NAT Gateway (Private Internet Access)](#architecture-4--vpc-with-nat-gateway-private-internet-access)
5. [Architecture 5 — VPC Peering (Two Apps Talking Privately)](#architecture-5--vpc-peering-two-apps-talking-privately)
6. [Architecture 6 — Transit Gateway (Hub-and-Spoke)](#architecture-6--transit-gateway-hub-and-spoke)
7. [Architecture 7 — Hybrid Cloud (VPN + Direct Connect)](#architecture-7--hybrid-cloud-vpn--direct-connect)
8. [Architecture 8 — VPC Endpoints (Private AWS Access)](#architecture-8--vpc-endpoints-private-aws-access)
9. [Architecture 9 — Multi-Region Disaster Recovery](#architecture-9--multi-region-disaster-recovery)
10. [Architecture 10 — Zero-Trust Microservices (PrivateLink)](#architecture-10--zero-trust-microservices-privatelink)
11. [How to Read CIDR Blocks](#how-to-read-cidr-blocks)
12. [Security Groups vs NACLs — Complete Comparison](#security-groups-vs-nacls--complete-comparison)
13. [Route Tables — How Traffic Finds Its Way](#route-tables--how-traffic-finds-its-way)
14. [Networking Troubleshooting — The 7-Step Checklist](#networking-troubleshooting--the-7-step-checklist)
15. [Cost Awareness — What's Free and What's Not](#cost-awareness--whats-free-and-whats-not)
16. [Quick Reference — All Services at a Glance](#quick-reference--all-services-at-a-glance)

---

## Architecture 1 — Basic VPC (Single App, Two Subnets)

> **What this is:** The simplest real-world setup — a web server that the internet can reach, and a database hidden from the internet.
>
> **Who uses this:** Small startups, personal projects, simple APIs, dev environments.
>
> **Think of it this way:** You built a shop (web server) on a public road so customers can find it. But you keep the cash safe (database) in a locked back room that only the shopkeeper can access. The public never sees the safe.

### The Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16                                                │
│  Region: us-east-1                                               │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  AZ: us-east-1a                                            │  │
│  │                                                            │  │
│  │   ┌──────────────────────────────┐                         │  │
│  │   │  Subnet: 10.0.1.0/24        │                         │  │
│  │   │  (Public: Yes)               │                         │  │
│  │   │                              │                         │  │
│  │   │     EC2 Instance             │                         │  │
│  │   │     (Web Server)             │                         │  │
│  │   │     Public IP: 54.x.x.x     │                         │  │
│  │   │              │               │                         │  │
│  │   └──────────────┼───────────────┘                         │  │
│  │                  │ Port 5432                               │  │
│  │   ┌──────────────▼───────────────┐                         │  │
│  │   │  Subnet: 10.0.10.0/24       │                         │  │
│  │   │  (Public: No)                │                         │  │
│  │   │                              │                         │  │
│  │   │     RDS Postgres Instance    │                         │  │
│  │   │     (No public IP)           │                         │  │
│  │   │                              │                         │  │
│  │   └──────────────────────────────┘                         │  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│          ┌────────────┐     ┌────────────┐                       │
│          │   Router   │────▶│  Internet  │                       │
│          └────────────┘     │  Gateway   │                       │
│                             └─────┬──────┘                       │
└───────────────────────────────────┼──────────────────────────────┘
                                    │
                              ┌─────▼─────┐
                              │ INTERNET  │
                              └───────────┘
```

#### Security Group — `web-sg` (attached to EC2)

**Inbound Rules:**

| Source | Protocol | Port |
|--------|----------|------|
| 0.0.0.0/0 | TCP | 80 (HTTP) |
| 0.0.0.0/0 | TCP | 443 (HTTPS) |
| Your IP only | TCP | 22 (SSH) |

**Outbound Rules:**

| Destination | Protocol | Port |
|-------------|----------|------|
| 0.0.0.0/0 | ALL | ALL |

#### Security Group — `db-sg` (attached to RDS)

**Inbound Rules:**

| Source | Protocol | Port |
|--------|----------|------|
| web-sg (SG reference) | TCP | 5432 (PostgreSQL) |

**Outbound Rules:**

| Destination | Protocol | Port |
|-------------|----------|------|
| — | — | — (none needed) |

#### Custom Route Table (Public Subnet)

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | igw-xxxxx (Internet Gateway) |

#### Main Route Table (Private Subnet)

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| *(No internet route — completely isolated)* | — |

### How Traffic Flows (Step by Step)

**When a user visits your website (`http://54.x.x.x`):**

```
Step 1:  User's browser → Internet → Internet Gateway (IGW)
         "A customer walks up to the shop's front door."

Step 2:  IGW checks → Is there a route? → Route table says 10.0.0.0/16 is local
         "The doorman checks if the shop is open."

Step 3:  Traffic hits Security Group (web-sg) → Port 80 allowed? → YES +
         "The security guard checks: 'Are customers allowed in?' Yes."

Step 4:  Traffic reaches EC2 instance → Nginx serves the web page
         "The shopkeeper hands the customer their order."

Step 5:  EC2 needs data → Connects to RDS on port 5432 (within the VPC)
         "The shopkeeper walks to the back room to get the item."

Step 6:  Traffic hits db-sg → Is source web-sg? → YES + → Port 5432 allowed? → YES +
         "The back room guard checks: 'Are you the shopkeeper?' Yes. Door opens."

Step 7:  RDS returns data → EC2 sends response → IGW → Internet → User
         "The customer gets their order and leaves happy."
```

> **Why is the database in a PRIVATE subnet?**
> Because there is NO route to the internet (`0.0.0.0/0 → igw`) in its route table. Even if a hacker somehow knows the database IP, they literally cannot reach it. There is no road. This is your first line of defense.

### Key Takeaways

| Component | What It Does | Why It Matters |
|-----------|-------------|----------------|
| VPC (`10.0.0.0/16`) | Your private network — 65,536 IP addresses | Isolation from all other AWS customers |
| Public Subnet | Has a route to IGW | EC2 can receive traffic from the internet |
| Private Subnet | NO route to IGW | Database is completely hidden from internet |
| Internet Gateway | Door between VPC and internet | Without it, nothing can talk to the internet |
| Security Group (web-sg) | Firewall around EC2 | Only allows HTTP/HTTPS/SSH — blocks everything else |
| Security Group (db-sg) | Firewall around RDS | Only accepts connections FROM the web server's SG |
| Route Table | "GPS navigation" for packets | Tells traffic where to go — internet or stay local |

---

## Architecture 2 — Three-Tier Web Application

> **What this is:** The standard enterprise web application architecture — separate tiers for web, application logic, and database.
>
> **Who uses this:** E-commerce sites, SaaS platforms, banking applications, any business-critical app.
>
> **Think of it this way:** A restaurant has three areas:
> 1. **Dining room** (Web Tier) — where customers sit and order. Public-facing.
> 2. **Kitchen** (App Tier) — where the food is made. Customers can't enter.
> 3. **Cold storage / Pantry** (Data Tier) — where ingredients are stored. Only chefs access it.
>
> Each area has different security. You wouldn't let a customer walk into the kitchen.

### The Diagram

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16                                                                │
│  Region: us-east-1                                                               │
│                                                                                  │
│                              ┌─────────────┐                                     │
│                              │   USERS     │                                     │
│                              │ (Internet)  │                                     │
│                              └──────┬──────┘                                     │
│                              ┌──────▼──────┐                                     │
│                              │  CloudFront │  CDN (caches static content)         │
│                              └──────┬──────┘                                     │
│                              ┌──────▼──────┐                                     │
│                              │     ALB     │  Application Load Balancer           │
│                              │  (Public)   │  Distributes across servers          │
│                              └──┬───────┬──┘                                     │
│                                 │       │                                        │
│         ┌───────────────────────┘       └───────────────────────┐                │
│         │                                                      │                │
│  ┌──────▼──────────────────────────┐  ┌────────────────────────▼───────────┐     │
│  │  AZ: us-east-1a                 │  │  AZ: us-east-1b                   │     │
│  │                                 │  │                                   │     │
│  │  ┌───────────────────────────┐  │  │  ┌───────────────────────────┐   │     │
│  │  │ Subnet: 10.0.1.0/24      │  │  │  │ Subnet: 10.0.2.0/24      │   │     │
│  │  │ (Public: Yes)             │  │  │  │ (Public: Yes)             │   │     │
│  │  │   NAT Gateway (standby)  │  │  │  │   NAT Gateway (active)   │   │     │
│  │  └───────────────────────────┘  │  │  └───────────────────────────┘   │     │
│  │                                 │  │                                   │     │
│  │  ┌───────────────────────────┐  │  │  ┌───────────────────────────┐   │     │
│  │  │ Subnet: 10.0.10.0/24     │  │  │  │ Subnet: 10.0.20.0/24     │   │     │
│  │  │ (Public: No) — WEB TIER  │  │  │  │ (Public: No) — WEB TIER  │   │     │
│  │  │      EC2: Nginx          │  │  │  │      EC2: Nginx          │   │     │
│  │  │      (Reverse Proxy)     │  │  │  │      (Reverse Proxy)     │   │     │
│  │  └─────────────┬─────────────┘  │  │  └─────────────┬─────────────┘   │     │
│  │                │                │  │                │                 │     │
│  │  ┌─────────────▼─────────────┐  │  │  ┌─────────────▼─────────────┐   │     │
│  │  │ Subnet: 10.0.30.0/24     │  │  │  │ Subnet: 10.0.40.0/24     │   │     │
│  │  │ (Public: No) — APP TIER  │  │  │  │ (Public: No) — APP TIER  │   │     │
│  │  │      EC2: Node.js /      │  │  │  │      EC2: Node.js /      │   │     │
│  │  │      Python / Java       │  │  │  │      Python / Java       │   │     │
│  │  │      (API Backend)       │  │  │  │      (API Backend)       │   │     │
│  │  └─────────────┬─────────────┘  │  │  └─────────────┬─────────────┘   │     │
│  │                │                │  │                │                 │     │
│  │  ┌─────────────▼─────────────┐  │  │  ┌─────────────▼─────────────┐   │     │
│  │  │ Subnet: 10.0.100.0/24    │  │  │  │ Subnet: 10.0.200.0/24    │   │     │
│  │  │ (Public: No) — DATA TIER │  │  │  │ (Public: No) — DATA TIER │   │     │
│  │  │      RDS Primary (Write) │──┼──┼──│      RDS Standby (Read)  │   │     │
│  │  │      ElastiCache Primary │──┼──┼──│      ElastiCache Replica │   │     │
│  │  └───────────────────────────┘  │  │  └───────────────────────────┘   │     │
│  │                                 │  │                                   │     │
│  └─────────────────────────────────┘  └───────────────────────────────────┘     │
│                                                                                  │
│         ┌────────────┐     ┌──────────────┐                                      │
│         │   Router   │────▶│ Internet GW  │                                      │
│         └────────────┘     └──────┬───────┘                                      │
└────────────────────────────────────┼─────────────────────────────────────────────┘
                                     │
                               ┌─────▼─────┐
                               │ INTERNET  │
                               └───────────┘
```

#### Security Group — `alb-sg` (attached to ALB)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| 0.0.0.0/0 | TCP | 80 (HTTP) |
| 0.0.0.0/0 | TCP | 443 (HTTPS) |

**Outbound:**

| Destination | Protocol | Port |
|-------------|----------|------|
| web-sg | TCP | 80 |

#### Security Group — `web-sg` (attached to Nginx EC2s)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| alb-sg (SG reference) | TCP | 80 |
| alb-sg (SG reference) | TCP | 443 |

**Outbound:**

| Destination | Protocol | Port |
|-------------|----------|------|
| app-sg | TCP | 8080 |

#### Security Group — `app-sg` (attached to API EC2s)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| web-sg (SG reference) | TCP | 8080 |

**Outbound:**

| Destination | Protocol | Port |
|-------------|----------|------|
| db-sg | TCP | 5432 |
| cache-sg | TCP | 6379 |

#### Security Group — `db-sg` (attached to RDS)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| app-sg (SG reference) | TCP | 5432 (PostgreSQL) |

#### Security Group — `cache-sg` (attached to ElastiCache)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| app-sg (SG reference) | TCP | 6379 (Redis) |

#### Route Table — Public Subnets (10.0.1.0/24, 10.0.2.0/24)

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | igw-xxxxx (Internet Gateway) |

#### Route Table — Private Subnets (all tier subnets)

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | nat-gw-xxxxx (NAT Gateway) |

### How Traffic Flows

```
User → CloudFront (cache check)
     → ALB (distributes to healthy server)
     → Nginx in Web Tier (handles SSL, static files, rate limiting)
     → Node.js in App Tier (business logic, API processing)
     → Redis in Data Tier (fast cache lookup — "is this data already cached?")
     → RDS PostgreSQL (if not cached, query the database)
     → Response travels back the same path in reverse
```

> **Why THREE tiers instead of putting everything in one?**
>
> | Approach | Problem |
> |----------|---------|
> | All in one EC2 | One server crash = entire app down. Can't scale web and API separately. |
> | Two tiers (web + DB) | Better, but web and API scale together even if only API is overloaded. |
> | Three tiers | Web, API, and DB scale independently. Security at each layer. Industry standard. |

### Security Group Chain (Defense in Depth)

```
alb-sg          → Allows 80/443 from 0.0.0.0/0
     │
     ▼
web-sg          → Allows 80/443 from alb-sg ONLY
     │
     ▼
app-sg          → Allows 8080 from web-sg ONLY
     │
     ▼
db-sg           → Allows 5432 from app-sg ONLY
cache-sg        → Allows 6379 from app-sg ONLY

X A hacker who compromises the ALB cannot directly reach the database —
   they must breach EACH layer one by one.
```

> **This is called "Defense in Depth"** — multiple layers of security. Even if one layer is breached, the attacker still can't reach the database directly.

---

## Architecture 3 — Multi-AZ High Availability

> **What this is:** The same application deployed across multiple Availability Zones (data centers) so it survives hardware failures.
>
> **Who uses this:** Any production system that can't afford downtime — banks, healthcare, e-commerce.
>
> **Think of it this way:** You don't keep all your backup generators in one building. If that building floods, everything goes dark. You put generators in two separate buildings in different parts of the city. If one floods, the other keeps the lights on. That's Multi-AZ.

### The Diagram

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16                                                                │
│  Region: us-east-1                                                               │
│                                                                                  │
│                         ┌───────────────────┐                                    │
│                         │   Route 53 (DNS)  │                                    │
│                         │  app.example.com  │                                    │
│                         └────────┬──────────┘                                    │
│                         ┌────────▼──────────┐                                    │
│                         │      ALB          │                                    │
│                         │  (spans both AZs) │                                    │
│                         └───┬───────────┬───┘                                    │
│                             │           │                                        │
│    ┌────────────────────────┘           └────────────────────────┐                │
│    │                                                            │                │
│  ┌─▼──────────────────────────────────┐  ┌──────────────────────▼─────────────┐   │
│  │  AZ: us-east-1a                    │  │  AZ: us-east-1b                    │   │
│  │                                    │  │                                    │   │
│  │  ┌──────────────────────────────┐  │  │  ┌──────────────────────────────┐  │   │
│  │  │ Subnet: 10.0.10.0/24        │  │  │  │ Subnet: 10.0.20.0/24        │  │   │
│  │  │ (Public: No)                 │  │  │  │ (Public: No)                 │  │   │
│  │  │                              │  │  │  │                              │  │   │
│  │  │     EC2: App Server #1      │  │  │  │     EC2: App Server #2      │  │   │
│  │  │     (Running) +             │  │  │  │     (Running) +             │  │   │
│  │  └──────────────┬───────────────┘  │  │  └──────────────┬───────────────┘  │   │
│  │                 │                  │  │                 │                  │   │
│  │  ┌──────────────▼───────────────┐  │  │  ┌──────────────▼───────────────┐  │   │
│  │  │ Subnet: 10.0.100.0/24       │  │  │  │ Subnet: 10.0.200.0/24       │  │   │
│  │  │ (Public: No)                 │  │  │  │ (Public: No)                 │  │   │
│  │  │                              │  │  │  │                              │  │   │
│  │  │     RDS: PRIMARY        +  │══╪══╪══│     RDS: STANDBY        ~   │  │   │
│  │  │     (Writes + Reads)         │sync│  │     (Auto-failover)          │  │   │
│  │  │                              │  │  │  │                              │  │   │
│  │  │     ElastiCache: Primary    │══╪══╪══│     ElastiCache: Replica    │  │   │
│  │  │                              │sync│  │                              │  │   │
│  │  └──────────────────────────────┘  │  │  └──────────────────────────────┘  │   │
│  │                                    │  │                                    │   │
│  └────────────────────────────────────┘  └────────────────────────────────────┘   │
│                                                                                  │
│         ┌────────────┐     ┌──────────────┐                                      │
│         │   Router   │────▶│ Internet GW  │                                      │
│         └────────────┘     └──────┬───────┘                                      │
└───────────────────────────────────┼──────────────────────────────────────────────┘
                                    │
                              ┌─────▼─────┐
                              │ INTERNET  │
                              └───────────┘
```

#### Security Group — `alb-sg` (attached to ALB)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| 0.0.0.0/0 | TCP | 80 (HTTP) |
| 0.0.0.0/0 | TCP | 443 (HTTPS) |

**Outbound:**

| Destination | Protocol | Port |
|-------------|----------|------|
| app-sg | TCP | 8080 |

#### Security Group — `app-sg` (attached to EC2 App Servers)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| alb-sg (SG reference) | TCP | 8080 |

**Outbound:**

| Destination | Protocol | Port |
|-------------|----------|------|
| db-sg | TCP | 5432 |
| cache-sg | TCP | 6379 |

#### Security Group — `db-sg` (attached to RDS)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| app-sg (SG reference) | TCP | 5432 (PostgreSQL) |

#### Route Table — Private Subnets

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | nat-gw-xxxxx (NAT Gateway) |

### What Happens When AZ-a Goes Down?

```
BEFORE FAILURE:
  ALB → sends 50% traffic to AZ-a, 50% to AZ-b
  RDS Primary in AZ-a, Standby in AZ-b

** AZ-a DATA CENTER GOES DOWN! (power outage, earthquake, etc.)

WITHIN 30 SECONDS:
  1. ALB health check detects AZ-a servers are unreachable
  2. ALB stops sending traffic to AZ-a → ALL traffic goes to AZ-b +
  3. RDS detects primary is down → promotes standby to PRIMARY (60-120 seconds)
  4. ElastiCache replica becomes primary

AFTER FAILOVER:
  ALB → sends 100% traffic to AZ-b
  RDS Primary now in AZ-b (automatic!)
  Users notice: maybe 1-2 minutes of slow responses. No data loss.

WHEN AZ-a RECOVERS:
  New standby instances are created in AZ-a
  ALB re-balances traffic across both AZs
```

> **How is this different from single-AZ?**
>
> | Setup | AZ-a goes down | Downtime |
> |-------|---------------|----------|
> | Single AZ | Everything is down. Manual recovery. | Hours to days |
> | Multi-AZ | Automatic failover. ALB + RDS handle it. | 1-2 minutes |
> | Multi-Region | Even if entire region goes down, DR region takes over. | 5-15 minutes |

---

## Architecture 4 — VPC with NAT Gateway (Private Internet Access)

> **What this is:** Private servers that need to download updates or call external APIs — but should NEVER be directly reachable from the internet.
>
> **Think of it this way:** Your private servers are like inmates in a secure facility. They can make outgoing phone calls (download packages, call APIs), but nobody from outside can call IN. The NAT Gateway is the facility's one-way phone system.
>
> **When you need this:**
> - EC2 instances running `yum update` or `apt-get upgrade`
> - Lambda functions calling external APIs
> - Private services pulling Docker images from Docker Hub
> - Applications sending emails via external SMTP servers

### The Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16                                                            │
│  Region: us-east-1                                                           │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐   │
│  │  AZ: us-east-1a                                                        │   │
│  │                                                                        │   │
│  │  ┌──────────────────────────────────────────────────────────────────┐   │   │
│  │  │  Subnet: 10.0.1.0/24  (Public: Yes)                              │   │   │
│  │  │                                                                  │   │   │
│  │  │     NAT Gateway              Bastion Host (Jump Box)           │   │   │
│  │  │     Has Elastic IP            For SSH access to private EC2s    │   │   │
│  │  │     (public)                                                    │   │   │
│  │  └──────────────┬───────────────────────────────────────────────────┘   │   │
│  │                 │                                                      │   │   │
│  │  ┌──────────────▼───────────────────────────────────────────────────┐   │   │
│  │  │  Subnet: 10.0.10.0/24  (Public: No)                              │   │   │
│  │  │                                                                  │   │   │
│  │  │     EC2: App Server             EC2: Worker                    │   │   │
│  │  │     Needs to:                     Needs to:                     │   │   │
│  │  │     - apt update                  - Call APIs                   │   │   │
│  │  │     - pip install                 - Send email                  │   │   │
│  │  │                                                                  │   │   │
│  │  └──────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                        │   │
│  └────────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│         ┌────────────┐     ┌──────────────┐                                  │
│         │   Router   │────▶│ Internet GW  │                                  │
│         └────────────┘     └──────┬───────┘                                  │
└───────────────────────────────────┼──────────────────────────────────────────┘
                                    │
                              ┌─────▼─────┐
                              │ INTERNET  │
                              └───────────┘
```

#### Security Group — `bastion-sg` (attached to Bastion Host)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| Your IP only | TCP | 22 (SSH) |

**Outbound:**

| Destination | Protocol | Port |
|-------------|----------|------|
| 10.0.10.0/24 | TCP | 22 (SSH to private instances) |

#### Security Group — `app-sg` (attached to private EC2s)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| bastion-sg (SG reference) | TCP | 22 (SSH) |

**Outbound:**

| Destination | Protocol | Port |
|-------------|----------|------|
| 0.0.0.0/0 | ALL | ALL (via NAT GW — outbound only) |

#### Route Table — Public Subnet (10.0.1.0/24)

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | igw-xxxxx (Internet Gateway) |

#### Route Table — Private Subnet (10.0.10.0/24)

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | nat-gw-xxxxx (NAT Gateway) — **Outbound ONLY** |

### How NAT Gateway Works (The Flow)

```
OUTBOUND (Private EC2 → Internet):
  EC2 (10.0.10.5) wants to download from pypi.org
  ┌──────────┐                     ┌─────────────┐           ┌──────────┐
  │  EC2     │  src: 10.0.10.5    │  NAT GW     │  src: EIP │ Internet │
  │ (Private)│ ──────────────────▶│             │ ─────────▶│ (pypi)   │
  │          │  dst: pypi.org     │ Translates  │  dst: pypi│          │
  └──────────┘                     │ private IP  │           └──────────┘
                                   │ to public   │
  The internet sees the NAT GW's   │ Elastic IP  │
  Elastic IP, NOT the EC2's        └─────────────┘
  private IP.

INBOUND (Internet → Private EC2):
  X BLOCKED! The internet cannot initiate a connection to 10.0.10.5.
  The NAT Gateway only allows responses to connections that the EC2 started.
  
  Think of it like a one-way mirror in a detective show:
  The detective (EC2) can see through the mirror (internet).
  But the suspect (internet) only sees their own reflection — they can't see in.
```

> **NAT Gateway vs NAT Instance:**
>
> | Feature | NAT Gateway (Recommended) | NAT Instance (Old way) |
> |---------|--------------------------|----------------------|
> | Managed | AWS manages it (no patching) | You manage it (patching, monitoring) |
> | Availability | Highly available in AZ | Single point of failure |
> | Bandwidth | Up to 100 Gbps | Depends on instance type |
> | Cost | ~$0.045/hr + data processing | EC2 instance cost |
> | Use when | Always (default choice) | Need custom NAT rules or very low budget |

---

## Architecture 5 — VPC Peering (Two Apps Talking Privately)

> **What this is:** Two separate VPCs communicating directly without going through the public internet.
>
> **When you use this:**
> - Team A's app needs to call Team B's API
> - Development VPC needs to access a shared database in another VPC
> - One AWS account's services need to talk to another account's services
>
> **Think of it this way:** Two neighboring houses build a private tunnel between their basements. They can visit each other without going outside. But the tunnel is NOT transitive — if House A has a tunnel to House B, and House B has a tunnel to House C, House A can NOT use House B's tunnel to reach House C.

### The Diagram

```
┌────────────────────────────────────┐         ┌────────────────────────────────────┐
│ VPC-A (Account: Team Frontend)     │         │ VPC-B (Account: Team Backend)      │
│ CIDR: 10.0.0.0/16                  │         │ CIDR: 10.1.0.0/16                  │
│                                    │         │                                    │
│  ┌──────────────────────────────┐  │         │  ┌──────────────────────────────┐  │
│  │  Private Subnet: 10.0.1.0/24│  │         │  │  Private Subnet: 10.1.1.0/24│  │
│  │                              │  │         │  │                              │  │
│  │  ┌──────────────────────┐    │  │  VPC    │  │  ┌──────────────────────┐    │  │
│  │  │  EC2: React Frontend │    │  │ Peering │  │  │  EC2: API Backend    │    │  │
│  │  │                      │────┼──┼────◄►───┼──┼──│                      │    │  │
│  │  │  Calls API at        │    │  │  pcx-   │  │  │  Listens on :8080   │    │  │
│  │  │  10.1.1.50:8080      │    │  │  xxxxx  │  │  │  IP: 10.1.1.50     │    │  │
│  │  └──────────────────────┘    │  │         │  │  └──────────────────────┘    │  │
│  │                              │  │         │  │                              │  │
│  └──────────────────────────────┘  │         │  └──────────────────────────────┘  │
│                                    │         │                                    │
└────────────────────────────────────┘         └────────────────────────────────────┘
```

#### Route Table — VPC-A (Team Frontend)

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| 10.1.0.0/16 | pcx-xxxxx (Peering to VPC-B) |

> *"To reach VPC-B, use the peering tunnel"*

#### Route Table — VPC-B (Team Backend)

| Destination | Target |
|-------------|--------|
| 10.1.0.0/16 | local |
| 10.0.0.0/16 | pcx-xxxxx (Peering to VPC-A) |

> *"To reach VPC-A, use the peering tunnel"*

#### Security Group — `api-sg` (in VPC-B, attached to API Backend)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| 10.0.0.0/16 (VPC-A CIDR) | TCP | 8080 |

**Outbound:**

| Destination | Protocol | Port |
|-------------|----------|------|
| 0.0.0.0/0 | ALL | ALL |

### VPC Peering — Critical Rules

```
!!  RULE 1: CIDRs MUST NOT OVERLAP
    VPC-A: 10.0.0.0/16  + VPC-B: 10.0.0.0/16  = X CONFLICT (same range!)
    VPC-A: 10.0.0.0/16  + VPC-B: 10.1.0.0/16  = + No overlap

!!  RULE 2: NOT TRANSITIVE
    VPC-A ←→ VPC-B (peered)
    VPC-B ←→ VPC-C (peered)
    VPC-A ←→ VPC-C = X NOT connected (need separate peering or Transit Gateway)

!!  RULE 3: Both sides must ACCEPT
    Account A creates peering request → Account B must accept → Both update route tables

!!  RULE 4: Route tables in BOTH VPCs must be updated
    Peering connection alone is not enough — you must tell each VPC how to route to the other.
```

### When to Use VPC Peering vs Transit Gateway

```
2-3 VPCs talking to each other?     → VPC Peering (simpler, cheaper)
5+ VPCs or complex routing?          → Transit Gateway (hub-and-spoke)
Cross-region with many VPCs?          → Transit Gateway with cross-region peering

Peering connections needed:
  3 VPCs = 3 peering connections   (A↔B, A↔C, B↔C)
  5 VPCs = 10 peering connections  (becomes unmanageable)
  10 VPCs = 45 peering connections (nightmare!)
  Transit Gateway: 10 VPCs = 10 attachments (one per VPC to the hub)
```

---

## Architecture 6 — Transit Gateway (Hub-and-Spoke)

> **What this is:** A central hub that connects ALL your VPCs, VPN connections, and Direct Connect — like a main train station where all lines meet.
>
> **Who uses this:** Any company with 4+ VPCs, multi-account setups, or hybrid cloud.
>
> **Think of it this way:** Without Transit Gateway, connecting 5 airports (VPCs) requires 10 direct flights (peering connections). With Transit Gateway, you build ONE central hub airport — every airport just needs ONE connection to the hub. The hub handles all routing.

### The Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          TRANSIT GATEWAY (Central Hub)                         │
└──────────────────┬─────────────────────┬───────────────────┬────────────────┘
                   │                     │                   │
     ┌─────────────▼─────────┐  ┌─────▼─────────────┐  ┌───▼───────────────┐
     │ VPC: PRODUCTION       │  │ VPC: DEVELOPMENT  │  │ VPC: SHARED         │
     │ 10.0.0.0/16           │  │ 10.1.0.0/16       │  │ SERVICES            │
     │                       │  │                   │  │ 10.2.0.0/16         │
     │     Web Servers        │  │     Dev Servers   │  │                     │
     │     API Servers        │  │     Test DBs      │  │     NAT Gateway     │
     │     Prod RDS           │  │     CI/CD Runners │  │     Bastion Host    │
     │                       │  │                   │  │     VPN Endpoint    │
     │     Prod → Shared only │  │  X Dev CANNOT    │  │     DNS Resolver    │
     │                       │  │    reach Prod!   │  │     Monitoring      │
     └───────────────────────┘  └───────────────────┘  └─────────────┬───────┘
                                                                │
                                                      ┌────────▼────────┐
                                                      │  ON-PREMISE       │
                                                      │  Data Center      │
                                                      │  172.16.0.0/12    │
                                                      │                   │
                                                      │  Connected via:   │
                                                      │  Site-to-Site VPN │
                                                      │  or Direct Connect│
                                                      └───────────────────┘
```

#### Transit Gateway Route Table — `Prod-RT`

| Destination | Target | Note |
|-------------|--------|------|
| 10.0.0.0/16 | VPC-Prod attachment | Local production traffic |
| 10.2.0.0/16 | VPC-Shared attachment | Access shared services |
| 0.0.0.0/0 | VPC-Shared attachment | Internet via centralized NAT |
| *(No route to 10.1.0.0/16)* | — | **Dev is completely isolated from Prod** |

#### Transit Gateway Route Table — `Dev-RT`

| Destination | Target | Note |
|-------------|--------|------|
| 10.1.0.0/16 | VPC-Dev attachment | Local dev traffic |
| 10.2.0.0/16 | VPC-Shared attachment | Access shared services |
| *(No route to 10.0.0.0/16)* | — | **Dev CANNOT reach Prod!** |

#### Transit Gateway Route Table — `Shared-RT`

| Destination | Target | Note |
|-------------|--------|------|
| 10.0.0.0/16 | VPC-Prod attachment | Route to Prod VPC |
| 10.1.0.0/16 | VPC-Dev attachment | Route to Dev VPC |
| 10.2.0.0/16 | VPC-Shared attachment | Local shared traffic |
| 0.0.0.0/0 | Internet Gateway | Internet egress |

### Why This Architecture Matters

```
KEY INSIGHT: Transit Gateway route tables let you ISOLATE environments!

Without isolation:
  Dev → TGW → Prod  ← A developer's bug or test script could hit production DB!

With TGW route table isolation:
  Dev → TGW → Dev-RT → X No route to Prod CIDR → Packet dropped!
  Dev → TGW → Dev-RT → + Route to Shared Services → Can reach NAT/Bastion

This is how enterprises prevent dev/test from accidentally impacting production.
```

### Centralized Egress (Saving Money)

```
WITHOUT centralized egress:
  VPC-Prod → NAT GW ($45/month)  → Internet
  VPC-Dev  → NAT GW ($45/month)  → Internet
  VPC-QA   → NAT GW ($45/month)  → Internet
  Total: $135/month for 3 NAT Gateways

WITH centralized egress through Shared VPC:
  VPC-Prod → TGW → VPC-Shared → NAT GW ($45/month) → Internet
  VPC-Dev  → TGW → VPC-Shared → NAT GW ($45/month) → Internet
  VPC-QA   → TGW → VPC-Shared → ↗ (same NAT GW)
  Total: $45/month for 1 NAT Gateway (saves $90/month!)

  At enterprise scale with 20 VPCs: saves $855/month = $10,260/year!
```

---

## Architecture 7 — Hybrid Cloud (VPN + Direct Connect)

> **What this is:** Connecting your AWS cloud to your physical office or data center — creating one unified network.
>
> **Who uses this:** Banks (can't move everything to cloud overnight), hospitals (some systems must stay on-prem), any company migrating to AWS gradually.
>
> **Think of it this way:** Your company has an old office building (on-premise data center) and you're building a new one (AWS). During construction, you need a bridge between both buildings so people can go back and forth. The VPN is a temporary wooden bridge. Direct Connect is a permanent steel bridge.

### The Diagram

```
┌──────────────────────────────────────┐          ┌──────────────────────────────┐
│      ON-PREMISE DATA CENTER          │          │       AWS CLOUD              │
│      (Your physical servers)         │          │                              │
│                                      │          │   ┌──────────────────────┐   │
│  ┌──────────────────────────────┐    │          │   │  VPC: 10.0.0.0/16   │   │
│  │  Internal Apps               │    │          │   │                      │   │
│  │  - Active Directory (AD)     │    │          │   │  ┌────────────────┐  │   │
│  │  - Legacy ERP System         │    │          │   │  │ EC2 Instances  │  │   │
│  │  - File Servers              │    │          │   │  │ RDS Databases  │  │   │
│  │  - Internal Wikis            │    │          │   │  │ Lambda         │  │   │
│  └──────────────────────────────┘    │          │   │  └────────────────┘  │   │
│                                      │          │   │                      │   │
│  Network: 172.16.0.0/12             │          │   │ Virtual Private GW   │   │
│                                      │          │   └──────────┬───────────┘   │
│  ┌──────────────────────────────┐    │          │              │               │
│  │  Customer Gateway Device     │    │          └──────────────┼───────────────┘
│  │  (Your router/firewall)      │    │                         │
│  │  IP: 203.0.113.50           │    │                         │
│  └──────────┬───────────────────┘    │                         │
│             │                        │                         │
└─────────────┼────────────────────────┘                         │
              │                                                  │
              │         ┌────────────────────────────┐           │
              │         │    CONNECTION OPTIONS:      │           │
              │         │                            │           │
              ├─────────│  OPTION A: Site-to-Site VPN │───────────┤
              │         │  - Over public Internet    │           │
              │         │  - Encrypted (IPSec)       │           │
              │         │  - ~1 Gbps max             │           │
              │         │  - Setup: Hours             │           │
              │         │  - Cost: ~$0.05/hr          │           │
              │         │  - Redundancy: 2 tunnels   │           │
              │         │                            │           │
              ├─────────│  OPTION B: Direct Connect   │───────────┤
              │         │  - Dedicated fiber cable    │           │
              │         │  - NOT over Internet        │           │
              │         │  - 1/10/100 Gbps            │           │
              │         │  - Setup: Weeks to months   │           │
              │         │  - Cost: $0.30/hr + data   │           │
              │         │  - Lowest latency           │           │
              │         │                            │           │
              └─────────│  OPTION C: Both! (Best)     │───────────┘
                        │  - Direct Connect (primary) │
                        │  - VPN (backup/failover)    │
                        └────────────────────────────┘
```

### Decision Guide — VPN vs Direct Connect

```
                       ┌─────────────────────────────────┐
                       │  How much bandwidth do you need? │
                       └───────────┬─────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
              Less than 1 Gbps              More than 1 Gbps
                    │                             │
              ┌─────▼────────┐             ┌──────▼──────────┐
              │ Latency      │             │   Direct Connect │
              │ sensitive?   │             │   (1-100 Gbps)   │
              └──┬────────┬──┘             │                  │
                 │        │                │ Add VPN as backup │
          No     │        │ Yes            └──────────────────┘
           ┌─────▼──┐  ┌──▼─────────┐
           │  VPN   │  │  Direct    │
           │(cheapest)│  │  Connect  │
           └────────┘  └────────────┘
```

| Feature | VPN | Direct Connect | Both (Recommended) |
|---------|-----|----------------|-------------------|
| **Speed** | ~1.25 Gbps max | 1 / 10 / 100 Gbps | Full speed + failover |
| **Latency** | Variable (internet-dependent) | Consistent, low latency | Best of both |
| **Security** | Encrypted (IPSec) | Private (not over internet) but unencrypted by default | Encrypted + Private |
| **Setup time** | Minutes to hours | Weeks to months | Months |
| **Cost** | $ (cheap) | $$$ (expensive) | $$$$ |
| **Availability** | 2 tunnels | Need 2 connections for redundancy | Highest availability |
| **Best for** | Dev, backup, low traffic | Production, data migration, real-time apps | Enterprise production |

#### Route Table — AWS VPC (for Hybrid Connectivity)

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| 172.16.0.0/12 | vgw-xxxxx (Virtual Private Gateway) |
| 0.0.0.0/0 | igw-xxxxx (Internet Gateway) |

> *Traffic to 172.16.x.x (on-premise) goes through the VPN tunnel / Direct Connect, while internet traffic goes through the IGW.*

#### Security Group — `hybrid-app-sg` (EC2 in AWS VPC)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| 172.16.0.0/12 (on-premise CIDR) | TCP | 443 (HTTPS) |
| 172.16.0.0/12 (on-premise CIDR) | TCP | 8080 (API) |
| 10.0.0.0/16 (VPC local) | TCP | ALL |

**Outbound:**

| Destination | Protocol | Port |
|-------------|----------|------|
| 172.16.0.0/12 (on-premise) | TCP | 1433 (SQL Server) |
| 172.16.0.0/12 (on-premise) | TCP | 389 (LDAP / Active Directory) |
| 0.0.0.0/0 | ALL | ALL |

---

## Architecture 8 — VPC Endpoints (Private AWS Access)

> **What this is:** Accessing AWS services (S3, DynamoDB, SQS, etc.) WITHOUT going through the public internet — the traffic stays entirely within AWS's private network.
>
> **Think of it this way:** You work in a 50-floor office building (AWS). Your office is on floor 10 (your VPC). S3 is on floor 40. Instead of leaving the building, walking around the block, and entering through the main lobby to reach floor 40 — you take the private elevator. Faster, safer, cheaper.
>
> **Why this matters:**
> - Without endpoint: EC2 → NAT Gateway ($$$) → Internet → S3
> - With endpoint: EC2 → VPC Endpoint → S3 (no internet, no NAT needed!)

### The Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        VPC: 10.0.0.0/16                                 │
│                                                                         │
│  ┌─────────────────────────────────────────────────┐                    │
│  │  PRIVATE SUBNET: 10.0.10.0/24                   │                    │
│  │                                                 │                    │
│  │  ┌──────────────┐   ┌──────────────┐            │                    │
│  │  │  EC2: App    │   │  Lambda      │            │                    │
│  │  │  Server      │   │  Functions   │            │                    │
│  │  └──────┬───────┘   └──────┬───────┘            │                    │
│  │         │                  │                     │                    │
│  │         │                  │                     │                    │
│  └─────────┼──────────────────┼─────────────────────┘                    │
│            │                  │                                          │
│    ┌───────▼──────────────────▼──────────────┐                          │
│    │         VPC ENDPOINTS                    │                          │
│    │                                         │                          │
│    │  ┌─────────────────────────────────┐    │                          │
│    │  │  GATEWAY ENDPOINT (Free!)       │    │   ┌───────────────────┐  │
│    │  │                                 │────┼──▶│  Amazon S3        │  │
│    │  │  - S3                           │    │   └───────────────────┘  │
│    │  │  - DynamoDB                     │────┼──▶┌───────────────────┐  │
│    │  │                                 │    │   │  DynamoDB         │  │
│    │  │  Works via route table entry    │    │   └───────────────────┘  │
│    │  │  (prefix list → vpce)           │    │                          │
│    │  └─────────────────────────────────┘    │                          │
│    │                                         │                          │
│    │  ┌─────────────────────────────────┐    │                          │
│    │  │  INTERFACE ENDPOINT (PrivateLink)│   │   ┌───────────────────┐  │
│    │  │  ($0.01/hr + data)              │────┼──▶│  SQS              │  │
│    │  │                                 │    │   └───────────────────┘  │
│    │  │  - SQS, SNS, CloudWatch        │────┼──▶┌───────────────────┐  │
│    │  │  - Secrets Manager, SSM        │    │   │  Secrets Manager  │  │
│    │  │  - API Gateway, ECS, ECR       │    │   └───────────────────┘  │
│    │  │  - 100+ other AWS services     │────┼──▶┌───────────────────┐  │
│    │  │                                 │    │   │  CloudWatch Logs  │  │
│    │  │  Creates an ENI in your subnet  │    │   └───────────────────┘  │
│    │  │  with a private IP address     │    │                          │
│    │  └─────────────────────────────────┘    │                          │
│    │                                         │                          │
│    └─────────────────────────────────────────┘                          │
│                                                                         │
│  X NO NAT Gateway needed! X NO Internet Gateway needed!               │
│  + Traffic stays 100% within AWS private network                       │
│  + More secure — data never touches the public internet                │
│  + Lower latency — fewer network hops                                  │
│  + Cost savings — no NAT data processing charges                       │
└─────────────────────────────────────────────────────────────────────────┘
```

### Gateway Endpoint vs Interface Endpoint

| Feature | Gateway Endpoint | Interface Endpoint |
|---------|-----------------|-------------------|
| **Services** | S3, DynamoDB only | 100+ services (SQS, SNS, SSM, ECR, etc.) |
| **Cost** | FREE | ~$0.01/hr per AZ + $0.01/GB data |
| **How it works** | Route table entry | Creates an ENI (network interface) in your subnet |
| **Access from on-prem** | ❌ No (VPC only) | ✅ Yes (via VPN/Direct Connect) |
| **Cross-region** | ❌ No | ❌ No (must be same region) |
| **Security** | Endpoint policy | Endpoint policy + Security Groups |

> **Rule of thumb:** If the service is S3 or DynamoDB → use Gateway Endpoint (free). For everything else → use Interface Endpoint.

#### Route Table — Private Subnet (with Gateway Endpoint)

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| pl-xxxxx (S3 prefix list) | vpce-xxxxx (S3 Gateway Endpoint) |
| pl-yyyyy (DynamoDB prefix list) | vpce-yyyyy (DynamoDB Gateway Endpoint) |
| *(No 0.0.0.0/0 route needed!)* | — |

> *The prefix list (`pl-xxxxx`) is a managed list of S3 IP ranges that AWS maintains automatically. The route table sends S3 traffic directly to the endpoint — no NAT or IGW required.*

#### Security Group — Interface Endpoint (for SQS, Secrets Manager, etc.)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| 10.0.10.0/24 (Private subnet CIDR) | TCP | 443 (HTTPS) |

> *Interface endpoints use HTTPS (443) — your app talks to the service via the endpoint's private IP on port 443.*

### Cost Savings Example

```
WITHOUT VPC Endpoints:
  10 EC2 instances uploading 1 TB/month to S3 via NAT Gateway
  NAT Gateway: $0.045/hr × 730 hrs = $32.85/month
  NAT Data Processing: 1,000 GB × $0.045/GB = $45.00/month
  Total: $77.85/month

WITH S3 Gateway Endpoint:
  Same traffic goes directly to S3 — NO NAT involved
  Gateway Endpoint: $0.00
  Total: $0.00/month

  Savings: $77.85/month = $934/year (and this grows with traffic!)
```

---

## Architecture 9 — Multi-Region Disaster Recovery

> **What this is:** Your application runs in one AWS region (primary) with a copy ready in another region (DR). If the primary region goes completely down, your DR region takes over.
>
> **Think of it this way:** A hospital has its main building (primary region) and a backup facility across town (DR region). If the main building has a power outage or flood, patients are redirected to the backup facility which has copies of all medical records.
>
> **When you need this:** Regulatory compliance (some industries require geo-redundancy), SLA requirements (<99.99% uptime), applications where downtime costs millions (finance, healthcare, e-commerce).

### The Diagram

```
                            ┌───────────────────┐
                            │     Route 53      │
                            │   (Global DNS)    │
                            │                   │
                            │ Failover routing: │
                            │ Primary → us-east │
                            │ Secondary → eu-west│
                            │                   │
                            │ Health checks run  │
                            │ every 10 seconds  │
                            └─────┬─────────┬───┘
                                  │         │
                    ┌─────────────┘         └─────────────┐
                    │ (Primary)                           │ (Secondary / DR)
                    │                                     │
┌───────────────────▼──────────────────┐  ┌───────────────▼──────────────────┐
│        REGION: us-east-1             │  │        REGION: eu-west-1         │
│        (PRIMARY)                     │  │        (DISASTER RECOVERY)       │
│                                      │  │                                  │
│  ┌────────────────────────────────┐  │  │  ┌────────────────────────────┐  │
│  │  CloudFront Distribution      │  │  │  │  CloudFront Distribution   │  │
│  └──────────┬─────────────────────┘  │  │  └──────────┬─────────────────┘  │
│             │                        │  │             │                    │
│  ┌──────────▼─────────────────────┐  │  │  ┌──────────▼─────────────────┐  │
│  │  ALB (Active — serving traffic)│  │  │  │  ALB (Standby OR active)  │  │
│  └──────────┬─────────────────────┘  │  │  └──────────┬─────────────────┘  │
│             │                        │  │             │                    │
│  ┌──────────▼─────────────────────┐  │  │  ┌──────────▼─────────────────┐  │
│  │  Auto Scaling Group            │  │  │  │  Auto Scaling Group        │  │
│  │  EC2: 4 instances (running)    │  │  │  │  EC2: 1 instance (warm)   │  │
│  └──────────┬─────────────────────┘  │  │  └──────────┬─────────────────┘  │
│             │                        │  │             │                    │
│  ┌──────────▼─────────────────────┐  │  │  ┌──────────▼─────────────────┐  │
│  │  RDS: Primary (Writer)         │  │  │  │  RDS: Read Replica         │  │
│  │                                │──┼──┼──│  (Cross-Region Replication)│  │
│  │  Handles all writes + reads    │  │  │  │  Can be promoted to writer │  │
│  └────────────────────────────────┘  │  │  └────────────────────────────┘  │
│                                      │  │                                  │
│  ┌────────────────────────────────┐  │  │  ┌────────────────────────────┐  │
│  │  S3: Primary Bucket            │  │  │  │  S3: Replica Bucket        │  │
│  │                                │──┼──┼──│  (Cross-Region Replication)│  │
│  └────────────────────────────────┘  │  │  └────────────────────────────┘  │
│                                      │  │                                  │
│  ┌────────────────────────────────┐  │  │  ┌────────────────────────────┐  │
│  │  DynamoDB Global Table         │  │  │  │  DynamoDB Global Table     │  │
│  │  (Active-Active replication)   │◄─┼──┼─▶│  (Active-Active)          │  │
│  └────────────────────────────────┘  │  │  └────────────────────────────┘  │
│                                      │  │                                  │
└──────────────────────────────────────┘  └──────────────────────────────────┘
```

### DR Strategies — From Cheapest to Fastest Recovery

| Strategy | Cost | RTO | RPO | Description |
|----------|------|-----|-----|-------------|
| **Backup & Restore** | $ (lowest) | 24 hours (slowest) | 24 hours | Backups stored in DR region. Restore from scratch. |
| **Pilot Light** | $$ | 1-4 hours | Minutes | Core systems always on (DB replicas). Scale up on trigger. |
| **Warm Standby** | $$$ | 15-30 min | Seconds | Scaled-down copy running. Scale UP on failover. |
| **Active-Active** | $$$$ (highest) | ~0 (fastest) | ~0 | Both regions serve traffic. No downtime on failover. |

> **RTO** = Recovery Time Objective (how long until app is back online)
> **RPO** = Recovery Point Objective (how much data can you afford to lose)

#### Route 53 — Failover Routing Policy

| Record | Type | Routing Policy | Health Check |
|--------|------|----------------|--------------|
| app.example.com | A (ALB alias) | Failover — **Primary** | us-east-1 ALB health check |
| app.example.com | A (ALB alias) | Failover — **Secondary** | eu-west-1 ALB health check |

> *Route 53 health checks run every 10 seconds. After 3 consecutive failures, DNS automatically points to the DR region.*

### Failover Flow

```
NORMAL OPERATION:
  Route 53 → Health check passes for us-east-1 → All traffic goes there

** us-east-1 GOES DOWN!

  MINUTE 0:    Route 53 health check fails (3 consecutive failures)
  MINUTE 1:    Route 53 updates DNS → points to eu-west-1
  MINUTE 1-5:  DNS TTL propagates (depends on TTL setting)
  MINUTE 2:    eu-west-1 ASG scales from 1 → 4 instances
  MINUTE 2-3:  RDS read replica promoted to primary (writer)
  MINUTE 5:    All traffic now served from eu-west-1

  Total downtime: ~5 minutes (Warm Standby strategy)
```

---

## Architecture 10 — Zero-Trust Microservices (PrivateLink)

> **What this is:** Microservices in different VPCs or AWS accounts communicating securely through AWS PrivateLink — without ANY internet exposure.
>
> **Who uses this:** Companies running microservices (each team owns their own VPC/account), SaaS providers exposing services to customers privately.
>
> **Think of it this way:** Instead of two buildings communicating by shouting across the street (internet), they install a private intercom system. Only the intended recipients can hear the message, and nobody on the street has any idea it's happening.

### The Diagram

```
┌────────────────────────────────────────┐     ┌────────────────────────────────────────┐
│  VPC-A: Payment Service               │     │  VPC-B: Order Service                  │
│  (Account: Team Payments)              │     │  (Account: Team Orders)                │
│                                        │     │                                        │
│  ┌──────────────────────────────────┐  │     │  ┌──────────────────────────────────┐  │
│  │  Private Subnet                  │  │     │  │  Private Subnet                  │  │
│  │                                  │  │     │  │                                  │  │
│  │  ┌────────────────────────┐      │  │     │  │  ┌────────────────────────┐      │  │
│  │  │  NLB (Network Load    │      │  │     │  │  │  EC2: Order API        │      │  │
│  │  │  Balancer)             │      │  │ AWS │  │  │                        │      │  │
│  │  │    ↓                   │      │  │PrivateLink  │  Calls payment svc   │      │  │
│  │  │  EC2: Payment API      │      │  │     │  │  │  at:                   │      │  │
│  │  │  (Process payments)    │◄─────┼──┼─────┼──┼──│  vpce-xxx.payment.    │      │  │
│  │  │                        │      │  │     │  │  │  vpc-endpoint.com     │      │  │
│  │  └────────────────────────┘      │  │     │  │  └────────────────────────┘      │  │
│  │                                  │  │     │  │                                  │  │
│  │  This is the SERVICE PROVIDER    │  │     │  │  This is the SERVICE CONSUMER    │  │
│  │  - Creates NLB                   │  │     │  │  - Creates Interface Endpoint    │  │
│  │  - Creates Endpoint Service      │  │     │  │  - Gets private DNS or ENI IP   │  │
│  │  - Approves connection requests  │  │     │  │  - Calls the service privately  │  │
│  └──────────────────────────────────┘  │     │  └──────────────────────────────────┘  │
│                                        │     │                                        │
│  + Payment API is NEVER on internet   │     │  + Order API talks to Payment API     │
│  + Only approved consumers connect   │     │     without EVER touching the internet │
│  + CIDR blocks can overlap!          │     │  + Looks like a local private IP      │
└────────────────────────────────────────┘     └────────────────────────────────────────┘
```

### Why PrivateLink Instead of VPC Peering?

| Feature | VPC Peering | PrivateLink |
|---------|------------|-------------|
| **Exposes** | Entire VPC network to the peer | Only the specific service (one port) |
| **CIDR overlap** | ❌ Cannot overlap | ✅ Can overlap |
| **Access control** | Route tables + Security Groups | Endpoint policy + approval list |
| **Blast radius** | Full network access between VPCs | Only the exposed service |
| **Used for** | Trusted VPCs that need broad access | Microservices, SaaS, zero-trust |
| **Analogy** | Opening a door between two rooms | Installing an intercom system |

#### Security Group — `nlb-target-sg` (VPC-A: Payment API behind NLB)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| 10.0.0.0/16 (VPC-A CIDR) | TCP | 443 |

> *NLB forwards traffic to the Payment API. The source IP seen by the target is the NLB's private IP within VPC-A.*

#### Security Group — `endpoint-sg` (VPC-B: Interface Endpoint ENI)

**Inbound:**

| Source | Protocol | Port |
|--------|----------|------|
| 10.1.0.0/16 (VPC-B CIDR) | TCP | 443 |

> *The Order API calls `vpce-xxx.payment.vpc-endpoint.com` on port 443. The endpoint's ENI receives the traffic and forwards it across PrivateLink to VPC-A's NLB.*

---

## How to Read CIDR Blocks

> CIDR (Classless Inter-Domain Routing) defines how many IP addresses a network has. It's the `10.0.0.0/16` notation you see everywhere.

### The Simple Explanation

```
10.0.0.0/16
│        │
│        └── /16 means "first 16 bits are fixed, rest can vary"
│            = 65,536 IP addresses (2^16)
│
└── Starting address: 10.0.0.0

QUICK CHEAT SHEET:
  /8   → 16,777,216 IPs  (10.x.x.x)         — Massive (think "entire company")
  /16  → 65,536 IPs      (10.0.x.x)          — Large (think "VPC")
  /20  → 4,096 IPs       (10.0.0.0–10.0.15.255) — Medium
  /24  → 256 IPs         (10.0.0.x)           — Normal (think "subnet")
  /28  → 16 IPs                               — Small (think "small subnet")
  /32  → 1 IP            (one specific host)  — Single machine
```

### Memory Trick

```
EASY RULE: Every time you increase the / by 1, you HALVE the IPs

  /16 = 65,536 IPs
  /17 = 32,768 IPs  (halved)
  /18 = 16,384 IPs  (halved again)
  ...
  /24 = 256 IPs
  /25 = 128 IPs
  /26 = 64 IPs
  /27 = 32 IPs
  /28 = 16 IPs

Formula: IPs = 2^(32 - prefix)
  /16 → 2^(32-16) = 2^16 = 65,536
  /24 → 2^(32-24) = 2^8  = 256
```

### Practical CIDR Design for a Company

```
Company CIDR: 10.0.0.0/8 (whole 10.x.x.x range — 16M IPs)

  Production VPC:     10.0.0.0/16    (65,536 IPs)
  ├── Public:         10.0.1.0/24    (256 IPs)  — ALB, NAT GW
  ├── Public:         10.0.2.0/24    (256 IPs)  — ALB, NAT GW (AZ-b)
  ├── App (Private):  10.0.10.0/24   (256 IPs)  — EC2 app servers (AZ-a)
  ├── App (Private):  10.0.20.0/24   (256 IPs)  — EC2 app servers (AZ-b)
  ├── DB (Private):   10.0.100.0/24  (256 IPs)  — RDS, ElastiCache (AZ-a)
  └── DB (Private):   10.0.200.0/24  (256 IPs)  — RDS, ElastiCache (AZ-b)

  Development VPC:    10.1.0.0/16    (65,536 IPs)
  ├── Same subnet pattern as production...

  Staging VPC:        10.2.0.0/16    (65,536 IPs)
  Shared Services:    10.3.0.0/16    (65,536 IPs)
  DR Region:          10.10.0.0/16   (65,536 IPs)

  + No overlapping CIDRs → All VPCs can peer or connect via Transit Gateway
  + Organized by environment → Easy to create firewall rules
  + Room to grow → Each VPC has 65K IPs
```

> **AWS reserves 5 IPs in every subnet:**
> ```
> 10.0.1.0   → Network address
> 10.0.1.1   → VPC router
> 10.0.1.2   → DNS server
> 10.0.1.3   → Reserved for future use
> 10.0.1.255 → Broadcast address
>
> So a /24 subnet (256 IPs) actually gives you 251 usable IPs!
> ```

---

## Security Groups vs NACLs — Complete Comparison

> Two types of firewalls in AWS. You MUST understand both — they're in every interview.

### Visual Comparison

```
NACL (Network ACL) — Subnet Level Firewall
┌──────────────────────────────────────────────────────┐
│  SUBNET                                              │
│  ┌──── NACL RULES ────┐                             │
│  │ Rule 100: ALLOW TCP │                             │
│  │   80 from 0.0.0.0/0│                             │
│  │ Rule 200: DENY  TCP │                             │
│  │   22 from 0.0.0.0/0│    ┌─────────────────────┐  │
│  │ Rule *  : DENY ALL  │    │                     │  │
│  └─────────────────────┘    │  EC2 ─── EC2 ─── EC2│  │
│                             │                     │  │
│  NACL checks traffic AT     │  Security Group     │  │
│  the subnet boundary.       │  checks traffic AT  │  │
│  Like a gate guard at       │  each EC2 door.     │  │
│  the neighborhood entrance. │  Like a lock on     │  │
│                             │  each apartment.    │  │
│                             └─────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

### Side-by-Side Comparison

| Feature | Security Group | Network ACL |
|---------|---------------|-------------|
| **Level** | Instance (EC2, RDS, etc.) | Subnet |
| **Stateful?** | ✅ YES — if inbound is allowed, outbound response is automatic | ❌ NO — must allow BOTH inbound AND outbound explicitly |
| **Default** | Deny all inbound, Allow all outbound | Allow ALL inbound and outbound |
| **Rules** | ALLOW only (no deny rules) | ALLOW and DENY rules |
| **Rule order** | All rules evaluated together | Rules evaluated in order (lowest number first) |
| **Association** | Attached to ENI (network interface) | Attached to subnet |
| **Analogy** | Lock on each apartment door | Gate guard at neighborhood entrance |

### Stateful vs Stateless — The Key Difference

```
STATEFUL (Security Group):
  Request:   Client → Port 80 → EC2  (Inbound rule: ALLOW 80 +)
  Response:  EC2 → Client            (Automatically allowed — SG remembers the connection)
  
  You only write ONE rule (inbound). The response is handled automatically.

STATELESS (NACL):
  Request:   Client → Port 80 → EC2  (Inbound rule: ALLOW 80 +)
  Response:  EC2 → Client            (Outbound rule ALSO needed!
                                       EC2 responds on ephemeral port 1024-65535.
                                       If outbound rule doesn't allow this → X BLOCKED!)
  
  You must write TWO rules (inbound + outbound). NACL has no memory.
```

> **Common interview mistake:** People set up NACL inbound rules correctly but forget outbound rules for responses. Remember: NACLs are stateless!

---

## Route Tables — How Traffic Finds Its Way

> Every packet in AWS asks: "Where do I go?" The route table is the GPS.

### How Route Tables Work

```
When EC2 (10.0.10.5) wants to reach Google.com:

Step 1: EC2 sends packet → destination: 142.250.80.46 (Google's IP)

Step 2: Route table lookup (most specific match wins):

  ┌─────────────────────────────────────────────┐
  │  ROUTE TABLE                                │
  │                                             │
  │  Destination      │  Target         │ Match? │
  │  ──────────────── │ ─────────────── │ ────── │
  │  10.0.0.0/16      │  local          │ X No  │  (Google IP not in 10.0.x.x range)
  │  10.1.0.0/16      │  pcx-xxxxx      │ X No  │  (Not in 10.1.x.x either)
  │  0.0.0.0/0        │  nat-gw-xxxxx   │ + Yes!│  (0.0.0.0/0 matches EVERYTHING)
  └─────────────────────────────────────────────┘

Step 3: Packet is sent to NAT Gateway → Internet Gateway → Google

KEY RULE: "Most specific match wins"
  If destination is 10.0.5.5:
    10.0.0.0/16 matches (it's in the 10.0.x.x range)
    0.0.0.0/0 also matches (matches everything)
    → 10.0.0.0/16 wins because /16 is MORE SPECIFIC than /0
```

### Common Route Table Patterns

```
PUBLIC SUBNET ROUTE TABLE:
  10.0.0.0/16  → local              (VPC internal traffic — stays in VPC)
  0.0.0.0/0    → igw-xxxxx          (Everything else → Internet Gateway)
  
  "Public things can reach the internet directly."

PRIVATE SUBNET ROUTE TABLE:
  10.0.0.0/16  → local              (VPC internal traffic)
  0.0.0.0/0    → nat-gw-xxxxx       (Outbound internet via NAT — inbound blocked)
  
  "Private things can download updates but nobody can reach them from outside."

PRIVATE SUBNET WITH VPC PEERING:
  10.0.0.0/16  → local              (This VPC)
  10.1.0.0/16  → pcx-xxxxx          (Peered VPC — traffic goes through peering tunnel)
  0.0.0.0/0    → nat-gw-xxxxx       (Everything else → internet via NAT)

PRIVATE SUBNET WITH TRANSIT GATEWAY:
  10.0.0.0/16  → local              (This VPC)
  10.0.0.0/8   → tgw-xxxxx          (ALL other VPCs → through Transit Gateway)
  0.0.0.0/0    → tgw-xxxxx          (Internet also via TGW → Shared VPC → NAT)
```

---

## Networking Troubleshooting — The 7-Step Checklist

> When traffic isn't flowing, check these in ORDER. 90% of AWS networking issues are found in the first 4 steps.

```
┌───────────────────────────────────────────────────────┐
│  STEP 1: SECURITY GROUP                               │
│  "Is the firewall on the instance allowing traffic?"  │
│                                                       │
│  Check: Is there an INBOUND rule for the port?        │
│  Check: Is the SOURCE correct? (IP, SG, or CIDR)     │
│  Fix:   Add inbound rule                              │
│                                                       │
│  aws ec2 describe-security-groups --group-ids sg-xxx  │
├───────────────────────────────────────────────────────┤
│  STEP 2: NACL (Network ACL)                           │
│  "Is the subnet firewall allowing traffic?"           │
│                                                       │
│  Check: INBOUND rule allows the port                  │
│  Check: OUTBOUND rule allows ephemeral ports          │
│         (1024-65535) — people forget this!             │
│  Check: DENY rules before ALLOW (rules are ordered!)  │
│                                                       │
│  aws ec2 describe-network-acls --filters ...          │
├───────────────────────────────────────────────────────┤
│  STEP 3: ROUTE TABLE                                  │
│  "Does the subnet know HOW to reach the destination?" │
│                                                       │
│  Check: Is there a route for the destination?         │
│  Check: For internet: 0.0.0.0/0 → igw or nat-gw?     │
│  Check: For other VPCs: CIDR → pcx or tgw?            │
│                                                       │
│  aws ec2 describe-route-tables --filters ...          │
├───────────────────────────────────────────────────────┤
│  STEP 4: INTERNET GATEWAY / NAT GATEWAY               │
│  "Is the door to the internet actually attached?"     │
│                                                       │
│  Check: IGW attached to VPC?                          │
│  Check: NAT GW in a public subnet with Elastic IP?   │
│  Check: NAT GW's subnet has route to IGW?             │
├───────────────────────────────────────────────────────┤
│  STEP 5: SUBNET ASSOCIATION                           │
│  "Is the route table actually applied to the subnet?" │
│                                                       │
│  Check: Explicit association (not just main RT)       │
├───────────────────────────────────────────────────────┤
│  STEP 6: PUBLIC IP / ELASTIC IP                       │
│  "Does the instance have a public address?"           │
│                                                       │
│  Check: EC2 in public subnet needs public IP or EIP   │
│  Check: Auto-assign public IP enabled on subnet?      │
├───────────────────────────────────────────────────────┤
│  STEP 7: VPC FLOW LOGS                                │
│  "What does the traffic camera show?"                 │
│                                                       │
│  Check: Enable flow logs → see ACCEPT/REJECT          │
│  If REJECT: Security Group or NACL is blocking         │
│  If no log: Route table issue (traffic never arrived) │
│                                                       │
│  aws ec2 describe-flow-logs                           │
└───────────────────────────────────────────────────────┘
```

### Quick Diagnostic Commands

```bash
# Check Security Group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx \
    --query 'SecurityGroups[].IpPermissions[]' --output table

# Check Route Table
aws ec2 describe-route-tables \
    --filters "Name=association.subnet-id,Values=subnet-xxxxx" \
    --query 'RouteTables[].Routes[]' --output table

# Check NACL
aws ec2 describe-network-acls \
    --filters "Name=association.subnet-id,Values=subnet-xxxxx" \
    --query 'NetworkAcls[].Entries[]' --output table

# Check if IGW is attached
aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=vpc-xxxxx" --output table

# Check VPC Flow Logs
aws ec2 describe-flow-logs \
    --filter "Name=resource-id,Values=vpc-xxxxx" --output table

# Reachability Analyzer (automated troubleshooting!)
aws ec2 create-network-insights-path \
    --source eni-source --destination eni-dest \
    --protocol TCP --destination-port 443
```

---

## Cost Awareness — What's Free and What's Not

> Networking costs catch people off guard. Here's what you need to know.

```
┌────────────────────────────────────────────────────────────────┐
│                   AWS NETWORKING COSTS                          │
│                                                                │
│  + FREE:                                                      │
│  ├── VPC creation                                              │
│  ├── Subnets, Route Tables, Security Groups, NACLs             │
│  ├── Internet Gateway                                          │
│  ├── VPC Peering (no charge for the connection itself)         │
│  ├── Gateway Endpoints (S3, DynamoDB)                          │
│  ├── Data transfer IN to AWS                                   │
│  └── Data transfer within same AZ (same VPC)                   │
│                                                                │
│  $$ COSTS MONEY:                                               │
│  ├── NAT Gateway: ~$32/month + $0.045/GB data processed        │
│  ├── Transit Gateway: $0.05/hr per attachment + $0.02/GB       │
│  ├── Interface Endpoints: ~$7/month per AZ + $0.01/GB          │
│  ├── Elastic IP (if NOT attached to running instance): $3.6/mo │
│  ├── VPN Connection: ~$36/month                                │
│  ├── Direct Connect: $0.30/hr (port) + data transfer           │
│  ├── Data transfer OUT to internet: $0.09/GB (first 10 TB)    │
│  ├── Data transfer between AZs: $0.01/GB each way              │
│  └── Data transfer between regions: $0.02/GB                   │
│                                                                │
│  >> COST-SAVING TIPS:                                          │
│  ├── Use S3 Gateway Endpoint → avoid NAT data charges          │
│  ├── Centralize NAT via Transit Gateway → 1 NAT instead of N  │
│  ├── Use VPC Flow Logs → S3 (cheaper) not CloudWatch           │
│  ├── Keep traffic in same AZ when possible                     │
│  ├── Use CloudFront → reduces data transfer OUT costs          │
│  └── Delete unused Elastic IPs ($3.6/month each!)              │
└────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference — All Services at a Glance

| Service | What It Does | Analogy | When to Use |
|---------|-------------|---------|-------------|
| **VPC** | Private network in AWS | Private neighborhood | Always — every resource needs one |
| **Subnet** | Subdivision of a VPC | Streets in a neighborhood | Public (internet-facing) or Private (internal) |
| **Internet Gateway** | VPC ↔ Internet | Highway on-ramp | When instances need public internet access |
| **NAT Gateway** | Private → Internet (outbound only) | One-way shuttle bus | Private instances need updates/API calls |
| **Security Group** | Instance-level firewall (stateful) | Apartment door lock | Always — every instance gets one |
| **NACL** | Subnet-level firewall (stateless) | Neighborhood gate guard | Extra layer of defense |
| **Route Table** | Traffic routing rules | GPS / road signs | Every subnet has one (explicit or default) |
| **VPC Peering** | Direct VPC-to-VPC link | Tunnel between two houses | 2-3 VPCs need to communicate |
| **Transit Gateway** | Central hub for all VPCs | Central bus station | 4+ VPCs, hybrid cloud, multi-account |
| **VPN** | Encrypted tunnel over internet | Secret underground tunnel | Connect office to AWS |
| **Direct Connect** | Dedicated private connection | Private highway (fiber) | High bandwidth, low latency needs |
| **VPC Endpoint (GW)** | Free private access to S3/DynamoDB | Private elevator | Always use for S3 — it's free! |
| **VPC Endpoint (IF)** | Private access to 100+ AWS services | Private intercom | Zero-trust, no internet required |
| **PrivateLink** | Expose service to other VPCs/accounts | Private intercom system | Microservices, SaaS, zero-trust |
| **VPC Flow Logs** | Network traffic logging | Traffic cameras | Security audits, troubleshooting |
| **Elastic IP** | Static public IP | Permanent address | Instances that need a fixed public IP |
| **Route 53** | DNS service (name → IP) | Phone book | Every public-facing app needs DNS |

---

> **Learning path:**
> 1. **Start here:** Architecture 1 (Basic VPC) → CIDR → Security Groups vs NACLs
> 2. **Build up:** Architecture 2 (Three-Tier) → Architecture 3 (Multi-AZ) → Architecture 4 (NAT)
> 3. **Go advanced:** Architecture 5-6 (Peering, Transit GW) → Architecture 7 (Hybrid Cloud)
> 4. **Expert level:** Architecture 8-10 (Endpoints, DR, PrivateLink) → Cost Optimization
> 5. **Real work:** Use the Troubleshooting Checklist daily — it will save you hours
