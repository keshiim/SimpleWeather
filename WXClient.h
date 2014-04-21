//
//  WXClient.h
//  SimpleWeather
//
//  Created by Jason on 14-4-13.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

/*
 * WXClient的唯一责任是创建API请求，并解析它们；
 * 别人可以不用担心用数据做什么以及如何存储它。
 * 划分类的不同工作职责的设计模式被称为关注点分离。
 * 这使你的代码更容易理解，扩展和维护
 */

#import <ReactiveCocoa/ReactiveCocoa/ReactiveCocoa.h>
@import CoreLocation;
@import Foundation;

@interface WXClient : NSObject

- (RACSignal *)fetchJSONFromURL:(NSURL *)url;
- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate;
- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate;
- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate;

@end
