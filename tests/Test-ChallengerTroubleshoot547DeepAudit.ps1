# ==============================================================================
# Test-ChallengerTroubleshoot547DeepAudit.ps1
# EMPIRICAL CHALLENGER STRESS HARNESS: IT Helpdesk 547 Issues & Troubleshoot Engine
# ==============================================================================

$ErrorActionPreference = "Continue"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ">>> EMPIRICAL CHALLENGE HARNESS: IT HELPDESK 547 ISSUES & ENGINE <<<" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$PassedCount = 0
$FailedCount = 0
$TestResults = @()

function Assert-Test {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Details = ""
    )
    if ($Condition) {
        $script:PassedCount++
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $script:TestResults += [PSCustomObject]@{ Test = $TestName; Status = "PASS"; Details = $Details }
    } else {
        $script:FailedCount++
        Write-Host "  [FAIL] $TestName" -ForegroundColor Red
        if ($Details) {
            Write-Host "         -> $Details" -ForegroundColor Yellow
        }
        $script:TestResults += [PSCustomObject]@{ Test = $TestName; Status = "FAIL"; Details = $Details }
    }
}

# ------------------------------------------------------------------------------
# SECTION 1: TroubleshootDatabase.json Deep Integrity & Schema Stress Test
# ------------------------------------------------------------------------------
Write-Host "`n--- SECTION 1: TroubleshootDatabase.json Deep Schema Audit ---" -ForegroundColor Yellow

$dbPath = "$PSScriptRoot\..\src\Data\TroubleshootDatabase.json"
Assert-Test "Database file exists at src\Data\TroubleshootDatabase.json" (Test-Path $dbPath)

$jsonRaw = Get-Content -Raw -Encoding UTF8 -Path $dbPath
Assert-Test "Database file is non-empty (>100KB)" ($jsonRaw.Length -gt 100000) "Length: $($jsonRaw.Length) bytes"

$db = $null
try {
    $db = $jsonRaw | ConvertFrom-Json
    Assert-Test "Database parses cleanly from JSON without syntax errors" ($null -ne $db)
} catch {
    Assert-Test "Database parses cleanly from JSON without syntax errors" $false $_.Exception.Message
}

if ($db) {
    # 1.1 Category Count
    $catCount = if ($db.Categories) { $db.Categories.Count } else { 0 }
    Assert-Test "Category count is exactly 7" ($catCount -eq 7) "Found: $catCount"

    # 1.2 Problem Count
    $probCount = if ($db.Problems) { $db.Problems.Count } else { 0 }
    Assert-Test "Problem count is exactly 547" ($probCount -eq 547) "Found: $probCount"

    # 1.3 Uniqueness of Problem IDs
    $ids = $db.Problems | ForEach-Object { $_.Id }
    $uniqueIds = $ids | Select-Object -Unique
    Assert-Test "All problem IDs are unique (no duplicates)" ($uniqueIds.Count -eq $probCount) "Unique: $($uniqueIds.Count) vs Total: $probCount"

    # 1.4 Required Schema Fields on EVERY single problem
    $requiredFields = @("Id", "Category", "SubCategory", "TargetPage", "Title", "ErrorCode", "Symptoms", "Cause", "Diagnosis", "Fix", "Verification", "Escalation")
    $missingFieldIssues = @()
    $emptyFieldIssues = @()

    foreach ($p in $db.Problems) {
        foreach ($f in $requiredFields) {
            $val = $p.$f
            if ($null -eq $val) {
                $missingFieldIssues += "Problem $($p.Id) missing field $f"
            } elseif ($f -ne "Escalation" -and ([string]$val).Trim() -eq "") {
                $emptyFieldIssues += "Problem $($p.Id) has empty string for $f"
            }
        }
        # Check Escalation is an array and non-empty
        if ($null -ne $p.Escalation) {
            if ($p.Escalation.Count -eq 0) {
                $emptyFieldIssues += "Problem $($p.Id) has empty Escalation array"
            }
        }
    }

    Assert-Test "Zero missing schema fields across all 547 problems" ($missingFieldIssues.Count -eq 0) "Issues: $($missingFieldIssues.Count)"
    Assert-Test "Zero empty/blank critical fields across all 547 problems" ($emptyFieldIssues.Count -eq 0) "Issues: $($emptyFieldIssues.Count)"

    # 1.5 Category Distribution: All 7 categories must be represented
    $catGroups = $db.Problems | Group-Object -Property Category
    Assert-Test "Problems cover all 7 distinct categories" ($catGroups.Count -eq 7) "Represented categories: $($catGroups.Count)"
    foreach ($grp in $catGroups) {
        Write-Host "       Category [$($grp.Name)]: $($grp.Count) problems" -ForegroundColor Gray
    }
}

