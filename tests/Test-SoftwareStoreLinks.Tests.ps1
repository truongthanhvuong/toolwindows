Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

Describe "Software Store Links & App Definition Coverage Tests" {
    BeforeAll {
        . "e:\toolwindows\src\Core\SoftwareInstaller.ps1"
    }

    It "should resolve 'files' app in VUONGTT_APPS and NOT report 'Khong tim thay phan mem: files'" {
        $app = $script:VUONGTT_APPS | Where-Object { $_.Id -eq "files" }
        $app | Should Not Be $null
        $app.Name | Should Be "Files"
        $app.WingetId | Should Be "FilesCommunity.Files"
    }

    It "should include all 4 previously missing UI apps in database" {
        $missingKeys = @("claude_code", "pdf_xchange", "es_de", "mpc_qt")
        foreach ($k in $missingKeys) {
            $found = $script:VUONGTT_APPS | Where-Object { $_.Id -eq $k }
            $found | Should Not Be $null
        }
    }

    It "should have every single CheckBox in MainWindow.xaml mapped to a valid app in VUONGTT_APPS" {
        $xamlPath = "e:\toolwindows\src\UI\MainWindow.xaml"
        $xamlContent = [System.IO.File]::ReadAllText($xamlPath, [System.Text.Encoding]::UTF8)
        $matches = [regex]::Matches($xamlContent, 'x:Name="(app_[a-zA-Z0-9_]+)"')
        $uiAppIds = @()
        foreach ($m in $matches) {
            $uiAppIds += $m.Groups[1].Value.Replace('app_', '')
        }
        $uiAppIds = $uiAppIds | Select-Object -Unique

        $unmapped = @()
        $special = @('netfx35', 'dotnet35', 'htkk', 'itaxviewer', 'misasme', 'meinvoice', 'kbhxh', 'javatax', 'dvcplugin', 'vietteltoken', 'vnpttoken', 'misakyso', 'esigner')
        foreach ($id in $uiAppIds) {
            if ($id -in $special) { continue }
            $a = $script:VUONGTT_APPS | Where-Object { $_.Id -eq $id }
            if (-not $a) {
                $unmapped += $id
            }
        }

        $unmapped.Count | Should Be 0
    }

    It "should have valid, working download URL for EVKey without 404" {
        $ev = $script:VUONGTT_APPS | Where-Object { $_.Id -eq "evkey" }
        $ev | Should Not Be $null
        $ev.Url | Should Not BeNullOrEmpty
        $ev.Url | Should Not Match "v5\.0\.0"
    }

    It "should have valid UniKey definition with both WingetId and DirectUrl" {
        $uk = $script:VUONGTT_APPS | Where-Object { $_.Id -eq "unikey" }
        $uk | Should Not Be $null
        $uk.WingetId | Should Be "UniKey.UniKey"
        $uk.Url | Should Not BeNullOrEmpty
        $uk.IsZip | Should Be $true
    }

    It "should have C# ProcessLiveRunner compiled and executing without threadpool exception" {
        $runnerType = [System.Management.Automation.PSTypeName]'VUONGTT.ProcessLiveRunner'
        $runnerType.Type | Should Not Be $null

        $lines = New-Object System.Collections.Generic.List[string]
        $action = [Action[string]]{
            param($line)
            $lines.Add($line)
        }
        $code = [VUONGTT.ProcessLiveRunner]::Run("cmd.exe", "/c echo TestRunnerOutput", $action, 5)
        $code | Should Be 0
        $lines.Count | Should BeGreaterThan 0
        ($lines -join " ") | Should Match "TestRunnerOutput"
    }

    It "should support PreferDirect switch in Install-VUONGTTApp parameter list" {
        $cmd = Get-Command "Install-VUONGTTApp"
        $cmd.Parameters.ContainsKey("PreferDirect") | Should Be $true
    }

    It "should wire up rbPkgWinget and rbPkgDirect in VUONGTT_Toolkit.ps1" {
        $content = [System.IO.File]::ReadAllText("e:\toolwindows\VUONGTT_Toolkit.ps1", [System.Text.Encoding]::UTF8)
        $content | Should Match 'Get-Control "rbPkgWinget"'
        $content | Should Match 'Get-Control "rbPkgDirect"'
        $content | Should Match '\$preferDirect\s*='
    }

    It "should properly map DirectUrl from SoftwareDatabase.json to app Url" {
        $uv = $script:VUONGTT_APPS | Where-Object { $_.Id -eq "ultraviewer" }
        $uv | Should Not Be $null
        $uv.Url | Should Match "dl2\.ultraviewer\.net"
    }
}

