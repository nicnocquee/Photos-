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
        
    self.assets = [[NSMutableOrderedSet alloc] init];
    
    [self loadPhotos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPhotos {
    [self showLoadingView:YES];
    
    [self loadCachedWithCompletion:^{
        __weak typeof (self) selfie = self;
        void (^enumerate)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
        {
            if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos)
            {
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop2) {
                    if ([selfie cachedQueryString]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [selfie setTitleWithAnalyzingIndex:index total:group.numberOfAssets];
                        });
                    }
                    
                    if (result) {
                        PhotoAsset *photoAsset = [selfie photoAssetForALAsset:result];
                        if (photoAsset) {
                            NSInteger count = selfie.assets.count;
                            [selfie.assets insertObject:photoAsset atIndex:0];
                            if (selfie.assets.count > count) {
                                if ([selfie cachedQueryString]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [selfie.collectionView performBatchUpdates:^{
                                            [selfie.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
                                        } completion:^(BOOL finished) {
                                            
                                        }];
                                    });
                                }
                            }
                        }
                    }
                }];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    selfie.navigationItem.titleView = nil;
                    selfie.navigationItem.title = [selfie title];
                    [selfie didFinishFetchingAssets];
                    [selfie showLoadingView:NO];
                    [selfie.collectionView reloadData];
                });
                *stop = YES;
            }
        };
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [ASSETS_LIBRARY enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                          usingBlock:enumerate
                                        failureBlock:^(NSError *error) {
                                            NSLog(@"Error enumerate: %@", error);
                                        }];
        });
    }];
}

- (void)setTitleWithAnalyzingIndex:(NSInteger)index total:(NSInteger)total {
    if (index == total-1) {
        [self.navigationItem setTitleView:nil];
        self.navigationItem.title = [self title];
    } else {
        NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"Analyzing %1$d of %2$d", nil), index, total];
        NSString *text = [NSString stringWithFormat:@"%@\n%@", [self title], progressString];
        NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];
        [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range:[text rangeOfString:[self title]]];
        [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:[text rangeOfString:progressString]];
        UILabel *label = [[UILabel alloc] init];
        [label setAttributedText:attr];
        [label setNumberOfLines:2];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label sizeToFit];
        [self.navigationItem setTitleView:label];
    }
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

- (PhotoAsset *)photoAssetForALAsset:(ALAsset *)asset {
    PhotoAsset *photoAsset = [[PhotoAsset alloc] init];
    [photoAsset setALAsset:asset];
    return photoAsset;
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

- (void)didFinishFetchingAssets {
    
}

- (NSString *)cachedQueryString {
    return nil;
}

- (void)loadCachedWithCompletion:(void (^)())completion {
    if ([self cachedQueryString]) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        RLMArray *cached = [PhotoAsset objectsInRealm:realm where:[self cachedQueryString]];
        if (cached.count > 0) {
            __weak typeof (self) selfie = self;
            __block int count = (int)cached.count;
            for (PhotoAsset *asset in cached) {
                [asset loadAssetWithCompletion:^(id completedAsset) {
                    count--;
                    if (completedAsset) {
                        [selfie.assets addObject:asset];
                    } else {
                        [realm beginWriteTransaction];
                        [asset setDeleted:YES];
                        [realm commitWriteTransaction];
                    }
                    if (count == 0) {
                        [selfie.collectionView reloadData];
                        if (completion) {
                            completion();
                        }
                    }
                }];
            }
        } else{
            if (completion) {
                completion();
            }
        }
    } else {
        if (completion) {
            completion();
        }
    }
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
