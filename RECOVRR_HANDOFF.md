# Recovrr handoff: meeting accessibility and attendance flags

Prepared October 23, 2026.

## Goal and integration path

Expose the new meeting attributes in Recovrr through its intermediate library:

LGV_MeetingServer → SwiftBMLSDK → RecovrrSDK → Recovrr app.

Start by reading the instructions and inspecting the existing models, mapping,
persistence, filtering, and UI conventions in RecovrrSDK and the app. This handoff
specifies the SDK contract, not the current architecture of either consumer.
Preserve unrelated changes in all repositories.

## SDK location and delivery status

SwiftBMLSDK checkout:
`/Users/chrismarshall/Developer/LGV/SwiftBMLSDK`

RecovrrSDK checkout:
`/Users/chrismarshall/Developer/LGV/RecovrrSDK`

The SwiftBMLSDK implementation is complete and verified in the local working tree.
The checkout version is **1.5.7**. At handoff preparation, its changes are **uncommitted**; no release, tag, push, or
published package version was created. Do not assume a remote package dependency
already includes these properties. Inspect how RecovrrSDK resolves SwiftBMLSDK and
how the app resolves RecovrrSDK, and ensure the builds actually use the updated
sources. Follow the consuming projects' dependency conventions.

Authoritative SDK references:

- `Sources/SwiftBMLSDK/SwiftBMLSDK_Parser.swift`: meeting properties, strict input parsing, and flat export.
- `README.md`, “Meeting accessibility and attendance flags”: semantics and usage.
- `Sources/SwiftBMLSDK/SwiftBMLSDK.docc/SwiftBMLSDK.md`: public guide and symbols.
- `Tests/SwiftBMLSDKTests/SwiftBMLSDK_RegressionTests.swift`: deterministic fixtures and optional live verification.
- `CHANGELOG.md`, version 1.5.7 (October 23, 2026): change summary.

The prior server-to-SDK temporary handoff was removed after SDK completion; the
SDK documentation and tests now retain its lasting contract.

## Public API and wire contract

These read-only properties are on `SwiftBMLSDK_Parser.Meeting`:

| Swift property | Type | Server JSON key | Meaning when true |
| --- | --- | --- | --- |
| `wheelchairAccessible` | `Bool?` | `wheelchair_accessible` | Source explicitly asserts wheelchair accessibility |
| `isOpen` | `Bool?` | `is_open` | Source explicitly asserts an open meeting |
| `isClosed` | `Bool?` | `is_closed` | Source explicitly asserts a closed meeting |

The server fields occur directly on each object in the unchanged `meetings` array.
LGV_MeetingServer 1.6.1 currently emits true or omits each field.

- Missing fields and JSON null decode to nil: unknown/unconfirmed. Older responses
  continue to decode. Unknown accessibility does not mean inaccessible.
- The SDK retains explicit Boolean false if a response supplies it. Preserve this
  distinction across consumer mappings and persistence.
- Open and closed are independent assertions. Missing open does not mean closed,
  and missing closed does not mean open. Both may be true; retain the conflict.
- Accessibility is independent of attendance status and venue type.
- Do not infer flags from display format keys, names, descriptions, or localized
  labels such as O, C, or WC. Existing `formats` are unchanged.
- Invalid types, including numeric 0/1 and string booleans, cause the SDK parser to
  skip the malformed meeting record. Do not introduce permissive coercion upstream.
- Meeting identity remains the server/meeting pair, exposed as the SDK composite
  `meeting.id`. Local meeting IDs alone are not globally unique. Equality remains
  identity-based; changed attributes on the same ID still need UI refreshes.

The SDK's Encodable output is a separate flat export schema. It uses camel-case
`wheelchairAccessible`, `isOpen`, and `isClosed`, omits nil values, and retains
explicit true/false. It is not the server input schema or a decodable SDK cache.

## RecovrrSDK work

Trace every path carrying meetings into the app. If RecovrrSDK already passes the
SDK meeting object through, verify the properties remain accessible. If it wraps
or copies meetings, add equivalent optional properties and propagate all three
without defaulting nil to false or collapsing open/closed into one Boolean.

Review initializers, adapters, copies, fixtures, previews, persistence, cache loads,
serialization, and update detection. Use source-compatible defaults where needed.
Old cached records without these attributes must remain readable as unknown.
Persist both assertions even if the UI presents a combined attendance status.
Document any new public RecovrrSDK API using that project's conventions.

## App behavior and design constraints

Choose presentation using the app's existing design and localization conventions.
These are semantic requirements, not a prescribed layout:

- A positive wheelchair indicator should mean confirmed accessibility. Do not show
  unknown meetings as inaccessible. If useful, explain unknown as “Not specified.”
- Label open/closed as meeting attendance status so “closed” is not mistaken for a
  cancelled meeting or a venue that is currently shut.
- A both-true status needs a visible conflict/uncertainty treatment; do not silently
  choose one assertion or display an unambiguous single status.
- Provide accessible text for any icons and localize user-facing labels.
- Filtering for confirmed attributes uses `== true`. An unknown option, if offered,
  should use nil explicitly; false and nil should not be silently conflated.

For example, when working directly with SDK results:

```swift
let accessible = results.meetings.filter { $0.wheelchairAccessible == true }
let open = results.meetings.filter { $0.isOpen == true }
let conflicting = results.meetings.filter { $0.isOpen == true && $0.isClosed == true }
```

No server flag query parameters were added. Client filtering covers only fetched
records. Pagination is zero-based, and the original metadata counts are not
filtered counts. Do not claim a server-wide count from a filtered page. Reuse the
app's existing paging approach when a filter needs matches beyond the current page.

## Validation and prerelease verification

Completed SDK validation on October 23, 2026:

- `SWIFTBMLSDK_LIVE_TESTS=1 swift test`: **37 tests passed, zero failures**.
- Deterministic coverage includes all eight true/absent combinations, conflicting
  open/closed assertions, missing fields with ordinary display formats, JSON null,
  explicit false, invalid types, and flat export behavior.
- Prerelease info reported server version 1.6.1.
- A bounded query returned ten meetings on page zero; SDK properties matched the
  wire values by server ID and meeting ID. The page included accessibility and
  closed assertions. These are observations, not stable fixture requirements.
- `git diff --check` passed.

Use the prerelease endpoint for development and live verification:

`https://recovrr.org/recovrr/testMeetings/entrypoint.php`

Read-only requests:

```text
https://recovrr.org/recovrr/testMeetings/entrypoint.php?info
https://recovrr.org/recovrr/testMeetings/entrypoint.php?query&page_size=10&page=0
```

The first query component is the bare command (`query` or `info`), not
`command=query`. Use existing SDK query methods and URL conventions for app tests.
Do not fetch the entire dataset for a smoke test, trigger server imports, or use
production unless the user explicitly requests production work.

To repeat the SDK's optional live smoke test from this checkout:

```sh
SWIFTBMLSDK_LIVE_TESTS=1 swift test --filter testPrereleaseMeetingFlagsLive
```

Add consumer tests for propagation through RecovrrSDK, old cache compatibility,
explicit false and unknown values, all status combinations, applicable filtering,
and the app's labels/icons/conflict presentation. Include replacement or refresh
of attributes on a meeting whose composite ID stays the same. Keep deterministic
tests independent of live records and IDs.

## Completion

Report RecovrrSDK changes, app behavior, dependency resolution used for validation,
test results, and any remaining work. Preserve lasting API and behavior guidance
in those projects' normal documentation and tests. This temporary handoff may be
removed after the downstream integration is complete and verified; retain it while
work remains incomplete. Check for intervening edits before removing it.
