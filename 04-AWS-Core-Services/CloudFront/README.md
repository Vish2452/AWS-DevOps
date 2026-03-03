# CloudFront — Content Delivery Network

> Global CDN for low-latency content delivery. Cache at 400+ edge locations worldwide. Makes your website load in milliseconds from anywhere.

---

## Real-World Analogy

CloudFront is like a **pizza chain with 400+ locations worldwide**:
- Without CloudFront: Every pizza order goes to the main kitchen in New York → takes 30 min to deliver to London
- With CloudFront: Pre-make popular pizzas at every location → customer in London gets pizza in 2 minutes
- **Origin** = the main kitchen (your S3 bucket or EC2 server)
- **Edge Location** = local pizza shops worldwide (cached copies)
- **Cache Invalidation** = "We changed the recipe! Throw out all old pizzas and make fresh ones"

---

## Key Concepts

| Concept | Description | Real-World Example |
|---------|-------------|-------------------|
| **Distribution** | CDN configuration | Your website `www.myapp.com` served globally |
| **Origins** | Where content comes from | S3 bucket, ALB, EC2, any HTTP server |
| **Behaviors** | Path-based caching rules | `/api/*` → don't cache, `/images/*` → cache 30 days |
| **Cache invalidation** | Force refresh of cached content | Updated your logo? Invalidate `/logo.png` |
| **OAC** | Origin Access Control — secure S3 access | Only CloudFront can read your S3 bucket |
| **Lambda@Edge** | Run code at edge locations | Resize images, add headers, A/B testing |
| **CloudFront Functions** | Lightweight edge compute (< 1ms) | URL redirect, header manipulation |
| **Signed URLs/Cookies** | Restrict content access | Premium video content only for paid subscribers |
| **WAF Integration** | Web Application Firewall | Block SQL injection, rate limiting at the edge |
| **Field-level Encryption** | Encrypt sensitive form fields | Credit card numbers encrypted at edge, only backend can decrypt |

---

## Real-Time Example 1: E-Commerce Website (Like Amazon/Flipkart)

**Scenario:** You have an online store. Images load slowly for users in India because your servers are in US-East-1.

```
WITHOUT CloudFront:
User in Mumbai → Request travels to US-East-1 → 800ms latency
User in London → Request travels to US-East-1 → 400ms latency

WITH CloudFront:
User in Mumbai → Served from Mumbai edge location → 20ms latency ⚡
User in London → Served from London edge location → 15ms latency ⚡
```

**Architecture:**
```
User (Mumbai) ──► CloudFront Edge (Mumbai)
                       │
                       ├── Cache HIT? → Return immediately (20ms)
                       │
                       └── Cache MISS? → Fetch from S3 (US-East-1)
                                         → Cache it at Mumbai edge
                                         → Return to user
                                         → Next user gets cache HIT
```

**Impact:** 
- Page load time: 3.2s → 0.8s (75% faster)
- S3 bandwidth costs reduced by 60% (cached at edge)
- Better SEO ranking (Google rewards fast websites)

---

## Real-Time Example 2: Video Streaming Platform (Like Netflix/Hotstar)

**Scenario:** You stream movies. Only paid subscribers should access content. Users worldwide need buffer-free playback.

```bash
# Step 1: Create signed URL (expires in 2 hours)
# Only your backend generates these, so only logged-in subscribers get access

aws cloudfront sign --url "https://d1234.cloudfront.net/movies/avengers.mp4" \
    --key-pair-id APKA1234567890 \
    --private-key file://private_key.pem \
    --date-less-than "2026-03-02T20:00:00Z"

# Output: https://d1234.cloudfront.net/movies/avengers.mp4?Expires=1741118400&Signature=abc...&Key-Pair-Id=APKA1234567890
```

**How it works:**
1. User clicks "Play" → your backend verifies they're a paid subscriber
2. Backend generates a **signed URL** valid for 2 hours
3. User's browser uses the signed URL to stream from CloudFront
4. CloudFront verifies the signature → serves the video from nearest edge
5. Non-subscribers can't access the video (no valid signature)

---

## Real-Time Example 3: Multi-Origin Architecture

**Scenario:** Your app has static files (images, CSS, JS) AND an API. Different caching rules for each.

```
CloudFront Distribution: www.myapp.com
│
├── Behavior 1: /api/* → ALB Origin (no caching, always fresh)
│   TTL: 0 seconds
│   Forward: All headers, cookies, query strings
│
├── Behavior 2: /static/* → S3 Origin (cache for 30 days)
│   TTL: 2,592,000 seconds
│   Compress: Yes (gzip/brotli)
│
├── Behavior 3: /images/* → S3 Origin + Lambda@Edge (resize on-the-fly)
│   Lambda@Edge: Resize image based on device (mobile vs desktop)
│
└── Default (*): S3 Origin (cache for 1 day)
    TTL: 86,400 seconds
```

---

## Lambda@Edge Use Cases

| Use Case | Trigger | Example |
|----------|---------|---------|
| **Image optimization** | Origin Response | Serve WebP to Chrome, JPEG to Safari |
| **A/B testing** | Viewer Request | 50% users see new homepage design |
| **Authentication** | Viewer Request | Verify JWT token before serving content |
| **SEO** | Origin Request | Pre-render pages for Googlebot |
| **Redirect** | Viewer Request | `http://` → `https://`, country-based redirect |
| **Custom error page** | Origin Response | Show branded 404 page instead of default |

