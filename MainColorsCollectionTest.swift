//
//  MainColorsCollectionTest.swift
//  PaintIt
//
//  Created by keisyrzk on 10.02.2017.
//  Copyright © 2017 keisyrzk. All rights reserved.
//

import XCTest
@testable import PaintIt

class MainColorsCollectionTest: XCTestCase
{
    var controller: DefaultColorsVC!
    
    
    
    override func setUp()
    {
        super.setUp()
        
            //instatiate the right controller
        controller = UIStoryboard(name: "Colors", bundle: nil).instantiateViewController(withIdentifier: "DefaultColorsVC") as! DefaultColorsVC
        
            //load the controllers view hierarchy
        let _ = controller.view
    }
    
    func testCollectionViewOutlet()
    { 
        XCTAssertNotNil(controller.collectionView, "colelctionView outlet is nil")
    }
    
    func testCollectionHasCorrectNumberOfItems()
    {
        controller.collectionView.inputDataSource = DefaultColors().colors
        controller.collectionView.reloadData()
        
        XCTAssertNotNil(controller.collectionView.dataSource, "datasource is nil")
        
        if let dataSource = controller.collectionView.dataSource
        {
            XCTAssert(dataSource.collectionView(controller.collectionView, numberOfItemsInSection: 0) == DefaultColors().colors.count, "colors collectionView does not have correct number of elements")
        }
    }

    func testColorCell()
    {
        let colorIndex = IndexPath(item: 3, section: 0)
        
        controller.collectionView.inputDataSource = DefaultColors().colors
        controller.collectionView.reloadData()
        
        let cell = controller.collectionView.dequeueReusableCell(withReuseIdentifier: "colorCell", for: colorIndex) as! ColorCell
        
        let colorsDatasource = DefaultColors().colors
        cell.config(color: colorsDatasource[colorIndex.row])

        XCTAssertEqual(cell.cellTitle.text, "Ivory", "cell title is wrong")
        XCTAssertEqual(cell.cellColorView.backgroundColor, UIColor(red: 255/255, green: 255/255, blue: 240/255, alpha: 1), "the cell has wrong color")
    }
    
}//end of class
