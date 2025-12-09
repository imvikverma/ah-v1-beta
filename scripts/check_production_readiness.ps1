# Production Readiness Checker for AurumHarmony
# Run this script to verify if the system is ready for production deployment

$ErrorActionPreference = "Continue"
$projectRoot = $PSScriptRoot + "\.."
Set-Location $projectRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Production Readiness Check" -ForegroundColor Cyan
Write-Host "  AurumHarmony System Audit" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$warnings = @()
$passed = @()

# ============================================
# 1. HYPERLEDGER FABRIC CHECKS
# ============================================
Write-Host "`n[1/6] Checking Hyperledger Fabric..." -ForegroundColor Yellow

# Check if gateway is a stub
$gatewayFile = "fabric\gateway\fabric_gateway.py"
if (Test-Path $gatewayFile) {
    $gatewayContent = Get-Content $gatewayFile -Raw
    if ($gatewayContent -match "TODO.*Fabric SDK" -or $gatewayContent -match "stub" -or $gatewayContent -match "Fabric SDK integration pending") {
        $issues += "❌ Fabric Gateway is still a stub - needs SDK implementation"
    } else {
        $passed += "✅ Fabric Gateway has SDK implementation"
    }
    
    if ($gatewayContent -match "debug=True") {
        $issues += "❌ Gateway running in debug mode - security risk"
    } else {
        $passed += "✅ Gateway debug mode disabled"
    }
} else {
    $issues += "❌ Fabric gateway file not found"
}

# Check if chaincode is deployed
$chaincodeDeployed = $false
try {
    $dockerPs = docker ps --filter "name=peer0.org1" --format "{{.Names}}" 2>&1
    if ($dockerPs -match "peer0.org1") {
        $chaincodeCheck = docker exec peer0.org1.example.com peer lifecycle chaincode querycommitted --channelID aurumchannel --name aurum_cc 2>&1
        if ($chaincodeCheck -match "Committed chaincode definition" -or $chaincodeCheck -match "Version:") {
            $chaincodeDeployed = $true
            $passed += "✅ Chaincode is deployed to network"
        } else {
            $issues += "❌ Chaincode not deployed - run deploy_chaincode.ps1"
        }
    } else {
        $warnings += "⚠️  Fabric network not running - cannot check chaincode deployment"
    }
} catch {
    $warnings += "⚠️  Could not check chaincode deployment status"
}

# Check Fabric network status
try {
    $fabricRunning = docker ps --filter "name=fabric-" --format "{{.Names}}" 2>&1
    if ($fabricRunning) {
        $peerCount = ($fabricRunning | Select-String "peer").Count
        $ordererCount = ($fabricRunning | Select-String "orderer").Count
        
        if ($peerCount -ge 2 -and $ordererCount -ge 1) {
            $passed += "✅ Fabric network is running ($peerCount peers, $ordererCount orderer)"
        } else {
            $warnings += "⚠️  Fabric network partially running (peers: $peerCount, orderers: $ordererCount)"
        }
    } else {
        $warnings += "⚠️  Fabric network not running (optional for development)"
    }
} catch {
    $warnings += "⚠️  Could not check Fabric network status"
}

# ============================================
# 2. SECURITY CHECKS
# ============================================
Write-Host "`n[2/6] Checking Security..." -ForegroundColor Yellow

# Check .env file security
if (Test-Path ".env") {
    $envContent = Get-Content ".env" -Raw
    if ($envContent -match "password.*=.*password" -or $envContent -match "secret.*=.*secret" -or $envContent -match "key.*=.*123") {
        $issues += "❌ Weak credentials detected in .env file"
    } else {
        $passed += "✅ .env file exists (verify credentials are strong)"
    }
} else {
    $warnings += "⚠️  .env file not found (may be using environment variables)"
}

# Check for hardcoded secrets
$pythonFiles = Get-ChildItem -Recurse -Include "*.py" -Exclude "*test*", "*__pycache__*" | Select-Object -First 20
$foundSecrets = $false
foreach ($file in $pythonFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match "api_key.*=.*['\"][a-zA-Z0-9]{20,}" -or $content -match "password.*=.*['\"][^'\"]{8,}") {
        $foundSecrets = $true
        break
    }
}
if ($foundSecrets) {
    $issues += "❌ Potential hardcoded secrets found in code"
} else {
    $passed += "✅ No obvious hardcoded secrets detected"
}

