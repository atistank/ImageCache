//
//  FolderViewController.swift
//  ADImageCatch
//
//  Created by Apple on 6/27/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import UIKit

class FolderViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("test")
        setUI()
    }
    
    func setUI() {
        self.navigationController?.isNavigationBarHidden = false
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension FolderViewController: UICollectionViewDataSource,UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FolderCollectionViewCell", for: indexPath) as! FolderCollectionViewCell
        return cell
    }
}
