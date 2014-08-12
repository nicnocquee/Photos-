//
//  PhotoAsset.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotoAsset.h"

@interface PhotoAsset ()

@end

@implementation PhotoAsset

- (UIImage *)thumbnailImage {
    return [UIImage imageWithCGImage:[self.asset thumbnail]];
}

@end
