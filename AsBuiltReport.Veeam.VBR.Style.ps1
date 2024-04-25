# Veeam Default Heading and Font Styles
Style -Name 'Title' -Size 24 -Color '005f4b' -Align Center
Style -Name 'Title 2' -Size 18 -Color '565656' -Align Center
Style -Name 'Title 3' -Size 12 -Color '565656' -Align Left
Style -Name 'Heading 1' -Size 16 -Color '005f4b'
Style -Name 'NO TOC Heading 1' -Size 16 -Color '005f4b'
Style -Name 'Heading 2' -Size 14 -Color '005f4b'
Style -Name 'NO TOC Heading 2' -Size 14 -Color '005f4b'
Style -Name 'Heading 3' -Size 12 -Color '005f4b'
Style -Name 'NO TOC Heading 3' -Size 12 -Color '005f4b'
Style -Name 'Heading 4' -Size 11 -Color '005f4b'
Style -Name 'NO TOC Heading 4' -Size 11 -Color '005f4b'
Style -Name 'Heading 5' -Size 10  -Color '005f4b'
Style -Name 'NO TOC Heading 5' -Size 10  -Color '005f4b'
Style -Name 'Heading 6' -Size 10 -Color '005f4b'
Style -Name 'NO TOC Heading 6' -Size 10 -Color '005f4b'
Style -Name 'NO TOC Heading 7' -Size 10 -Color '00EBCD' -Italic
Style -Name 'Normal' -Size 10 -Color '565656' -Default
# Header & Footer Styles
Style -Name 'Header' -Size 10 -Color '565656' -Align Center
Style -Name 'Footer' -Size 10 -Color '565656' -Align Center
# Table of Contents Style
Style -Name 'TOC' -Size 16 -Color '005f4b'
# Table Heading & Row Styles
Style -Name 'TableDefaultHeading' -Size 10 -Color 'FAFAFA' -BackgroundColor '005f4b'
Style -Name 'TableDefaultRow' -Size 10 -Color '565656'
# Table Row/Cell Highlight Styles
Style -Name 'Critical' -Size 10 -Color '565656' -BackgroundColor 'FEDDD7'
Style -Name 'Warning' -Size 10 -Color '565656' -BackgroundColor 'FFF4C7'
Style -Name 'Info' -Size 10 -Color '565656' -BackgroundColor 'E3F5FC'
Style -Name 'OK' -Size 10 -Color '565656' -BackgroundColor 'DFF0D0'
# Table Caption Style
Style -Name 'Caption' -Size 10 -Color '005f4b' -Italic -Align Left
# Veeam Backup Windows Time Period Table
Style -Name 'ON' -Size 8 -BackgroundColor 'DFF0D0' -Color DFF0D0
Style -Name 'OFF' -Size 8 -BackgroundColor 'FFF4C7' -Color FFF4C7

if ($Options.ReportStyle -eq 'Veeam') {
    $TableBorderColor = '005f4b'
} else {
    $TableBorderColor = '072E58'
}

# Configure Table Styles
$TableDefaultProperties = @{
    Id = 'TableDefault'
    HeaderStyle = 'TableDefaultHeading'
    RowStyle = 'TableDefaultRow'
    BorderColor = $TableBorderColor
    Align = 'Left'
    CaptionStyle = 'Caption'
    CaptionLocation = 'Below'
    BorderWidth = 0.25
    PaddingTop = 1
    PaddingBottom = 1.5
    PaddingLeft = 2
    PaddingRight = 2
}

TableStyle @TableDefaultProperties -Default
TableStyle -Id 'Borderless' -HeaderStyle Normal -RowStyle Normal -BorderWidth 0