//
//  DateInfoView.m
//  Photos+
//
//  Created by  on 9/15/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "DateInfoView.h"

#import "NSString+Additionals.h"

#import "UIFont+Additionals.h"

@implementation DateInfoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [self.dateIcon setFont:[UIFont photosplusFontWithSize:12]];
    [self.dateIcon setText:[NSString unicodeForSymbol:PPSymbolsWhiteClock]];
    
    [self.locationIcon setFont:[UIFont photosplusFontWithSize:12]];
    [self.locationIcon setText:[NSString unicodeForSymbol:PPSymbolsLocation]];
    
    [self.infoLabel setFont:[UIFont photosplusFontWithSize:22]];
    [self.infoLabel setText:[NSString unicodeForSymbol:PPSymbolsWhiteInfo]];
}



@end
