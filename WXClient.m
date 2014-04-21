//
//  WXClient.m
//  SimpleWeather
//
//  Created by Jason on 14-4-13.
//  Copyright (c) 2014年 Jason. All rights reserved.
//

#import "WXClient.h"
#import "WXCondition.h"
#import "WXDailyForecast.h"

@interface WXClient ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation WXClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (RACSignal *)fetchJSONFromURL:(NSURL *)url {
    NSLog(@"Fetching: %@", url.absoluteString);
    /*
     1. 返回信号。请记住，这将不会执行，直到这个信号被订阅。 - fetchJSONFromURL：创建一个对象给其他方法和对象使用；这种行为有时也被称为工厂模式。
     2. 创建一个NSURLSessionDataTask（在iOS7中加入）从URL取数据。你会在以后添加的数据解析。
     3. 一旦订阅了信号，启动网络请求。
     4. 创建并返回RACDisposable对象，它处理当信号摧毁时的清理工作。
     5. 增加了一个“side effect”，以记录发生的任何错误。side effect不订阅信号，相反，他们返回被连接到方法链的信号。你只需添加一个side effect来记录错误。
     */
    /*==================================================================================*/
    /*
     t1: 当JSON数据存在并且没有错误，发送给订阅者序列化后的JSON数组或字典。
     t2: 在任一情况下如果有一个错误，通知订阅者。
     t3: 无论该请求成功还是失败，通知订阅者请求已经完成
     */
    
    //1
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        //2
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // TODO: Handle retrieved data
            if (!error) {
                NSError *jsonError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                if (!jsonError) {
                    // t:1
                    [subscriber sendNext:json];
                } else {
                    // t:2
                    [subscriber sendError:jsonError];
                }
            } else {
                // T:2
                [subscriber sendError:error];
            }
            
            // t:3
            [subscriber sendCompleted];
        }];
        
        //3
        [dataTask resume];
        
        //4
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }] doError:^(NSError *error) {
        //5
        NSLog(@"%@", error);
    }];
}

- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate {
    /*
     1. 使用CLLocationCoordinate2D对象的经纬度数据来格式化URL。
     2. 用你刚刚建立的创建信号的方法。由于返回值是一个信号，你可以调用其他ReactiveCocoa的方法。 在这里，您将返回值映射到一个不同的值 – 一个NSDictionary实例。
     3. 使用MTLJSONAdapter来转换JSON到WXCondition对象 – 使用MTLJSONSerializing协议创建的WXCondition。
     */
    // 1
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&units=imperial", coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    // 2
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // 3
        return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:json error:nil];
    }];
}

- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    /*
     1. 再次使用-fetchJSONFromUR方法，映射JSON。注意：重复使用该方法节省了多少代码！
     2. 使用JSON的”list”key创建RACSequence。 RACSequences让你对列表进行ReactiveCocoa操作。
     3. 映射新的对象列表。调用-map：方法，针对列表中的每个对象，返回新对象的列表。
     4. 再次使用MTLJSONAdapter来转换JSON到WXCondition对象。
     5. 使用RACSequence的-map方法，返回另一个RACSequence，所以用这个简便的方法来获得一个NSArray数据
     */
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%f&lon=%f&units=imperial&cnt=12",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    // 1
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // 2
        RACSequence *list = [json[@"list"] rac_sequence];
        
        // 3
        return [[list map:^(NSDictionary *item) {
            // 4
            return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:item error:nil];
            // 5
        }] array];
    }];
}

- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?lat=%f&lon=%f&units=imperial&cnt=7",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Use the generic fetch method and map results to convert into an array of Mantle objects
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // Build a sequence from the list of raw JSON
        RACSequence *list = [json[@"list"] rac_sequence];
        
        // Use a function to map results from JSON to Mantle objects
        return [[list map:^(NSDictionary *item) {
            return [MTLJSONAdapter modelOfClass:[WXDailyForecast class] fromJSONDictionary:item error:nil];
        }] array];
    }];
}
@end
