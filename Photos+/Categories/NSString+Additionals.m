//
//  NSString+Additionals.m
//  Photos+
//
//  Created by  on 9/15/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "NSString+Additionals.h"

#define pp_symbol_string_image @"image"
#define pp_symbol_string_images @"images"
#define pp_symbol_string_camera @"camera"
#define pp_symbol_string_location @"location"
#define pp_symbol_string_white_clock @"white_clock"
#define pp_symbol_string_black_clock @"black_clock"
#define pp_symbol_string_white_phone @"white_phone"
#define pp_symbol_string_black_phone @"black_phone"
#define pp_symbol_string_user @"user"
#define pp_symbol_string_white_grin @"white_grin"
#define pp_symbol_string_black_grin @"black_grin"
#define pp_symbol_string_white_info @"white_info"
#define pp_symbol_string_black_info @"black_info"
#define pp_symbol_string_square_mail @"square_mail"
#define pp_symbol_string_circle_mail @"circle_mail"
#define pp_symbol_string_facebook @"facebook"
#define pp_symbol_string_square_facebook @"square_facebook"
#define pp_symbol_string_circle_facebook @"circle_facebook"
#define pp_symbol_string_instagram @"instagram"
#define pp_symbol_string_twitter @"twitter"
#define pp_symbol_string_squre_twitter @"square_twitter"
#define pp_symbol_string_circle_twitter @"circle_twitter"
#define pp_symbol_string_export @"export"

@implementation NSString (Additionals)

+ (NSString *)unicodeForSymbol:(PPSymbols)symbol {
    NSDictionary *unicodeDictionary = @{
                                        pp_symbol_string_image: @"\ue600",
                                        pp_symbol_string_images: @"\ue601",
                                        pp_symbol_string_camera: @"\ue602",
                                        pp_symbol_string_location: @"\ue603",
                                        pp_symbol_string_white_clock: @"\ue604",
                                        pp_symbol_string_black_clock: @"\ue605",
                                        pp_symbol_string_white_phone: @"\ue615",
                                        pp_symbol_string_black_phone: @"\ue606",
                                        pp_symbol_string_user: @"\ue607",
                                        pp_symbol_string_white_grin: @"\ue608",
                                        pp_symbol_string_black_grin: @"\ue609",
                                        pp_symbol_string_white_info: @"\ue60a",
                                        pp_symbol_string_black_info: @"\ue60b",
                                        pp_symbol_string_square_mail: @"\ue60c",
                                        pp_symbol_string_circle_mail: @"\ue60d",
                                        pp_symbol_string_facebook: @"\ue60e",
                                        pp_symbol_string_square_facebook: @"\ue60f",
                                        pp_symbol_string_circle_facebook: @"\ue610",
                                        pp_symbol_string_instagram: @"\ue611",
                                        pp_symbol_string_twitter: @"\ue612",
                                        pp_symbol_string_squre_twitter: @"\ue613",
                                        pp_symbol_string_circle_twitter: @"\ue614",
                                        pp_symbol_string_export: @"\ue616",
                                        };
    return unicodeDictionary[[NSString stringForSymbol:symbol]];
}

+ (NSString *)stringForSymbol:(PPSymbols)symbol {
    switch (symbol) {
        case PPSymbolsImage:
            return pp_symbol_string_image;
            break;
        case PPSymbolsImages:
            return pp_symbol_string_images;
            break;
        case PPSymbolsBlackClock:
            return pp_symbol_string_black_clock;
            break;
        case PPSymbolsBlackGrin:
            return pp_symbol_string_black_grin;
            break;
        case PPSymbolsBlackInfo:
            return pp_symbol_string_black_info;
            break;
        case PPSymbolsBlackPhone:
            return pp_symbol_string_black_phone;
            break;
        case PPSymbolsCamera:
            return pp_symbol_string_camera;
            break;
        case PPSymbolsCircleFacebook:
            return pp_symbol_string_circle_facebook;
            break;
        case PPSymbolsCircleMail:
            return pp_symbol_string_circle_mail;
            break;
        case PPSymbolsCircleTwitter:
            return pp_symbol_string_circle_twitter;
            break;
        case PPSymbolsExport:
            return pp_symbol_string_export;
            break;
        case PPSymbolsInstagram:
            return pp_symbol_string_instagram;
            break;
        case PPSymbolsLetterFacebook:
            return pp_symbol_string_facebook;
            break;
        case PPSymbolsLocation:
            return pp_symbol_string_location;
            break;
        case PPSymbolsSquareFacebook:
            return pp_symbol_string_square_facebook;
            break;
        case PPSymbolsSquareMail:
            return pp_symbol_string_square_mail;
            break;
        case PPSymbolsSquareTwitter:
            return pp_symbol_string_squre_twitter;
            break;
        case PPSymbolsTwitter:
            return pp_symbol_string_twitter;
            break;
        case PPSymbolsUser:
            return pp_symbol_string_user;
            break;
        case PPSymbolsWhiteClock:
            return pp_symbol_string_white_clock;
            break;
        case PPSymbolsWhiteGrin:
            return pp_symbol_string_white_grin;
            break;
        case PPSymbolsWhiteInfo:
            return pp_symbol_string_white_info;
            break;
        case PPSymbolsWhitePhone:
            return pp_symbol_string_white_phone;
            break;
        default:
            break;
    }
    return nil;
}

@end
