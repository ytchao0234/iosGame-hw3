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
            VStack {
                Text("Kitty Crush")
                    .font(.custom("Hannotate TC", size: 60))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.99, green: 0.96, blue: 0.89))
                    .padding(.top, 40)
                VStack {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(maximum: 120)), count: 3)) {
                        ForEach(levelList.indices) { idx in
                            Button {
                                Grid.size = levelList[idx].gridSize
                                game.setShape(levelList[idx].boardShape)
                                game.restart()
                                levelList[idx].startGame = true
                            } label: {
                                Text("\(levelList[idx].name) \(idx % 3 + 1)")
                                    .font(.custom("Hannotate TC", size: 18))
                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                                    .foregroundColor(Color(red: 0.99, green: 0.96, blue: 0.89))
                                    .padding(10)
                                    .background(Color(red: 0.60, green: 0.53, blue: 0.43))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 7)
                                            .stroke(Color(red: 0.99, green: 0.96, blue: 0.89), lineWidth: 3)
                                            .padding(4)
                                    }
                            }
                            .background(
                                NavigationLink(isActive: $levelList[idx].startGame, destination: {
                                    GameView(game: game, level: idx, startGame: $levelList[idx].startGame)
                                }, label: {
                                    EmptyView()
                                })
                            )
                        }
                    }
                    Spacer()
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .padding()
                .background(Color(red: 0.89, green: 0.86, blue: 0.79))
                .cornerRadius(10)
                .padding([.bottom, .horizontal])
            }
            .ignoresSafeArea()
            .background(Color(red: 0.50, green: 0.43, blue: 0.33))
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
