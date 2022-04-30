//
//  Game.swift
//  Match3
//
//  Created by FanRende on 2022/4/28.
//

import SwiftUI

struct Game {
    var board: Array<Grid> = [Grid]()
    var row: Int = Int(UIScreen.main.bounds.height) / Grid.size - 4
    var column: Int = Int(UIScreen.main.bounds.width) / Grid.size - 2
    var size: Int
    var disable: Bool = false
    var gameOver: Bool = false
    var score: Int = 0

    var matchHint: Array<Int> = [Int]()
    var lastSwap: Date = .now
    var hintInterval: Double = 3
    var showHint: Bool = false
    var isMatched: Bool = false

    var timer: Timer?
    var timeLimit: TimeInterval = 30
    var countDown: TimeInterval
    var timerLabel = String()
    var formatter = DateFormatter()

    init() {
        self.row = 3
        self.column = 3
        self.size = self.row * self.column

        for _ in 0 ..< self.size * 3 {
//            self.board.append(Grid(Int.random(in: 1...Grid.typeNumber)))
            self.board.append(Grid(Int.random(in: 1...5)))
        }

        self.countDown = self.timeLimit
        self.formatter.dateFormat = "mm:ss"

        let dateComponent = DateComponents(
            calendar: .current,
            hour: 0,
            minute: Int(self.countDown) / 60,
            second: Int(self.countDown) % 60
        )
        self.timerLabel = self.formatter.string(from: dateComponent.date!)
    }
}

extension Game {
    enum HINT: Int {
        case NONE = -1
        case TYPE0 = 0, TYPE1 = 1, TYPE2 = 2 // -__, _-_, __-
    }
}

class GameViewModel: ObservableObject {
    @Published var property: Game = Game()
    
    init() {
        self.restart()
    }
    
