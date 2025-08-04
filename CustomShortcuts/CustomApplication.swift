import SwiftUI
import HotKey
import Carbon
import ServiceManagement

struct CustomApplication: Identifiable, Codable {
    let id: UUID
    let name: String
    let bundleIdentifier: String
    let url: URL

    init(name: String, bundleIdentifier: String, url: URL, id: UUID = UUID()) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.url = url
        self.id = id
    }
}
