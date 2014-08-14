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

@interface PhotosViewController : UIViewController

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableOrderedSet *assets;

- (NSString *)tabBarItemTitle;

- (UIImage *)tabBarItemImage;

- (void)didFinishFetchingAssets;

- (void)loadCachedWithCompletion:(void(^)())completion;

- (NSString *)cachedQueryString;

- (PhotoAsset *)photoAssetForALAsset:(ALAsset *)asset index:(NSInteger)index;

- (dispatch_queue_t)libraryEnumerationQueue;

@end