# ------------------------------------------------------------------------------
# SECTION 2: TroubleshootManager.ps1 Parameter Validation Stress Test
# ------------------------------------------------------------------------------
Write-Host "`n--- SECTION 2: TroubleshootManager.ps1 Parameter Validation Stress Test ---" -ForegroundColor Yellow

$mgrPath = "$PSScriptRoot\..\src\Core\TroubleshootManager.ps1"
Assert-Test "TroubleshootManager.ps1 exists" (Test-Path $mgrPath)

if (Test-Path $mgrPath) {
    . $mgrPath
    $initOk = Initialize-VUONGTTTroubleshootEngine
    Assert-Test "Initialize-VUONGTTTroubleshootEngine executes successfully" ($initOk -eq $true)

    # 2.1 Valid ActionTypes must NOT throw parameter validation exceptions
    $validActions = @("Diagnosis", "Fix", "Verify", "Escalation")
    foreach ($act in $validActions) {
        $caughtEx = $null
        try {
            $res = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-001" -ActionType $act
            $actionPass = ($null -ne $res) -and ($res.ContainsKey("Success")) -and ($res.ContainsKey("StatusText"))
            Assert-Test "Invoke-VUONGTTTroubleshootAction accepts ActionType '$act' without parameter error" $actionPass
        } catch {
            Assert-Test "Invoke-VUONGTTTroubleshootAction accepts ActionType '$act' without parameter error" $false $_.Exception.Message
        }
    }

    # 2.2 Invalid ActionTypes ('Remediation', 'Verification') MUST be rejected by ValidateSet
    $invalidActionRejected = $false
    try {
        Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-001" -ActionType "Remediation" -ErrorAction Stop
    } catch {
        $invalidActionRejected = ($_.Exception.Message -like "*ValidateSet*" -or $_.FullyQualifiedErrorId -like "*Validation*")
    }
    Assert-Test "ActionType 'Remediation' is strictly rejected by ValidateSet (Confirms bug fix rationale)" $invalidActionRejected

    $invalidActionRejected2 = $false
    try {
        Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-001" -ActionType "Verification" -ErrorAction Stop
    } catch {
        $invalidActionRejected2 = ($_.Exception.Message -like "*ValidateSet*" -or $_.FullyQualifiedErrorId -like "*Validation*")
    }
    Assert-Test "ActionType 'Verification' is strictly rejected by ValidateSet (Confirms bug fix rationale)" $invalidActionRejected2

    # 2.3 Non-existent ProblemId handling: Must return Success = $false gracefully, not crash
    $nonExistentRes = Invoke-VUONGTTTroubleshootAction -ProblemId "NON_EXISTENT_ISSUE_999" -ActionType "Diagnosis"
    $gracefulFailure = ($null -ne $nonExistentRes) -and ($nonExistentRes.Success -eq $false) -and ($nonExistentRes.StatusText -like "*NON_EXISTENT_ISSUE_999*")
    Assert-Test "Non-existent ProblemId handled gracefully without crash" $gracefulFailure "Status: $($nonExistentRes.StatusText)"
}

# ------------------------------------------------------------------------------
# SECTION 3: Live PowerShell Execution across all 7 Categories
# ------------------------------------------------------------------------------
Write-Host "`n--- SECTION 3: Live Execution Across All 7 Categories ---" -ForegroundColor Yellow

