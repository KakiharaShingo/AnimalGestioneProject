//
//  week.swift
//  AnimalGestioneProject
//
//  Created by 垣原親伍 on 2024/04/03.
//

import Foundation

struct WeekContent {
    init() {}

    func GetWeekNumber(year: Int, month: Int) -> Int {
        var result = 0
        if CaseFourWeek(year: year, month: month) {
            result = 4
        } else if CaseSixWeek(year: year, month: month) {
            result = 6
        } else {
            result = 5
        }
        return result
    }

    private func CaseFourWeek(year: Int, month: Int) -> Bool {
        let firstdayofweek = Zeller().DayofWeekCalc(year: year, month: month, day: 1)
        let result = (!LeapYear(year: year) && month == 2 && (firstdayofweek == 0)) ? true : false
        return result
    }

    private func CaseSixWeek(year: Int, month: Int) -> Bool {
        let firstdayofweek = Zeller().DayofWeekCalc(year: year, month: month, day: 1)
        let days = CurrentMonth().DayNumber(year: year, month: month)
        let result = ((firstdayofweek == 6 && days == 30) || (firstdayofweek >= 5 && days == 31)) ? true : false
        return result
    }
}
