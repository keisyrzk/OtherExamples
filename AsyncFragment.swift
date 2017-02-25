GalleryService().getMyGallery(completionHandler: { (response) in
    
    switch response
    {
    case .success(let gallery):
        
        self.photosObjects = [LocalImageModel(imageId: nil, image: #imageLiteral(resourceName: "addPlus"))]
        
        for img in gallery
        {
            if let _url = img.imageUrl
            {
                if let _imgId = img.imageId
                {
                    ImageLoaderFromURL.loadImage(url: _url, successful: { (image) in
                        
                        DispatchQueue.main.async(execute: {
                            self.photosObjects.insert(LocalImageModel(imageId: _imgId, image: image), at: 0)
                            self.photosCollectionView.reloadData()
                            UIView.setAnimationsEnabled(true)
                        })
                    })
                }
            }
        }
        
    case .failure(let error):
        print(error.localizedDescription)
        break
    }
})
