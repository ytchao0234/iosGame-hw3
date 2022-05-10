//
//  Game.swift
//  Match3
//
//  Created by FanRende on 2022/4/28.
//

import SwiftUI

struct Game {
    var shape: Game.SHAPE
    var board: Array<Grid> = [Grid]()
    var validArea: Array<Int> = [Int]()
    var disable: Bool = false
    var gameOver: Bool = false
    var score: Int = 0
    var combo: Int = 0

    var matchHint: Array<Int> = [Int]()
    var lastSwap: Date = .now
    var hintInterval: Double = 3
    var showHint: Bool = false
    var isMatched: Bool = false

    var timer: Timer?
    var timeLimit: TimeInterval = 60
    var countDown: TimeInterval
    var timerLabel = String()
    var formatter = DateFormatter()

    init(_ shape: Game.SHAPE = .NORMAL) {
        self.countDown = self.timeLimit
        self.formatter.dateFormat = "mm:ss"

        let dateComponent = DateComponents(
            calendar: .current,
            hour: 0,
            minute: Int(self.countDown) / 60,
            second: Int(self.countDown) % 60
        )
        self.timerLabel = self.formatter.string(from: dateComponent.date!)
        
        Game.row = Int(UIScreen.main.bounds.height - 300) / (Grid.size)
        Game.column = Int(UIScreen.main.bounds.width - 50) / (Grid.size)
        Game.size = Game.row * Game.column
        self.shape = shape
        self.setValidArea()

        for _ in 0 ..< Game.size {
            self.board.append(Grid.random())
        }
    }

    mutating func setValidArea() {
        switch(self.shape) {
        case .NORMAL:
            self.validArea = Array(0 ..< Game.size)
        case .HEART:
            let minimum = (Game.row < Game.column) ? Game.row : Game.column
            Game.row = minimum + minimum % 2 - 1
            Game.column = Game.row
            Game.size = Game.row * Game.column
            self.validArea = Array(0 ..< Game.size)

            var toRemove = [Int]()
            let colCenter = Game.column / 2
            
            for i in (0..<colCenter).reversed() {
                for j in 0...i {
                    toRemove.append(contentsOf: [
                        (Game.row - colCenter + i) * Game.column + j,
                        (Game.row - colCenter + i + 1) * Game.column - j - 1
                    ])
                }
            }
            
            let rowQuarter = Game.row / 4
            
            for i in 0..<rowQuarter {
                for j in 0..<rowQuarter - i {
                    toRemove.append(contentsOf: [
                        i * Game.column + j,
                        i * Game.column + colCenter + j,
                        i * Game.column + colCenter - j,
                        (i + 1) * Game.column - j - 1,
                    ])
                }
            }
            self.validArea.remove(atOffsets: IndexSet(toRemove))
        }
    }
}

extension Game {
    enum SHAPE {
        case NORMAL, HEART
    }
    enum HINT: Int {
        case NONE = -1
        case TYPE0 = 0, TYPE1 = 1, TYPE2 = 2 // -__, _-_, __-
    }
    
    static var row = Int(UIScreen.main.bounds.height - 300) / (Grid.size)
    static var column = Int(UIScreen.main.bounds.width - 50) / (Grid.size)
    static var size = row * column
}

class GameViewModel: ObservableObject {
    @Published var property: Game
    
    init(_ shape: Game.SHAPE = .NORMAL) {
        self.property = Game(shape)
    }
    
    func setShape(_ shape: Game.SHAPE = .NORMAL) {
        self.property.shape = shape
        self.property.setValidArea()
    }

