//
//  WXDailyForecast.m
//  SimpleWeather
//
//  Created by Jason on 14-4-13.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

#import "WXDailyForecast.h"

@implementation WXDailyForecast

#pragma mark - Override
+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    // 1
    NSMutableDictionary *paths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    // 2
    paths[@"tempHigh"] = @"temp.max";
    paths[@"tempLow"] = @"temp.min";
    // 3
    return paths;
}

@end
