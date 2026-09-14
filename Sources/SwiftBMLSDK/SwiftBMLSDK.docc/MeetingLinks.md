# App Links and Dial-In Numbers

Obtain a meeting's web URL, app-specific URL, or dial-in URL.

## Overview

### App links

``SwiftBMLSDK_Parser/Meeting/virtualURL`` is the meeting's normalized web or telephone URL.
``SwiftBMLSDK_Parser/Meeting/directApp`` identifies a recognized app-link converter;
``SwiftBMLSDK_Parser/Meeting/directAppURI`` supplies its app-specific URL. Unsupported hosts
or incomplete room paths return nil.

The SDK includes converters for Zoom, GoToMeeting, Skype, Google Meet, Discord, and Jitsi.
A generated URL describes a conversion; it does not guarantee that a service or a particular
installed app version supports the link.

On iOS and iPadOS, access app-link properties on the main thread. The SDK calls
`UIApplication.canOpenURL`, and the host app must declare the relevant URL schemes in
`LSApplicationQueriesSchemes`:

| Converter | Scheme |
| --- | --- |
| Zoom | `zoomus` |
| GoToMeeting | `lmi-g2m` |
| Skype | `skype` |
| Google Meet | `gmeet` |
| Discord | `discord` |
| Jitsi | `org.jitsi.meet` |

macOS and watchOS generate URLs without checking app installation. `SKIP_CANOPEN` bypasses the
iOS check for testing. ``SwiftBMLSDK_Parser/Meeting/DirectVirtual/appName`` returns a localization
key such as `SLUG-DIRECT-URI-ZOOM`; your app supplies the translated display name.

### Phone links

``SwiftBMLSDK_Parser/Meeting/virtualPhoneNumber`` preserves the server's dial-in text.
``SwiftBMLSDK_Parser/Meeting/directPhoneURI`` extracts a primary number, validates and normalizes it
with PhoneNumberKit, and retains explicit dialing pauses and numeric meeting IDs or PINs.
Numbers without a country prefix use the US region. Use `+` and the country code for international numbers.

For example, `+1 (212) 555-1212,,1234567890#` becomes `tel:+12125551212,,1234567890%23`.
The `#` is encoded to keep it in the dial string rather than treating it as a URL fragment.
Multiple distinct plausible phone numbers are ambiguous and return nil. Extraction is best effort;
it cannot infer every provider's dialing sequence and does not check the device's calling capability.

Normal package builds include PhoneNumberKit. A documentation-only build using
`SWIFTBMLSDK_DOCS=1` omits that dependency and returns nil for phone URL helpers.
