//
//  Grid.swift
//  Match3
//
//  Created by FanRende on 2022/4/27.
//

import SwiftUI

struct Grid: Identifiable {
    let id = UUID()
    var type: Int = 0
    var image: String = ""
//    var color: Color = .clear
    
    init(_ i: Int) {
        self.type = i
//        self.color = Grid.colorList[i]
        self.image = Grid.imageList[i]
    }
}

extension Grid {
    static var typeNumber = 11
    static let imageList: Array<String> = Array(0...typeNumber).map { "\($0)" }
//    static let colorList: Array<Color> = Array(0...typeNumber).map { _ in
//        Color.blue
//    }
}

struct GridView: View {
    let grid: Grid
    var body: some View {
        ZStack {
//            grid.color
            
            if grid.type > 0 {
                Image(grid.image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 50, height: 50)
        .cornerRadius(5)
    }
}

struct GridView_Previews: PreviewProvider {
    static var previews: some View {
        GridView(grid: Grid(1))
    }
}
