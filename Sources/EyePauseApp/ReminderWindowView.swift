import EyePauseCore
import SwiftUI

struct ReminderWindowView: View {
    @ObservedObject var model: AppModel
    @State private var blinkGlow = false
    @State private var forcedSkipAvailableAt = Date().addingTimeInterval(15)
    @FocusState private var isSkipCodeFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background
                VStack(spacing: 28) {
                    if let exercise = model.currentExercise {
                        exerciseView(exercise, canvasSize: geometry.size)
                    } else {
                        reminderPrompt
                    }
                }
                .frame(maxWidth: min(geometry.size.width * 0.72, 900))
                .padding(48)
            }
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.09, blue: 0.06),
                    Color(red: 0.04, green: 0.18, blue: 0.11),
                    model.isForcedPresentation ? Color(red: 0.12, green: 0.03, blue: 0.03) : Color(red: 0.03, green: 0.12, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            forestCanopy
        }
        .ignoresSafeArea()
    }

    private var forestCanopy: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<9, id: \.self) { index in
                    Circle()
                        .fill(Color(red: 0.10, green: 0.34, blue: 0.18).opacity(0.20))
                        .frame(width: CGFloat(170 + index * 18), height: CGFloat(170 + index * 18))
                        .blur(radius: 18)
                        .position(
                            x: geometry.size.width * CGFloat((index % 3) + 1) / 3.4,
                            y: geometry.size.height * CGFloat((index / 3) + 1) / 4.0
                        )
                }
            }
        }
    }

    private var reminderPrompt: some View {
        VStack(spacing: 18) {
            Image(systemName: model.isForcedPresentation ? "lock.circle" : "eye.circle")
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(.white)

            Text(model.isForcedPresentation ? model.text(.forcedBreak) : model.text(.timeToRest))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text(model.text(.chooseExercise))
                .foregroundStyle(.white.opacity(0.72))

            HStack(spacing: 12) {
                exerciseButton(.distantLook)
                exerciseButton(.nearFarFocus)
                exerciseButton(.closeEyes)
            }

            if model.isForcedPresentation {
                forcedSkipView
            } else {
                HStack {
                    Button(model.text(.delayFiveMinutes)) {
                        model.delayCurrentReminder()
                    }
                    Button(model.text(.skip)) {
                        model.skipForcedBreak()
                    }
                }
            }
        }
    }

    private func exerciseButton(_ exercise: Exercise) -> some View {
        Button {
            model.beginExercise(exercise)
        } label: {
            VStack(spacing: 6) {
                Text(title(for: exercise))
                    .font(.headline)
                Text(durationText(model.settings.breakDurationSeconds(isLongBreak: false)))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.70))
            }
            .frame(width: 112, height: 72)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.10, green: 0.36, blue: 0.22))
    }

    private func exerciseView(_ exercise: Exercise, canvasSize: CGSize) -> some View {
        let visualSize = min(canvasSize.width, canvasSize.height) * 0.34
        return VStack(spacing: 18) {
            Text(model.isLongBreakActive ? model.text(.longBreakTitle) : title(for: exercise))
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)

            ZStack {
                switch exercise {
                case .distantLook:
                    distantLookScene
                case .nearFarFocus:
                    nearFarFocusScene
                case .closeEyes:
                    closeEyesScene
                }
            }
            .frame(width: visualSize, height: visualSize * 0.86)
            .scaleEffect(max(1, visualSize / 220))

            Text("\(model.remainingExerciseSeconds)")
                .font(.system(size: 78, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(model.isLongBreakActive ? model.text(.longBreakSubtitle) : subtitle(for: exercise))
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))

            Text(model.exerciseSteps(for: exercise))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.82))
                .frame(maxWidth: 620)

            Button(model.text(.complete)) {
                model.completeExercise()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.12, green: 0.42, blue: 0.25))
        }
    }

    private var distantLookScene: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.03, green: 0.16, blue: 0.12).opacity(0.65))
            Path { path in
                path.move(to: CGPoint(x: 12, y: 150))
                path.addCurve(to: CGPoint(x: 208, y: 150), control1: CGPoint(x: 72, y: 70), control2: CGPoint(x: 148, y: 80))
                path.addLine(to: CGPoint(x: 208, y: 190))
                path.addLine(to: CGPoint(x: 12, y: 190))
                path.closeSubpath()
            }
            .fill(Color(red: 0.10, green: 0.30, blue: 0.18))
            Path { path in
                path.move(to: CGPoint(x: 20, y: 116))
                path.addCurve(to: CGPoint(x: 200, y: 116), control1: CGPoint(x: 70, y: 54), control2: CGPoint(x: 142, y: 56))
            }
            .stroke(Color.white.opacity(0.65), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 8]))
            Circle()
                .fill(Color(red: 0.65, green: 0.85, blue: 0.58).opacity(0.9))
                .frame(width: 14, height: 14)
                .position(x: 178, y: 74)
        }
    }

    private var nearFarFocusScene: some View {
        TimelineView(.periodic(from: .now, by: 5)) { timeline in
            let isNear = Int(timeline.date.timeIntervalSinceReferenceDate / 5).isMultiple(of: 2)
            Circle()
                .strokeBorder(Color(red: 0.70, green: 0.95, blue: 0.72), lineWidth: isNear ? 10 : 4)
                .frame(width: isNear ? 170 : 72, height: isNear ? 170 : 72)
                .shadow(color: Color(red: 0.54, green: 0.95, blue: 0.62).opacity(isNear ? 0.45 : 0.18), radius: isNear ? 24 : 8)
                .animation(.easeInOut(duration: 1.2), value: isNear)
            }
    }

    private var closeEyesScene: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 18)
                .frame(width: 160, height: 160)
            Circle()
                .stroke(Color(red: 0.72, green: 0.94, blue: 0.70).opacity(0.72), lineWidth: blinkGlow ? 14 : 5)
                .frame(width: blinkGlow ? 172 : 118, height: blinkGlow ? 172 : 118)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: blinkGlow)
                .onAppear {
                    blinkGlow = true
                }
            Image(systemName: "eye.slash")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(.white.opacity(0.88))
        }
    }

    private var forcedSkipView: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let remainingSeconds = max(0, Int(ceil(forcedSkipAvailableAt.timeIntervalSince(timeline.date))))
            VStack(spacing: 8) {
                Text(model.text(.enterCode))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                if remainingSeconds > 0 {
                    Text("\(remainingSeconds)s")
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                } else {
                    Text(model.forcedSkipCode)
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                    TextField("Code", text: $model.skipInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .focused($isSkipCodeFocused)
                        .onAppear {
                            isSkipCodeFocused = true
                        }
                    Button(model.text(.skipForcedBreak)) {
                        model.skipForcedBreak()
                    }
                }
                if let skipError = model.skipError {
                    Text(skipError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .onAppear {
            forcedSkipAvailableAt = Date().addingTimeInterval(15)
        }
    }

    private func title(for exercise: Exercise) -> String {
        switch exercise {
        case .distantLook:
            return model.text(.distantLookTitle)
        case .nearFarFocus:
            return model.text(.nearFarFocusTitle)
        case .closeEyes:
            return model.text(.closeEyesTitle)
        }
    }

    private func subtitle(for exercise: Exercise) -> String {
        switch exercise {
        case .distantLook:
            return model.text(.distantLookSubtitle)
        case .nearFarFocus:
            return model.text(.nearFarFocusSubtitle)
        case .closeEyes:
            return model.text(.closeEyesSubtitle)
        }
    }

    private func durationText(_ seconds: Int) -> String {
        switch model.settings.language {
        case .english:
            return "\(seconds)s"
        case .traditionalChinese:
            return "\(seconds)秒"
        case .simplifiedChinese:
            return "\(seconds)秒"
        case .japanese:
            return "\(seconds)秒"
        case .korean:
            return "\(seconds)초"
        }
    }
}
