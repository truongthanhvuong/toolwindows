Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

Describe "Software Tab Visibility & Layout Render Tests" {
    It "should successfully switch from Office to Software and layout without XamlParseException" {
        $xamlPath = "e:\toolwindows\src\UI\MainWindow.xaml"
        $xamlContent = [System.IO.File]::ReadAllText($xamlPath, [System.Text.Encoding]::UTF8)
        $xamlClean = $xamlContent -replace 'x:Class="[^"]*"', ''
        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlClean))
        $window = [System.Windows.Markup.XamlReader]::Load($reader)

        $pageOffice = $window.FindName("pageOffice")
        $pageSoftware = $window.FindName("pageSoftware")

        $window.Show()

        # Switch to Office first
        $pageSoftware.Visibility = [System.Windows.Visibility]::Collapsed
        $pageOffice.Visibility = [System.Windows.Visibility]::Visible
        $window.UpdateLayout()

        # Switch to Software - should NOT throw any layout/template exception
        {
            $pageOffice.Visibility = [System.Windows.Visibility]::Collapsed
            $pageSoftware.Visibility = [System.Windows.Visibility]::Visible
            $window.UpdateLayout()
        } | Should Not Throw

        $pageSoftware.Visibility | Should Be ([System.Windows.Visibility]::Visible)
        $pageOffice.Visibility | Should Be ([System.Windows.Visibility]::Collapsed)

        $window.Close()
    }
}
