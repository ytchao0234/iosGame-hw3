//
//  Grid.swift
//  Match3
//
//  Created by FanRende on 2022/4/28.
//

import SwiftUI

struct Grid: Identifiable {
    let id = UUID()
    var type: Int = 0
    var image: String = ""
    var scale: CGFloat = 1
//    var color: Color = .clear
    
    init(_ i: Int = 0) {
        self.type = i
//        self.color = Grid.colorList[i]
        self.image = Grid.imageList[i]
    }
}

extension Grid {
    static var size: Int = 50
    static var typeNumber = 11
    static let imageList: Array<String> = Array(0...typeNumber).map { "\($0)" }
//    static let colorList: Array<Color> = Array(0...typeNumber).map { _ in
//        Color.blue
//    }
}
