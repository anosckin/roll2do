import Foundation

enum TaskPreset: String, CaseIterable, Identifiable, Sendable {
    case almostAlways
    case regular
    case occasional
    case challenge
    case rare

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .almostAlways: "Almost Always"
        case .regular: "Regular"
        case .occasional: "Occasional"
        case .challenge: "Challenge"
        case .rare: "Rare"
        }
    }

    var description: String {
        switch self {
        case .almostAlways:
            "~75% chance every time. Great for daily habits you want to reinforce."
        case .regular:
            "~50% chance every time. A coin flip each day."
        case .occasional:
            "Starts at ~30%, gets easier after each miss. You'll do it eventually."
        case .challenge:
            "Starts at ~15%, builds up quickly. Exciting when you hit it early!"
        case .rare:
            "Starts at ~5%, but guaranteed eventually. A special treat when it happens."
        }
    }

    var initialDC: Int {
        switch self {
        case .almostAlways: 6
        case .regular: 11
        case .occasional: 15
        case .challenge: 18
        case .rare: 20
        }
    }

    var dcDrop: Int {
        switch self {
        case .almostAlways: 0
        case .regular: 0
        case .occasional: 3
        case .challenge: 4
        case .rare: 5
        }
    }

    var minDC: Int {
        switch self {
        case .almostAlways: 6
        case .regular: 11
        case .occasional: 1
        case .challenge: 2
        case .rare: 1
        }
    }

    static func matching(initialDC: Int, dcDrop: Int, minDC: Int) -> TaskPreset? {
        allCases.first { preset in
            preset.initialDC == initialDC &&
                preset.dcDrop == dcDrop &&
                preset.minDC == minDC
        }
    }
}