if ($db -and (Test-Path $mgrPath)) {
    # Pick representative problems from each category
    $sampleProblems = @(
        @{ Cat = "HieuNang"; Id = "PERF-001"; Name = "Cat 1: He thong cham chap" },
        @{ Cat = "HieuNang"; Id = "PERF-012"; Name = "Cat 1: TiWorker high CPU" },
        @{ Cat = "Mang";     Id = "NET-001";  Name = "Cat 2: Mat ket noi mang" },
        @{ Cat = "Mang";     Id = "NET-024";  Name = "Cat 2: TCP/IP Winsock" },
        @{ Cat = "MayIn";    Id = "PRINT-001"; Name = "Cat 3: Spooler crash" },
        @{ Cat = "BaoMat";   Id = "SEC-001";   Name = "Cat 4: Windows Security" },
        @{ Cat = "Office";   Id = "OFFICE-001"; Name = "Cat 5: Office khoi dong cham" },
        @{ Cat = "UngDung";  Id = "APP-001";    Name = "Cat 6: Ung dung treo/crash" },
        @{ Cat = "ThietBi";  Id = "AUDIO-001";  Name = "Cat 7: Mat tieng/Audio service" }
    )

    foreach ($sp in $sampleProblems) {
        $id = $sp.Id
        $label = $sp.Name

        # Diagnosis
        $diagRes = Invoke-VUONGTTTroubleshootAction -ProblemId $id -ActionType "Diagnosis"
        $diagValid = ($null -ne $diagRes) -and ($diagRes.Success -eq $true) -and ([string]$diagRes.OutputDetails).Length -gt 10
        Assert-Test "[$id] Diagnosis execution ($label)" $diagValid "Details length: $(($diagRes.OutputDetails).Length)"

        # Verify
        $verRes = Invoke-VUONGTTTroubleshootAction -ProblemId $id -ActionType "Verify"
        $verValid = ($null -ne $verRes) -and ($verRes.Success -eq $true) -and ([string]$verRes.OutputDetails).Length -gt 10
        Assert-Test "[$id] Verify execution ($label)" $verValid "Details length: $(($verRes.OutputDetails).Length)"
    }
}

# ------------------------------------------------------------------------------
# SECTION 4: Rust Backend Bridge Contract Simulation
# ------------------------------------------------------------------------------
Write-Host "`n--- SECTION 4: Rust Backend Bridge Invocation Simulation ---" -ForegroundColor Yellow

