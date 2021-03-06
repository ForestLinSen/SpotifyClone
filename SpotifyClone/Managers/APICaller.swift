//
//  APICaller.swift
//  SpotifyClone
//
//  Created by Sen Lin on 17/2/2022.
//

import Foundation

final class APICaller{
    static let shared = APICaller()
    
    private init(){}
    
    // MARK: - User Profile
    
    public func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void){
        
        createRequest(with: URL(string: K.baseAPIURL + "/me"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    print("Debug: cannot fetch user profile")
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do{
//                     let jsonData = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
//                     print("Debug: json data of user profile \(jsonData)")
//                    print("Debug: begin to convert user profile")
                    let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                    print("Debug: user profile data model: \(profile)")
                    completion(.success(profile))
                }catch{
                    print("Cannot convert user profile model: \(error)")
                }
            }
            
            task.resume()
        }
    }
    
    
    // MARK: - New releases
    
    public func getReleases(completion: @escaping (Result<NewReleasesResponse, Error>) -> Void){
        
        let requestString = K.baseAPIURL + "/browse/new-releases?limit=10"
        
        createRequest(with: URL(string: requestString), type: .GET) { request in
            let dataTask = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do{
                    let releases = try JSONDecoder().decode(NewReleasesResponse.self, from: data)
                    
                    completion(.success(releases))
                    
                }catch{
                    completion(.failure(APIError.failedToGetData))
                    print("Debug: release response error: \(error)")
                }
                
            }
            
            dataTask.resume()
        }
    }
    
    
    // MARK: - Playlists
    
    public func getFeaturedPlaylists(completion: @escaping (Result<FeaturedPlaylistsResponse, Error>) -> Void){
        let requestString = K.baseAPIURL + "/browse/featured-playlists?limit=10"
        createRequest(with: URL(string: requestString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do{
                    let featuredReleases = try JSONDecoder().decode(FeaturedPlaylistsResponse.self, from: data)
                    completion(.success(featuredReleases))
                    
                }catch{
                    print("Debug: cannot fetch featured releases: \(error)")
                    completion(.failure(APIError.failedToGetData))
                }
            }
            
            task.resume()
            
        }
    }
    
    
    // MARK: - Track
    
    public func getRecommendation(completion: @escaping (Result<RecommendationResponse, Error>) -> Void){
        getGenres {[weak self] result in
            switch result{
            case .success(let genres ):
                var genreSeed = Set<String>()
                
                while(genreSeed.count < 5){
                    if let genre = genres.genres.randomElement(){
                        genreSeed.insert(genre)
                    }
                }
                
                let genresString = genreSeed.joined(separator: ",")
                
                let recommendationString = K.baseAPIURL + "/recommendations?limit=15&seed_genres=\(genresString)"
                //print("Debug: recommendation url: \(recommendationString)")
                self?.createRequest(with: URL(string: recommendationString), type: .GET) { request in
                    let task = URLSession.shared.dataTask(with: request) { data, _, error in
                        guard let data = data, error == nil else{
                            completion(.failure(APIError.failedToGetData))
                            print("Debug: error getting recommendation: \(error)")
                            return
                        }
                        
                        do{
                            let recommendation = try JSONDecoder().decode(RecommendationResponse.self, from: data)
                            //print("Debug: recommendation \(recommendation)")
                            
                            completion(.success(recommendation))
                        }catch{}
                        
                        
                    }
                    task.resume()
                }
                
                
            case .failure(_):
                break
            }
        }
    }
    
    
    public func getGenres(completion: @escaping (Result<Genres, Error>) -> Void){
        let requestString = K.baseAPIURL + "/recommendations/available-genre-seeds"
        
        createRequest(with: URL(string: requestString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do{
       
                    let genres = try JSONDecoder().decode(Genres.self, from: data)
                    completion(.success(genres))
                    
                }catch{}

            }
            
            task.resume()
        }
    }
    
    
    // MARK: - Album
    func getAlbumDetail(albumID: String, completion: @escaping (Result<AlbumDetailResponse, Error>) -> Void){
        let requestString = K.baseAPIURL + "/albums/\(albumID)"
        
        createRequest(with: URL(string: requestString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                //print("Debug: request string \(requestString)")
                
                guard let data = data, error == nil else{
                    print("Debug: error in fetching album: \(error)")
                    completion(.failure(APIError.failedToGetData))
                    return
                }

                do{
                    //let jsonData = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                    //print("Debug: album detail \(jsonData)")
                    
                    let albumDetail = try JSONDecoder().decode(AlbumDetailResponse.self, from: data)
                    completion(.success(albumDetail))
                    
                }catch{
                    completion(.failure(APIError.failedToConvertData))
                    print("Debug: error in fetching album: \(error)")
                }
                
            }
            
            task.resume()
        }
    }
    
    
    func getUserSavedAlbums(completion: @escaping (Result<LibraryAlbumsResponse, Error>) -> Void){
        let requestString = K.baseAPIURL + "/me/albums?limit=5"
        
        AuthManager.shared.withValideToken {[weak self] token in
            self?.createRequest(with: URL(string: requestString), type: .GET) { request in
                var request = request
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
                        return
                    }
                    
                    do{
                        let albums = try JSONDecoder().decode(LibraryAlbumsResponse.self, from: data)
                        completion(.success(albums))
                        
                    }catch{
                        completion(.failure(APIError.failedToConvertData))
                    }

                }
                
                task.resume()
            }
        }
    }
    
    
    func saveAlbum(albumID: String, completion: @escaping (Bool) -> Void){
        let requestString = K.baseAPIURL + "/me/albums?ids=\(albumID)"
        
        AuthManager.shared.withValideToken {[weak self] token in
            self?.createRequest(with: URL(string: requestString), type: .PUT) { request in
                var request = request
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: request) { data, _, error in
                    guard let data = data, error == nil else {
                        print("Debug: cannot save this album")
                        return
                    }
                    
                    do{
                        let jsonData = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                        print(jsonData)
                        completion(true)
                    }catch{}

                }
                
                task.resume()
            }
        }
        
    }
    
    
    // MARK: - Playlist
    func getPlaylistDetail(playlistID: String, completion: @escaping (Result<PlaylistDetailResponse, Error>) -> Void){
        let requestString = K.baseAPIURL + "/playlists/\(playlistID)"
        
        createRequest(with: URL(string: requestString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do{
                    
                    let playlistDetail = try JSONDecoder().decode(PlaylistDetailResponse.self, from: data)
                    
                    //print("Debug: playlist detail: \(playlistDetail)")
                    completion(.success(playlistDetail))
                    
                }catch{
                    print("Debug: Error in converting playlist detail into swift model: \(error)")
                    completion(.failure(APIError.failedToConvertData))
                }
            }
            
            task.resume()
        }
    }
    
    
    func getCurrentUserPlaylist(completion: @escaping ((Result<UserPlaylistResponse, Error>) -> Void)){
        
        if let data = UserDefaults.standard.object(forKey: "userProfile") as? Data{
            do{
                let userProfile = try JSONDecoder().decode(UserProfile.self, from: data)
                let user_id = userProfile.id
                let requestString = K.baseAPIURL + "/users/\(user_id)/playlists?limit=5"
                
                createRequest(with: URL(string: requestString), type: .GET) { request in
                    let task = URLSession.shared.dataTask(with: request) { data, _, error in
                        guard let data = data, error == nil else {
                            completion(.failure(APIError.failedToGetData))
                            print("Debug: cannot fetch user playlist")
                            return
                        }
                        
                        do{
                            let userPlaylists = try JSONDecoder().decode(UserPlaylistResponse.self, from: data)
                            completion(.success(userPlaylists))
                        }catch{
                            print("Debug: cannot convert data into user playlists \(error)")
                            completion(.failure(APIError.failedToConvertData))
                        }
                    }
                    
                    task.resume()
                }
                
            }catch{}
        }
    }
    
    
    func createPlaylist(with name: String, description: String = "", completion: @escaping ((Bool) -> Void)){
        
        if let data = UserDefaults.standard.object(forKey: "userProfile") as? Data{
            do{
                let userProfile = try JSONDecoder().decode(UserProfile.self, from: data)
                let userID = userProfile.id
                
                let requestString = K.baseAPIURL + "/users/\(userID)/playlists"
                
                
                createRequest(with: URL(string: requestString), type: .POST) { request in
                    var request = request
                    let newPlaylistData: [String: Any] = [
                        "name": name,
                        "public": false
                    ]
                    
                    do{
                        let data = try JSONSerialization.data(withJSONObject: newPlaylistData, options: .fragmentsAllowed)
                        request.httpBody = data
                        
                        let task = URLSession.shared.dataTask(with: request) { _, _, error in
                            
                            guard error == nil else {
                                print("Debug: failed to create playlist")
                                return
                            }
                            
                            completion(true)
                            //print("Debug: successfully add new playlist")

                        }
                        
                        task.resume()
                        
                    }catch{}
                    
                }
                
            }catch{}
        }
    }
    
    
    func getPlaylistTracks(with playlistID: String, completion: @escaping ((Result<PlaylistTracks,Error>) -> Void)){
        let requestString = K.baseAPIURL + "/playlists/\(playlistID)/tracks"
        
        createRequest(with: URL(string: requestString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    return
                }
                
                do{
                    let tracks = try JSONDecoder().decode(PlaylistTracks.self, from: data)
                    completion(.success(tracks))
                }catch{}

            }
            
            task.resume()
        }
    }
    
    
    func addTrackToPlaylist(playlistID: String, trackURI: String, completion: @escaping ((Bool) -> Void)){
        let requestString = K.baseAPIURL + "/playlists/\(playlistID)/tracks"
        
        createRequest(with: URL(string: requestString), type: .POST) { request in
            var request = request
            
            AuthManager.shared.withValideToken { token in
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                do{
                    let jsonData: [String: [String]] = ["uris": [trackURI]]
                    request.httpBody = try JSONSerialization.data(withJSONObject: jsonData, options: .fragmentsAllowed)
                    
                    let task = URLSession.shared.dataTask(with: request) { data, _, error in
                        guard let data = data, error == nil else{
                            print("Debug: cannot add this track to playlist")
                            completion(false)
                            return
                        }
                        
                        do{
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                            print("Debug: response of track added: \(jsonData)")
                            print("Debug: track added")
                            completion(true)
                        }catch{
                            print("Debug: something wrong v1 : \(error)")
                        }
                        
                        
                    }
                    
                    task.resume()
                }catch{
                    print("Debug: something wrong v2 : \(error)")
                }
            }
        }
    }
    
    func deleteTrackFromPlaylist(playlistID: String, trackURI: String, completion: @escaping ((Bool) -> Void)){
        let requestString = K.baseAPIURL + "/playlists/\(playlistID)/tracks"
        
        AuthManager.shared.withValideToken {[weak self] token in
            self?.createRequest(with: URL(string: requestString), type: .DELETE) { request in
                var request = request
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // { "tracks": [{ "uri": "spotify:track:4iV5W9uYEdYUVa79Axb7Rh" },{ "uri": "spotify:track:1301WleyT98MSxVHPZCA6M" }] }
                
                let json: [String: Any] = [
                    "tracks": [
                        ["uri": trackURI]
                    ]
                ]
                
                do{
                    let data = try JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
                    request.httpBody = data
                    
                    let task = URLSession.shared.dataTask(with: request) { data, _, error in
                        guard let data = data, error == nil else{
                            print("Debug: failed to remove the given track")
                            completion(false)
                            return
                        }
                        
                        do{
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                            completion(true)
                            print("Debug: remove response: \(jsonData)")
                        }catch{}
                        
                        
                        
                        
                    }
                    
                    task.resume()
                    
                }catch{
                    print("Debug: failed to remove track in converting the json data")
                }
                
            }
        }
    }
    
    
    // MARK: - Caregories & Category Playlists
    func getCategories(completion: @escaping (Result<CategoriesResponse, Error>) -> Void){
        let requestString = K.baseAPIURL + "/browse/categories"
        createRequest(with: URL(string: requestString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request){data, _, error in
                
                guard let data = data else {
                    print("Debug: cannot get genre data: \(error)")
                    return
                }
                
                do{
                    //let json = try JSONSerialization.jsonObject(with: data)
                    
                    let categoryResponse = try JSONDecoder().decode(CategoriesResponse.self, from: data)
                    completion(.success(categoryResponse))
                    //print("Debug: getCategories: \(categoryResponse)")
                    
                    
                }catch{}
            }
            
            task.resume()
        }
    }
    
    func getCategoryPlaylists(id: String, completion: @escaping (Result<CategoryPlaylistsResponse, Error>) -> Void){
        let requestString = K.baseAPIURL + "/browse/categories/\(id)/playlists"
        
        createRequest(with: URL(string: requestString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data else {
                    print("Debug: cannot get category playlist data: \(error)")
                    return
                }
                
                do{
                    let playlists = try JSONDecoder().decode(CategoryPlaylistsResponse.self, from: data)
                    //let jsonData = try JSONSerialization.jsonObject(with: data)
                    
                    print("Debug: category playlists: \(playlists)")
                    completion(.success(playlists))
                    
                }catch{
                    print("Debug: cannot convert playlist data model: \(error)")
                }
                
            }
            
            task.resume()
        }
    }
    
    
    // MARK: - Search
    func searchQuery(query: String, completion: @escaping (Result<[SearchResult], Error>) -> Void){
        let requestString = K.baseAPIURL + "/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=album,playlist,track,artist&limit=2"
        
        
        print("Debug: request string: \(requestString)")
        
        createRequest(with: URL(string: requestString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do{
                    let result = try JSONDecoder().decode(SearchQueryResponse.self, from: data)
                    var searchResults: [SearchResult] = []
                    
                    searchResults.append(contentsOf: result.tracks.items.compactMap{SearchResult.track(model: $0)})
                    searchResults.append(contentsOf: result.playlists.items.compactMap{SearchResult.playlist(model: $0)})
                    searchResults.append(contentsOf: result.albums.items.compactMap{SearchResult.album(model: $0)})
                    searchResults.append(contentsOf: result.artists.items.compactMap{SearchResult.artist(model: $0)})
                    
                    completion(.success(searchResults))
                }catch{
                    print("Debug: cannot conver search model: \(error)")
                }

            }
            
            task.resume()
        }
    }
    
    
    // MARK: - Private
    enum HTTPMethod: String{
        case GET
        case POST
        case DELETE
        case PUT
    }
    
    enum APIError: Error{
        case failedToGetData
        case failedToConvertData
    }
    
    
    //https://developer.spotify.com/documentation/general/guides/authorization/use-access-token/
    public func createRequest(with url: URL?,
                              type: HTTPMethod,
                              completion: @escaping (URLRequest) -> Void){
        
        AuthManager.shared.withValideToken { token in
            
            guard let apiURL = url else { return }
            
            var request = URLRequest(url: apiURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = type.rawValue
            request.timeoutInterval = 30
            completion(request)
            
        }
    }
}
