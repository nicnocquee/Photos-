//
//  PhotosLibrary.m
//  Photos+
//
//  Created by  on 8/14/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotosLibrary.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "PhotoAsset.h"

#import "UIDevice+Additionals.h"

#import <ImageIO/CGImageProperties.h>

NSString *photosUpdatedNotification = @"com.getdelightfulapp.photosplus.updatednotification";
NSString *facesUpdatedNotification = @"com.getdelightfulapp.photosplus.facesupdatednotification";
NSString *selfiesUpdatedNotification = @"com.getdelightfulapp.photosplus.selfiesupdatednotification";
NSString *screenshotsUpdatedNotification = @"com.getdelightfulapp.photosplus.screenshotsudpatednotification";
NSString *didChangeFacesTasksNumberNotification = @"com.getdelightfulapp.facestaskchangednotification";
NSString *didChangeSelfiesTasksNumberNotification = @"com.getdelightfulapp.selfiestaskchangednotification";
NSString *didChangeScreenshotsTasksNumberNotification = @"com.getdelightfulapp.screenshotstaskchangednotification";

NSString *insertedAssetKey = @"insertedAssetKey";
NSString *updatedAssetKey = @"updatedAssetKey";
NSString *deletedAssetKey = @"deletedAssetKey";

static BOOL isSelfieAsset(ALAsset *asset) {
    NSCAssert(asset, @"Selfie: Assert is nil");
    ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
    NSDictionary *metadata = [assetRepresentation metadata];
    if (metadata) {
        NSDictionary *exif = metadata[(NSString *)kCGImagePropertyExifDictionary];
        if (exif) {
            NSString *lensModel = exif[@"LensModel"];
            if (lensModel && [lensModel rangeOfString:@"front camera"].location != NSNotFound) {
                return YES;
            }
        }
    }
    
    return NO;
}

static BOOL isScreenshotAsset(ALAsset *asset) {
    NSCAssert(asset, @"Screenshot: Assert is nil");
    ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
    CGSize size = [assetRepresentation dimensions];
    NSCAssert(!CGSizeEqualToSize(size, CGSizeZero), @"Screenshot: asset has zero dimension");
    CGSize windowSize = [[UIApplication sharedApplication] keyWindow].frame.size;
    if (CGSizeEqualToSize(size, windowSize)) {
        return YES;
    }
    
    for (NSValue *dimension in [UIDevice deviceDimensions]) {
        if (CGSizeEqualToSize(size, [dimension CGSizeValue])) {
            return YES;
            break;
        }
    }
    
    return NO;
}

static BOOL hasFacesAsset(ALAsset *asset) {
    NSCAssert(asset, @"Has faces: Assert is nil");
    static CIDetector *faceDetector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    });
    CIImage *image = [[CIImage alloc] initWithCGImage:[asset thumbnail]];
    NSArray *features = [faceDetector featuresInImage:image];
    if (features.count > 0) {
        return YES;
    }
    return NO;
}

@interface PhotosLibrary ()

@property (nonatomic, strong) ALAssetsLibrary *library;

@property (nonatomic, strong) NSMutableOrderedSet *photos;

@property (nonatomic, strong) NSOperationQueue *operationsQueue;

@property (nonatomic, assign) NSInteger numberOfPhotos;

@property (nonatomic, assign) NSInteger numberOfPhotosToCheckForSelfies;

@property (nonatomic, assign) NSInteger numberOfPhotosToCheckForScreenshots;

@property (nonatomic, assign) NSInteger numberOfPhotosToCheckForFaces;

@property (nonatomic, assign) NSInteger numberOfPhotosToCheckForAllPhotos;

@property (nonatomic, assign) NSInteger numberOfPhotosToCheck;

@property (nonatomic, assign) BOOL loadingPhotos;

@end

@implementation PhotosLibrary

