//
//  VTResponse.swift
//  VirtualTouristV2
//
//  Created by Alexandra Hufnagel on 01.08.21.
//

import Foundation
// like OnTheMap
struct VTResponse: Codable {
    let statusCode: Int
    let statusMessage: String
    
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}

extension VTResponse: LocalizedError {
    var errorDescription: String? {
        return statusMessage
    }
}
