//
//  PhotoCell.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotoCell.h"

#import "PhotoCellView.h"

@interface PhotoCell ()

@property (nonatomic, weak) PhotoCellView *cellView;

@end

@implementation PhotoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        PhotoCellView *cellView = (PhotoCellView *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([PhotoCellView class]) owner:nil options:nil] firstObject];
        [self.contentView addSubview:cellView];
        self.cellView = cellView;
        NSDictionary *dict = @{@"cellView": self.cellView};
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[cellView]-0-|" options:0 metrics:nil views:dict]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cellView]-0-|" options:0 metrics:nil views:dict]];
    }
    return self;
}

- (void)prepareForReuse {
    self.photoAsset = nil;
}

- (void)setPhotoAsset:(PhotoAsset *)photoAsset {
    if (_photoAsset != photoAsset) {
        _photoAsset = photoAsset;
        [self.cellView.imageView setImage:_photoAsset.thumbnailImage];
        [_photoAsset loadAssetWithCompletion:^(ALAsset *asset) {
            if (asset) [self.cellView.imageView setImage:[UIImage imageWithCGImage:[asset thumbnail]]];
        }];
    }
}

@end
