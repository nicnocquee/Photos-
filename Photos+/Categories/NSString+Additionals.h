//
//  NSString+Additionals.h
//  Photos+
//
//  Created by  on 9/15/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PPSymbols) {
    PPSymbolsImage,
    PPSymbolsImages,
    PPSymbolsCamera,
    PPSymbolsLocation,
    PPSymbolsWhiteClock,
    PPSymbolsBlackClock,
    PPSymbolsBlackPhone,
    PPSymbolsWhitePhone,
    PPSymbolsUser,
    PPSymbolsWhiteGrin,
    PPSymbolsBlackGrin,
    PPSymbolsWhiteInfo,
    PPSymbolsBlackInfo,
    PPSymbolsSquareMail,
    PPSymbolsCircleMail,
    PPSymbolsLetterFacebook,
    PPSymbolsSquareFacebook,
    PPSymbolsCircleFacebook,
    PPSymbolsInstagram,
    PPSymbolsTwitter,
    PPSymbolsSquareTwitter,
    PPSymbolsCircleTwitter,
    PPSymbolsExport
};

@interface NSString (Additionals)

+ (NSString *)unicodeForSymbol:(PPSymbols)symbol;

@end
