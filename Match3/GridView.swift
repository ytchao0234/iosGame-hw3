//
//  GridView.swift
//  Match3
//
//  Created by FanRende on 2022/4/27.
//

import SwiftUI

struct GridView: View {
    let grid: Grid
    var body: some View {
        ZStack {
//            grid.color
            
            if grid.type > 0 {
                Image(grid.image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(grid.scale)
            }
        }
        .cornerRadius(5)
    }
}

struct GridView_Previews: PreviewProvider {
    static var previews: some View {
        GridView(grid: Grid(1))
    }
}
