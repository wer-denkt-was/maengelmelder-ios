[1.7.22]
- fix npe with specific categories

[1.7.21]
- fixed own reports being displayed twice in "Meine Meldungen"

[1.7.20]
- first public release on GitHub

[1.7.19]
- switched license to EUPL v1.2, prepared documentation for open source release

[1.7.18]
- use default domain with configurable hint when no position is available during login

[1.7.17]
- fetch file size from server

[1.7.16]
- fixed visual bug in offline maps

[1.7.15]
- improved download for offline maps

[1.7.14]
- fix null pointer when no position step is required

[1.7.13]
- fix null pointer

[1.7.12]
- added marker assets for category 386

[1.7.11]
- fixed missing codes for fill in from user details

[1.7.10]
- fixed fill in from user details

[1.7.9]
- use token (af available) when getting domain

[1.7.8]
- fix for wrong cell height in my messages

[1.7.7]
- fix textsize in message detail

[1.7.6]
- added setting to disable category check (position)

[1.7.5]
- added ordering to valuelist attribute

[1.7.4]
- minor ui changes for missing location permission

[1.7.3]
- fix missing duplicate check

[1.7.2]
- fix editing of description

[1.7.1]
- fix loading indicator keeps showing in login screen

[1.7.0]
- added scanner for qr codes 
- added code for opening via url
- use new category endpoint

[1.6.6] 2025-12-04 bessler
- small changes attributed text helpers

[1.6.4] 2025-12-04 bessler
- small changes to infoTextBottom

[1.6.3] 2025-12-02 bessler
- multiple minor updates and bug fixes

[1.6.2] 2025-11-24 christian
- Warning icon for outdated maps

[1.6.1] 2025-11-24 christian, bessler
- Added option to update map file for offline map
- Added app-settings and functionality to check for offline map version
- Added individual map data version

[1.6.0] 2025-11-11 christian, bessler
- added versionName to param
- added basemap switching on overview map
- fix header title in category step
- added showMapTypeButtonOnMainMap setting
- added requireManualPositionUpdate setting
- added colorscheme inputbg and tableViewHeaderBg
- added setting defaultBaseMapType
- fixed typo
- Major changes for WaldEcho

[1.5.5] 2025-10-13 christian
- T23475 - white text on dark mode in message detail
- T23475 - Fixed system API not being called correctly in message list

[1.5.4] 2025-09-09 christian
- T23438 - hide comment button if message does not allow commenting 

[1.5.3] 2025-09-01 christian
- T23357 - Use system host of the domain for user login and subsequent user message list

[1.5.2] 2025-08-18 christian
- T23197 - Clickable links in history text

[1.5.1] 2025-07-28 christian
- T23242 - Fixed newline not correctly escaped on message update

[1.5.0] 2025-05-27 bessler
- added login for multiple domains
- added parameter for domains without anonymous reporting

[1.4.3] 2025-05-20 bessler
- fix location when no permission

[1.4.2] 2025-05-06 bessler
- fix bug with sqllite in export

[1.4.1] 2025-05-06 bessler
- fix bug with attribute in comments 

[1.4.0] 2025-05-06 bessler
- added offline maps
- accessibility changes for voice over

[1.3.13] 2025-04-14 bessler
 - small bugfix for adress search

[1.3.12] 2025-04-14 bessler
 - updated position step - part 3

[1.3.11] 2025-04-11 bessler
 - updated position step - part 2

[1.3.10] 2025-04-10 bessler
 - updated position step

[1.3.9] 2025-04-04 bessler
 - show error messages on attributes

[1.3.8] 2025-03-28 bessler
- fix basic auth

[1.3.7] 2025-03-27 bessler
 - only show size info when report is bigger than 1 MB

[1.3.6] 2025-03-27 bessler
 - required text field needs at least one character (not counting space)

[1.3.5] 2025-01-21 bessler
- fix filter on map
- fix keyboard in searchbar in position

[1.3.4] 2025-01-14 bessler
- fix wrong text in filter

[1.3.3] 2025-01-14 bessler
- filter on map now uses api

