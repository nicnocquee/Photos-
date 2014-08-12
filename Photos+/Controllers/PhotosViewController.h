//
//  PhotosViewController.h
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotosViewController : UIViewController

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray *assets;

- (BOOL)shouldIncludeAsset:(ALAsset *)asset;

- (NSString *)tabBarItemTitle;

- (UIImage *)tabBarItemImage;

@end
