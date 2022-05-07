//
//  GameView.swift
//  Match3
//
//  Created by FanRende on 2022/4/27.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var game: GameViewModel
    @Binding var startGame: Bool

    var body: some View {
        VStack {
            HStack {
                Button("<") {
                    startGame = false
                }
                .font(.title)
                Spacer()
                Text("\(game.property.timerLabel)")
                    .font(.title)
                Spacer()
                Button("<") {
                    startGame = false
                }
                .font(.title)
                .hidden()
            }
            .padding([.top, .horizontal])

            HStack {
                let timeLimit = game.property.timeLimit
                Capsule()
                    .fill((game.property.countDown / timeLimit > 0.5) ? .blue : (game.property.countDown / timeLimit > 0.25) ? .yellow : .red)
                    .frame(height: 10)
                    .scaleEffect(x: game.property.countDown / timeLimit, y: 1, anchor: .leading)
                    .padding(.horizontal)
                    .animation(.linear(duration: 1), value: game.property.countDown)
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()

            BoardView(game: game)
            
            Spacer()

            HStack {
                Button {
                    game.restart()
                } label: {
                    Image(systemName: "gobackward")
                        .resizable()
                        .scaleEffect()
                        .frame(width: 30, height: 30)
                }
                Spacer()
                Text("\(game.property.score)")
                    .font(.largeTitle)
                
                Spacer()
                Button {
                    game.resetBoard()
                } label: {
                    Image(systemName: "shuffle")
                        .resizable()
                        .scaleEffect()
                        .frame(width: 30, height: 30)
                }
            }
            .padding(20)
        }
        .alert("Game Over!", isPresented: $game.property.gameOver) {
            Button("OK") {
                game.restart()
            }
        }
        .navigationBarHidden(true)
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(game: GameViewModel(), startGame: .constant(true))
    }
}

struct BoardView: View {
    @ObservedObject var game: GameViewModel

    func dragGesture(idx: Int) -> some Gesture {
        DragGesture()
            .onEnded({ value in
                if game.property.validArea.contains(idx) {
                    game.property.disable = true

                    withAnimation(.easeOut(duration: 0.3)) {
                        game.swapGrid(idx: idx, x: value.translation.width, y: value.translation.height)
                        
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            if !game.judge() {
                                game.swapGrid(idx: idx, x: value.translation.width, y: value.translation.height)
                            }
                            else {
                                game.property.showHint = false
                                game.property.isMatched = true
                            }
                        }
                    }
                }
            })
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(minimum: CGFloat(Grid.size), maximum: CGFloat(Grid.size)), spacing: 0), count: Game.column)
        
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(game.property.board.enumerated()), id: \.element.id) { idx, grid in
                if game.property.validArea.contains(idx), grid.scale == 1 {
                    GridView(grid: grid)
                        .overlay {
                            ZStack {
                                if game.property.matchHint.contains(idx) && game.property.showHint {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color(red: 0.99, green: 0.96, blue: 0.89), lineWidth: 3)
                                }
                            }
                            .animation(.easeOut(duration: 0.5), value: game.property.showHint)
                        }
                        .padding(3)
                        .gesture(dragGesture(idx: idx))
                        .transition(.asymmetric(insertion: .offset(x: 0, y: -CGFloat(Grid.size * Game.row)), removal: .scale))
                }
                else {
                    GridView(grid: grid).hidden()
                }
            }
        }
        .background(Background(game: game, columns: columns))
        .clipped()
        .padding()
        .disabled(game.property.disable && game.property.gameOver)
        .onChange(of: game.property.disable) { value in
            if !value && game.property.isMatched {
                game.property.lastSwap = .now
                game.setMatchHint()
                game.property.isMatched = false
            }
        }
    }
}

struct Background: View {
    @ObservedObject var game: GameViewModel
    let columns: Array<GridItem>
    
    func getCorner(_ idx: Int) -> UIRectCorner {
        var result = UIRectCorner()
        var temp = [false, false, false, false]
        
        for (i, j) in [-1, 1, -Game.column, Game.column].enumerated() {
            let isValid = game.isNextTo(idx: idx, next: idx + j)
            if !isValid  || (isValid && !game.property.validArea.contains(idx+j)){
                temp[i] = true
            }
        }
        
        if temp[0] && temp[2] {
            result.insert(.topLeft)
        }
        if temp[1] && temp[2] {
            result.insert(.topRight)
        }
        if temp[0] && temp[3] {
            result.insert(.bottomLeft)
        }
        if temp[1] && temp[3] {
            result.insert(.bottomRight)
        }

        return result
    }
    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(0..<Game.size), id: \.self) { idx in
                if game.property.validArea.contains(idx) {
                    Color(red: 0.70, green: 0.63, blue: 0.53)
                        .cornerRadius(10, corners: getCorner(idx))
                }
                else {
                    Color.clear
                }
            }
            .frame(width: CGFloat(Grid.size), height: CGFloat(Grid.size))
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