    func restart() {
        self.property.timer?.invalidate()
        self.property = Game(self.property.shape)

        let _ = self.judge(with_animation: false)
        self.setMatchHint()
        
        self.property.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            if self.property.countDown != 0 {
                self.property.countDown -= 1

                let dateComponent = DateComponents(
                    calendar: .current,
                    hour: 0,
                    minute: Int(self.property.countDown) / 60,
                    second: Int(self.property.countDown) % 60
                )
                self.property.timerLabel = self.property.formatter.string(from: dateComponent.date!)
                
                if abs(self.property.lastSwap.timeIntervalSinceNow) > self.property.hintInterval &&
                    !self.property.isMatched && !self.property.disable {
                    self.property.showHint = true
                }
            }
            else if !self.property.disable {
                self.property.timer?.invalidate()
                self.property.gameOver = true
            }
        })
    }
    
    func resetBoard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.property.board.shuffle()
            let _ = self.judge(with_animation: false)
        }
        self.setMatchHint()
        self.property.lastSwap = .now
        self.property.showHint = false
    }
    
    func isNextTo(idx: Int, next: Int?) -> Bool {
        if let next = next {
            return self.property.validArea.contains(next) &&
                   abs(next % Game.column - idx % Game.column) <= 1
        }
        else {
            return false
        }
    }
    
    func swapGrid(idx: Int, x: Double, y: Double) {
        var next = idx

        if  abs(x) > abs(y) {
            next = (x > 0) ? idx + 1: idx - 1
        }
        else {
            next = (y > 0) ? idx + Game.column: idx - Game.column
        }
        
        if isNextTo(idx: idx, next: next) {
            self.property.board.swapAt(idx, next)
        }
    }
    
    func judge(with_animation: Bool = true) -> Bool {
        func setValue(start: Int, end: Int, step: Int) -> Bool {
            let range = stride(from: start, through: end, by: step)
    
            if range.underestimatedCount >= 3 {
                if with_animation {
                    self.property.combo += 1
                }
                for i in range {
                    self.property.board[i].scale = 0.5
                }
                return true
            }
            return false
        }
        func checkHorizontal() -> Bool {
            var start = 0
            var end = start
            var isMatched = false
            var metGap = false

            for idx in 0 ..< Game.size {
                if !self.property.validArea.contains(idx) {
                    metGap = true
                    continue
                }
                if metGap ||
                    idx % Game.column == 0 ||
                    self.property.board[idx].type != self.property.board[start].type {
                    metGap = false
                    isMatched = setValue(start: start, end: end, step: 1) || isMatched
                    start = idx
                }
                end = idx
            }
            isMatched = setValue(start: start, end: end, step: 1) || isMatched

            return isMatched
        }
        func checkVertical() -> Bool {
            var start = 0
            var end = start
            var isMatched = false
            var metGap = false

            for col in 0 ..< Game.column {
                for idx in stride(from: col, to: Game.size, by: Game.column) {
                    if !self.property.validArea.contains(idx) {
                        metGap = true
                        continue
                    }
                    if metGap ||
                        idx / Game.column == 0 ||
                        self.property.board[idx].type != self.property.board[start].type {
                        metGap = false
                        isMatched = setValue(start: start, end: end, step: Game.column) || isMatched
                        start = idx
                    }
                    end = idx
                }
            }
            isMatched = setValue(start: start, end: end, step: Game.column) || isMatched

            return isMatched
        }
        
        let isMatchableH = checkHorizontal()
        let isMatchableV = checkVertical()
        let isMatchable = isMatchableH || isMatchableV

        if isMatchable {
            if with_animation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        self.dropDown(with_animation: with_animation)
                    }
                }
            }
            else {
                self.dropDown(with_animation: with_animation)
            }
        }
        else {
            self.property.disable = false
            
            if with_animation {
                let combo: Double = Double(self.property.combo)
                self.property.score += Int(ceil((0.1 * (combo-1) + 1.0) * combo))
            }
        }
        return isMatchable
    }
    
    func dropDown(with_animation: Bool = true) {
        for idx in (0 ..< Game.size).reversed() {
            if self.property.board[idx].scale == 1 {
                for i in stride(from: idx, to: Game.size, by: Game.column).reversed() {
                    if self.property.board[i].scale < 1 {
                        self.property.board.swapAt(idx, i)
                        break
                    }
                }
            }
        }
        for idx in (0 ..< Game.size) {
            if self.property.board[idx].scale < 1 {
                self.property.board[idx] = Grid.random()
            }
        }

        if with_animation {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    let _ = self.judge(with_animation: true)
                }
            }
        }
        else {
            let _ = self.judge(with_animation: false)
        }
    }
    
    func setMatchHint() {
        func getCheckPoint(_ idx: Int, offset1: Int, offset2: Int) -> Array<Int>? {
            var result = [Int]()
            let indexList = Array(stride(from: idx, through: idx + 2 * offset1, by: offset1))
            let gridList = indexList.map { self.property.board[$0] }
            
            for i in indexList {
                if !self.property.validArea.contains(i) {
                    return nil
                }
            }

            if gridList[0].type == gridList[1].type {
                result.append(contentsOf: [indexList[0], indexList[1], indexList[2],
                                           indexList[2] - offset2, indexList[2] + offset2, indexList[2] + offset1])
            } else if gridList[0].type == gridList[2].type {
                result.append(contentsOf: [indexList[0], indexList[2], indexList[1],
                                           indexList[1] - offset2, indexList[1] + offset2])
            } else if gridList[1].type == gridList[2].type {
                result.append(contentsOf: [indexList[1], indexList[2], indexList[0],
                                           indexList[0] - offset2, indexList[0] + offset2, indexList[0] - offset1])
            } else {
                return nil
            }
            
            var toRemove = [Int]()
            for i in 3 ..< result.count {
                if !isNextTo(idx: result[2], next: result[i]) {
                    toRemove.append(i)
                }
            }
            result.remove(atOffsets: IndexSet(toRemove))

            return (result.count >= 3) ? result : nil
        }

        func getCheckList() -> Array<Array<Int>> {
            var checkList = [[Int]]()
            
            for idx in 0 ..< Game.size {
                if Game.column - idx % Game.column >= 3,
                   let checkPoint = getCheckPoint(idx, offset1: 1, offset2: Game.column) {
                    checkList.append(checkPoint)
                }
                if Game.row - idx / Game.column >= 3,
                    let checkPoint = getCheckPoint(idx, offset1: Game.column, offset2: 1) {
                    checkList.append(checkPoint)
                }
            }
            return checkList
        }
        
        let checkList = getCheckList()
        var hintList = [[Int]]()

        for checkPoint in checkList {
            for i in 3 ..< checkPoint.count {
                if self.property.board[checkPoint[0]].type == self.property.board[checkPoint[i]].type {
                    hintList.append([checkPoint[0], checkPoint[1], checkPoint[i]])
                }
            }
        }

        if hintList.count > 0 {
            self.property.matchHint = hintList.randomElement()!
        }
        else if checkList.count > 0, let candidate = checkList.filter({ $0.count > 3 }).randomElement() {
            self.property.matchHint = [candidate[0], candidate[1], candidate[3..<candidate.count].randomElement()!]
            let type = self.property.board[self.property.matchHint[0]].type
            self.property.board[self.property.matchHint[2]] = Grid(type)

            if self.judge(with_animation: false) {
                self.setMatchHint()
            }
        }
        else {
            self.resetBoard()
        }
    }
}