+ (instancetype)sharedLibrary {
    static PhotosLibrary *_sharedLibrary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLibrary = [[PhotosLibrary alloc] init];
    });
    
    return _sharedLibrary;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.photos = [[NSMutableOrderedSet alloc] init];
        self.library = [[ALAssetsLibrary alloc] init];
        
        self.operationsQueue = [[NSOperationQueue alloc] init];
        [self.operationsQueue setMaxConcurrentOperationCount:1];
        [self.operationsQueue setName:@"com.getdelightfulapp.photosplus.operations"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryDidChangeNotification:) name:ALAssetsLibraryChangedNotification object:nil];
    }
    return self;
}

- (void)loadPhotos {
    if (self.loadingPhotos && self.numberOfPhotosToCheckForAllPhotos > 0 && self.numberOfPhotosToCheckForFaces > 0 && self.numberOfPhotosToCheckForScreenshots > 0 && self.numberOfPhotosToCheckForSelfies > 0) {
        return;
    }
    self.loadingPhotos = YES;
    void (^enumerate)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
    {
        //NSLog(@"start enumerating");
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos)
        {
            self.numberOfPhotosToCheck = self.numberOfPhotosToCheckForAllPhotos = self.numberOfPhotosToCheckForFaces = self.numberOfPhotosToCheckForScreenshots = self.numberOfPhotosToCheckForSelfies = group.numberOfAssets;
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop2) {
                
                if (result) {

                    PhotoAsset *photoAsset = [PhotoAsset firstInstanceWhere:@"url = ? order by assetIndex limit 1", result.defaultRepresentation.url];
                    if (!photoAsset) {
                        //NSLog(@"creating new asset");
                        photoAsset = [[PhotoAsset alloc] init];
                        [photoAsset setALAsset:result];
                        [photoAsset setAssetIndex:index];
                        [photoAsset save];
                    } else {
                        if (photoAsset.assetIndex != index) {
                            [photoAsset setAssetIndex:index];
                            [photoAsset save];
                        }
                    }
                    [self.photos addObject:photoAsset];
                    
                    if (index%500 == 0) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:photosUpdatedNotification object:nil userInfo:nil];
                        }];
                    }
                    
                    if (!photoAsset.checkedForFaces) {
                        NSBlockOperation *facesOperation = [NSBlockOperation blockOperationWithBlock:^{
                            BOOL hasFaces = hasFacesAsset(result);
                            if (hasFaces != photoAsset.hasFaces) [photoAsset setHasFaces:hasFaces];
                            [photoAsset setCheckedForFaces:YES];
                            [photoAsset save];
                            
                            if (photoAsset.hasFaces) {
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:facesUpdatedNotification object:nil userInfo:@{insertedAssetKey: photoAsset.url}];
                                }];
                            }
                            self.numberOfPhotosToCheckForFaces--;
                        }];
                        
                        [self.operationsQueue addOperation:facesOperation];
                    } else {
                        self.numberOfPhotosToCheckForFaces--;
                    }
                    
                    if (!photoAsset.checkedForScreenshot) {
                        NSBlockOperation *screenshotsOperation = [NSBlockOperation blockOperationWithBlock:^{
                            BOOL screenshots = isScreenshotAsset(result);
                            if (screenshots != photoAsset.isScreenshot) [photoAsset setScreenshot:screenshots];
                            [photoAsset setCheckedForScreenshot:YES];
                            [photoAsset save];
                            
                            if (photoAsset.isScreenshot) {
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:screenshotsUpdatedNotification object:nil userInfo:@{insertedAssetKey: photoAsset.url}];
                                }];
                            }
                            self.numberOfPhotosToCheckForScreenshots--;
                        }];
                        
                        [self.operationsQueue addOperation:screenshotsOperation];
                    } else {
                        self.numberOfPhotosToCheckForScreenshots--;
                    }
                    
                    if (!photoAsset.checkedForSelfies) {
                        NSBlockOperation *screenshotsOperation = [NSBlockOperation blockOperationWithBlock:^{
                            BOOL selfie = isSelfieAsset(result);
                            if (selfie != photoAsset.isSelfies) [photoAsset setSelfies:selfie];
                            [photoAsset setCheckedForSelfies:YES];
                            [photoAsset save];
                            
                            if (photoAsset.isSelfies) {
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:selfiesUpdatedNotification object:nil userInfo:@{insertedAssetKey: photoAsset.url}];
                                }];
                            }
                            self.numberOfPhotosToCheckForSelfies--;
                        }];
                        
                        [self.operationsQueue addOperation:screenshotsOperation];
                    } else {
                        self.numberOfPhotosToCheckForSelfies--;
                    }
                }
                self.numberOfPhotosToCheckForAllPhotos--;
            }];
            
            //NSLog(@"Done enumerating assets: %d", (int)self.photos.count);
            self.numberOfPhotos = self.photos.count;
            self.loadingPhotos = NO;
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:photosUpdatedNotification object:nil userInfo:nil];
            }];
            
            *stop = YES;
        }
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                    usingBlock:enumerate
                                  failureBlock:^(NSError *error) {
                                      //NSLog(@"Error enumerate: %@", error);
                                  }];
    });
}

- (void)assetsLibraryDidChangeNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSLog(@"Library did change notification: %@", userInfo);
    if (userInfo) {
        if (userInfo.count > 0) {
            NSArray *updatedAssets = userInfo[ALAssetLibraryUpdatedAssetsKey];
            for (NSURL *updatedAsset in updatedAssets) {
                [self.library assetForURL:updatedAsset resultBlock:^(ALAsset *asset) {
                    NSLog(@"here");
                } failureBlock:^(NSError *error) {
                    NSLog(@"error: %@", error);
                }];
            }
        } else {
            // empty dictionary no need to do anything
        }
    } else {
        // need to reload all assets
    }
    [self loadPhotos];
}

- (void)setNumberOfPhotos:(NSInteger)numberOfPhotos {
    if (_numberOfPhotos != numberOfPhotos) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotos))];
        _numberOfPhotos = numberOfPhotos;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotos))];
    }
}

- (void)setNumberOfPhotosToCheck:(NSInteger)numberOfPhotosToCheck {
    if (_numberOfPhotosToCheck != numberOfPhotosToCheck) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotosToCheck))];
        _numberOfPhotosToCheck = numberOfPhotosToCheck;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotosToCheck))];
    }
}

- (void)setNumberOfPhotosToCheckForAllPhotos:(NSInteger)numberOfPhotosToCheckForAllPhotos {
    if (_numberOfPhotosToCheckForAllPhotos != numberOfPhotosToCheckForAllPhotos) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotosToCheckForAllPhotos))];
        _numberOfPhotosToCheckForAllPhotos = numberOfPhotosToCheckForAllPhotos;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotosToCheckForAllPhotos))];
    }
}

- (void)setNumberOfPhotosToCheckForFaces:(NSInteger)numberOfPhotosToCheckForFaces {
    if (_numberOfPhotosToCheckForFaces != numberOfPhotosToCheckForFaces) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotosToCheckForFaces))];
        _numberOfPhotosToCheckForFaces = numberOfPhotosToCheckForFaces;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotosToCheckForFaces))];
    }
}

- (void)setNumberOfPhotosToCheckForScreenshots:(NSInteger)numberOfPhotosToCheckForScreenshots {
    if (_numberOfPhotosToCheckForScreenshots != numberOfPhotosToCheckForScreenshots) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotosToCheckForScreenshots))];
        _numberOfPhotosToCheckForScreenshots = numberOfPhotosToCheckForScreenshots;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotosToCheckForScreenshots))];
    }
}

- (void)setNumberOfPhotosToCheckForSelfies:(NSInteger)numberOfPhotosToCheckForSelfies {
    if (_numberOfPhotosToCheckForSelfies != numberOfPhotosToCheckForSelfies) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotosToCheckForSelfies))];
        _numberOfPhotosToCheckForSelfies = numberOfPhotosToCheckForSelfies;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotosToCheckForSelfies))];
    }
}

@end
