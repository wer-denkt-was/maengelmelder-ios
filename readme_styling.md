## Styling the Mängelmelder module

### Banners

The banner shown in left Menu can be changed by adding a `mm_menu_banner` asset to the project.

### Colors

Color overriding can be done through the `MMColorScheme` class. For each type of view you need to set two colors: One for normal mode and one for dark mode.

`MMColorScheme.shared.set(MMColorScheme.MMColor(normal: .white, dark: .white), for: .appTheme)`

The list of values:

| Code                                  | default color | Used in |
|---------------------------------------|---------------|-------------------------------------------------------------------------------------------|
| appTheme   | darkBlue | The base color, that is used where no other color type fits. |
| secondaryAppTheme | cyan | The accent color, that is used where no other accent color type fits. |
| barTint   | darkblue | The color for toolbar and navigationbar |
| tint | white | The tint color for the diffrent icons. |
| titleText | white | The color for all titles |
| inputText | black | The color for all user inputs |
| inputBg | lightGray | The color for the input views in the attributes step. |
| normalText | white | The color for all normal texts |
| buttonTitleText | white | The color for all text on buttons |
| buttonBg | darkBlue | The color of the background from buttons |
| tableViewCellText | black | the color of the text in tableviewcells |
| tableViewHeaderBg | white | the color of the header in report types and attributes |
| tutorialBg | cyan | The color of the background in the tutorial |
| tutorialText | white | The color of the text in the tutorial |
| menuHeaderBg | white | The color of the background of the banner in the menu |
