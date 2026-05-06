import Foundation

public enum Exercise: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case distantLook
    case nearFarFocus
    case closeEyes

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .distantLook:
            return "20-20-20"
        case .nearFarFocus:
            return "Near/Far Focus"
        case .closeEyes:
            return "Close Eyes"
        }
    }

    public var subtitle: String {
        switch self {
        case .distantLook:
            return "Look at a distant object."
        case .nearFarFocus:
            return "Follow the focus target."
        case .closeEyes:
            return "Close your eyes or blink slowly."
        }
    }

    public var durationSeconds: Int {
        switch self {
        case .distantLook:
            return 20
        case .nearFarFocus, .closeEyes:
            return 30
        }
    }
}

public struct ExerciseEngine: Sendable {
    private var nextIndex: Int

    public init(nextIndex: Int = 0) {
        self.nextIndex = nextIndex
    }

    public mutating func nextExercise() -> Exercise {
        let exercises = Exercise.allCases
        let exercise = exercises[nextIndex % exercises.count]
        nextIndex += 1
        return exercise
    }
}

public struct ForcedSkipGate: Sendable {
    public let code: String

    public init(code: String = String(format: "%04d", Int.random(in: 0...9999))) {
        self.code = code
    }

    public func canSkip(with input: String) -> Bool {
        input == code
    }
}
