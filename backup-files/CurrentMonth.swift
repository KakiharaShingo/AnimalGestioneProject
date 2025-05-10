//
//  currentMonth.swift
//  AnimalGestioneProject
//
//  Created by 垣原親伍 on 2024/04/03.
//

import Foundation

struct CurrentMonth{
    init(){}
    
    func DayNumber(year:Int,month:Int) -> Int{
        var result : Int = 0
            
        switch month {
        case 1,3,5,7,8,10,12:
            result = 31
        case 4,6,9,11:
            result = 30
        case 2:
            if LeapYear(year: year){
                result = 29
            }else{
                result = 28
            }
        default: break
        }
        return result
    }
}

