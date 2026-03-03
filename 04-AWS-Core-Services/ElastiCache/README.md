# ElastiCache — In-Memory Caching Service

> Fully managed Redis and Memcached. Microsecond latency for frequently accessed data. Reduce database load by 80%+.

---

## Real-World Analogy

ElastiCache is like a **sticky note on your desk**:
- Full filing cabinet (database) takes 30 seconds to search
- Sticky note on desk (cache) = instant answer
- You write frequently-needed info on sticky notes
- Notes expire and get replaced (TTL)
- If the note is missing (cache miss), you go to the cabinet and make a new note

---

## Redis vs Memcached

| Feature | Redis | Memcached |
|---------|-------|-----------|
| **Data structures** | Strings, lists, sets, hashes, sorted sets | Simple key-value only |
| **Persistence** | Yes (RDB/AOF snapshots) | No (pure cache) |
| **Replication** | Multi-AZ with failover | No replication |
| **Cluster mode** | Yes (sharding across nodes) | Yes (sharding) |
| **Pub/Sub** | Yes | No |
| **Lua scripting** | Yes | No |
| **Backup/Restore** | Yes | No |
| **Use cases** | Session store, leaderboard, queues | Simple caching, HTML fragments |

**Choose Redis 90% of the time.** Memcached only if you need simple caching with multi-threaded performance.

---

## Caching Strategies

| Strategy | How It Works | Best For |
|----------|-------------|----------|
| **Lazy Loading** | Cache on first read (cache miss → DB → cache) | Read-heavy, eventual consistency OK |
| **Write-Through** | Write to cache + DB simultaneously | Always fresh data, write overhead |
| **Write-Behind** | Write to cache, async write to DB | High write throughput |
| **TTL** | Data expires after set time | Balance freshness vs performance |

```
Lazy Loading (Cache-Aside):
                    ┌──────────┐
             ┌─(1)─▶│  Cache   │──(2) HIT ──▶ Return data
             │      │ (Redis)  │
  App ───────┤      └──────────┘
             │           │
             │      (2) MISS
             │           │
             └─(3)─▶┌────▼─────┐
                    │ Database │──(4) Store in cache + return
                    └──────────┘
```

---

## Real-Time Example 1: E-Commerce Session Store

**Scenario:** Your e-commerce app has 100,000 concurrent users. Storing sessions in RDS causes slow queries. Move to Redis for <1ms session access.

```
BEFORE (Sessions in RDS):
- 100K concurrent sessions
- DB query per page load: ~50ms
- DB CPU: 90% (overloaded)
- User experience: slow

AFTER (Sessions in Redis):
- 100K concurrent sessions
- Redis get per page load: <1ms
- DB CPU: 20% (relieved)
- User experience: fast
```

```bash
# Create Redis cluster (Multi-AZ for production)
aws elasticache create-replication-group \
    --replication-group-id session-store \
    --replication-group-description "Session store" \
    --engine redis \
    --engine-version 7.0 \
    --node-type cache.r6g.large \
    --num-cache-clusters 2 \
    --automatic-failover-enabled \
    --multi-az-enabled \
    --at-rest-encryption-enabled \
    --transit-encryption-enabled \
    --cache-subnet-group-name private-cache-subnets \
    --security-group-ids sg-cache

# Application code (Python):
# import redis
# r = redis.Redis(host='session-store.xxxx.cache.amazonaws.com', port=6379, ssl=True)
#
# # Store session
# r.setex(f"session:{session_id}", 3600, json.dumps(session_data))  # TTL 1 hour
#
# # Retrieve session
# session = json.loads(r.get(f"session:{session_id}"))
```

---

## Real-Time Example 2: Database Query Caching

**Scenario:** Product listing page queries RDS 5,000 times/minute (same query). Cache results in Redis.

