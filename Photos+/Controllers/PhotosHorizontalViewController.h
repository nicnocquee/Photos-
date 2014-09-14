//
//  PhotosHorizontalViewController.h
//  Photos+
//
//  Created by  on 9/13/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ShowFullScreenPhotosAnimatedTransitioning.h"

@class PhotosHorizontalViewController;

@protocol PhotosHorizontalViewControllerDelegate <NSObject>

- (void)photosHorizontalScrollingViewController:(PhotosHorizontalViewController *)viewController didChangePage:(NSInteger)page item:(id)item;
- (UIView *)snapshotView;
- (CGRect)selectedItemRectInSnapshot;
- (void)photosHorizontalWillClose;

@end

@interface PhotosHorizontalViewController : UIViewController <CustomAnimationTransitionFromViewControllerDelegate>

- (id)initWithPhotos:(NSArray *)photos;

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, copy) NSArray *photos;

@property (nonatomic, assign) NSInteger firstShownPhotoIndex;

@property (nonatomic, weak) id<PhotosHorizontalViewControllerDelegate>delegate;

@end