    func restart() {
        self.property = Game()

        let _ = self.judge(with_animation: false)
        self.setMatchHint()
        
        self.property.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            if self.property.countDown != 0 && !self.property.gameOver {
                self.property.countDown -= 1

                let dateComponent = DateComponents(
                    calendar: .current,
                    hour: 0,
                    minute: Int(self.property.countDown) / 60,
                    second: Int(self.property.countDown) % 60
                )
                self.property.timerLabel = self.property.formatter.string(from: dateComponent.date!)
                
                if abs(self.property.lastSwap.timeIntervalSinceNow) > self.property.hintInterval && !self.property.isMatched && !self.property.disable {
                    self.property.showHint = true
                }
            }
            else {
                self.property.timer?.invalidate()
                
                if self.property.countDown == 0 {
                    self.property.gameOver = true
                }
            }
        })
    }
    
    func resetBoard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.property.board[self.property.size ..< self.property.size * 2].shuffle()
            let _ = self.judge(with_animation: false)
        }
        self.setMatchHint()
        self.property.lastSwap = .now
        self.property.showHint = false
    }
    
    func isNextTo(idx: Int, next: Int?) -> Bool {
        if let next = next {
            return (self.property.size ..< self.property.size * 2).contains(next) &&
                   abs(next % self.property.column - idx % self.property.column) <= 1
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
            next = (y > 0) ? idx + self.property.column: idx - self.property.column
        }
        
        if isNextTo(idx: idx, next: next) {
            self.property.board.swapAt(idx, next)
        }
    }
    
    func judge(with_animation: Bool = true) -> Bool {
        func checkHorizontal(_ idx: Int) -> Int {
            var matchLength = 1
            let columnIdx = idx % self.property.column

            for temp in 1 ..< self.property.column - columnIdx {
                if self.property.board[idx + temp].type == self.property.board[idx].type {
                    matchLength += 1
                }
                else {
                    break
                }
            }
            return matchLength
        }
    
        func checkVertical(_ idx: Int) -> Int {
            var matchLength = 1
            var next = idx

            while next < self.property.size * 2 {
                next += self.property.column

                if next < self.property.size * 2,
                   self.property.board[next].type == self.property.board[idx].type {
                    matchLength += 1
                }
                else {
                    break
                }
            }
            return matchLength
        }
        
        var isMatchable = false
        var tempBoard = Array(self.property.board[self.property.size ..< self.property.size * 2])
        
        for idx in 0 ..< self.property.size {
            if self.property.board[idx + self.property.size].scale == 1 {
                let matchLength_H = checkHorizontal(idx + self.property.size)
                let matchLength_V = checkVertical(idx + self.property.size)
                
                if matchLength_H >= 3 {
                    self.property.score += (with_animation) ? 1 : 0
                    isMatchable = true

                    for i in idx ..< idx + matchLength_H {
                        tempBoard[i].scale = 0.1
                    }
                }
                if matchLength_V >= 3 {
                    self.property.score += (with_animation) ? 1 : 0
                    isMatchable = true

                    for j in 0 ..< matchLength_V {
                        tempBoard[idx + j * self.property.column].scale = 0.1
                    }
                }
            }
            else {
                continue
            }
        }
        
        if isMatchable {
            self.property.board[self.property.size ..< self.property.size * 2] = ArraySlice(tempBoard)
            
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
        }
        return isMatchable
    }
    
    func dropDown(with_animation: Bool = true) {
        for idx in (0 ..< self.property.size * 2).reversed() {
            var this = idx
            var next = idx + self.property.column

            while self.property.board[this].scale == 1,
                  next < self.property.size * 2,
                  self.property.board[next].scale < 1 {
                self.property.board.swapAt(this, next)
                this = next
                next += self.property.column
            }
        }
        for idx in (0 ..< self.property.size) {
            if self.property.board[idx].scale < 1 {
//                self.board.append(Grid(Int.random(in: 1...Grid.typeNumber)))
                self.property.board[idx] = Grid(Int.random(in: 1...5))
            }
        }

        if with_animation {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    let _ = self.judge(with_animation: with_animation)
                }
            }
        }
        else {
            let _ = self.judge(with_animation: with_animation)
        }
    }
    
    func setMatchHint() {
        func check(leading: Grid, center: Grid, trailing: Grid) -> Game.HINT {
            if center.type == trailing.type {
                return .TYPE0
            }
            else if leading.type == trailing.type {
                return .TYPE1
            }
            else if leading.type == center.type {
                return .TYPE2
            }

            return .NONE
        }
        func checkHorizontal(_ idx: Int) -> Game.HINT {
            if self.property.column - idx % self.property.column <= 2 {
                return .NONE
            }

            let leading = self.property.board[idx]
            let center = self.property.board[idx + 1]
            let trailing = self.property.board[idx + 2]
            
            return check(leading: leading, center: center, trailing: trailing)
        }
        func checkVertical(_ idx: Int) -> Game.HINT {
            if self.property.row - (idx - self.property.size) / self.property.column <= 2 {
                return .NONE
            }

            let leading = self.property.board[idx]
            let center = self.property.board[idx + self.property.column]
            let trailing = self.property.board[idx + self.property.column * 2]
            
            return check(leading: leading, center: center, trailing: trailing)
        }
        func findMatch(theSame2: Array<Int>, candidate0: Int?, candidate1: Int?, candidate2: Int?) -> Array<Int> {
            var result = theSame2

            if let candidate0 = candidate0,
               self.property.board[candidate0].type == self.property.board[theSame2[0]].type {
                result.append(candidate0)
            }
            else if let candidate1 = candidate1,
               self.property.board[candidate1].type == self.property.board[theSame2[0]].type {
                result.append(candidate1)
            }
            else if let candidate2 = candidate2,
                self.property.board[candidate2].type == self.property.board[theSame2[0]].type {
                result.append(candidate2)
            }

            return result
        }
        
        var hintList = [[Int]]()
        var candidateList = [[Int]]()

        for idx in self.property.size ..< self.property.size * 2 {
            let matchType_H = checkHorizontal(idx)
            let matchType_V = checkVertical(idx)
            var candidate0: Int?
            var candidate1: Int?
            var candidate2: Int? = nil
            var theSame2: Array<Int>
            
            if matchType_H != .NONE {
                theSame2 = [
                    idx + (matchType_H.rawValue + 1) % 3,
                    idx + (matchType_H.rawValue + 2) % 3
                ]
                candidate0 = idx - self.property.column + matchType_H.rawValue
                candidate1 = idx + self.property.column + matchType_H.rawValue
                
                if matchType_H == .TYPE0 && idx % self.property.column > 0 {
                    candidate2 = idx - 1
                }
                else if matchType_H == .TYPE2 && idx % self.property.column <= self.property.column - 3 {
                    candidate2 = idx + 3
                }
                else {
                    candidate2 = nil
                }

                let swapGrid = (candidate0! + candidate1!) / 2
                candidate0 = isNextTo(idx: swapGrid, next: candidate0) ? candidate0 : nil
                candidate1 = isNextTo(idx: swapGrid, next: candidate1) ? candidate1 : nil
                candidate2 = isNextTo(idx: swapGrid, next: candidate2) ? candidate1 : nil

                let result = findMatch(theSame2: theSame2, candidate0: candidate0, candidate1: candidate1, candidate2: candidate2)

                if result.count >= 3 {
                    hintList.append(result)
                }
                else {
                    if let candidate0 = candidate0 {
                        candidateList.append([theSame2[0], theSame2[1], candidate0])
                    }
                    if let candidate1 = candidate1 {
                        candidateList.append([theSame2[0], theSame2[1], candidate1])
                    }
                    if let candidate2 = candidate2 {
                        candidateList.append([theSame2[0], theSame2[1], candidate2])
                    }
                }
            }
            if matchType_V != .NONE {
                theSame2 = [
                    idx + ((matchType_V.rawValue + 1) % 3) * self.property.column,
                    idx + ((matchType_V.rawValue + 2) % 3) * self.property.column
                ]
                candidate0 = idx - 1 + self.property.column * matchType_V.rawValue
                candidate1 = idx + 1 + self.property.column * matchType_V.rawValue

                if matchType_V == .TYPE0 && idx / self.property.column > 0 {
                    candidate2 = idx - self.property.column
                }
                else if matchType_V == .TYPE2 && idx / self.property.column <= self.property.row - 3 {
                    candidate2 = idx + 3 * self.property.column
                }
                else {
                    candidate2 = nil
                }
                
                let swapGrid = (candidate0! + candidate1!) / 2
                candidate0 = isNextTo(idx: swapGrid, next: candidate0) ? candidate0 : nil
                candidate1 = isNextTo(idx: swapGrid, next: candidate1) ? candidate1 : nil
                candidate2 = isNextTo(idx: swapGrid, next: candidate2) ? candidate1 : nil
                
                let result = findMatch(theSame2: theSame2, candidate0: candidate0, candidate1: candidate1, candidate2: candidate2)

                if result.count >= 3 {
                    hintList.append(result)
                }
                else {
                    if let candidate0 = candidate0 {
                        candidateList.append([theSame2[0], theSame2[1], candidate0])
                    }
                    if let candidate1 = candidate1 {
                        candidateList.append([theSame2[0], theSame2[1], candidate1])
                    }
                    if let candidate2 = candidate2 {
                        candidateList.append([theSame2[0], theSame2[1], candidate2])
                    }
                }
            }
        }
        
        if hintList.count > 0 {
            self.property.matchHint = hintList.randomElement()!
        }
        else if candidateList.count > 0 {
            self.property.matchHint = candidateList.randomElement()!
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
