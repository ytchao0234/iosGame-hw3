//
//  Game.swift
//  Match3
//
//  Created by FanRende on 2022/4/27.
//

import SwiftUI

struct Game {
    var board: Array<Grid> = [Grid]()
    var match: Array<Game.DIRECTION> = [DIRECTION]()
    var row: Int
    var column: Int
    var size: Int

    init(row: Int = 5, column: Int = 5) {
        self.row = row
        self.column = column
        self.size = self.row * self.column

        for _ in 0 ..< self.size {
            self.board.append(Grid(Int.random(in: 1...Grid.typeNumber)))
        }
    }
}

extension Game {
    enum DIRECTION {
        case NONE
        case TOP0, TOP1, TOP2          // -__, _-_, __-
        case BOTTOM0, BOTTOM1, BOTTOM2 // _--, -_-, --_
        case LEFT0, LEFT1, LEFT2       // -=
        case RIGHT0, RIGHT1, RIGHT2    // =-
    }
}

struct GameView: View {
    @StateObject var game = GameViewModel()
    
    func dragGesture(idx: Int) -> some Gesture {
        DragGesture()
            .onEnded({ value in
                withAnimation(.easeOut(duration: 0.5)) {
                    game.swapGrid(idx: idx, x: value.translation.width, y: value.translation.height)
                }
            })
    }

    var body: some View {
        let columns = Array(repeating: GridItem(), count: game.property.column)
        
        LazyVGrid(columns: columns) {
            ForEach(Array(game.property.board.enumerated()), id: \.element.id) { idx, grid in
                GridView(grid: grid)
                    .gesture(dragGesture(idx: idx))
            }
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}

class GameViewModel: ObservableObject {
    @Published var property: Game = Game()
    
    func resetBoard() {
        self.property.board.removeAll()

        for _ in 0 ..< self.property.size {
            self.property.board.append(Grid(Int.random(in: 1...Grid.typeNumber)))
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
        
        if next >= 0, next < self.property.size,
           abs(next % self.property.column - idx % self.property.column) <= 1 {
            self.property.board.swapAt(idx, next)
        }
    }
    
    func verifyBoard() {
        func checkHorizontal(_ idx: Int) -> Game.DIRECTION {
            let type0 = self.property.board[idx].type
            let type1 = self.property.board[idx+1].type
            let type2 = self.property.board[idx+2].type

            if type1 == type2 {
                
            }
            else if type0 == type2 {
                
            }
            else if type0 == type1 {
                
            }
            return .NONE
        }
        
        for _ in 0 ..< self.property.row {
            for temp in 0 ..< self.property.column - 2 {
                self.property.match[temp] = checkHorizontal(temp)
            }
        }
    }
}
