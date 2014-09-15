//
//  PhotoAsset.h
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

#import <CoreLocation/CoreLocation.h>

@interface PhotoAsset : FCModel

@property (nonatomic) int64_t id;

@property (nonatomic, strong, readonly) UIImage *thumbnailImage;

@property (nonatomic, strong, readonly) NSURL *url;

@property (nonatomic, strong, readonly) NSDictionary *metadata;

@property (nonatomic, strong, readonly) NSDictionary *exifMetadata;

@property (nonatomic, strong, readonly) NSDictionary *tiffMetadata;

@property (nonatomic, assign, getter = isScreenshot) BOOL screenshot;

@property (nonatomic, assign) BOOL hasFaces;

@property (nonatomic, assign, getter = isSelfies) BOOL selfies;

@property (nonatomic, assign, getter = isDeleted) BOOL deleted;

@property (nonatomic, assign) BOOL checkedForSelfies;

@property (nonatomic, assign) BOOL checkedForScreenshot;

@property (nonatomic, assign) BOOL checkedForFaces;

@property (nonatomic, assign) NSInteger assetIndex;

@property (nonatomic, strong) NSString *location;

@property (nonatomic, strong, readonly) CLLocation *clLocation;

@property (nonatomic, strong) NSString *cameraType;

@property (nonatomic, strong) NSDate *dateTaken;

@property (nonatomic, strong) NSDate *dateCreated;

@property (nonatomic, strong, readonly) ALAsset *rawAsset;

@property (nonatomic, strong, readonly) NSNumber *latitude;

@property (nonatomic, strong, readonly) NSNumber *longitude;

@property (nonatomic, strong, readonly) NSString *latitudeLongitudeString;

@property (nonatomic, strong, readonly) NSString *dimensionString;

@property (nonatomic, strong, readonly) NSString *dateTakenString;

@property (nonatomic, strong, readonly) NSString *dateCreatedString;

- (void)setALAsset:(ALAsset *)asset;

- (void)loadAssetWithCompletion:(void(^)(id asset))completion;

- (BOOL)isEqualToPhotoAsset:(PhotoAsset *)asset;

@end
