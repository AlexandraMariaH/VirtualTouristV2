//
//  PhotoResponse.swift
//  VirtualTouristV2
//
//  Created by Alexandra Hufnagel on 01.08.21.
//

import Foundation

struct PhotoResponse: Decodable {
    let photos: Photos
}

struct Photos: Decodable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [PhotoDetails]
}

struct PhotoDetails: Decodable {
    let id: String
    let server: String
    let secret: String
}
