## MMSettings

All settings are accessed via `MMSettings.shared`, e.g. `MMSettings.shared.APP_ID = 1`.

### Required Settings

| Property | Type | Default | Info |
|----------------------------------|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|-----|
| APP_ID | Int | 1 | The App-ID that is used in the communication with the server. |
| DEFAULT_DOMAIN_ID | Int | 32 | The default domain-id that is used as default when fetching domains. |
| APP_NAME | String | "MM" | Name of the app. Is only used internally and should not contain spaces. |
| APP_TITLE | String | "Mängelmelder" | Title of the app that is shown on the initial screen. |
| REGISTRATION_PAGE_URL | String | "https://www.xn--mngelmelder-l8a.de/login" | The url for registration if the login module is enabled. |
| OVERRIDE_API_BASE_URL | String? | nil | If given, overrides the default base URL used for all API calls (see `MMApi.shared.SERVER_URL`). |

### Modules

| Property | Type | Default | Info |
|----------------------------------|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|-----|
| isLoginModuleActivated | Bool | false | Enables the Login module |
| isIdeaModuleActivated | Bool | false | Enables the Idea module |
| isManualOfflineModeActivated | Bool | false | Enables manual offline mode |
| isSammelcheckActivated | Bool | false | When activated an extra button for creating a message is shown (Sammelcheck) |
| isQRCodeActivated | Bool | false | When activated an extra button for creating a message via a QR code is shown |
| showRatingAfterUpload | Bool | false | When activated the rating popup is shown after uploading a message |
| showReportListButton | Bool | true | Show reports from map as list |
| showReportListButtonInMenu | Bool | false | Show menu item for report list in overview menu |
| localMapLayers | Array<(String, LocalLayer)> | [] | Defines local map layers loaded from `.geojson`/`.mbtiles` files. Each entry is (name shown in the layer chooser, `LocalLayer`). |
| offlineMaps | Array<DownloadableMap> | [] | Defines the list of downloadable offline map data. |
| mapLayers | Array<(Int, String, String, Double, String, String)> | [] | Map layers loaded in addition to the basemap: (id, name, tile-URL, transparency 0-1, map type "XYZ"/"WMS", layer name for WMS). |
| satelliteMapLayer | (Int, String, String, Double, String, String)? | nil | If set, overrides iOS MapKit's built-in satellite map with a custom layer (same tuple format as `mapLayers`). |
| defaultBaseMapType | MapType (`.streets`/`.satellite`) | .streets | The default basemap type. |
| offlineMapVersionCheckUrl | String | "" | URL used to check the offline map's version. |

### Create Report Settings

| Property | Type | Default | Info |
|----------------------------------|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|-----|
| showTypesFirst | Bool | false | When activated the position and type steps are switched when creating a message. |
| showGroupAsHeader | Bool | true | Show group names in table as header. |
| showSearchBarInTypes | Bool | false | Show a search bar on type selection. |
| showSearchBarInPosition | Bool | false | Show a search bar on position selection. |
| emptyCategoriesText | String | "An dieser Stelle ist keine Zuständigkeit hinterlegt, keine Meldung möglich." | Text shown when there is no category at the chosen position, so no message can be created. |
| messageInvalidPositionText | String | "" | Text shown for locations where it is not possible to create a message. Overrides the default value if set. |
| requireManualPositionUpdate | Bool | false | If true, the user has to press a button to update the position in the position step. |
| emptyPicturesText | NSAttributedString | "kein Foto hinzugefügt" | The text that is shown if no picture is added. |
| headerInAttributes | String? | localized `TABLE_HEADER_STEP_4` | Header shown above the attributes step. |

### Prefill Settings

| Property | Type | Default | Info |
|----------------------------------|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|-----|
| formEmail | String? | nil | The mail of the current user, used to prefill form fields. |
| formFirstName | String? | nil | The first name of the current user, used to prefill form fields. |
| formLastName | String? | nil | The last name of the current user, used to prefill form fields. |
| defaultMessageDescription | String | "" | Default text for the message description. |

### Message Detail Settings

| Property | Type | Default | Info |
|----------------------------------|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|-----|
| messageDetailsConfig | [(String, ReportDetails.Typ)] | [("Anfrage", .text), ("Typ", .typ), ("Status", .state), ("Datum", .date), ("Adresse", .address), ("Historie", .history)] | Defines the order and information shown on the message details screen. `ReportDetails.Typ` also has `.allow_comment`, `.message_type`, `.name`, `.state_german`, `.created`, `.attachments`, `.thumbnails`, `.sq256`. |
| isFinishOnCommentActivated | Bool | true | Enables the "report finished" switch on the comment view. |
| isPictureOnCommentActivated | Bool | true | Enables pictures on the comment view. |
| subscribeReportTyp | SubscriptionTyp (`.API`/`.EMail`) | .API | Defines the kind of subscription to a report used inside the app. Use `.API` to subscribe via the API, or `.EMail` to send a mail (also set `subscriptionMail`). |
| subscriptionMail | String? | nil | The mail address used for `SubscriptionTyp.EMail`. Must contain a placeholder `%d` for the ID of the report. |
| subscriptionButtonTitle | String? | nil | The button title for subscription via mail. |

