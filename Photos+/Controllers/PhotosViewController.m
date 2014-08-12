//
//  PhotosViewController.m
//  Photos+
//
//  Created by  on 8/12/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "PhotosViewController.h"

#import "PhotoCell.h"

#import "PhotosViewControllerCollectionViewDelegate.h"

#import "PhotoAsset.h"

@interface PhotosViewController () <UICollectionViewDataSource>

@property (nonatomic, strong) PhotosViewControllerCollectionViewDelegate *collectionViewDelegate;

@property (nonatomic, strong) ALAssetsLibrary *library;

@end

@implementation PhotosViewController

- (void)awakeFromNib {
    self.navigationController.tabBarItem.title = [self tabBarItemTitle];
    self.navigationController.tabBarItem.image = [self tabBarItemImage];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [self title];
    
    self.collectionViewDelegate = [[PhotosViewControllerCollectionViewDelegate alloc] initWithCollectionView:self.collectionView];
    [self.collectionView setDataSource:self];
    [self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:NSStringFromClass([PhotoCell class])];
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    self.assets = [NSMutableArray array];
    
    [self loadPhotos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPhotos {
    [self showLoadingView:YES];
    __weak typeof (self) selfie = self;
    
    void (^enumerate)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
    {
        if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos)
        {
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (result) {
                    if ([selfie shouldIncludeAsset:result]) {
                        PhotoAsset *photoAsset = [[PhotoAsset alloc] init];
                        [photoAsset setAsset:result];
                        [selfie.assets addObject:photoAsset];
                    }
                }
            }];
            
            *stop = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [selfie showLoadingView:NO];
                [selfie.collectionView reloadData];
            });
        }
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                    usingBlock:enumerate
                                  failureBlock:nil];
    });
}

- (void)showLoadingView:(BOOL)show {
    if (show) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
        [self.navigationItem setRightBarButtonItem:loadingItem];
        [indicator startAnimating];
    } else {
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (BOOL)shouldIncludeAsset:(ALAsset *)asset {
    return YES;
}

- (NSString *)tabBarItemTitle {
    return self.title;
}

- (UIImage *)tabBarItemImage {
    return nil;
}

- (NSString *)title {
    return NSLocalizedString(@"All Photos", nil);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PhotoCell class]) forIndexPath:indexPath];
    [cell setPhotoAsset:[self.assets objectAtIndex:indexPath.item]];
    return cell;
}

@end