[1.3.2] 2025-01-07 bessler
- filter on map now shows maximum markes

[1.3.1] 2025-01-03 bessler
- bugfix for login via api

[1.3.0] 2025-01-03 bessler
- added new settings for fuss 

[1.2.23] 2024-12-17 bessler
- added filter to mapview

[1.2.22] 2024-12-13 bessler
- added max_length to text attributes
- fixed small bug with ideas

[1.2.21] 2024-12-05 bessler
- fixed external categories
- added search address

[1.2.20] 2024-11-04 bessler
- scale images down (1280)

[1.2.19] 2024-10-30 bessler
- fix missing headers

[1.2.18] 2024-10-30 bessler
- fix review with position == never
- select current report type when editing
- fix edit of reports with rubrics
- fixing "," in option

[1.2.17] 2024-10-22 bessler

- fix bug when changing category with rubrics and search enabled

[1.2.16] 2024-10-16 bessler

- check duplicates on position step when types are first
- new text for customer with type first

[1.2.15] 2024-10-16 bessler

- fixed bug in duplicates

[1.2.14] 2024-10-15 bessler

- close keyboard on search

[1.2.13] 2024-10-15 bessler

- show rubric as subtitle on search

[1.2.12] 2024-10-15 bessler

- do not check duplicates if we have no location

[1.2.11] 2024-10-15 bessler

- fix tutorial on types first 

[1.2.10] 2024-10-15 bessler

- fix bug with layer button 

[1.2.9] 2024-10-15 bessler

- fix bug with layer button
- fix types first apps (use app id in get domain)

[1.2.8] 2024-10-14 bessler

- fix category names (trim)

[1.2.7] 2024-10-14 bessler

- fix rubrics

[1.2.6] 2024-10-14 bessler

- fix rubrics

[1.2.5] 2024-10-14 bessler

- fix typo

[1.2.4] 2024-10-14 bessler

- fix canceling search with rubrics

[1.2.3] 2024-10-14 bessler

- fix bug with new lines in message

[1.2.2] 2024-10-14 bessler

- search bar now works in rubrics selection as well

[1.2.1] 2024-10-14 bessler

- show searched results in type selection

[1.2.0] 2024-10-14 bessler

- fix height of rubrics info
- added api for category search
- added search bar on type selection and setting for it

[1.1.13] 2024-10-11 bessler

- Part 6: added possibility for two-step category chooser (group, type) 

[1.1.12] 2024-10-11 bessler

- Part 5: added possibility for two-step category chooser (group, type) 

[1.1.11] 2024-10-11 bessler

- Part 4: added possibility for two-step category chooser (group, type) 

[1.1.10] 2024-10-11 bessler

- Part 3: added possibility for two-step category chooser (group, type) 

[1.1.9] 2024-10-11 bessler

- Part 2: added possibility for two-step category chooser (group, type) 

[1.1.8] 2024-10-11 bessler

- added possibility for two-step category chooser (group, type)

[1.1.7] 2024-10-11 bessler

- fix tint color of bar button item - part 2

[1.1.6] 2024-10-11 bessler

- fix tint color of bar button item

[1.1.5] 2024-10-11 bessler

- fix layerbutton not showing because of offline button

[1.1.4] 2024-10-11 bessler

- updated localLayer config with color

[1.1.3] 2024-10-10 bessler

- fixed iOS 18 bug on collection view (dequeue)

[1.1.2] 2024-10-02 bessler

- fixed bug with internal infopage

[1.1.1] 2024-09-24 bessler

- fixed bug in translation

[1.1.0] 2024-09-18 bessler

 - added offline functionality from develop branch
 - added missing changes from main

[1.0.4] 2024-09-18 bessler

- fix minor ui bugs

[1.0.3] 2024-09-18 bessler

- fix dependencie with branch

[1.0.2] 2024-09-11 bessler

- added rating controller after uploading a message
- fix small bug when types step is first

[1.0.1] 2024-07-30 bessler

- fix bug with info pages
- fix transulcent nav bar

[1.0.0] 2024-06-30 bessler

- first version
