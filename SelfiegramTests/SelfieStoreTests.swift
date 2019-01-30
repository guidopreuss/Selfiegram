//
//  SelfieStoreTests.swift
//  SelfiegramTests
//
//  Created by Guido Preuß on 14.01.19.
//  Copyright © 2019 Guido Preuß. All rights reserved.
//

import XCTest
@testable import Selfiegram
import UIKit

class SelfieStoreTests: XCTestCase {
    
    /// A helper function to create images with text being used as the image content.
    /// - returns: an image containing a representation of the text
    /// - parameter text: the string ou want rendered into the image
    func createImage(text: String) -> UIImage
    {
        // Start a drawing canvas
        UIGraphicsBeginImageContext(CGSize(width: 100, height: 100 ))
        // Close the canvas after we return from this function
        defer {
            UIGraphicsEndImageContext()
        }
        // Create a label
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        label.font = UIFont.systemFont(ofSize: 50)
        label.text = text
        // Draw the label in the current drawing context
        label.drawHierarchy(in: label.frame, afterScreenUpdates: true)
        // return the label
        // (the ! means we either successfully get an image, or we crash)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }

    func testCreatingSelfie()
    {
        // Arrange
        let selfieTitle = "Creation Test Selfie"
        let newSelfie = Selfie(title: selfieTitle)
        // Act
        try? SelfieStore.shared.save(selfie: newSelfie)
        // Assert
        let allSelfies = try! SelfieStore.shared.listSelfies()
        
        guard let theSelfie = allSelfies.first(where: {$0.id == newSelfie.id}) else
        {
            XCTFail("Selfies list should contain the one we just created.")
            return
        }
        // org: XCTAssertEqual(selfieTitle, newSelfie.title)
        XCTAssertEqual(selfieTitle, theSelfie.title)
    }
    
    func testSaving()  throws {
        // Arrage
        let newSelfie = Selfie(title: "Selfie with image test")
        
        // Act
        newSelfie.image = createImage(text: "💯")
        try SelfieStore.shared.save(selfie: newSelfie)
        
        // Assert
        let loadedImage = SelfieStore.shared.getImage(id: newSelfie.id)
        
        XCTAssertNotNil(loadedImage, "The image should be loaded.")
        
        
    }
    
    func testLoadingSelfie() throws
    {
        // Arrange
        let selfieTitle = "Test loading selfie"
        let newSelfie = Selfie(title: selfieTitle)
        try SelfieStore.shared.save(selfie: newSelfie)
        let id = newSelfie.id
        // Act
        let loadSelfie = SelfieStore.shared.load(id: id)
        
        // Assert
        XCTAssertNotNil(loadSelfie, "The selfie should be loaded")
        XCTAssertEqual(loadSelfie?.id, newSelfie.id, "The loaded selfie should have the same ID")
        XCTAssertEqual(loadSelfie?.created, newSelfie.created, "The loaded selfie should have the same creation date")
        XCTAssertEqual(loadSelfie?.title, selfieTitle, "The loaded selfie should have the same title")
    }
    
    func testDeletingSelfie() throws
    {
        // Arrange
        let newSelfie = Selfie(title: "Test deleting a selfie")
        try SelfieStore.shared.save(selfie: newSelfie)
        let id = newSelfie.id
        // Act
        let allSelfies = try SelfieStore.shared.listSelfies()
        try SelfieStore.shared.delete(id: id)
        let selfieList = try SelfieStore.shared.listSelfies()
        let loadedSelfie = SelfieStore.shared.load(id: id)
        // Assert
        XCTAssertEqual(allSelfies.count - 1 , selfieList.count, "There should be one less selfie after deletion.")
        XCTAssertNil(loadedSelfie, "deleded selfie should be nil")
    
    }

}
