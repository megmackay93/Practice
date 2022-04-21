//
//  ContentManager.swift
//  PracticeTest
//
//  Created by Megan Mackay on 4/20/22.
//

import Foundation
import UIKit

class ContentManager: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    let gitService = GitService()
    let fetchContentGroup = DispatchGroup()
    var contentArray = [ContentItem]()
    
    func fetchContent(completionHandler: @escaping () -> Void) {
        fetchContentGroup.enter()
        gitService.fetchGitContent(sha: "ed3c099e0e13c8a485b5fa6244517f8b2da7f885") { rayContent in
            // Called for articles.json
            for articleContent in rayContent.data {
                self.contentArray.append(ContentItem.init(contentData: articleContent))
            }
            self.fetchContentGroup.leave()
        }
        fetchContentGroup.enter()
        gitService.fetchGitContent(sha: "b8a526684d3a997a8c1ffc4d73ca698af0152956") { rayContent in
            // Called for videos.json
            for videoContent in rayContent.data {
                self.contentArray.append(ContentItem.init(contentData: videoContent))
            }
            self.fetchContentGroup.leave()
        }
        
        fetchContentGroup.notify(queue: .main) {
            // Received all content
            // Sort content by release date
            self.contentArray.sort { lhs, rhs in
                return lhs.releaseDate > rhs.releaseDate
            }
            completionHandler()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contentCell", for: indexPath) as! ContentTableViewCell
        let contentItem = contentArray[indexPath.row]
        
        cell.nameLabel?.text = contentItem.name
        cell.descriptionLabel?.text = contentItem.description
        
        if let data = contentItem.description.data(using: .utf8) {
            do {
                let htmlString = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
                cell.descriptionLabel?.text = ""
                cell.descriptionLabel?.attributedText = htmlString
            } catch {
                print("html error")
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d yyyy"
        cell.subtitleLabel?.text = dateFormatter.string(from: contentItem.releaseDate) + " - " + contentItem.type
        
        cell.artworkImage?.image = contentItem.artImage
        if contentItem.artImage == nil {
            contentItem.addArtImageCallback {
                cell.artworkImage?.image = contentItem.artImage
            }
            contentItem.downloadImage()
        }
        return cell
    }
}

class ContentItem {
    var name: String
    var description: String
    var type: String
    var releaseDate: Date
    
    var artUrl: String?
    var artImage: UIImage?
    var artImageDispatchGroup = DispatchGroup()
    var artImageCompletionHandler: (() -> Void)?
    
    init(contentData: ContentData) {
        name = contentData.attributes.name ?? "N/A"
        description = contentData.attributes.description ?? ""
        type = contentData.attributes.content_type == "article" ? "Article" : "Video Course"
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions.insert(.withFractionalSeconds)
        releaseDate = dateFormatter.date(from: contentData.attributes.released_at)!
        
        artUrl = contentData.attributes.card_artwork_url
    }
    
    func addArtImageCallback(artImageDownloadHandler: (() -> Void)?) {
        artImageCompletionHandler = artImageDownloadHandler
    }
    
    func downloadImage() {
        artImageDispatchGroup.enter()
        guard let artUrl = artUrl, let url = URL(string: artUrl) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error downloading image - \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error with status code")
                return
            }
            if let data = data {
                // Save image data to content item
                self.artImage = UIImage(data: data)
                self.artImageDispatchGroup.leave()
            }
        }
        artImageDispatchGroup.notify(queue: .main) {
            // Notify image download is finished
            self.artImageCompletionHandler?()
        }
        task.resume()
    }
}
