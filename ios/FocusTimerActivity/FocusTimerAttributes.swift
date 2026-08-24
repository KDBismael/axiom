import ActivityKit
import Foundation

/// Matches the keys `FocusPresenceService._startIOS`/`_update` send via
/// `live_activities`' `createActivity`/`updateActivity` calls. The plugin
/// only bridges String values across the Dart/Swift boundary today, so
/// every field here is a String — `startedAt` is an epoch-millisecond
/// timestamp, `paused` is `"true"`/`"false"`, both parsed in the widget view.
struct FocusTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var paused: String
    }

    var questTitle: String
    var startedAt: String
}
