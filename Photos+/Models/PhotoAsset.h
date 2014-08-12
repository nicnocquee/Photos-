//
//  PhotoAsset.h
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoAsset : NSObject

@property (nonatomic, strong) ALAsset *asset;

@property (nonatomic, strong, readonly) UIImage *thumbnailImage;

@end
