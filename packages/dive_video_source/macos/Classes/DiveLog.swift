public class DiveLog {
    static public func message(_ message: String, _ group: String = "") {
      _output(message, group);
    }

    static public func error(_ message: String, _ group: String = "") {
      _output(message, group);
    }

    static public func _output(_ message: String, _ group: String = "") {
        let groupMsg = group.isEmpty ? "" : " [\(group)]";
        let formatter = DateFormatter()
        formatter.dateFormat = "y/M/d H:mm:ss.SSS" //yyyy-MM-dd'T'HH:mm:ssZ
        let timeMsg = formatter.string(from: Date())
        print("flutter: \(timeMsg)\(groupMsg) \(message)");
    }
}
