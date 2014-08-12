//
//  FacesViewController.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "FacesViewController.h"

@interface FacesViewController ()

@property (nonatomic, strong) CIDetector *faceDetector;

@end

@implementation FacesViewController

- (CIDetector *)faceDetector {
    if (!_faceDetector) {
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    }
    return _faceDetector;
}

- (NSString *)title {
    return NSLocalizedString(@"Faces", nil);
}

- (BOOL)shouldIncludeAsset:(ALAsset *)asset {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMArray *cached = [PhotoAsset objectsInRealm:realm where:[self cachedQueryString]];
    if (cached.count > 0) {
        for (PhotoAsset *photo in cached) {
            if ([photo.urlString isEqualToString:asset.defaultRepresentation.url.absoluteString] && photo.checkedForFaces) {
                return NO;
            }
        }
    }
    
    CIImage *image = [[CIImage alloc] initWithCGImage:[asset thumbnail]];
    NSArray *features = [self.faceDetector featuresInImage:image];
    if (features.count > 0) {
        return YES;
    }
    return NO;
}

- (PhotoAsset *)photoAssetForALAsset:(ALAsset *)asset {
    if (![self shouldIncludeAsset:asset]) {
        return nil;
    }
    PhotoAsset *photoAsset = [[PhotoAsset alloc] init];
    [photoAsset setALAsset:asset];
    [photoAsset setCheckedForFaces:YES];
    return photoAsset;
}

- (void)didFinishFetchingAssets {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        
        for (PhotoAsset *photoAsset in self.assets) {
            RLMArray *cached = [PhotoAsset objectsInRealm:realm where:@"urlString = %@", photoAsset.urlString];
            if ([cached firstObject]) {
                PhotoAsset *asset = [cached firstObject];
                [realm beginWriteTransaction];
                [asset setHasFaces:YES];
                [realm commitWriteTransaction];
            } else {
                [realm beginWriteTransaction];
                [photoAsset setHasFaces:YES];
                [realm addObject:photoAsset];
                [realm commitWriteTransaction];
            }
            
        }
    });
}

- (NSString *)cachedQueryString {
    return @"hasFaces = true && deleted = false";
}

@end
