//
//  leapYear.swift
//  AnimalGestioneProject
//
//  Created by 垣原親伍 on 2024/04/03.
//

import Foundation

func LeapYear(year:Int) -> Bool {
    let result =  (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0 )) ? true : false
    return result
}
