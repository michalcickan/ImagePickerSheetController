//
//  SheetController.swift
//  ImagePickerSheetController
//
//  Created by Laurin Brandner on 27/08/15.
//  Copyright © 2015 Laurin Brandner. All rights reserved.
//

import UIKit

private let defaultInset: CGFloat = 10

class SheetController: NSObject {
    
    fileprivate(set) lazy var sheetCollectionView: UICollectionView = {
        let layout = SheetCollectionViewLayout()
        let collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = "ImagePickerSheet"
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = false
        collectionView.register(SheetPreviewCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(SheetPreviewCollectionViewCell.self))
        collectionView.register(SheetActionCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(SheetActionCollectionViewCell.self))
        collectionView.register(SheetTitleCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(SheetTitleCollectionViewCell.self))
        
        return collectionView
    }()
    
    weak var previewCollectionView: PreviewCollectionView?
    
    fileprivate(set) var actions = [ImagePickerAction]()
    
    var actionHandlingCallback: (() -> ())?
    
    var sheetTitle : String?
    
    fileprivate(set) var previewHeight: CGFloat = 0
    var numberOfSelectedImages = 0
    
    var preferredSheetHeight: CGFloat {
        return allIndexPaths().map { self.sizeForSheetItemAtIndexPath($0).height }
            .reduce(0, +)
    }
    
