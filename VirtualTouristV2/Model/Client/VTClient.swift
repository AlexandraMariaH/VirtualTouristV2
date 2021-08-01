//
//  VTClient.swift
//  VirtualTouristV2
//
//  Created by Alexandra Hufnagel on 01.08.21.
//

import Foundation

class VTClient {
    
    struct API {
        static let key = "911871b1c7060cdb4b1b2d084d55a9ea"
    }
    
    enum Endpoints {
        static let baseFlickr = "https://www.flickr.com/services/rest"
        static let baseStaticFlickr = "https://live.staticflickr.com"
        
        case getLocationURL(Double, Double, Int, Int)
        case getPhotoURL(String, String, String)
        
        var stringValue: String {
            switch self {
            
            case .getLocationURL(let latitude, let longitude, let perPage, let page):
                return Endpoints.baseFlickr + "/?method=flickr.photos.search&api_key=" + API.key + "&lat=\(latitude.description)&lon=\(longitude.description)&per_page=\(perPage)&page=\(page)&format=json&nojsoncallback=1"
                
            case .getPhotoURL(let server, let id, let secret):
                return Endpoints.baseStaticFlickr + "/\(server)/\(id)_\(secret).jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func downloadPhotos(latitude: Double, longitude: Double, perPage: Int, page: Int, completion:@escaping (Photos?, Error?) -> Void) {
        
        taskForGETRequest(url: Endpoints.getLocationURL(latitude, longitude, perPage, page).url, responseType: PhotoResponse.self){
            (response,error) in
            
            if let response = response {
                DispatchQueue.main.async {
                    completion(response.photos, nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion(response?.photos, error)
                }
            }
        }
    }
    
    // Like OnTheMap
    @discardableResult class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            do {
                let responseObject = try JSONDecoder().decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try JSONDecoder().decode(VTResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        
        return task
    }
    
    class func taskForDownloadImage(url: URL, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, error)
        }
        task.resume()
    }
    
    class func getPhotoURL(server: String, id: String, secret: String) -> String {
        let urlString = Endpoints.getPhotoURL(server, id, secret).url.absoluteString
        return urlString
    }
    
}
