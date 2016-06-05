//
//  MMBenchMarker.h
//
//
//  Created by Michael Mork on 5/26/16.
//
//

#import <Foundation/Foundation.h>
typedef void(^BenchMarkInterval)();
@interface MMBenchMarker : NSObject

+(instancetype)shared;

//Log asynchronous or contextually complex intervals by key.
- (void)beginInterval:(NSString *)key noOverWrite:(BOOL)noOverWrite;

//Log encapsulatable intervals by key.
- (void)beginInterval:(BenchMarkInterval)interval key:(NSString *)key;

//BOOL indicates interval was stored
- (BOOL)endInterval:(NSString *)key;

- (void)nullifyInterval:(NSString *)key;

- (void)printAveragesAndDifferencesWithTitles:(NSString *)title initialValueKey:(NSString *)key subtractorValueKey:(NSString *)subtractor;

- (void)reset;

@end
