import Foundation

struct FontFamily: Identifiable, Hashable {
    let name: String        // e.g. "Helvetica Neue"
    let styles: [String]    // e.g. ["Regular", "Bold", "Italic", "Bold Italic"]

    var id: String { name }
}
