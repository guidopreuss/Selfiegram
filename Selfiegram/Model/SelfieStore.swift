//
//  SelfieStore.swift
//  Selfiegram
//
//  Created by Guido Preuß on 13.01.19.
//  Copyright © 2019 Guido Preuß. All rights reserved.
//

import Foundation
import UIKit.UIImage

class Selfie: Codable {
    // When it was created
    let created : Date
    // A unique ID, used to ink this selfie to its image on disk
    let id : UUID
    // The name of the selfie
    var title = "New Selfie!"
    
    // The image on disk for this selfie
    var image : UIImage?
    {
        get
        {
            return SelfieStore.shared.getImage(id: self.id)
        }
        set
        {
            try? SelfieStore.shared.setImage(id: self.id, image: newValue)
        }
    }
    
    init(title: String) {
        self.title = title
        // the current time
        self.created = Date()
        // a new UUID
        self.id = UUID()
    }
}

enum SelfieStoreError : Error
{
    case connotSaveImage(UIImage?)
}

final class SelfieStore
{
    static let shared = SelfieStore()
    private var imageCache : [UUID:UIImage] = [:]
    var documentsFolder : URL
    {
        return FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!
    }
    
    /// Gets an image by ID. Will cahed in memory for future lookups.
    /// - parameter id: th id of the selfie whose image you are after
    /// - returns: the image for that selfie or nil if it doesen't  exits
    func getImage(id:UUID) -> UIImage?
    {
        // If the image is already in the cache return ist
        if let image = imageCache[id]
        {
            return image
        }
        
        // Figure out where this image should live
        let imageURL = documentsFolder.appendingPathComponent("\(id.uuidString)-image.jpg")
        
        // Get the data from this file; exit if we fail
        guard let imageData = try? Data(contentsOf: imageURL) else {
            return nil
        }
        
        // Get th eimage from this data; exit if we fail
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        // Store the loaded image in the cache for the next time
        imageCache[id] = image
        
        return image
    }
    
    /// Saves an image
    /// - parameter id: the id of the selfie you want this image is associated with
    /// - parameter image: the image you want to save
    /// - Throws: 'SelfieStoreObject' if it fails to save the disk
    func setImage(id:UUID, image: UIImage?) throws
    {
        // Figure out where the file would end up
        let fileName = "\(id.uuidString)-image.jpg"
        let destinationURL = self.documentsFolder.appendingPathComponent(fileName)
        
        if let image = image
        {
            // we have an image to work with, so save it out.
            // Attempt to convert the image into the JPEG data.
            guard let data = image.jpegData(compressionQuality: 0.9) else
            //guard let data = UIImageJPEGRepresentation(image, 0.9) else
            {
                throw SelfieStoreError.connotSaveImage(image)
            }
            try data.write(to: destinationURL)
        }
        else
        {
            // the image is nil, indication that we want to remove the image.
            // Attempt to perform the deletion
            try FileManager.default.removeItem(at: destinationURL)
        }
        // Cache this image in the memory. (If image is nil, his has the effect of removing th eentry from the cache directory.
        imageCache[id] = image
    }
    
    /// Returns a list of Selfie Objects loaded from the disk
    /// - returns: an array of all selfies previously saved
    /// - Throws: 'SelfieStoreErroe' if it fails to load a selfie correctly from disk
    func listSelfies() throws -> [Selfie]
    {
        // Get the list of files in the Documents directory
        let contents = try FileManager.default.contentsOfDirectory(at: self.documentsFolder, includingPropertiesForKeys: nil)
        // Get all files whose path extension is 'json'
        // loas them as data and decode them from JSON
        return try contents.filter {$0.pathExtension == "json" }
            .map {try Data(contentsOf: $0)}
            .map {try JSONDecoder().decode(Selfie.self, from: $0)}
        
    }
    
    /// Deletes a selfie and its corresponding image from the disk
    /// This function simply takes th ID from the Selfie you pass in and gives it to the other version of the delete function
    /// - parameter selfie: the selfie you want to delete
    /// - Throws: 'SelfieStorageError' if it fails to delete the selfie from disk
    func delete(selfie: Selfie) throws
    {
        try delete(id: selfie.id)
    }
    
    /// Deletes a selfie and its corresponding image from disk
    /// - parameter id: the id propterty of the Selfie yout want to delete
    /// - Throws: 'SelfieStoreError' if it fails to delete the selfie from disk
    func delete(id: UUID) throws
    {
        let selfieDataFileName = "\(id.uuidString).json"
        let imageFileName = "\(id.uuidString)-image.jpg"
        
        let selfieDataURL = self.documentsFolder.appendingPathComponent(selfieDataFileName)
        let imageURL = self.documentsFolder.appendingPathComponent(imageFileName)
        
        // Remove the two files if they exits
        if FileManager.default.fileExists(atPath: selfieDataURL.path)
        {
            try FileManager.default.removeItem(at: selfieDataURL)
        }
        if FileManager.default.fileExists(atPath: imageURL.path)
        {
            try FileManager.default.removeItem(at: imageURL)
        }
        // Wipe the image from the cache if it's there
        imageCache[id] = nil
    }
    
    /// Attempts to load selfie from disk
    /// - parameter id: the id property of the Selfie object you want to load from disk
    /// - returns: the selfie with the matching id or nil of it does not exits
    func load(id: UUID) -> Selfie?
    {
        let dataFileName = "\(id.uuidString).json"
        let dataURL = self.documentsFolder.appendingPathComponent(dataFileName)
        
        // Attempt to load the data in this file and then attempt to convert the data into a Photo and return it
        // return nil if any of these steps fail
        if let data = try? Data(contentsOf: dataURL), let selfie = try? JSONDecoder().decode(Selfie.self, from: data)
        {
            return selfie
        }
        else
        {
            return nil
        }
    }
    
    /// Attempts to save a selfie to disk
    /// - parameter selfie: the selfie to save to the disk
    /// - Throws: 'SelfieStoreError' if it fails to write data
    func save(selfie: Selfie) throws
    {
        let selfieData = try JSONEncoder().encode(selfie)
        
        let fileName = "\(selfie.id.uuidString).json"
        let destinationURL = self.documentsFolder.appendingPathComponent(fileName)
        
        try selfieData.write(to: destinationURL)
    }
    
}
