<#
================================================================================
  VUONGTT TOOL PRO 2026 - SHORTCUT BOOTSTRAPPER (WIN ALIAS)
  irm https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/win.ps1 | iex
================================================================================
#>
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 -bor [Net.SecurityProtocolType]::Tls
& { irm "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/vuongtt.ps1" | iex }
