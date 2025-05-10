//
//  zeller.swift
//  AnimalGestioneProject
//
//  Created by 垣原親伍 on 2024/04/03.
//

import Foundation

struct Zeller {
    init() {}

    func DayofWeekCalc(year: Int, month: Int, day: Int) -> Int {
        var result = 0
        if month == 1 || month == 2 { // monthが1,2の時は前年として計算をする
            var changeyear: Int = year
            var changemonth: Int = month
            changeyear -= 1
            changemonth += 12
            result = (day + (26 * (changemonth + 1)) / 10 + changeyear + (changeyear / 4) + (5 * (changeyear / 100)) + ((changeyear / 100) / 4) + 5) % 7 as Int
        } else {
            result = (day + (26 * (month + 1)) / 10 + year + (year / 4) + (5 * (year / 100)) + ((year / 100) / 4) + 5) % 7 as Int
        }
        return result
    }
}
