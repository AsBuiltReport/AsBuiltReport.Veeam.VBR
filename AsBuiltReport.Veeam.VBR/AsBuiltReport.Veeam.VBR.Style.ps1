# Veeam Official Color Palette — https://www.veeam.com/company/brand-resource-center.html
# Primary:       Viridis      #00D15F | Black  #000000 | White  #FFFFFF
# Complementary: Pine         #007F49 | Dark Mineral #505861 | French Grey #ADACAF | Fog #F0F0F0
#                Lime         #9CFFA3 | Mint   #32F26F
# Secondary:     Sol          #FFD839 | Suma   #FE8A25 | Sky    #57E0FF | Ignis  #ED2B3D

# Veeam Default Heading and Font Styles
Style -Name 'Title' -Size 24 -Color '007F49' -Align Center
Style -Name 'Title 2' -Size 18 -Color '505861' -Align Center
Style -Name 'Title 3' -Size 12 -Color '505861' -Align Left
Style -Name 'Heading 1' -Size 16 -Color '007F49'
Style -Name 'NO TOC Heading 1' -Size 16 -Color '007F49'
Style -Name 'Heading 2' -Size 14 -Color '007F49'
Style -Name 'NO TOC Heading 2' -Size 14 -Color '007F49'
Style -Name 'Heading 3' -Size 12 -Color '007F49'
Style -Name 'NO TOC Heading 3' -Size 12 -Color '007F49'
Style -Name 'Heading 4' -Size 11 -Color '007F49'
Style -Name 'NO TOC Heading 4' -Size 11 -Color '007F49'
Style -Name 'Heading 5' -Size 10 -Color '007F49'
Style -Name 'NO TOC Heading 5' -Size 10 -Color '007F49'
Style -Name 'Heading 6' -Size 10 -Color '007F49'
Style -Name 'NO TOC Heading 6' -Size 10 -Color '007F49'
Style -Name 'NO TOC Heading 7' -Size 10 -Color '00D15F' -Italic
Style -Name 'Normal' -Size 10 -Color '505861' -Default
# Header & Footer Styles
Style -Name 'Header' -Size 10 -Color '505861' -Align Center
Style -Name 'Footer' -Size 10 -Color '505861' -Align Center
# Table of Contents Style
Style -Name 'TOC' -Size 16 -Color '007F49'
# Table Heading & Row Styles
Style -Name 'TableDefaultHeading' -Size 10 -Color 'FFFFFF' -BackgroundColor '007F49'
Style -Name 'TableDefaultRow' -Size 10 -Color '505861'
# Table Row/Cell Highlight Styles  (tints derived from Veeam secondary palette)
Style -Name 'Critical' -Size 10 -Color '505861' -BackgroundColor 'FECDD1'
Style -Name 'Warning' -Size 10 -Color '505861' -BackgroundColor 'FFF3C4'
Style -Name 'Info' -Size 10 -Color '505861' -BackgroundColor 'D9F6FF'
Style -Name 'OK' -Size 10 -Color '505861' -BackgroundColor '9CFFA3'
# Table Caption Style
Style -Name 'Caption' -Size 10 -Color '007F49' -Italic -Align Left
# Veeam Backup Windows Time Period Table
Style -Name 'ON' -Size 8 -BackgroundColor '00D15F' -Color '00D15F'
Style -Name 'OFF' -Size 8 -BackgroundColor 'ADACAF' -Color 'ADACAF'

if ($Options.ReportStyle -eq 'Veeam') {
    $TableBorderColor = '007F49'
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