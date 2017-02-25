//
//  MainNavigationContainer.swift
//
//  Created by keisyrzk on 28.12.2016.
//  Copyright © 2016 keisyrzk. All rights reserved.
//

import UIKit
import CoreData
import SwiftSpinner

protocol MainNavigationContainerDelegate
{
    func screenDidLock(state: LockedButtonState)
    func currentImageDidReset()
}

enum ListAlertType
{
    case PaintIt
    case MyColors
    case Gallery
}

class MainNavigationContainer: UIViewController, ColorWheelDelegate, ListAlertDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var listAlert: ListAlert!
    @IBOutlet weak var listAlertHeight: NSLayoutConstraint!
    
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    var mainNavigationContainerDelegate: MainNavigationContainerDelegate? = nil
    
    var listAlertType: ListAlertType = .PaintIt
    {
        didSet
        {
            switch listAlertType
            {
            case .MyColors:
                self.listAlertDatasource = [NSLocalizedString("_colorWheel", comment: ""),
                                            NSLocalizedString("_camera", comment: ""),
                                            NSLocalizedString("_browse", comment: "")]
                
            case .PaintIt:
                self.listAlertDatasource = [NSLocalizedString("_save", comment: ""),
                                            NSLocalizedString("_reset", comment: ""),
                                            NSLocalizedString("_camera", comment: ""),
                                            NSLocalizedString("_browse", comment: "")]
                
            case .Gallery:
                self.listAlertDatasource = [NSLocalizedString("_saveInRoll", comment: ""),
                                            NSLocalizedString("_share", comment: "")]
            }
            self.listAlert.inputData = listAlertDatasource
            self.listAlert.reloadData()
            self.listAlert.subviews.first?.removeFromSuperview()
            self.listAlert.makeBackground(frame: listAlert.frame)
        }
    }
    var listAlertDatasource = [NSLocalizedString("_save", comment: ""),
                               NSLocalizedString("_reset", comment: ""),
                               NSLocalizedString("_camera", comment: ""),
                               NSLocalizedString("_browse", comment: "")]
    
    let removeModeButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(removeModeButtonAction(sender:)))
    let lockedModeButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.pause, target: self, action: #selector(lockedModeButtonAction(sender:)))
    let moreButton = UIBarButtonItem(image: #imageLiteral(resourceName: "moreButton"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(moreButtonAction(sender:)))
    
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setup()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    @IBAction func menuButtonAction(_ sender: Any)
    {
        MainMenu.shared.show(parentCtrl: self, menuWidth: nil)
    }
    
    
    
    /////////////////
    /// FUNCTIONS ///
    
    func setup()
    {
        navItem.title = NSLocalizedString("_paintIt", comment: "")
        
        let nib = UINib(nibName: "ListAlertCell", bundle: nil)
        listAlert.register(nib, forCellReuseIdentifier: "listAlertCell")
        listAlert.inputData = listAlertDatasource
        listAlert.listAlertDelegate = self
        
        imagePicker.delegate = self
    }
    
    func moreHide()
    {
        UIView.animate(withDuration: 0.5) {
            self.listAlert.frame.size.height = 1
        }
    }
    
    func moreShow()
    {
        UIView.animate(withDuration: 0.5) {
            self.listAlert.frame.size.height = CGFloat(self.listAlertDatasource.count) * self.listAlert.cellHeight
        }
    }
    
    func moreButtonAction(sender: UIBarButtonItem)
    {
        if listAlertHeight.constant == 1
        {
            moreShow()
        }
        else
        {
            moreHide()
        }
        listAlertHeight.constant = listAlertHeight.constant == 1 ? CGFloat(listAlertDatasource.count) * listAlert.cellHeight : 1
    }

    func colorWheel(photo: UIImage)
    {
        if let alertController = Bundle.main.loadNibNamed("ColorWheelAlert", owner: nil, options: nil)
        {
            let newAlert = alertController[0] as! ColorWheelAlert
            newAlert.colorWheelDelegate = self
            newAlert.colorWheel.image = photo
            newAlert.modalPresentationStyle = .overCurrentContext            
            present(newAlert, animated: true, completion: nil)
        }
    }
    
    func removeModeButtonAction(sender: UIBarButtonItem)
    {
        removeButtonState = removeButtonState == .Normal ? .Remove : .Normal
        removeModeButton.tintColor = removeButtonState == .Normal ? UIColor.darkGray : UIColor.red
    }
    
    func lockedModeButtonAction(sender: UIBarButtonItem)
    {
        lockedButtonState = lockedButtonState == .Normal ? .Locked : .Normal
        lockedModeButton.tintColor = lockedButtonState == .Normal ? UIColor.darkGray : UIColor.red
        mainNavigationContainerDelegate?.screenDidLock(state: lockedButtonState)
    }

    func showSaveAlert(object: NSManagedObject)
    {
        let alertCtrl = UIAlertController(title: nil, message: NSLocalizedString("_doOverrideExistingImage", comment: ""), preferredStyle: .alert)
        let overrideAction = UIAlertAction(title: NSLocalizedString("_override", comment: ""), style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            
            SwiftSpinner.show(NSLocalizedString("_processing", comment: ""))
            DispatchQueue.main.async(execute: {
                self.overridePhoto(object: object)
            })
        }
        let makeCopyAction = UIAlertAction(title: NSLocalizedString("_makeCopy", comment: ""), style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            
            SwiftSpinner.show(NSLocalizedString("_processing", comment: ""))
            DispatchQueue.main.async(execute: {
                self.saveCopy()
            })
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("_cancelAction", comment: ""), style: UIAlertActionStyle.destructive) { (result : UIAlertAction) -> Void in
        }
        
        alertCtrl.addAction(overrideAction)
        alertCtrl.addAction(makeCopyAction)
        alertCtrl.addAction(cancelAction)
        self.present(alertCtrl, animated: true, completion: nil)
    }
    
        //removed the current object and saves anotherone
    func overridePhoto(object: NSManagedObject)
    {
        CoreDataManager.sharedInstance.delete(object: object) { (result) in
            switch result
            {
            case .success(_):
                currentImageObject = nil
                self.saveCopy()
                
            case .failure(let error):
                SwiftSpinner.show(duration: 3, title: error.localizedDescription)
                print(error.localizedDescription)
            }
        }
    }
    
        //creates a new core data object
    func saveCopy()
    {
        if let image = currentImage
        {
            CoreDataManager.sharedInstance.saveImage(newImage: image, completion: { (result) in
                switch result
                {
                case .success(_):
                    print("success save")
                    SwiftSpinner.hide()
                    
                case .failure(let error):
                    SwiftSpinner.show(duration: 3, title: error.localizedDescription)
                    print(error.localizedDescription)
                }
            })
        }
    }
    
    
        //takea photo with camera
    func takePhoto()
    {
            //check if the camera is available
        if (UIImagePickerController.isSourceTypeAvailable(.camera))
        {
                //check the rear camera
            if UIImagePickerController.availableCaptureModes(for: .rear) != nil
            {
                imagePicker.allowsEditing = false
                imagePicker.sourceType = .camera
                imagePicker.cameraCaptureMode = .photo
                
                if UIApplication.shared.statusBarOrientation == .portrait
                {
                    let spinner = SwiftSpinner.show(NSLocalizedString("_landscapePhotoTitle", comment: ""))
                    spinner.addTapHandler({
                        SwiftSpinner.hide()
                        self.present(self.imagePicker, animated: true, completion: nil)
                    }, subtitle: NSLocalizedString("_landscapePhotoSubtitle", comment: ""))
                }
                else
                {
                    present(imagePicker, animated: true, completion: nil)
                }
            }
            else
            {
                print("Application cannot access the camera.")
            }
        }
        else
        {
            print("Application cannot access the camera.")
        }
    }
    
        //browse phone photo gallery
    func browseDevicePhotoLibrary()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)
        {
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = false
            
            if UIApplication.shared.statusBarOrientation == .portrait
            {
                let spinner = SwiftSpinner.show(NSLocalizedString("_landscapePhotoTitle", comment: ""))
                spinner.addTapHandler({
                    SwiftSpinner.hide()
                    self.present(self.imagePicker, animated: true, completion: nil)
                }, subtitle: NSLocalizedString("_landscapePhotoSubtitle", comment: ""))
            }
            else
            {
                present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
        //when the user accepts the photo
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            if listAlertType == .MyColors
            {
                self.dismiss(animated: true, completion: nil)
                colorWheel(photo: image)
            }
            else
            {
                currentImage = image
                currentImageObject = nil
                showMainController()
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        self.dismiss(animated: true, completion: nil)
    }

    func showMainController()
    {
        for child in self.childViewControllers
        {
            if child.isKind(of: PaintMain.self)
            {
                (child as! PaintMain).doNeccessaryActions()
            }
        }

        self.dismiss(animated: true, completion: nil)
    }
    
    /// FUNCTIONS ///
    /////////////////

    
    /////////////////
    /// DELEGATES ///
    
        //colorWheel delegate - reload data in all neccesary child controllers (reload user colors)
    func colorWheelDidSave()
    {
        for child in self.childViewControllers
        {
            if child.isKind(of: PaintMain.self)
            {
                (child as! PaintMain).getData()
            }
            if child.isKind(of: MyColorsVC.self)
            {
                (child as! MyColorsVC).getData()
            }
        }
    }
    
    
    func didSelectOption(listAlert: ListAlert, optionIndex: Int)
    {
        moreHide()
        listAlertHeight.constant = listAlertHeight.constant == 1 ? CGFloat(listAlertDatasource.count) * listAlert.cellHeight : 1

        if listAlertType == .PaintIt
        {
            switch optionIndex
            {
            case 0: //save
                if let _currentObject = currentImageObject
                {
                    showSaveAlert(object: _currentObject)
                }
                else
                {
                    SwiftSpinner.show(NSLocalizedString("_processing", comment: ""))
                    DispatchQueue.main.async(execute: {
                        self.saveCopy()
                    })
                }
                
            case 1: //reset
                currentImage = currentImageCopy
                mainNavigationContainerDelegate?.currentImageDidReset()
                
            case 2: //camera
                self.takePhoto()
                
            case 3: //browse
                self.browseDevicePhotoLibrary()

            default:
                print("")
            }
        }
        else if listAlertType == .MyColors
        {
            switch optionIndex
            {
            case 0: //color wheel
                colorWheel(photo: #imageLiteral(resourceName: "colorWheel"))
                
            case 1: // camera
                takePhoto()
                
            case 2: //browse
                browseDevicePhotoLibrary()
                
            default:
                print("")
            }
        }
        else if listAlertType == .Gallery
        {
            switch optionIndex
            {
            case 0: //to camera roll
                if let _currentGalleryImage = currentGalleryImage
                {
                    UIImageWriteToSavedPhotosAlbum(_currentGalleryImage, nil, nil, nil)
                    self.view.makeToast(NSLocalizedString("_photoSavedInRoll", comment: ""), duration: 2, position: .center)
                }
                
            case 1: //share with email
                ServiceEmail.instance.shareEmail(viewController: self)
                
            default:
                print("")
            }
        }
    }
    
    /// DELEGATES ///
    /////////////////
    
    
}//end of class
