//
//  PhotoCell.h
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PhotoAsset.h"

@class PhotoCellView;

@interface PhotoCell : UICollectionViewCell

@property (nonatomic, strong) PhotoAsset *photoAsset;

@property (nonatomic, weak, readonly) PhotoCellView *cellView;

@end
