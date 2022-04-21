//
//  GitService.swift
//  PracticeTest
//
//  Created by Megan Mackay on 4/20/22.
//

import UIKit

class GitService: NSObject {
    
    func fetchGitRepo(completionHandler: @escaping (_ repo: GitRepo) -> Void) {
        let url = URL(string: "https://api.github.com/repos/raywenderlich/ios-interview/git/trees/0bd00b5b6d29b249bcd2f95791db7fbddb1152bd")
        guard let url = url else { fatalError() }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Returned error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Returned error: status code \(response.debugDescription)")
                return
            }
            if let data = data {
                do {
                    let gitRepo = try JSONDecoder().decode(GitRepo.self, from: data)
                    completionHandler(gitRepo)
                    return
                } catch {
                    print("Decode error")
                }
            }
        }
        task.resume()
    }
    
    func fetchGitBlob(sha: String, completionHandler: @escaping (_ blob: GitBlob) -> Void) {
        let url = URL(string: "https://api.github.com/repos/raywenderlich/ios-interview/git/blobs/\(sha)")
        guard let url = url else { fatalError() }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error occured: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error with status code")
                return
            }
            if let data = data {
                do {
                    let gitBlob = try JSONDecoder().decode(GitBlob.self, from: data)
                    completionHandler(gitBlob)
                } catch {
                    print("Decode error")
                }
            }
        }
        task.resume()
    }
    
    func fetchGitContent(sha: String, completionHandler: @escaping (_ rayContent: RayContent) -> Void) {
        fetchGitBlob(sha: sha) { blob in
            let data = Data(base64Encoded: blob.content, options: [.ignoreUnknownCharacters])
            do {
                let content = try JSONDecoder().decode(RayContent.self, from: data!)
                completionHandler(content)
            } catch {
                print("json error: \(error.localizedDescription)")
                print(error)
            }
        }
    }
}

struct GitRepo: Codable {
    var url: String
    var sha: String
    var truncated: Bool
    var tree: [GitTree]
}

struct GitTree: Codable {
    var path: String
    var type: String
    var sha: String
    var url: String
}

struct GitBlob: Codable {
    var content: String
    var encoding: String
    var url: String
    var sha: String
    var node_id: String
}

struct RayContent: Codable {
    var links: ContentLinks
    var data: [ContentData]
}

struct ContentLinks: Codable {
    var currentLink: String
    var next: String
    var last: String
    
    enum CodingKeys: String, CodingKey {
        case currentLink = "self"
        case next, last
    }
}

struct ContentData: Codable {
    var type: String
    var id: String
    var attributes: ContentDataAtttributes
    var relationships: ContentDataRelationships
    //var links: ContentDataLinks
}

struct ContentDataAtttributes: Codable {
    var name: String?
    var description: String?
    var title: String?
    var content_type: String
    var released_at: String
    var card_artwork_url: String?
}

struct ContentDataRelationships: Codable {
    var author: ContentDataRelationshipAuthor?
}

struct ContentDataRelationshipAuthor: Codable {
    var data: ContentDataBasic
}

struct ContentDataLinks: Codable {
    var currentLink: String
    
    enum CodingKeys: String, CodingKey {
        case currentLink = "self"
    }
}

struct ContentDataBasic: Codable {
    var type: String
    var id: String
}