```javascript
// Lambda@Edge: Add security headers to all responses
exports.handler = async (event) => {
    const response = event.Records[0].cf.response;
    const headers = response.headers;
    
    headers['strict-transport-security'] = [{
        key: 'Strict-Transport-Security',
        value: 'max-age=63072000; includeSubdomains; preload'
    }];
    headers['x-content-type-options'] = [{
        key: 'X-Content-Type-Options', value: 'nosniff'
    }];
    headers['x-frame-options'] = [{
        key: 'X-Frame-Options', value: 'DENY'
    }];
    
    return response;
};
```

---

## Labs

### Lab 1: Create CloudFront Distribution for S3 Website
```bash
# Create S3 bucket for static website
aws s3 mb s3://my-website-bucket-unique-name
aws s3 website s3://my-website-bucket-unique-name \
    --index-document index.html --error-document error.html

# Create CloudFront distribution with OAC
aws cloudfront create-distribution --distribution-config '{
    "CallerReference": "unique-ref-123",
    "Origins": {
        "Quantity": 1,
        "Items": [{
            "Id": "S3Origin",
            "DomainName": "my-bucket.s3.amazonaws.com",
            "S3OriginConfig": {"OriginAccessIdentity": ""},
            "OriginAccessControlId": "OAC_ID"
        }]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3Origin",
        "ViewerProtocolPolicy": "redirect-to-https",
        "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
        "Compress": true
    },
    "Enabled": true,
    "DefaultRootObject": "index.html"
}'
```

### Lab 2: Invalidate Cache After Deployment
```bash
# After deploying new code, invalidate changed files
aws cloudfront create-invalidation --distribution-id DIST_ID \
    --paths "/index.html" "/css/*" "/js/*"

# Invalidate EVERYTHING (costs $$$, use sparingly)
aws cloudfront create-invalidation --distribution-id DIST_ID \
    --paths "/*"

# Check invalidation status
aws cloudfront get-invalidation --distribution-id DIST_ID \
    --id INV_ID
```

### Lab 3: Set Up Custom Domain with SSL
```bash
# Step 1: Request SSL certificate (must be in us-east-1 for CloudFront)
CERT_ARN=$(aws acm request-certificate \
    --domain-name "www.myapp.com" \
    --validation-method DNS \
    --region us-east-1 \
    --query 'CertificateArn' --output text)

# Step 2: Update CloudFront to use custom domain + SSL
aws cloudfront update-distribution --id DIST_ID \
    --distribution-config '{
        "Aliases": {"Quantity": 1, "Items": ["www.myapp.com"]},
        "ViewerCertificate": {
            "ACMCertificateArn": "'$CERT_ARN'",
            "SSLSupportMethod": "sni-only",
            "MinimumProtocolVersion": "TLSv1.2_2021"
        }
    }'

# Step 3: Create Route53 alias record
# www.myapp.com → d1234567.cloudfront.net
```

---

## CloudFront vs Direct S3/ALB Access

| Aspect | Without CloudFront | With CloudFront |
|--------|-------------------|-----------------|
| **Latency** | 100-800ms (depends on distance) | 10-50ms (served from edge) |
| **Bandwidth cost** | S3: $0.09/GB | CF: $0.085/GB + caching saves 60%+ |
| **DDoS protection** | Basic AWS Shield | AWS Shield Standard included free |
| **SSL** | Must configure per service | Free SSL with ACM at edge |
| **Custom error pages** | Not available | Yes, branded 404/500 pages |

---

## Interview Questions

1. **What is CloudFront and how does it work?**
   > CloudFront is a CDN with 400+ edge locations. It caches content close to users, reducing latency from hundreds of ms to single digits. On cache miss, it fetches from the origin and caches for future requests.

2. **What is the difference between CloudFront and S3 Transfer Acceleration?**
   > CloudFront caches content at edge locations for downloads. S3 Transfer Acceleration uses edge locations to speed up uploads to S3. CloudFront is for reads, Transfer Acceleration is for writes.

3. **How do you secure S3 content served through CloudFront?**
   > Use OAC (Origin Access Control) — only CloudFront can access the S3 bucket. For premium content, use signed URLs or signed cookies. For additional security, enable WAF rules on the distribution.

4. **What is cache invalidation and when would you use it?**
   > Forces CloudFront to discard cached content and fetch fresh from origin. Use after deployments. But it costs money — better approach: use versioned file names (`app-v2.3.js`) so URLs change naturally.

5. **Explain Lambda@Edge with a real use case.**
   > Code that runs at CloudFront edge locations. Example: Resize images on-the-fly based on device. Mobile user gets 480px image, desktop gets 1920px — from the same URL. Saves bandwidth and improves UX.

6. **How would you set up CloudFront for a web application with both static and dynamic content?**
   > Create behaviors: `/api/*` → ALB origin (TTL 0, forward all headers), `/static/*` → S3 origin (TTL 30 days, compression enabled), default → S3 (TTL 1 day). This ensures APIs are always fresh while static files are cached.

7. **What is the difference between CloudFront Functions and Lambda@Edge?**
   > CloudFront Functions: lightweight (< 1ms, 10KB code limit), viewer request/response only. Lambda@Edge: more powerful (up to 30s, 50MB), all four event types. Use CF Functions for simple redirects, Lambda@Edge for complex logic.

8. **How does CloudFront help with DDoS protection?**
   > CloudFront absorbs traffic at 400+ edge locations — spreading the attack across the globe instead of hitting one server. AWS Shield Standard is included free. You can add WAF rules for rate limiting and IP blocking.
