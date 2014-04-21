//
//  WXManager.h
//  SimpleWeather
//
//  Created by Jason on 14-4-13.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

/*
  它使用单例设计模式。
  它试图找到设备的位置。
  找到位置后，它获取相应的气象数据。
 
1. 请注意，你没有引入WXDailyForecast.h，你会始终使用WXCondition作为预报的类。 WXDailyForecast的存在是为了帮助Mantle转换JSON到Objective-C。
2. 使用instancetype而不是WXManager，子类将返回适当的类型。
3. 这些属性将存储您的数据。由于WXManager是一个单例，这些属性可以任意访问。设置公共属性为只读，因为只有管理者能更改这些值。
4. 这个方法启动或刷新整个位置和天气的查找过程。
 */
@import CoreLocation;
#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa/ReactiveCocoa.h>
#import "WXCondition.h"

@interface WXManager : NSObject <CLLocationManagerDelegate>

//2
+ (instancetype)sharedManager;

//3
@property (nonatomic, strong, readonly) CLLocation    *currentLocation;
@property (nonatomic, strong, readonly) WXCondition   *currentCondition;
@property (nonatomic, strong, readonly) NSArray       *hourlyForecast;
@property (nonatomic, strong, readonly) NSArray       *dailyForecast;

//4
- (void)findCurrentLocation;

@end