# Check CORS configuration
$backendFiles = Get-ChildItem -Recurse -Include "app.py", "*blueprint*.py" | Select-Object -First 5
$corsConfigured = $false
foreach ($file in $backendFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match "CORS" -or $content -match "cors") {
        $corsConfigured = $true
        break
    }
}
if ($corsConfigured) {
    $passed += "✅ CORS appears to be configured"
} else {
    $warnings += "⚠️  CORS configuration not found"
}

# ============================================
# 3. MONITORING & OBSERVABILITY
# ============================================
Write-Host "`n[3/6] Checking Monitoring..." -ForegroundColor Yellow

# Check for monitoring setup
$monitoringFiles = Get-ChildItem -Recurse -Include "*prometheus*", "*grafana*", "*monitoring*" -ErrorAction SilentlyContinue
if ($monitoringFiles) {
    $passed += "✅ Monitoring configuration files found"
} else {
    $warnings += "⚠️  No monitoring setup detected (Prometheus/Grafana)"
}

# Check for health check endpoints
$healthCheckFound = $false
$backendFiles = Get-ChildItem -Recurse -Include "*.py" | Where-Object { $_.FullName -match "app\.py|main\.py|gateway" } | Select-Object -First 10
foreach ($file in $backendFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match "/health" -or $content -match "health_check" -or $content -match "@app.route.*health") {
        $healthCheckFound = $true
        break
    }
}
if ($healthCheckFound) {
    $passed += "✅ Health check endpoints found"
} else {
    $warnings += "⚠️  Health check endpoints not found"
}

# ============================================
# 4. DATABASE & PERSISTENCE
# ============================================
Write-Host "`n[4/6] Checking Database & Persistence..." -ForegroundColor Yellow

# Check for database migration files
$migrationFiles = Get-ChildItem -Recurse -Include "*migration*", "*migrate*", "*schema*" -ErrorAction SilentlyContinue
if ($migrationFiles) {
    $passed += "✅ Database migration files found"
} else {
    $warnings += "⚠️  No database migration files found"
}

# Check for backup scripts
$backupFiles = Get-ChildItem -Recurse -Include "*backup*", "*restore*" -ErrorAction SilentlyContinue
if ($backupFiles) {
    $passed += "✅ Backup/restore scripts found"
} else {
    $warnings += "⚠️  No backup/restore scripts found"
}

# ============================================
# 5. DEPLOYMENT & CI/CD
# ============================================
Write-Host "`n[5/6] Checking Deployment..." -ForegroundColor Yellow

# Check for deployment scripts
$deployScripts = Get-ChildItem -Recurse -Include "*deploy*", "*ci*", "*cd*" -ErrorAction SilentlyContinue
if ($deployScripts) {
    $passed += "✅ Deployment scripts found"
} else {
    $warnings += "⚠️  No deployment scripts found"
}

# Check for GitHub Actions
if (Test-Path ".github\workflows") {
    $workflows = Get-ChildItem ".github\workflows" -ErrorAction SilentlyContinue
    if ($workflows) {
        $passed += "✅ GitHub Actions workflows found"
    } else {
        $warnings += "⚠️  GitHub Actions directory exists but no workflows"
    }
} else {
    $warnings += "⚠️  No GitHub Actions workflows found"
}

# ============================================
# 6. DOCUMENTATION
# ============================================
Write-Host "`n[6/6] Checking Documentation..." -ForegroundColor Yellow

# Check for key documentation files
$requiredDocs = @("README.md", "CHANGELOG.md")
$missingDocs = @()
foreach ($doc in $requiredDocs) {
    if (Test-Path $doc) {
        $passed += "✅ $doc exists"
    } else {
        $missingDocs += $doc
    }
}
if ($missingDocs.Count -gt 0) {
    $warnings += "⚠️  Missing documentation: $($missingDocs -join ', ')"
}

