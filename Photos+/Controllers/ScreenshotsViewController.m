//
//  ScreenshotsViewController.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "ScreenshotsViewController.h"

#import "UIDevice+Additionals.h"

@interface ScreenshotsViewController ()

@end

@implementation ScreenshotsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self title];
}

- (BOOL)shouldIncludeAsset:(ALAsset *)asset {
    ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
    CGSize size = [assetRepresentation dimensions];
    CGSize windowSize = [[UIApplication sharedApplication] keyWindow].frame.size;
    if (CGSizeEqualToSize(size, windowSize)) {
        return YES;
    }
    
    for (NSValue *dimension in [UIDevice deviceDimensions]) {
        if (CGSizeEqualToSize(size, [dimension CGSizeValue])) {
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)title {
    return NSLocalizedString(@"Screenshots", nil);
}

@end