```bash
# Cache product listings with 5-minute TTL
# Pseudocode:
# key = f"products:category:{category_id}:page:{page}"
# 
# cached = redis.get(key)
# if cached:
#     return json.loads(cached)  # Cache HIT (<1ms)
# 
# result = db.query("SELECT * FROM products WHERE category=? LIMIT 20", category_id)
# redis.setex(key, 300, json.dumps(result))  # Cache for 5 min
# return result

# Result:
# 5,000 requests/min → 1 DB query + 4,999 cache hits
# DB load reduced by 99.98%
# Response time: 50ms → <1ms
```

---

## Real-Time Example 3: Real-Time Leaderboard with Redis Sorted Sets

**Scenario:** Gaming platform with 1 million players. Need real-time top 100 leaderboard with <5ms response.

```bash
# Redis Sorted Sets are perfect for leaderboards
# ZADD leaderboard score username

# Add/update player scores
# ZADD leaderboard 15000 "player_alice"
# ZADD leaderboard 23000 "player_bob"
# ZADD leaderboard 18000 "player_charlie"

# Get top 10 (with scores, descending)
# ZREVRANGE leaderboard 0 9 WITHSCORES
# Result in <1ms, even with 1M entries!

# Get player's rank
# ZREVRANK leaderboard "player_alice"
# Returns: 2 (0-indexed)

# This would take ~5 seconds with a SQL ORDER BY on 1M rows
# Redis does it in <1ms using in-memory sorted data structure
```

---

## Labs

### Lab 1: Create Redis Cluster
```bash
# Create subnet group
aws elasticache create-cache-subnet-group \
    --cache-subnet-group-name private-subnets \
    --cache-subnet-group-description "Private subnets for cache" \
    --subnet-ids subnet-priv-a subnet-priv-b

# Create Redis (single node for dev)
aws elasticache create-cache-cluster \
    --cache-cluster-id dev-cache \
    --engine redis \
    --cache-node-type cache.t3.micro \
    --num-cache-nodes 1 \
    --cache-subnet-group-name private-subnets \
    --security-group-ids sg-cache
```

### Lab 2: Test Connection
```bash
# From EC2 in same VPC
sudo yum install -y redis6
redis-cli -h dev-cache.xxxx.cache.amazonaws.com -p 6379

# Basic operations
# SET mykey "Hello from ElastiCache"
# GET mykey
# SETEX session:abc123 3600 '{"user":"alice"}'
# TTL session:abc123
```

---

## Interview Questions

1. **When would you use ElastiCache?**
   > Cache frequently accessed DB queries (reduce DB load 80%+), session storage (sub-ms access), leaderboards (sorted sets), real-time analytics, rate limiting (token bucket with Redis), message broker (pub/sub). Any time you need microsecond latency for repeated data access.

2. **Redis vs Memcached — which to choose?**
   > Redis: 90% of use cases. Supports complex data structures, persistence, replication, backup, pub/sub. Memcached: only for simple key-value caching where you need multi-threaded performance and don't need persistence/replication.

3. **What happens on a cache miss?**
   > With lazy loading: app queries the database, stores the result in cache with a TTL, then returns. Subsequent requests hit the cache. Risk: first request is slow (cold cache). Mitigation: warm the cache on deployment by pre-loading popular data.

4. **How to handle cache invalidation?**
   > Hardest problem in computer science! Options: (1) TTL-based expiry (simplest), (2) Write-through (update cache on write), (3) Event-driven invalidation (DB change → Lambda → invalidate cache key), (4) Pub/Sub notifications. Most apps use TTL + write-through combination.

5. **How does ElastiCache Multi-AZ work?**
   > Redis replication group with primary + replica in different AZ. Automatic failover: if primary fails, replica is promoted (typically <30 seconds). Reads can go to replicas (read scaling). Data is synchronously replicated. For cluster mode: data is sharded across multiple primary nodes.

6. **How to size your ElastiCache cluster?**
   > Calculate: (1) Expected data size (keys × avg value size), (2) Connections needed (max concurrent), (3) Operations per second. Add 25% buffer for memory overhead. Start with t3/r6g. Monitor `EngineCPUUtilization`, `DatabaseMemoryUsagePercentage`, `CacheHitRate`. Scale up if hit rate < 80% or memory > 70%.
