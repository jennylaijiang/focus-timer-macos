import Foundation

public enum TimeText {
    public static func clock(_ seconds: TimeInterval, roundingUp: Bool = false) -> String {
        guard seconds.isFinite else { return "00:00" }
        let value = max(0, seconds)
        let whole = Int(min(Double(Int.max / 2), roundingUp ? ceil(value) : floor(value)))
        if whole >= 3600 { return String(format: "%d:%02d:%02d", whole / 3600, (whole % 3600) / 60, whole % 60) }
        return String(format: "%02d:%02d", whole / 60, whole % 60)
    }
    public static func duration(_ seconds: TimeInterval) -> String {
        let whole = max(0, Int(seconds))
        if whole >= 3600 { return "\(whole / 3600)h \((whole % 3600) / 60)m \(whole % 60)s" }
        if whole >= 60 { return "\(whole / 60)m \(whole % 60)s" }
        return "\(whole)s"
    }
}
