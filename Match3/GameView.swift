//
//  GameView.swift
//  Match3
//
//  Created by FanRende on 2022/4/27.
//

import SwiftUI

struct GameView: View {
    @StateObject var game = GameViewModel()

    var body: some View {
        ZStack {
            BoardView(game: game)

            maskView(size: CGSize(width: (Grid.size + 20) * game.property.column, height: (Grid.size + 8) * game.property.row))
                .allowsHitTesting(false)

            Text("\(game.property.score)")
                .font(.largeTitle)
                .foregroundColor(.black)
                .offset(y: -UIScreen.main.bounds.height / 2 + 50)
            
            Text("\(game.property.timerLabel)")
                .font(.title)
                .foregroundColor(.black)
                .offset(y: -UIScreen.main.bounds.height / 2 + 100)
            HStack {
                Capsule()
                    .fill((game.property.timeLimit / 30 > 0.5) ? .blue : (game.property.timeLimit / 30 > 0.25) ? .yellow : .red)
                    .frame(height: 10)
                    .scaleEffect(x: game.property.timeLimit / 30, y: 1, anchor: .leading)
                    .padding()
                    .animation(.easeIn(duration: 1), value: game.property.timeLimit)
                Spacer()
            }
            .offset(y: -UIScreen.main.bounds.height / 2 + 120)
            
            Button("Shuffle") {
                game.resetBoard()
            }
            .font(.title)
            .offset(y: UIScreen.main.bounds.height / 2 - 50)
        }
        .alert("Game Over!", isPresented: $game.property.gameOver) {
            Button("OK") {
                game.restart()
            }
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}

struct BoardView: View {
    @ObservedObject var game: GameViewModel

    func dragGesture(idx: Int) -> some Gesture {
        DragGesture()
            .onEnded({ value in
                if idx >= game.property.size, idx < game.property.size * 2 {
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
        let columns = Array(repeating: GridItem(.flexible(minimum: CGFloat(Grid.size), maximum: CGFloat(Grid.size))), count: game.property.column)

        LazyVGrid(columns: columns) {
            ForEach(Array(game.property.board.enumerated()), id: \.element.id) { idx, grid in
                GridView(grid: grid)
                    .overlay {
                        ZStack {
                            if game.property.matchHint.contains(idx) && game.property.showHint {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.yellow, lineWidth: 3)
                            }
                        }
                        .animation(.easeOut(duration: 0.5), value: game.property.showHint)
                    }
                    .gesture(dragGesture(idx: idx))
            }
        }
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

struct maskView: View {
    @State var size: CGSize

    var body: some View {
        ZStack {
            Rectangle()
            RoundedRectangle(cornerRadius: 10)
                .padding(.horizontal)
                .frame(width: size.width, height: size.height)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }
}
