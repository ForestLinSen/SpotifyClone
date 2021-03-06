//
//  RecommendationResponse.swift
//  SpotifyClone
//
//  Created by Sen Lin on 23/2/2022.
//

import Foundation

struct RecommendationResponse: Codable{
    let tracks: [AudioTrack]
}

struct AudioTrack: Codable{
    let album: Album
    let artists: [Artist]
    let disc_number: Int
    let duration_ms: Int
    let explicit: Bool
    let external_urls: [String: String]
    let id: String
    let name: String
    let popularity: Int
    let preview_url: String?
    let uri: String
}
