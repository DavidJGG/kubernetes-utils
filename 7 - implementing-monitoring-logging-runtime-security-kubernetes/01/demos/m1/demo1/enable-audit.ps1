# Enable audit logging by replacing the policy and restarting k3s

kubectl delete -f log-reader.yaml 2>$null
Write-Host "Enabling audit logging..." -ForegroundColor Cyan

# Copy the real audit policy to the mounted directory
Write-Host "`nApplying audit policy..." -ForegroundColor Yellow
Copy-Item -Path audit-policy.yaml -Destination audit/audit-policy.yaml -Force

# Create the audit log directory
docker exec k3d-m1-demo1-server-0 mkdir -p /var/log/kubernetes/audit

# Restart k3s to pick up the new policy
# Note: Send SIGHUP directly to k3s process, not PID 1 (docker-init doesn't forward signals properly)
Write-Host "Restarting API server..." -ForegroundColor Yellow
docker exec k3d-m1-demo1-server-0 sh -c 'kill -HUP $(ps aux | grep "/bin/k3s server" | grep -v grep | awk "{print \$1}")'

# Wait for API server to be ready
Write-Host "Waiting for API server..." -ForegroundColor Yellow
Start-Sleep -Seconds 20
kubectl wait --for=condition=Ready nodes --all --timeout=60s

# Redeploy log-reader pod (lost during restart)
Write-Host "Redeploying log-reader pod..." -ForegroundColor Yellow
kubectl apply -f log-reader.yaml
kubectl wait --for=condition=Ready pod/log-reader -n kube-system --timeout=60s

Write-Host "`nAudit logging enabled!" -ForegroundColor Green