# Check for production readiness doc
if (Test-Path "fabric\PRODUCTION_READINESS.md") {
    $passed += "✅ Production readiness documentation exists"
} else {
    $warnings += "⚠️  Production readiness documentation not found"
}

# ============================================
# SUMMARY REPORT
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Production Readiness Report" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Calculate readiness score
$totalChecks = $issues.Count + $warnings.Count + $passed.Count
$criticalIssues = $issues.Count
$readinessScore = if ($totalChecks -gt 0) { [math]::Round(($passed.Count / $totalChecks) * 100) } else { 0 }

Write-Host "📊 Readiness Score: $readinessScore%" -ForegroundColor $(if ($readinessScore -ge 80) { "Green" } elseif ($readinessScore -ge 60) { "Yellow" } else { "Red" })
Write-Host ""

# Show passed checks
if ($passed.Count -gt 0) {
    Write-Host "✅ PASSED ($($passed.Count)):" -ForegroundColor Green
    foreach ($item in $passed) {
        Write-Host "   $item" -ForegroundColor Gray
    }
    Write-Host ""
}

# Show warnings
if ($warnings.Count -gt 0) {
    Write-Host "⚠️  WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($item in $warnings) {
        Write-Host "   $item" -ForegroundColor Gray
    }
    Write-Host ""
}

# Show critical issues
if ($issues.Count -gt 0) {
    Write-Host "❌ CRITICAL ISSUES ($($issues.Count)):" -ForegroundColor Red
    foreach ($item in $issues) {
        Write-Host "   $item" -ForegroundColor Gray
    }
    Write-Host ""
}

# Final verdict
Write-Host "========================================" -ForegroundColor Cyan
if ($criticalIssues -eq 0 -and $readinessScore -ge 80) {
    Write-Host "✅ PRODUCTION READY" -ForegroundColor Green
    Write-Host ""
    Write-Host "Minor warnings exist but no critical blockers." -ForegroundColor Gray
    Write-Host "Proceed with deployment after addressing warnings." -ForegroundColor Gray
} elseif ($criticalIssues -eq 0) {
    Write-Host "⚠️  MOSTLY READY" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "No critical issues, but several warnings to address." -ForegroundColor Gray
    Write-Host "Recommended: Fix warnings before production deployment." -ForegroundColor Gray
} else {
    Write-Host "❌ NOT PRODUCTION READY" -ForegroundColor Red
    Write-Host ""
    Write-Host "Critical issues must be resolved before production deployment." -ForegroundColor Gray
    Write-Host "See issues above and refer to:" -ForegroundColor Gray
    Write-Host "  - fabric/PRODUCTION_READINESS.md" -ForegroundColor Cyan
    Write-Host "  - fabric/FUTURE_IMPLEMENTATION_CHECKLIST.md" -ForegroundColor Cyan
}
Write-Host ""

# Recommendations
if ($issues.Count -gt 0 -or $warnings.Count -gt 5) {
    Write-Host "📋 Recommendations:" -ForegroundColor Cyan
    Write-Host ""
    
    if ($issues -match "Fabric Gateway") {
        Write-Host "   1. Implement Fabric SDK in gateway service" -ForegroundColor White
        Write-Host "      See: fabric/FUTURE_IMPLEMENTATION_CHECKLIST.md" -ForegroundColor Gray
        Write-Host ""
    }
    
    if ($issues -match "Chaincode") {
        Write-Host "   2. Deploy chaincode to Fabric network" -ForegroundColor White
        Write-Host "      Run: fabric\deploy_chaincode.ps1" -ForegroundColor Gray
        Write-Host ""
    }
    
    if ($issues -match "debug mode") {
        Write-Host "   3. Disable debug mode in gateway" -ForegroundColor White
        Write-Host "      Set debug=False in fabric_gateway.py" -ForegroundColor Gray
        Write-Host ""
    }
    
    if ($warnings -match "monitoring") {
        Write-Host "   4. Set up monitoring (Prometheus + Grafana)" -ForegroundColor White
        Write-Host "      Essential for production observability" -ForegroundColor Gray
        Write-Host ""
    }
    
    if ($warnings -match "backup") {
        Write-Host "   5. Implement backup and disaster recovery" -ForegroundColor White
        Write-Host "      Critical for data protection" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host ""

