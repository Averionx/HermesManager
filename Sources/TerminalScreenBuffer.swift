import Foundation

/// A lightweight terminal screen model for rendering full-screen CLI output inside SwiftUI.
/// It consumes ANSI/OSC control sequences across read chunks so partial escapes never leak.
final class TerminalScreenBuffer {
    private enum ParserState {
        case normal
        case escape
        case csi(String)
        case osc
        case oscEscape
        case charsetIntro
    }

    private let width: Int
    private let height: Int
    private var rows: [[Character]]
    private var cursorRow = 0
    private var cursorColumn = 0
    private var savedCursorRow = 0
    private var savedCursorColumn = 0
    private var state: ParserState = .normal
    private var lineDrawingMode = false

    init(width: Int = 120, height: Int = 34) {
        self.width = max(20, width)
        self.height = max(8, height)
        self.rows = Array(repeating: Array(repeating: " ", count: max(20, width)), count: max(8, height))
    }

    func reset() {
        rows = Array(repeating: blankRow(), count: height)
        cursorRow = 0
        cursorColumn = 0
        savedCursorRow = 0
        savedCursorColumn = 0
        state = .normal
        lineDrawingMode = false
    }

    func append(_ text: String) {
        for scalar in text.unicodeScalars {
            consume(scalar)
        }
    }

    func renderedText() -> String {
        rows
            .map { String($0).trimmingTrailingWhitespace() }
            .joined(separator: "\n")
    }

    private func consume(_ scalar: Unicode.Scalar) {
        switch state {
        case .normal:
            consumeNormal(scalar)
        case .escape:
            consumeEscape(scalar)
        case .csi(let buffer):
            consumeCSI(scalar, buffer: buffer)
        case .osc:
            if scalar.value == 0x07 {
                state = .normal
            } else if scalar.value == 0x1B {
                state = .oscEscape
            }
        case .oscEscape:
            if scalar == "\\" {
                state = .normal
            } else if scalar.value == 0x1B {
                state = .oscEscape
            } else {
                state = .osc
            }
        case .charsetIntro:
            lineDrawingMode = scalar == "0"
            state = .normal
        }
    }

    private func consumeNormal(_ scalar: Unicode.Scalar) {
        switch scalar.value {
        case 0x1B:
            state = .escape
        case 0x07:
            break
        case 0x08:
            cursorColumn = max(0, cursorColumn - 1)
        case 0x09:
            let nextTab = min(width - 1, ((cursorColumn / 8) + 1) * 8)
            while cursorColumn < nextTab {
                put(" ")
            }
        case 0x0A, 0x0B, 0x0C:
            lineFeed()
        case 0x0D:
            cursorColumn = 0
        case 0x0E:
            lineDrawingMode = true
        case 0x0F:
            lineDrawingMode = false
        case 0x00...0x1F, 0x7F:
            break
        default:
            let character = lineDrawingMode ? lineDrawingCharacter(for: scalar) : Character(String(scalar))
            put(character)
        }
    }

    private func consumeEscape(_ scalar: Unicode.Scalar) {
        switch scalar {
        case "[":
            state = .csi("")
        case "]":
            state = .osc
        case "(", ")":
            state = .charsetIntro
        case "7":
            saveCursor()
            state = .normal
        case "8":
            restoreCursor()
            state = .normal
        case "c":
            reset()
            state = .normal
        case "D":
            lineFeed()
            state = .normal
        case "E":
            cursorColumn = 0
            lineFeed()
            state = .normal
        case "M":
            reverseIndex()
            state = .normal
        case "\\":
            state = .normal
        default:
            state = .normal
        }
    }

    private func consumeCSI(_ scalar: Unicode.Scalar, buffer: String) {
        if (0x40...0x7E).contains(scalar.value) {
            handleCSI(buffer, final: scalar)
            state = .normal
        } else {
            state = .csi(buffer + String(scalar))
        }
    }

    private func handleCSI(_ raw: String, final: Unicode.Scalar) {
        let finalString = String(final)
        let privateMode = raw.contains("?")
        let normalized = raw
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: ">", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let params = normalized
            .split(separator: ";", omittingEmptySubsequences: false)
            .map { Int($0) ?? 0 }

        func parameter(_ index: Int, default defaultValue: Int = 1) -> Int {
            guard index < params.count else { return defaultValue }
            return params[index] == 0 ? defaultValue : params[index]
        }

        switch finalString {
        case "A":
            moveCursor(rowDelta: -parameter(0), columnDelta: 0)
        case "B":
            moveCursor(rowDelta: parameter(0), columnDelta: 0)
        case "C":
            moveCursor(rowDelta: 0, columnDelta: parameter(0))
        case "D":
            moveCursor(rowDelta: 0, columnDelta: -parameter(0))
        case "E":
            moveCursor(rowDelta: parameter(0), columnDelta: 0)
            cursorColumn = 0
        case "F":
            moveCursor(rowDelta: -parameter(0), columnDelta: 0)
            cursorColumn = 0
        case "G":
            cursorColumn = clamp(parameter(0) - 1, lower: 0, upper: width - 1)
        case "H", "f":
            cursorRow = clamp(parameter(0) - 1, lower: 0, upper: height - 1)
            cursorColumn = clamp(parameter(1) - 1, lower: 0, upper: width - 1)
        case "J":
            eraseDisplay(mode: parameter(0, default: 0))
        case "K":
            eraseLine(mode: parameter(0, default: 0))
        case "S":
            scrollUp(parameter(0))
        case "T":
            scrollDown(parameter(0))
        case "@":
            insertBlankCharacters(parameter(0))
        case "P":
            deleteCharacters(parameter(0))
        case "X":
            eraseCharacters(parameter(0))
        case "s":
            saveCursor()
        case "u":
            restoreCursor()
        case "h":
            if privateMode && (normalized.contains("1049") || normalized.contains("1047") || normalized.contains("47")) {
                reset()
            }
        case "l":
            if privateMode && (normalized.contains("1049") || normalized.contains("1047") || normalized.contains("47")) {
                reset()
            }
        default:
            break
        }
    }

