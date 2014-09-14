//
//  PhotoInfoViewController.m
//  PhotoBox
//
//  Created by Nico Prananta on 10/29/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import "PhotoInfoViewController.h"

#import "PhotoAsset.h"
#import "UIView+Additionals.h"

#import "LocationManager.h"

#import "InfoTableViewCell.h"

#define PHOTO_INFO_FONT_SIZE 12
#define PHOTO_INFO_CLOSE_OFFSET 50

@interface PhotoInfoViewController () {
    BOOL isClosing;
}

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSArray *cameraDataSectionRows;

@end

@implementation PhotoInfoViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setBackgroundColor:[UIColor clearColor]];

    self.sections = @[NSLocalizedString(@"Camera Data", nil)];
    
    self.cameraDataSectionRows = @[
                                NSLocalizedString(@"Camera Make", nil),
                                NSLocalizedString(@"Camera Model", nil),
                                NSLocalizedString(@"Exposure Time", nil),
                                NSLocalizedString(@"F Number", nil),
                                NSLocalizedString(@"Focal Length", nil),
                                NSLocalizedString(@"ISO Time", nil),
                                NSLocalizedString(@"Dimension", nil),
                                NSLocalizedString(@"File Name", nil),
                                NSLocalizedString(@"Date Taken", nil),
                                NSLocalizedString(@"Location", nil),
                                NSLocalizedString(@"Location Name", nil)
                                   ];
    
    CGFloat cellHeight = [self tableView:nil heightForRowAtIndexPath:nil];
    [self.tableView setContentInset:UIEdgeInsetsMake(CGRectGetHeight(self.tableView.frame)-cellHeight*(self.cameraDataSectionRows.count+1), 0, 0, 0)];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([InfoTableViewCell class]) bundle:nil] forCellReuseIdentifier:@"Cell"];
}

- (void)viewDidAppear:(BOOL)animated {
    NSNumber *latitude = [self.photo latitude];
    NSNumber *longitude = [self.photo longitude];
    if (latitude && ![latitude isKindOfClass:[NSNull class]] && longitude && ![longitude isKindOfClass:[NSNull class]]) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
        if (location) {
            __weak typeof (self) selfie = self;
            [[LocationManager sharedManager] nameForLocation:location completionHandler:^(NSString *placemark, NSError *error) {
                NSMutableArray *cameraDataSectionRowsCopy = [selfie.cameraDataSectionRows mutableCopy];
                [cameraDataSectionRowsCopy removeLastObject];
                if (placemark && !error) {
                    [cameraDataSectionRowsCopy addObject:@[NSLocalizedString(@"Location Name", nil), placemark]];
                } else {
                    [cameraDataSectionRowsCopy addObject:@[NSLocalizedString(@"Location Name", nil), @""]];
                }
                
                selfie.cameraDataSectionRows = cameraDataSectionRowsCopy;
                [selfie.tableView reloadData];
            }];
        } else {
            NSMutableArray *cameraDataSectionRowsCopy = [self.cameraDataSectionRows mutableCopy];
            [cameraDataSectionRowsCopy removeLastObject];
            [cameraDataSectionRowsCopy addObject:@[NSLocalizedString(@"Location Name", nil), @""]];
            self.cameraDataSectionRows = cameraDataSectionRowsCopy;
            [self.tableView reloadData];
        }
    } else {
        NSMutableArray *cameraDataSectionRowsCopy = [self.cameraDataSectionRows mutableCopy];
        [cameraDataSectionRowsCopy removeLastObject];
        [cameraDataSectionRowsCopy addObject:@[NSLocalizedString(@"Location Name", nil), @""]];
        self.cameraDataSectionRows = cameraDataSectionRowsCopy;
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.cameraDataSectionRows.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    InfoTableViewCell *cell = (InfoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [self configureCell:cell indexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(InfoTableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [self configureCameraDataCell:cell forIndexPath:indexPath];
    }
}

- (void)configureCameraDataCell:(InfoTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    NSArray *cameraDataRow = self.cameraDataSectionRows[indexPath.row];
    NSString *key = cameraDataRow[1];
    NSString *value = nil;
    if (key && [self.photo respondsToSelector:NSSelectorFromString(key)]) {
        id val = [self.photo valueForKey:key];
        if ([val isKindOfClass:[NSNumber class]]) {
            val = [NSString stringWithFormat:@"%f", [val doubleValue]];
            value = [[val stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"0"]] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
        } else value = val;
    } else {
        if (key) {
            value = [key stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[[]]"]];
        }
    }
    if (!value || value.length == 0) value = NSLocalizedString(@"Not available", nil);
    [cell setText:cameraDataRow[0] detail:value];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    InfoTableViewCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([InfoTableViewCell class]) owner:nil options:0] firstObject];
    [self configureCell:cell indexPath:indexPath];
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    return cell.intrinsicContentSize.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat distance = self.tableView.contentInset.top+scrollView.contentOffset.y;
    if (distance < 0) {
        CGFloat progress = MIN((-distance)/(float)PHOTO_INFO_CLOSE_OFFSET, 1);
        if (!isClosing) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(photoInfoViewController:didDragToClose:)]) {
                [self.delegate photoInfoViewController:self didDragToClose:progress];
            }
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat distance = self.tableView.contentInset.top+scrollView.contentOffset.y;
    CGFloat progress = MIN((-distance)/(float)PHOTO_INFO_CLOSE_OFFSET, 1);
    if (progress == 1) {
        isClosing = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoInfoViewControllerDidClose:)]) {
            [self.delegate photoInfoViewControllerDidClose:self];
        }
    }
}

@end
