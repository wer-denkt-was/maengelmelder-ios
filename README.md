# About the Library

Mängelmelder ("defect reporter") is an app used by municipalities that lets citizens report defects in public infrastructure (e.g. damaged streetlights, potholes, illegal dumping), track the status of their own reports, and browse reports from others on a map.

This repository contains the complete Mängelmelder App as an SPM Package that you can incorporate into your own application.

## Using the library in an XCode project

Add the library via SPM to the project (using git).

## Customizing your Mängelmelder library

The library comes with plenty of customization options, some are mandatory for it to function correctly.

### Starting the library's Mängelmelder controller

To start the Mängelmelder controller, you need to set up some variables first before launching it
```swift
MMSettings.shared.APP_ID = <appid>
MMSettings.shared.APP_NAME = "Custom"
MMSettings.shared.APP_TITLE = "App+MM"
MMSettings.shared.DEFAULT_DOMAIN_ID = <domainid>
// Start the controller
self.present(MM.shared.start()!, animated: true)
```
Complete list of settings can be found [here](readme_settings.md)

### Styling the Mängelmelder module

The module also comes with various styling parameters such as colors, banners, etc. that can be customized from the main App. See [Styling guide](readme_styling.md) for more information

### Using the API without the UI

You can use the API without using the UI. A documentation for this matter can be found [here](readme_api.md)

## License

This project is licensed under the European Union Public Licence v. 1.2 (EUPL-1.2) - see the [LICENSE](LICENSE) file for details.
