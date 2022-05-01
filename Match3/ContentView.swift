//
//  ContentView.swift
//  Match3
//
//  Created by FanRende on 2022/4/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject var game = GameViewModel()
    @State var levelList: Array<Level> = Level.defaultList

    var body: some View {
        NavigationView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(maximum: 120)), count: 3)) {
                ForEach(levelList.indices) { idx in
                    Button {
                        Grid.size = levelList[idx].gridSize
                        game.setShape(levelList[idx].boardShape)
                        game.restart()
                        levelList[idx].startGame = true
                    } label: {
                        Text("\(levelList[idx].name) \(idx % 3 + 1)")
                            .font(.title2)
                            .foregroundColor(.yellow)
                            .padding()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .background(.blue)
                            .cornerRadius(10)
                    }
                    .background(
                        NavigationLink(isActive: $levelList[idx].startGame, destination: {
                            GameView(game: game, startGame: $levelList[idx].startGame)
                        }, label: {
                            EmptyView()
                        })
                    )
                }
            }
//            .padding(30)
            .navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Level {
    var gridSize: Int
    var boardShape: Game.SHAPE
    var name: String
    var startGame: Bool = false
    
    static var defaultList = [
        Level(gridSize: 60, boardShape: .NORMAL, name: "Normal"),
        Level(gridSize: 50, boardShape: .NORMAL, name: "Normal"),
        Level(gridSize: 40, boardShape: .NORMAL, name: "Normal"),
        Level(gridSize: 60, boardShape: .HEART, name: "Heart"),
        Level(gridSize: 50, boardShape: .HEART, name: "Heart"),
        Level(gridSize: 40, boardShape: .HEART, name: "Heart"),
    ]
}
