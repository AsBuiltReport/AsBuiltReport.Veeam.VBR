# Veeam Default Document Style

# Configure document options
DocumentOption -EnableSectionNumbering -PageSize A4 -DefaultFont 'Arial' -MarginLeftAndRight 71 -MarginTopAndBottom 71 -Orientation $Orientation

# Configure Heading and Font Styles
Style -Name 'Title' -Size 24 -Color '54B948' -Align Center
Style -Name 'Title 2' -Size 18 -Color '565656' -Align Center
Style -Name 'Title 3' -Size 12 -Color '565656' -Align Left
Style -Name 'Heading 1' -Size 16 -Color '54B948' 
Style -Name 'Heading 2' -Size 14 -Color '54B948' 
Style -Name 'Heading 3' -Size 12 -Color '54B948' 
Style -Name 'Heading 4' -Size 11 -Color '54B948' 
Style -Name 'Heading 5' -Size 10 -Color '54B948'
Style -Name 'Normal' -Size 10 -Color '565656' -Default
Style -Name 'Caption' -Size 10 -Color '565656' -Italic -Align Center
Style -Name 'Header' -Size 10 -Color '565656' -Align Center
Style -Name 'Footer' -Size 10 -Color '565656' -Align Center
Style -Name 'TOC' -Size 16 -Color '54B948' 
Style -Name 'TableDefaultHeading' -Size 10 -Color 'FAFAFA' -BackgroundColor '54B948'
Style -Name 'TableDefaultRow' -Size 10 -Color '565656'
Style -Name 'Critical' -Size 10 -Color '565656' -BackgroundColor 'F5DBD9'
Style -Name 'Warning' -Size 10 -Color '565656' -BackgroundColor 'FEF3B5'
Style -Name 'Info' -Size 10 -Color '565656' -BackgroundColor 'E1F1F6'
Style -Name 'OK' -Size 10 -Color '565656' -BackgroundColor 'DFF0D0'

# Configure Table Styles
$TableDefaultProperties = @{
    Id = 'TableDefault'
    HeaderStyle = 'TableDefaultHeading'
    RowStyle = 'TableDefaultRow'
    BorderColor = '54B948'
    Align = 'Left'
    CaptionStyle = 'Caption'
    CaptionLocation = "Below" 
    BorderWidth = 0.25
    PaddingTop = 1
    PaddingBottom = 1.5
    PaddingLeft = 2
    PaddingRight = 2
}

TableStyle @TableDefaultProperties -Default
TableStyle -Id 'Borderless' -HeaderStyle Normal -RowStyle Normal -BorderWidth 0

# Veeam Cover Page Layout
# Header & Footer
Header -Default {
    Paragraph -Style Header "$($ReportConfig.Report.Name) - $($ReportConfig.Report.Version)"
}

Footer -Default {
    Paragraph -Style Footer 'Page <!# PageNumber #!>'
}

# Set position of report titles and information based on page orientation
if ($Orientation -eq 'Portrait') {
    BlankLine -Count 11
    $LineCount = 30
} else {
    BlankLine -Count 7
    $LineCount = 20
}

# Add Report Name
Paragraph -Style Title $ReportConfig.Report.Name

if ($AsBuiltConfig.Company.FullName) {
    # Add Company Name if specified
    Paragraph -Style Title2 $AsBuiltConfig.Company.FullName
    BlankLine -Count $LineCount
} else {
    BlankLine -Count ($LineCount + 1)
}
Table -Name 'Cover Page' -List -Style Borderless -Width 0 -Hashtable ([Ordered] @{
        'Author:' = $AsBuiltConfig.Report.Author
        'Date:' = (Get-Date).ToLongDateString()
        'Version:' = $ReportConfig.Report.Version
    })
PageBreak

# Add Table of Contents
TOC -Name 'Table of Contents'
PageBreak