$testProbId = "PERF-001"
$rustPsCodeDiagnosis = @"
if (Test-Path 'src\Core\TroubleshootManager.ps1') {
    . 'src\Core\TroubleshootManager.ps1'
    Initialize-VUONGTTTroubleshootEngine | Out-Null
    `$res = Invoke-VUONGTTTroubleshootAction -ProblemId '$testProbId' -ActionType 'Diagnosis'
    Write-Output "RESULT:`$(`$res.Success):`$(`$res.StatusText)``n``n`$(`$res.OutputDetails)"
} else {
    Write-Output "RESULT:True:Fallback"
}
"@

$rustPsCodeFix = @"
if (Test-Path 'src\Core\TroubleshootManager.ps1') {
    . 'src\Core\TroubleshootManager.ps1'
    Initialize-VUONGTTTroubleshootEngine | Out-Null
    `$res = Invoke-VUONGTTTroubleshootAction -ProblemId '$testProbId' -ActionType 'Fix'
    Write-Output "RESULT:`$(`$res.Success):`$(`$res.StatusText)``n``n`$(`$res.OutputDetails)"
} else {
    Write-Output "RESULT:True:Fallback"
}
"@

$rustPsCodeVerify = @"
if (Test-Path 'src\Core\TroubleshootManager.ps1') {
    . 'src\Core\TroubleshootManager.ps1'
    Initialize-VUONGTTTroubleshootEngine | Out-Null
    `$res = Invoke-VUONGTTTroubleshootAction -ProblemId '$testProbId' -ActionType 'Verify'
    Write-Output "RESULT:`$(`$res.Success):`$(`$res.StatusText)``n``n`$(`$res.OutputDetails)"
} else {
    Write-Output "RESULT:True:Fallback"
}
"@

$diagOut = powershell -NoProfile -ExecutionPolicy Bypass -Command $rustPsCodeDiagnosis
$diagContractOk = ($diagOut -match "^RESULT:True:") -and ($diagOut -notmatch "RESULT:True:`$")
Assert-Test "Rust bridge 'diagnose_problem' outputs valid RESULT format with live status" $diagContractOk "Output snippet: $($diagOut | Select-Object -First 2 | Out-String)"

$fixOut = powershell -NoProfile -ExecutionPolicy Bypass -Command $rustPsCodeFix
$fixContractOk = ($fixOut -match "^RESULT:True:") -and ($fixOut -notmatch "RESULT:True:`$")
Assert-Test "Rust bridge 'fix_problem' outputs valid RESULT format with live status" $fixContractOk "Output snippet: $($fixOut | Select-Object -First 2 | Out-String)"

$verifyOut = powershell -NoProfile -ExecutionPolicy Bypass -Command $rustPsCodeVerify
$verifyContractOk = ($verifyOut -match "^RESULT:True:") -and ($verifyOut -notmatch "RESULT:True:`$")
Assert-Test "Rust bridge 'verify_problem' outputs valid RESULT format with live status" $verifyContractOk "Output snippet: $($verifyOut | Select-Object -First 2 | Out-String)"

# ------------------------------------------------------------------------------
# SECTION 5: UI Elements & Event Handlers Audit
# ------------------------------------------------------------------------------
Write-Host "`n--- SECTION 5: Frontend UI & Event Handlers Audit ---" -ForegroundColor Yellow

$htmlPath = "$PSScriptRoot\..\src-ui\index.html"
$jsPath = "$PSScriptRoot\..\src-ui\app.js"

if ((Test-Path $htmlPath) -and (Test-Path $jsPath)) {
    $htmlContent = Get-Content -Raw -Encoding UTF8 -Path $htmlPath
    $jsContent = Get-Content -Raw -Encoding UTF8 -Path $jsPath

    # HTML elements
    $requiredDoms = @(
        "view-helpdesk-troubleshoot",
        "helpdeskProblemList",
        "helpdeskSearchInput",
        "helpdeskCategoryFilter",
        "btnHelpdeskDiagnose",
        "btnHelpdeskAutoFix",
        "btnHelpdeskVerify",
        "btnHelpdeskReport",
        "helpdeskActionOutput"
    )

    foreach ($dom in $requiredDoms) {
        Assert-Test "index.html contains #$dom" ($htmlContent.Contains($dom))
    }

    # JS event bindings
    Assert-Test "app.js binds btnHelpdeskDiagnose" ($jsContent.Contains("btnHelpdeskDiagnose"))
    Assert-Test "app.js binds btnHelpdeskAutoFix" ($jsContent.Contains("btnHelpdeskAutoFix"))
    Assert-Test "app.js binds btnHelpdeskVerify" ($jsContent.Contains("btnHelpdeskVerify"))
    Assert-Test "app.js binds btnHelpdeskReport" ($jsContent.Contains("btnHelpdeskReport"))

    # Exclusion guards against catch-all button interceptor
    $guard1 = $jsContent.Contains('btn.closest("#view-helpdesk-troubleshoot")')
    Assert-Test "app.js has exclusion guard for #view-helpdesk-troubleshoot" $guard1
    
    # Rust bridge action names in app.js
    Assert-Test "app.js dispatches 'diagnose_problem'" ($jsContent.Contains("diagnose_problem"))
    Assert-Test "app.js dispatches 'fix_problem' or 'autofix_problem'" ($jsContent.Contains("fix_problem") -or $jsContent.Contains("autofix_problem"))
    Assert-Test "app.js dispatches 'verify_problem'" ($jsContent.Contains("verify_problem"))
}

# ------------------------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------------------------
$summaryColor = if ($FailedCount -eq 0) { "Green" } else { "Red" }
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ">>> EMPIRICAL CHALLENGE SUMMARY: $PassedCount PASSED, $FailedCount FAILED <<<" -ForegroundColor $summaryColor
Write-Host "======================================================================" -ForegroundColor Cyan

if ($FailedCount -eq 0) {
    Write-Host "`n[CHALLENGE VERDICT: APPROVE] - 100% Empirical Tests Passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[CHALLENGE VERDICT: CHALLENGE_FAILED] - Found $FailedCount failures." -ForegroundColor Red
    exit 1
}
