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
    if (self.loadingPhotos) {
        return;
    }
    self.loadingPhotos = YES;
    
    void (^enumerate)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
    {
        NSLog(@"start enumerating");
        if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos)
        {
            self.numberOfPhotosToCheck = self.numberOfPhotosToCheckForAllPhotos = self.numberOfPhotosToCheckForFaces = self.numberOfPhotosToCheckForScreenshots = self.numberOfPhotosToCheckForSelfies = group.numberOfAssets;
            
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop2) {
                
                if (result) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    PhotoAsset *photoAsset = [[PhotoAsset objectsInRealm:realm where:@"urlString = %@", result.defaultRepresentation.url.absoluteString] firstObject];
                    if (!photoAsset) {
                        NSLog(@"creating new asset");
                        photoAsset = [[PhotoAsset alloc] init];
                        [realm beginWriteTransaction];
                        [photoAsset setALAsset:result];
                        [photoAsset setIndex:index];
                        [realm addObject:photoAsset];
                        [realm commitWriteTransaction];
                    } else {
                        NSLog(@"updating existing asset");
                        [realm beginWriteTransaction];
                        [photoAsset setALAsset:result];
                        [photoAsset setIndex:index];
                        [realm commitWriteTransaction];
                    }
                    NSLog(@"going to add asset to self.photos %@",result.defaultRepresentation.url.absoluteString);
                    NSString *assetURL = photoAsset.urlString;
                    NSBlockOperation *addAssetOperation = [NSBlockOperation blockOperationWithBlock:^{
                        RLMRealm *realm4 = [RLMRealm defaultRealm];
                        [realm4 setAutorefresh:YES];
                        [realm4 refresh];
                        PhotoAsset *photoAsset = [[PhotoAsset objectsInRealm:realm4 where:@"urlString = %@", assetURL] firstObject];
                        [self.photos addObject:photoAsset];
                        NSLog(@"added asset to self.photos");
                    }];
                    
                    [[NSOperationQueue mainQueue] addOperations:@[addAssetOperation] waitUntilFinished:YES];
                    
                    if (index%100 == 0) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:photosUpdatedNotification object:nil userInfo:nil];
                        }];
                    }
                    
                    if (!photoAsset.checkedForFaces) {
                        NSBlockOperation *facesOperation = [NSBlockOperation blockOperationWithBlock:^{
                            RLMRealm *realm1 = [RLMRealm defaultRealm];
                            [realm1 setAutorefresh:YES];
                            [realm1 refresh];
                            PhotoAsset *photoAsset = [[PhotoAsset objectsInRealm:realm1 where:@"urlString = %@", result.defaultRepresentation.url.absoluteString] firstObject];
                            [realm1 beginWriteTransaction];
                            if (hasFacesAsset(result)) {
                                NSLog(@"found face");
                                [photoAsset setHasFaces:YES];
                            } else {
                                [photoAsset setHasFaces:NO];
                            }
                            [photoAsset setCheckedForFaces:YES];
                            [realm1 commitWriteTransaction];
                            
                            if (photoAsset.hasFaces) {
                                NSString *urlString = photoAsset.urlString;
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:facesUpdatedNotification object:nil userInfo:@{insertedAssetKey: urlString}];
                                }];
                            }
                            self.numberOfPhotosToCheckForFaces--;
                            realm1 = nil;
                        }];
                        
                        [self.operationsQueue addOperation:facesOperation];
                    } else {
                        self.numberOfPhotosToCheckForFaces--;
                    }
                    
                    if (!photoAsset.checkedForScreenshot) {
                        NSBlockOperation *screenshotOperation = [NSBlockOperation blockOperationWithBlock:^{
                            RLMRealm *realm2 = [RLMRealm defaultRealm];
                            [realm2 setAutorefresh:YES];
                            [realm2 refresh];
                            PhotoAsset *photoAsset = [[PhotoAsset objectsInRealm:realm2 where:@"urlString = %@", result.defaultRepresentation.url.absoluteString] firstObject];
                            [realm2 beginWriteTransaction];
                            if (isScreenshotAsset(result)) {
                                [photoAsset setScreenshot:YES];
                            } else {
                                [photoAsset setScreenshot:NO];
                            }
                            [photoAsset setCheckedForScreenshot:YES];
                            [realm2 commitWriteTransaction];
                            
                            if (photoAsset.isScreenshot) {
                                NSString *urlString = photoAsset.urlString;
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:screenshotsUpdatedNotification object:nil userInfo:@{insertedAssetKey: urlString}];
                                }];
                            }
                            self.numberOfPhotosToCheckForScreenshots--;
                            realm2 = nil;
                        }];
                        
                        [self.operationsQueue addOperation:screenshotOperation];
                    } else {
                        self.numberOfPhotosToCheckForScreenshots--;
                    }
                    
                    if (!photoAsset.checkedForSelfies) {
                        NSBlockOperation *selfieOperation = [NSBlockOperation blockOperationWithBlock:^{
                            RLMRealm *realm3 = [RLMRealm defaultRealm];
                            [realm3 setAutorefresh:YES];
                            [realm3 refresh];
                            PhotoAsset *photoAsset = [[PhotoAsset objectsInRealm:realm3 where:@"urlString = %@", result.defaultRepresentation.url.absoluteString] firstObject];
                            [realm3 beginWriteTransaction];
                            if (isSelfieAsset(result)) {
                                [photoAsset setSelfies:YES];
                            } else {
                                [photoAsset setSelfies:NO];
                            }
                            [photoAsset setCheckedForSelfies:YES];
                            [realm3 commitWriteTransaction];
                            
                            if (photoAsset.isSelfies) {
                                NSString *urlString = photoAsset.urlString;
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:selfiesUpdatedNotification object:nil userInfo:@{insertedAssetKey: urlString}];
                                }];
                            }
                            self.numberOfPhotosToCheckForSelfies--;
                            realm3 = nil;
                        }];
                        
                        [self.operationsQueue addOperation:selfieOperation];
                    } else {
                        self.numberOfPhotosToCheckForSelfies--;
                    }
                }
                self.numberOfPhotosToCheckForAllPhotos--;
            }];
            
            NSLog(@"Done enumerating assets: %d", (int)self.photos.count);
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
                                        NSLog(@"Error enumerate: %@", error);
                                    }];
    });
}

- (void)assetsLibraryDidChangeNotification:(NSNotification *)notification {
    NSLog(@"Library did change notification: %@", notification.userInfo);
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
