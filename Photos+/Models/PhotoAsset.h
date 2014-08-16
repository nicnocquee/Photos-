//
//  PhotoAsset.h
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoAsset : RLMObject

@property (nonatomic, strong, readonly) UIImage *thumbnailImage;

@property (nonatomic, strong, readonly) NSURL *url;

@property (nonatomic, strong, readonly) NSString *urlString;

@property (nonatomic, strong, readonly) NSDictionary *metadata;

@property (nonatomic, assign, getter = isScreenshot) BOOL screenshot;

@property (nonatomic, assign) BOOL hasFaces;

@property (nonatomic, assign, getter = isSelfies) BOOL selfies;

@property (nonatomic, assign, getter = isDeleted) BOOL deleted;

@property (nonatomic, assign) BOOL checkedForSelfies;

@property (nonatomic, assign) BOOL checkedForScreenshot;

@property (nonatomic, assign) BOOL checkedForFaces;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, strong, readonly) ALAsset *rawAsset;

- (void)setALAsset:(ALAsset *)asset;

- (void)loadAssetWithCompletion:(void(^)(id asset))completion;

- (BOOL)isEqualToPhotoAsset:(PhotoAsset *)asset;

@end
