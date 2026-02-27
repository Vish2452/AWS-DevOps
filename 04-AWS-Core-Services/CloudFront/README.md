# CloudFront — Content Delivery Network

> Global CDN for low-latency content delivery. Cache at 400+ edge locations worldwide.

## Key Concepts
- **Distribution** — CDN configuration (origin, behaviors, caching)
- **Origins** — S3, ALB, EC2, custom HTTP server
- **Behaviors** — path-based caching rules
- **Cache invalidation** — force refresh of cached content
- **OAC (Origin Access Control)** — secure S3 access (replaces OAI)
- **Lambda@Edge / CloudFront Functions** — edge compute

## Labs
```bash
# Create CloudFront distribution for S3
aws cloudfront create-distribution --distribution-config '{
    "CallerReference": "unique-ref-123",
    "Origins": {
        "Quantity": 1,
        "Items": [{
            "Id": "S3Origin",
            "DomainName": "my-bucket.s3.amazonaws.com",
            "S3OriginConfig": {"OriginAccessIdentity": ""}
        }]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3Origin",
        "ViewerProtocolPolicy": "redirect-to-https",
        "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6"
    },
    "Enabled": true
}'

# Invalidate cache
aws cloudfront create-invalidation --distribution-id DIST_ID \
    --paths "/index.html" "/css/*" "/js/*"
```