### Menu Settings

| Property | Type | Default | Info |
|----------------------------------|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|-----|
| showProfileAvatarInMenu | Bool | false | If activated, the user's thumbnail (avatar) is shown in the menu. |
| showNewReportInMenu | Bool | false | If activated, shows a "New Report" button entry in the menu. |
| menuInfoPages | [InfoPage.Kind] | [.about, .terms, .privacy, .imprint] | The info pages that are shown in the menu, and in which order (more info below). |
| infoPages | [InfoPage] | about/terms/privacy/imprint/welcome, all `loadFromHTML: true` | Where to load the content for each info page from (more info below). |
| multipleAboutUsPages | [InfoPage] | [] | If you need multiple "about us" pages, put them here. Otherwise leave empty. |
| infoTextBottomMenu | NSAttributedString? | nil | Info text shown at the bottom part of the menu, above the version number. |
| linkTextBottomMenu | URL? | nil | If given, the info text at the bottom of the menu opens this URL when tapped. |

### Other Settings

| Property | Type | Default | Info |
|----------------------------------|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|-----|
| maximumMarker | Int | 50 | Maximum number of markers shown on the map at once. |
| onlyShowDefaultDomain | Bool | false | When activated, only the default domain is shown. |
| noPositionHintText | String | "" | Hint text shown when no user position is available during login. If empty, no hint is shown. |
| isLoginRequired | Bool | false | When activated a login is required to send a message (login module needs to be active). |
| showBlueStatus | Bool | false | When activated the filter for the blue status is shown. |
| loadDomainBeforeReports | Bool | false | Whether the domain is required before loading reports. |
| showWelcomeOnFirstStart | Bool | true | If true, the welcome page is shown on first start. |
| parentNavigationController | UINavigationController? | nil | If the Mängelmelder module is embedded in another `UINavigationController`, it can be passed here so that it is used for navigation instead of the internal one. |
| customTypeSelectionStoryboard | UIStoryboard? | nil | Custom storyboard for type selection. |
| customMyMessagesController | UIViewController? | nil | Custom view controller for "my messages". |
| showMapTypeButtonOnMainMap | Bool | false | Show a map type button on the main map to switch between satellite and street view. |
| customCategoryConfig | CustomCategoryConfig? | nil | Custom category config, see `CategoryConfig.swift`. |
| useBasicAuthentication | Bool | false | Whether to use HTTP Basic authentication for API requests. |
| basicAuthenticationUsername | String? | nil | Basic auth username (used when `useBasicAuthentication` is true). |
| basicAuthenticationPassword | String? | nil | Basic auth password (used when `useBasicAuthentication` is true). |
| checkIfAnyCategoryExistsOnPosition | Bool | false | If enabled, checks whether the given position has any category after choosing the position. |
| disableCategoryCheckOnPosition | Bool | false | If enabled, it will NOT check if the category exists at the chosen position. |
| versionNameSuffix | String | "" | Appended to the "appv" parameter sent to the server. |
| showAppIconOnWebViewNavigationBar | Bool | false | If true, shows the app icon on the right button bar of the navigation view. The app icon should be an image asset named `mm_app_icon`. |
| validateQRCode | (String) -> Bool | `{ _ in return false }` | The method used to validate QR codes when scanned via the app. |

### Side Menu

To change the banner on top of the side menu create an asset with the name `mm_menu_banner`. This will be used instead of the default one.

### Info pages

You can choose the info pages that are shown in the menu, and their order, via the setting `menuInfoPages` (an array of `InfoPage.Kind`).

Currently there are the following possible kinds:

- ABOUT
- IMPRINT
- PRIVACY
- TERMS
- WELCOME
- FAQ
- BARRIERE
- SAMMELCHECK
- ABOUT_US
- MORE
- USAGE_HELP
- RESET_TUTORIAL

For each kind shown in `menuInfoPages`, add a corresponding `InfoPage` entry to `infoPages` to define where its content comes from:

```swift
MMSettings.shared.infoPages = [
    InfoPage(type: .about, loadFromHTML: true),
    InfoPage(type: .terms, loadFromHTML: false, url: "https://example.com/terms")
]
```

If `loadFromHTML` is `true`, the library looks for a bundled HTML file named `<page>_<appname>.html` (lowercase), e.g. `about_mm.html` for `APP_NAME = "MM"`. Otherwise, set `url` to load the content from a remote address.
