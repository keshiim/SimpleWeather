//
//  WXManager.m
//  SimpleWeather
//
//  Created by Jason on 14-4-13.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

#import "WXManager.h"
#import "WXClient.h"
#import <TSMessages/TSMessage.h>

@interface WXManager ()

/*
 1. 声明你在公共接口中添加的相同的属性，但是这一次把他们定义为可读写，因此您可以在后台更改他们。
 2. 为查找定位和数据抓取声明一些私有变量。
 */
//1
@property (nonatomic, strong, readwrite) CLLocation    *currentLocation;
@property (nonatomic, strong, readwrite) WXCondition   *currentCondition;
@property (nonatomic, strong, readwrite) NSArray       *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray       *dailyForecast;
// 2
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) WXClient *client;
@end

@implementation WXManager

+ (instancetype)sharedManager {
    static id _shareManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareManager = [[self alloc] init];
    });
    
    return _shareManager;
}

#pragma mark - init
- (instancetype)init
{
    self = [super init];
    if (self) {
        /*
         1. 创建一个位置管理器，并设置它的delegate为self。
         2. 为管理器创建WXClient对象。这里处理所有的网络请求和数据分析，这是关注点分离的最佳实践。
         3. 管理器使用一个返回信号的ReactiveCocoa脚本来观察自身的currentLocation。这与KVO类似，但更为强大。
         4. 为了继续执行方法链，currentLocation必须不为nil。
         5. - flattenMap：非常类似于-map：，但不是映射每一个值，它把数据变得扁平，并返回包含三个信号中的一个对象。通过这种方式，你可以考虑将三个进程作为单个工作单元。
         6. 将信号传递给主线程上的观察者。
         7. 这不是很好的做法，在你的模型中进行UI交互，但出于演示的目的，每当发生错误时，会显示一个banner。
         */
        
        // 1
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        // 2
        _client = [[WXClient alloc] init];
        
        // 3
        [[[[RACObserve(self, currentLocation)
            // 4
            ignore:nil]
           // 5
           // Flatten and subscribe to all 3 signals when currentLocation updates
           flattenMap:^RACStream *(CLLocation *newLocation) {
               return [RACSignal merge:@[
                                         [self updateCurrentConditions],
                                         [self updateDailyForecast],
                                         [self updateHourlyForecast]
                                         ]];
               // 6
           }] deliverOn:RACScheduler.mainThreadScheduler]
         // 7
         subscribeError:^(NSError *error) {
             [TSMessage showNotificationWithTitle:@"Error"
                                         subtitle:@"There was a problem fetching the latest weather."
                                             type:TSMessageNotificationTypeError];
         }];
    }
    return self;
}

#pragma mark - CLLocationManagerDelegate
- (void)findCurrentLocation {
    self.isFirstUpdate = YES;
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    /*
     1. 忽略第一个位置更新，因为它一般是缓存值。
     2. 一旦你获得一定精度的位置，停止进一步的更新。
     3. 设置currentLocation，将触发您之前在init中设置的RACObservable
     */
    
    // 1
    if (self.isFirstUpdate) {
        self.isFirstUpdate = NO;
        return;
    }
    
    CLLocation *location = [locations lastObject];
    
    // 2
    if (location.horizontalAccuracy > 0) {
        // 3
        self.currentLocation = location;
        [self.locationManager stopUpdatingLocation];
    }
}

#pragma mark - 捆绑RACObservable
//添加在客户端上调用并保存数据的三个获取方法。
//将三个方法捆绑起来，被之前在init方法中添加的RACObservable订阅。
//您将返回客户端返回的，能被订阅的，相同的信号
- (RACSignal *)updateCurrentConditions {
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(WXCondition *condition) {
        self.currentCondition = condition;
    }];
}

- (RACSignal *)updateHourlyForecast {
    return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.hourlyForecast = conditions;
    }];
}

- (RACSignal *)updateDailyForecast {
    return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}

@end