    private func put(_ character: Character) {
        if cursorColumn >= width {
            cursorColumn = 0
            lineFeed()
        }
        rows[cursorRow][cursorColumn] = character
        cursorColumn += 1
    }

    private func lineFeed() {
        if cursorRow >= height - 1 {
            rows.removeFirst()
            rows.append(blankRow())
        } else {
            cursorRow += 1
        }
    }

    private func reverseIndex() {
        if cursorRow == 0 {
            rows.insert(blankRow(), at: 0)
            rows.removeLast()
        } else {
            cursorRow -= 1
        }
    }

    private func moveCursor(rowDelta: Int, columnDelta: Int) {
        cursorRow = clamp(cursorRow + rowDelta, lower: 0, upper: height - 1)
        cursorColumn = clamp(cursorColumn + columnDelta, lower: 0, upper: width - 1)
    }

    private func saveCursor() {
        savedCursorRow = cursorRow
        savedCursorColumn = cursorColumn
    }

    private func restoreCursor() {
        cursorRow = clamp(savedCursorRow, lower: 0, upper: height - 1)
        cursorColumn = clamp(savedCursorColumn, lower: 0, upper: width - 1)
    }

    private func eraseDisplay(mode: Int) {
        switch mode {
        case 1:
            for row in 0...cursorRow {
                let end = row == cursorRow ? cursorColumn : width - 1
                clear(row: row, from: 0, through: end)
            }
        case 2, 3:
            rows = Array(repeating: blankRow(), count: height)
        default:
            for row in cursorRow..<height {
                let start = row == cursorRow ? cursorColumn : 0
                clear(row: row, from: start, through: width - 1)
            }
        }
    }

    private func eraseLine(mode: Int) {
        switch mode {
        case 1:
            clear(row: cursorRow, from: 0, through: cursorColumn)
        case 2:
            clear(row: cursorRow, from: 0, through: width - 1)
        default:
            clear(row: cursorRow, from: cursorColumn, through: width - 1)
        }
    }

    private func eraseCharacters(_ count: Int) {
        guard count > 0 else { return }
        clear(row: cursorRow, from: cursorColumn, through: min(width - 1, cursorColumn + count - 1))
    }

    private func deleteCharacters(_ count: Int) {
        guard count > 0, cursorColumn < width else { return }
        let deleteCount = min(count, width - cursorColumn)
        rows[cursorRow].removeSubrange(cursorColumn..<(cursorColumn + deleteCount))
        rows[cursorRow].append(contentsOf: Array(repeating: " ", count: deleteCount))
    }

    private func insertBlankCharacters(_ count: Int) {
        guard count > 0, cursorColumn < width else { return }
        let insertCount = min(count, width - cursorColumn)
        rows[cursorRow].insert(contentsOf: Array(repeating: " ", count: insertCount), at: cursorColumn)
        rows[cursorRow].removeLast(insertCount)
    }

    private func scrollUp(_ count: Int) {
        guard count > 0 else { return }
        for _ in 0..<min(count, height) {
            rows.removeFirst()
            rows.append(blankRow())
        }
    }

    private func scrollDown(_ count: Int) {
        guard count > 0 else { return }
        for _ in 0..<min(count, height) {
            rows.insert(blankRow(), at: 0)
            rows.removeLast()
        }
    }

    private func clear(row: Int, from start: Int, through end: Int) {
        guard row >= 0, row < height else { return }
        let lower = clamp(start, lower: 0, upper: width - 1)
        let upper = clamp(end, lower: 0, upper: width - 1)
        guard lower <= upper else { return }
        for column in lower...upper {
            rows[row][column] = " "
        }
    }

    private func blankRow() -> [Character] {
        Array(repeating: " ", count: width)
    }

    private func clamp(_ value: Int, lower: Int, upper: Int) -> Int {
        min(max(value, lower), upper)
    }

    private func lineDrawingCharacter(for scalar: Unicode.Scalar) -> Character {
        switch scalar {
        case "j": return "┘"
        case "k": return "┐"
        case "l": return "┌"
        case "m": return "└"
        case "n": return "┼"
        case "q": return "─"
        case "t": return "├"
        case "u": return "┤"
        case "v": return "┴"
        case "w": return "┬"
        case "x": return "│"
        default: return Character(String(scalar))
        }
    }
}

private extension String {
    func trimmingTrailingWhitespace() -> String {
        var value = self
        while let last = value.last, last == " " || last == "\t" {
            value.removeLast()
        }
        return value
    }
}
