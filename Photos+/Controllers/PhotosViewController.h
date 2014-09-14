//
//  PhotosViewController.h
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AssetsLibrary/AssetsLibrary.h>

#import "PhotoAsset.h"

#import "ShowFullScreenPhotosAnimatedTransitioning.h"

@interface PhotosViewController : UIViewController <CustomAnimationTransitionFromViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableOrderedSet *assets;

- (NSString *)photosLibraryPropertyToObserve;

- (NSString *)tabBarItemTitle;

- (UIImage *)tabBarItemImage;

- (NSString *)cachedQueryString;

- (void)setupNotifications;

- (void)loadPhotos;

- (void)initObservers;

- (NSInteger)insertPhotoAsset:(PhotoAsset *)photoAsset;

- (void)photosLibraryDidChangeNotification:(NSNotification *)notification;

@end
