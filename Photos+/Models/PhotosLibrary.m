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

//@property (nonatomic, strong) NSMutableOrderedSet *facesPhotos;
//
//@property (nonatomic, strong) NSMutableOrderedSet *screenshotsPhotos;
//
//@property (nonatomic, strong) NSMutableOrderedSet *selfiesPhotos;

//@property (nonatomic, strong) NSOperationQueue *selfiesQueue;
//
//@property (nonatomic, strong) NSOperationQueue *facesQueue;
//
//@property (nonatomic, strong) NSOperationQueue *screenshotsQueue;

@property (nonatomic, strong) NSOperationQueue *operationsQueue;

@property (nonatomic, assign) NSInteger numberOfPhotos;

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
//        self.selfiesQueue = [[NSOperationQueue alloc] init];
//        [self.selfiesQueue setMaxConcurrentOperationCount:1];
//        [self.selfiesQueue setName:@"com.getdelightfulapp.photosplus.selfies"];
//        
//        self.facesQueue = [[NSOperationQueue alloc] init];
//        [self.facesQueue setMaxConcurrentOperationCount:1];
//        [self.facesQueue setName:@"com.getdelightfulapp.photosplus.faces"];
//        
//        self.screenshotsQueue = [[NSOperationQueue alloc] init];
//        [self.screenshotsQueue setMaxConcurrentOperationCount:1];
//        [self.screenshotsQueue setName:@"com.getdelightfulapp.photosplus.screenshots"];
        
        self.operationsQueue = [[NSOperationQueue alloc] init];
        [self.operationsQueue setMaxConcurrentOperationCount:1];
        [self.operationsQueue setName:@"com.getdelightfulapp.photosplus.operations"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryDidChangeNotification:) name:ALAssetsLibraryChangedNotification object:nil];
    }
    return self;
}

- (void)loadPhotos {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    void (^enumerate)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
    {
        if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos)
        {
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop2) {
                
                if (result) {
                    PhotoAsset *photoAsset = [[PhotoAsset objectsInRealm:realm where:@"urlString = %@", result.defaultRepresentation.url.absoluteString] firstObject];
                    if (!photoAsset) {
                        photoAsset = [[PhotoAsset alloc] init];
                        [photoAsset setALAsset:result];
                        [photoAsset setIndex:index];
                        [realm beginWriteTransaction];
                        [realm addObject:photoAsset];
                        [realm commitWriteTransaction];
                    } else {
                        [realm beginWriteTransaction];
                        [photoAsset setALAsset:result];
                        [photoAsset setIndex:index];
                        [realm commitWriteTransaction];
                    }
                    
                    [self.photos addObject:photoAsset];
                    
                    if (index%100 == 0) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:photosUpdatedNotification object:nil userInfo:nil];
                        }];
                    }
                    
                    if (!photoAsset.checkedForFaces) {
                        NSBlockOperation *facesOperation = [NSBlockOperation blockOperationWithBlock:^{
                            NSLog(@"starting faces operation");
                            RLMRealm *realm = [RLMRealm defaultRealm];
                            [realm setAutorefresh:YES];
                            PhotoAsset *photoAsset = [[PhotoAsset objectsInRealm:realm where:@"urlString = %@", result.defaultRepresentation.url.absoluteString] firstObject];
                            [realm beginWriteTransaction];
                            if (hasFacesAsset(result)) {
                                NSLog(@"found face");
                                [photoAsset setHasFaces:YES];
                            } else {
                                [photoAsset setHasFaces:NO];
                            }
                            [photoAsset setCheckedForFaces:YES];
                            [realm commitWriteTransaction];
                            
                            NSLog(@"done with faces");
                            if (photoAsset.hasFaces) {
                                NSLog(@"gonna post has faces notification");
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:facesUpdatedNotification object:nil userInfo:@{insertedAssetKey: photoAsset.urlString}];
                                }];
                            }
                        }];
                        
                        NSLog(@"adding face operation");
                        [self.operationsQueue addOperation:facesOperation];
                    }
                    
                    if (!photoAsset.checkedForScreenshot) {
                        NSBlockOperation *screenshotOperation = [NSBlockOperation blockOperationWithBlock:^{
                            NSLog(@"starting screenshot operation");
                            RLMRealm *realm = [RLMRealm defaultRealm];
                            [realm setAutorefresh:YES];
                            PhotoAsset *photoAsset = [[PhotoAsset objectsInRealm:realm where:@"urlString = %@", result.defaultRepresentation.url.absoluteString] firstObject];
                            [realm beginWriteTransaction];
                            if (isScreenshotAsset(result)) {
                                NSLog(@"Found screenshot");
                                [photoAsset setScreenshot:YES];
                            } else {
                                [photoAsset setScreenshot:NO];
                            }
                            [photoAsset setCheckedForScreenshot:YES];
                            [realm commitWriteTransaction];
                            
                            if (photoAsset.isScreenshot) {
                                NSLog(@"gonna post screenshot notification");
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:screenshotsUpdatedNotification object:nil userInfo:@{insertedAssetKey: photoAsset.urlString}];
                                }];
                            }
                        }];
                        
                        NSLog(@"adding screenshot operation");
                        [self.operationsQueue addOperation:screenshotOperation];
                    }
                    
                    if (!photoAsset.checkedForSelfies) {
                        NSBlockOperation *selfieOperation = [NSBlockOperation blockOperationWithBlock:^{
                            NSLog(@"starting selfies operation");
                            RLMRealm *realm = [RLMRealm defaultRealm];
                            [realm setAutorefresh:YES];
                            PhotoAsset *photoAsset = [[PhotoAsset objectsInRealm:realm where:@"urlString = %@", result.defaultRepresentation.url.absoluteString] firstObject];
                            [realm beginWriteTransaction];
                            if (isSelfieAsset(result)) {
                                NSLog(@"Found selfie");
                                [photoAsset setSelfies:YES];
                            } else {
                                [photoAsset setSelfies:NO];
                            }
                            [photoAsset setCheckedForSelfies:YES];
                            [realm commitWriteTransaction];
                            
                            if (photoAsset.isSelfies) {
                                NSLog(@"gonna post selfies notification");
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:selfiesUpdatedNotification object:nil userInfo:@{insertedAssetKey: photoAsset.urlString}];
                                }];
                            }
                        }];
                        
                        NSLog(@"adding selfies operation");
                        [self.operationsQueue addOperation:selfieOperation];
                    }
                }
            }];
            
            NSLog(@"Done enumerating assets: %d", (int)self.photos.count);
            self.numberOfPhotos = self.photos.count;
            
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
    [self loadPhotos];
}

- (void)setNumberOfPhotos:(NSInteger)numberOfPhotos {
    if (_numberOfPhotos != numberOfPhotos) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotos))];
        _numberOfPhotos = numberOfPhotos;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfPhotos))];
    }
}

@end
