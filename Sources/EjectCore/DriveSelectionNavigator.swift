public struct DriveSelectionNavigator: Sendable {
    public init() {}

    public func firstSelectableIndex(usage: [Bool]) -> Int? {
        usage.firstIndex(of: false)
    }

    public func normalizedSelection(current: Int?, usage: [Bool]) -> Int? {
        guard let current,
              usage.indices.contains(current),
              !usage[current] else {
            return firstSelectableIndex(usage: usage)
        }
        return current
    }

    public func movedSelection(current: Int?, by offset: Int, usage: [Bool]) -> Int? {
        let selectableIndices = usage.indices.filter { !usage[$0] }
        guard !selectableIndices.isEmpty else { return nil }

        guard let current,
              let position = selectableIndices.firstIndex(of: current) else {
            return offset < 0 ? selectableIndices.last : selectableIndices.first
        }

        let nextPosition = (position + offset % selectableIndices.count + selectableIndices.count)
            % selectableIndices.count
        return selectableIndices[nextPosition]
    }
}
