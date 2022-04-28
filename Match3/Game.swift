//
//  Game.swift
//  Match3
//
//  Created by FanRende on 2022/4/28.
//

import SwiftUI

struct Game {
    var board: Array<Grid> = [Grid]()
    var row: Int
    var column: Int
    var size: Int
    var disable: Bool = false

    init(row: Int = 5, column: Int = 5) {
        self.row = row
        self.column = column
        self.size = self.row * self.column

        for _ in 0 ..< self.size * 3 {
//            self.board.append(Grid(Int.random(in: 1...Grid.typeNumber)))
            self.board.append(Grid(Int.random(in: 1...5)))
        }
    }
}

class GameViewModel: ObservableObject {
    @Published var property: Game = Game()
    
    init() {
        self.judge(with_animation: false)
    }
    
    func resetBoard() {
        self.property.board[self.property.size ..< self.property.size * 2].shuffle()
        self.judge(with_animation: false)
    }
    
    func swapGrid(idx: Int, x: Double, y: Double) {
        var next = idx

        if  abs(x) > abs(y) {
            next = (x > 0) ? idx + 1: idx - 1
        }
        else {
            next = (y > 0) ? idx + self.property.column: idx - self.property.column
        }
        
        if next >= self.property.size, next < self.property.size * 2,
           abs(next % self.property.column - idx % self.property.column) <= 1 {
            self.property.board.swapAt(idx, next)
        }
    }
    
    func judge(with_animation: Bool = true) {
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
        var tempBoard = self.property.board[self.property.size ..< self.property.size * 2]
        
        for idx in self.property.size ..< self.property.size * 2 {
            if self.property.board[idx].type > 0 {
                let matchLength_H = checkHorizontal(idx)
                let matchLength_V = checkVertical(idx)
                
                if matchLength_H >= 3 {
                    isMatchable = true
                    for i in idx ..< idx + matchLength_H {
                        tempBoard[i] = Grid()
                    }
                }
                if matchLength_V >= 3 {
                    isMatchable = true
                    for j in 0 ..< matchLength_V {
                        tempBoard[idx + j * self.property.column] = Grid()
                    }
                }
            }
            else {
                continue
            }
        }
        
        if isMatchable {
            self.property.board[self.property.size ..< self.property.size * 2] = tempBoard
            dropDown(with_animation: with_animation)
        }
        else {
            self.property.disable = false
        }
    }
    
    func dropDown(with_animation: Bool = true) {
        for idx in (0 ..< self.property.size * 2).reversed() {
            var this = idx
            var next = idx + self.property.column

            while self.property.board[this].type > 0,
                  next < self.property.size * 2,
                  self.property.board[next].type == 0 {
                self.property.board.swapAt(this, next)
                this = next
                next += self.property.column
            }
        }
        for idx in (0 ..< self.property.size) {
            if self.property.board[idx].type == 0 {
//                self.board.append(Grid(Int.random(in: 1...Grid.typeNumber)))
                self.property.board[idx] = Grid(Int.random(in: 1...5))
            }
        }
        
        if with_animation {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.judge(with_animation: with_animation)
                }
            }
        }
        else {
            self.judge(with_animation: with_animation)
        }
    }
}
