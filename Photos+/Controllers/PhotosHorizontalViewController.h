//
//  PhotosHorizontalViewController.h
//  Photos+
//
//  Created by  on 9/13/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ShowFullScreenPhotosAnimatedTransitioning.h"

@interface PhotosHorizontalViewController : UIViewController <CustomAnimationTransitionFromViewControllerDelegate>

- (id)initWithPhotos:(NSArray *)photos;

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, copy) NSArray *photos;

@property (nonatomic, assign) NSInteger indexOfPhotoToShowOnLoad;

@end