    var preferredSheetWidth: CGFloat {
        guard #available(iOS 9, *) else {
            return sheetCollectionView.bounds.width
        }
        return sheetCollectionView.bounds.width - 2 * defaultInset
    }
    
    // MARK: - Initialization
    
    init(previewCollectionView: PreviewCollectionView) {
        self.previewCollectionView = previewCollectionView
        
        super.init()
    }
    
    // MARK: - Data Source
    // These methods are necessary so that no call cycles happen when calculating some design attributes
    
    fileprivate func numberOfSections() -> Int {
        return 2
    }
    
    fileprivate func numberOfItemsInSection(_ section: Int) -> Int {
        if section == 0 {
            return sheetTitle != nil ? 2 : 1
        }
        
        return actions.count
    }
    
    fileprivate func allIndexPaths() -> [IndexPath] {
        let s = numberOfSections()
        return (0 ..< s).map { (section: Int) -> (Int, Int) in (self.numberOfItemsInSection(section), section) }
            .flatMap { (numberOfItems: Int, section: Int) -> [IndexPath] in
                (0 ..< numberOfItems).map { (item: Int) -> IndexPath in IndexPath(item: item, section: section) }
        }
    }
    
    fileprivate func sizeForSheetItemAtIndexPath(_ indexPath: IndexPath) -> CGSize {
        let height: CGFloat = {
            if (indexPath as NSIndexPath).section == 0 {
                return (indexPath as NSIndexPath).row == 0 ? 34 : previewHeight
            }
            
            let actionItemHeight: CGFloat
            
            if #available(iOS 9, *) {
                actionItemHeight = 57
            }
            else {
                actionItemHeight = 50
            }
            
            let insets = attributesForItemAtIndexPath(indexPath).backgroundInsets
            return actionItemHeight + insets.top + insets.bottom
        }()
        
        return CGSize(width: sheetCollectionView.bounds.width, height: height)
    }
    
    // MARK: - Design
    
    fileprivate func attributesForItemAtIndexPath(_ indexPath: IndexPath) -> (corners: RoundedCorner, backgroundInsets: UIEdgeInsets) {
        guard #available(iOS 9, *) else {
            return (.none, UIEdgeInsets())
        }
        
        let cornerRadius: CGFloat = 13
        let innerInset: CGFloat = 4
        var indexPaths = allIndexPaths()
        
        guard indexPaths.first != indexPath else {
            return (.top(cornerRadius), UIEdgeInsets(top: 0, left: defaultInset, bottom: 0, right: defaultInset))
        }
        
        let cancelIndexPath = actions.index { $0.style == ImagePickerActionStyle.cancel }
            .map { IndexPath(item: $0, section: 1) }
        
        
        if let cancelIndexPath = cancelIndexPath {
            if cancelIndexPath == indexPath {
                return (.all(cornerRadius), UIEdgeInsets(top: innerInset, left: defaultInset, bottom: defaultInset, right: defaultInset))
            }
            
            indexPaths.removeLast()
            
            if indexPath == indexPaths.last {
                return (.bottom(cornerRadius), UIEdgeInsets(top: 0, left: defaultInset, bottom: innerInset, right: defaultInset))
            }
        }
        else if indexPath == indexPaths.last {
            return (.bottom(cornerRadius), UIEdgeInsets(top: 0, left: defaultInset, bottom: defaultInset, right: defaultInset))
        }
        
        return (.none, UIEdgeInsets(top: 0, left: defaultInset, bottom: 0, right: defaultInset))
    }
    
    fileprivate func fontForAction(_ action: ImagePickerAction) -> UIFont {
        guard #available(iOS 9, *), action.style == .cancel else {
            return UIFont.systemFont(ofSize: 21)
        }
        
        return UIFont.boldSystemFont(ofSize: 21)
    }
    
    func clearActions() {
        self.actions.removeAll()
    }
    
    // MARK: - Actions
    
    func reloadActionItems() {
        sheetCollectionView.reloadSections(IndexSet(integer: 1))
    }
    
    func addAction(_ action: ImagePickerAction) {
        if action.style == .cancel {
            actions = actions.filter { $0.style != .cancel }
        }
        
        actions.append(action)
        
        if let index = actions.index(where: { $0.style == .cancel }) {
            let cancelAction = actions.remove(at: index)
            actions.append(cancelAction)
        }
        
        reloadActionItems()
    }
    
    fileprivate func handleAction(_ action: ImagePickerAction) {
        actionHandlingCallback?()
        action.handle(numberOfSelectedImages)
    }
    
    func handleCancelAction() {
        let cancelAction = actions.filter { $0.style == ImagePickerActionStyle.cancel }
            .first
        
        if let cancelAction = cancelAction {
            handleAction(cancelAction)
        }
        else {
            actionHandlingCallback?()
        }
    }
    
    // MARK: -
    
    func setPreviewHeight(_ height: CGFloat, invalidateLayout: Bool) {
        previewHeight = height
        if invalidateLayout {
            sheetCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    deinit {
        print("sheet controller deinit")
    }
    
}

extension SheetController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsInSection(section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SheetCollectionViewCell
        
        if (indexPath as NSIndexPath).section == 0 {
            if (indexPath as NSIndexPath).row == 0 {
                let titleCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SheetTitleCollectionViewCell.self), for: indexPath) as! SheetTitleCollectionViewCell
                
                titleCell.titleLabel.text = sheetTitle ?? ""
                titleCell.titleLabel.font = UIFont.systemFont(ofSize: 13)
                
                cell = titleCell
            }
            else {
                let previewCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SheetPreviewCollectionViewCell.self), for: indexPath) as! SheetPreviewCollectionViewCell
                previewCell.collectionView = previewCollectionView
                
                cell = previewCell
            }
        }
        else {
            let action = actions[(indexPath as NSIndexPath).item]
            let actionCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SheetActionCollectionViewCell.self), for: indexPath) as! SheetActionCollectionViewCell
            actionCell.textLabel.font = fontForAction(action)
            actionCell.textLabel.text = numberOfSelectedImages > 0 ? action.secondaryTitle(numberOfSelectedImages) : action.title
            
            cell = actionCell
        }
        
        cell.separatorVisible = ((indexPath as NSIndexPath).section == 1)
        
        // iOS specific design
        (cell.roundedCorners, cell.backgroundInsets) = attributesForItemAtIndexPath(indexPath)
        if #available(iOS 9, *) {
            cell.normalBackgroundColor = UIColor(white: 0.97, alpha: 1)
            cell.highlightedBackgroundColor = UIColor(white: 0.92, alpha: 1)
            cell.separatorColor = UIColor(white: 0.84, alpha: 1)
        }
        else {
            cell.normalBackgroundColor = .white
            cell.highlightedBackgroundColor = UIColor(white: 0.85, alpha: 1)
            cell.separatorColor = UIColor(white: 0.784, alpha: 1)
        }
        
        return cell
    }
    
}

extension SheetController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return (indexPath as NSIndexPath).section != 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        handleAction(actions[(indexPath as NSIndexPath).item])
    }
    
}

extension SheetController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeForSheetItemAtIndexPath(indexPath)
    }
    
}
