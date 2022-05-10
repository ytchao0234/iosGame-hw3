//
//  GameView.swift
//  Match3
//
//  Created by FanRende on 2022/4/27.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var game: GameViewModel
    let level: Int
    @Binding var startGame: Bool
    @AppStorage var bestRecord: Int
    
    init(game: GameViewModel, level: Int, startGame: Binding<Bool>) {
        self.game = game
        self.level = level
        self._startGame = Binding(projectedValue: startGame)
        self._bestRecord = AppStorage(wrappedValue: 0, "bestRecord\(level)")
    }

    var body: some View {
        VStack {
            MenuView(game: game, level: level, startGame: $startGame)
                .padding()
                .background(Color(red: 0.89, green: 0.86, blue: 0.79))
                .cornerRadius(10)
                .padding(.top, 40)
                .padding(7)

            VStack {
                TimeView(game: game)
                Spacer()
                BoardView(game: game)
                Spacer()
            }
            .padding(2)
            .padding(.top, 10)
            .background(Color(red: 0.89, green: 0.86, blue: 0.79))
            .cornerRadius(10)
            .padding()
        }
        .ignoresSafeArea()
        .background(Color(red: 0.50, green: 0.43, blue: 0.33))
        .alert((game.property.score > bestRecord) ? "Break the Record!" : "Game Over!", isPresented: $game.property.gameOver, actions: {
            Button("OK") {
                if game.property.score > bestRecord {
                    bestRecord = game.property.score
                }
                game.restart()
            }
        }, message: {
            Text("Your Score: \(game.property.score)")
        })
        .navigationBarHidden(true)
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(game: GameViewModel(), level: 0, startGame: .constant(true))
    }
}

struct MenuView: View {
    @ObservedObject var game: GameViewModel
    let level: Int
    @Binding var startGame: Bool
    @AppStorage var bestRecord: Int
    
    init(game: GameViewModel, level: Int, startGame: Binding<Bool>) {
        self.game = game
        self.level = level
        self._startGame = Binding(projectedValue: startGame)
        self._bestRecord = AppStorage(wrappedValue: 0, "bestRecord\(level)")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Best Record: \(bestRecord)")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(red: 0.60, green: 0.53, blue: 0.43))
                    .frame(width: 150, alignment: .leading)
                Text("\(game.property.score)")
                    .font(.system(size: 24, weight: .regular, design: .monospaced))
                    .frame(width: 100, alignment: .trailing)
                    .foregroundColor(Color(red: 0.99, green: 0.96, blue: 0.89))
                    .padding(5)
                    .background(Color(red: 0.60, green: 0.53, blue: 0.43))
                    .cornerRadius(5)
            }

            Spacer()
            
            Group {
                Button {
                    game.property.timer?.invalidate()
                    startGame = false
                } label: {
                    Image(systemName: "house")
                        .resizable()
                }
                Button {
                    game.restart()
                } label: {
                    Image(systemName: "gobackward")
                        .resizable()
                }
                Button {
                    game.resetBoard()
                } label: {
                    Image(systemName: "shuffle")
                        .resizable()
                }
            }
            .frame(width: 20, height: 20)
            .foregroundColor(Color(red: 0.99, green: 0.96, blue: 0.89))
            .padding(10)
            .background(Color(red: 0.60, green: 0.53, blue: 0.43))
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color(red: 0.99, green: 0.96, blue: 0.89), lineWidth: 3)
                    .scaleEffect(0.8)
            }
            .padding(.horizontal, 5)

        }
    }
}

struct TimeView: View {
    @ObservedObject var game: GameViewModel

    var body: some View {
        HStack {
            let timeLimit = game.property.timeLimit
            let colorList = [Color(red: 0.99, green: 0.96, blue: 0.89), .yellow, .red]
            
            Group {
                Label(game.property.timerLabel, systemImage: "clock")
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(red: 0.99, green: 0.96, blue: 0.89))
                    .padding(5)

                Capsule()
                    .fill((game.property.countDown / timeLimit > 0.5) ? colorList[0] : (game.property.countDown / timeLimit > 0.25) ? colorList[1] : colorList[2])
                    .frame(height: 10)
                    .scaleEffect(x: game.property.countDown / timeLimit, y: 1, anchor: .leading)
                    .padding(10)
                    .animation(.linear(duration: 1), value: game.property.countDown)
            }
            .background(Color(red: 0.60, green: 0.53, blue: 0.43))
            .cornerRadius(5)
            Spacer()
        }
        .padding(.horizontal)
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
                            game.property.combo = 0

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
                        .padding(5)
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
        .disabled(game.property.disable || game.property.gameOver)
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
                    Color(red: 0.60, green: 0.53, blue: 0.43)
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
