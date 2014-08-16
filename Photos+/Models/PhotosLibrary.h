//
//  PhotosLibrary.h
//  Photos+
//
//  Created by  on 8/14/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *photosUpdatedNotification;
extern NSString *facesUpdatedNotification;
extern NSString *selfiesUpdatedNotification;
extern NSString *screenshotsUpdatedNotification;
extern NSString *didChangeFacesTasksNumberNotification;
extern NSString *didChangeSelfiesTasksNumberNotification;
extern NSString *didChangeScreenshotsTasksNumberNotification;

extern NSString *insertedAssetKey;
extern NSString *updatedAssetKey;
extern NSString *deletedAssetKey;

@class ALAssetsLibrary;

@interface PhotosLibrary : NSObject

+ (instancetype)sharedLibrary;

@property (nonatomic, assign, readonly) NSInteger numberOfPhotos;

@property (nonatomic, assign, readonly) NSInteger numberOfPhotosToCheckForSelfies;

@property (nonatomic, assign, readonly) NSInteger numberOfPhotosToCheckForScreenshots;

@property (nonatomic, assign, readonly) NSInteger numberOfPhotosToCheckForFaces;

@property (nonatomic, assign, readonly) NSInteger numberOfPhotosToCheck;

@property (nonatomic, assign, readonly) NSInteger numberOfPhotosToCheckForAllPhotos;

@property (nonatomic, strong, readonly) NSMutableOrderedSet *photos;

@property (nonatomic, strong, readonly) ALAssetsLibrary *library;

- (void)loadPhotos;

@end
