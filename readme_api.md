## API Request classes

### Preparation

Before using any API Requests, you need to set up the module parameters.
```swift
MMSettings.shared.APP_ID = <appid>
MMSettings.shared.APP_NAME = "Custom"
MMSettings.shared.APP_TITLE = "App+MM"
MMSettings.shared.DEFAULT_DOMAIN_ID = <domainid>
```

### Server URL

You can change the URL of the API via `MMApi.shared.SERVER_URL`.

### Authentication

Each API request (except for login) can be authenticated using Bearer token. The bearer token is obtained from [MMApi.shared.login]. 
Save that token to `UserDefaults.standard.string(forKey: "token")`, it is then used for all following requests.

### Location of classes

The API requests are located in `MMApi`. The requests can be safely called in main thread since it creates its own coroutine.

### Log in
```swift
MMApi.shared.login(email: mail, password: password, system: nil) { responseO, error in   
    if (response.success) {
        // Reponse is LoginResponse
    } else {
        // Failed - Show Error
    }
}
```

### Log out
```swift
MMApi.shared.logout() { responseO, error in   
    if (response.success) {
        // Reponse is CheckLoginResponse
    } else {
        // Failed - Show Error
    }
}
```

### Querying or checking Domain 
```swift
MMApi.shared.getDomain(lat: lat, lon: lon, system: system, appid: 1) { domainO, error in
    //Domain
}
```

### Retrieving the list of messages in a given location
```swift
MMApi.shared.getNearestMessages(boundingBox: BoundingBox(ne: neCoord, sw: swCoord), system: system) { data, error in
    //[ReportMO]
}
```

### Retrieving message detail
```swift
MMApi.shared.getMessageDetail(id: report.id.intValue, domainid: report.domainid?.intValue ?? 32, system: system) { detailsO, error in
    //ReportDetails
}
```

### Retrieving a category
```swift
MMApi.shared.getCategoryDetails(id: reportDetails.typeid, domainid: reportDetails.domainID, system: system) { reportType, error in
    //ReportTypeMO
}
```

### Retrieving a categories
```swift
MMApi.shared.getCategories(domainid: domainID, system: system) { types, error in
    //Array<ReportTypeMO>
}
```

### Searching a category
```swift
MMApi.shared.searchCategory(searchText: "TEST", domainid: 115, system: system) { reportTypes, error in
    //Array<ReportTypeMO>
}
```

### Checking possible duplicates of a message based on category and lat-lon
```swift
MMApi.shared.getDuplicates(lat: lat, lon: lon, categoryid: typeid, domainid: self.selectedDomain, system: self.mapDomainToSystem[self.selectedDomain]) { reports, error in
    //Array<ReportDetails>
}
```

### Creating a bundle for hosting images for soon-to-be message
When uploading images for a message, we use a bundle to host the images first before uploading the message.
The bundle ID will then be added when uploading the message so the server can find the images for this message.

```swift
MMApi.shared.createBundle(domainid: uploadable.domainid?.intValue ?? 32, system: system) { bundle, error in
    //PictureBundle
}
```

### Uploading an image to a file bundle for soon-to-be message
```swift
MMApi.shared.uploadFileToBundle(domainid: report.domainid?.intValue ?? 32, token: bundle.token, image: uploadable ?? UIImage(), system: system) { bundleO, error in
    //PictureBundle
}
```
### Uploading message

```swift
MMApi.shared.uploadReport(uploadable, bundle: nil, isCurrentUserResponsible: self.domainSettings?.isCurrentUserResponsible ?? false, system: system, updateProgress: { progress in
    //Progress as float
}) { result, error in
    //UploadReportResponse
}
```

### Adding comment to an existing message

```swift
MMApi.shared.updateReport(id: reportDetails?.messageid.intValue ?? 0, text: text, attributes: attributes, solved: solved, image: image, domainid: reportDetails?.domainID ?? 32, system: system) { result, error in
    //UploadReportResponse
}
```
