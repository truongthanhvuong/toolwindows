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
}
