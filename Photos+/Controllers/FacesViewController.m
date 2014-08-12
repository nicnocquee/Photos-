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
    CIImage *image = [[CIImage alloc] initWithCGImage:[asset thumbnail]];
    NSArray *features = [self.faceDetector featuresInImage:image];
    if (features.count > 0) {
        return YES;
    }
    return NO;
}

@end
