//
//  MMBenchMarker.m
//
//
//  Created by Michael Mork on 5/26/16.
//
//

#import "MMBenchMarker.h"
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>

//http://nshipster.com/benchmarking/
//https://developer.apple.com/library/mac/qa/qa1398/_index.html
//http://manpages.ubuntu.com/manpages/xenial/en/man3/dispatch_benchmark.3.html

typedef NS_ENUM(NSInteger, BenchMarkMetrics) {
  BenchMarkMetricsNanoseconds,
  BenchMarkMetricsSeconds,
  BenchMarkMetricsMilliseconds
};

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

@interface MMBenchMarker ()
@property (nonatomic) NSMutableDictionary *dictOfNumberLists;
@property (nonatomic) NSMutableDictionary *intervalsBeingLogged;
@end

@implementation MMBenchMarker

+ (instancetype)shared {
  static MMBenchMarker *sharedClient;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedClient = [[MMBenchMarker alloc] init];
    sharedClient.dictOfNumberLists = [[NSMutableDictionary alloc] init];
    sharedClient.intervalsBeingLogged = [[NSMutableDictionary alloc] init];
  });
  
  return sharedClient;
}

- (void)beginInterval:(NSString *)key noOverWrite:(BOOL)noOverWrite {

  if (noOverWrite) {
    if (self.intervalsBeingLogged[key]) {
      return;
    }
  }
  
  self.intervalsBeingLogged[key] = @(mach_absolute_time());
}

- (BOOL)endInterval:(NSString *)key {
  
  uint64_t        start = mach_absolute_time();

  double duration = 0.0;
  NSNumber *existing = self.intervalsBeingLogged[key];
  if (!existing) {
    return NO;
  } else {
    duration = mach_absolute_time() - [existing unsignedLongValue];
  }
  
  uint64_t        end = mach_absolute_time();
  duration -= (double)(end - start); //subtracting the time it takes to read duration because this is a strive for precision.
  if (duration < 0) {
      [self nullifyInterval:key];
    return NO;
  }
  
  static mach_timebase_info_data_t    sTimebaseInfo;
  if ( sTimebaseInfo.denom == 0 ) {
    (void) mach_timebase_info(&sTimebaseInfo);
  }
  
  [self storeIntervalValue:(duration * sTimebaseInfo.numer / sTimebaseInfo.denom) key:key];
  [self nullifyInterval:key];
  return YES;
}

- (void)beginInterval:(BenchMarkInterval)interval key:(NSString *)key {
  NSAssert(interval, @"benchmark interval must be set");
  NSAssert(key, @"benchmark key must be set");
  [self storeIntervalValue:dispatch_benchmark(1, ^{
    @autoreleasepool {
      interval();
    }}) key:key];
}

- (void)storeIntervalValue:(uint64_t)value key:(NSString *)key {
  
  NSMutableArray *array = [self.dictOfNumberLists[key] mutableCopy];
  if (array) {
    [array addObject:@(value)];
  } else {
    array = [[NSMutableArray alloc] init];
    [array addObject:@(value)];
  }
  self.dictOfNumberLists[key] = [array copy];
}

- (void)nullifyInterval:(NSString *)key {
  self.intervalsBeingLogged[key] = nil;
}

- (void)printAveragesAndDifferencesWithTitles:(NSString *)title
                   expectedGreaterDurationKey:(NSString *)expectedGreaterDuration
                    expectedLesserDurationKey:(NSString *)expectedLesserDurationKey {

  NSArray *initialList = [self.dictOfNumberLists objectForKey:expectedGreaterDuration];
  NSArray *subtractorList = [self.dictOfNumberLists objectForKey:expectedLesserDurationKey];
  
  NSNumber *initialAverage = [self averageOfNumbers:initialList];
  NSNumber *subtractorAverage = [self averageOfNumbers:subtractorList];
  
  
  NSInteger num = (NSInteger)(milliseconds([initialAverage unsignedLongLongValue]) - milliseconds([subtractorAverage unsignedLongLongValue]));
  
  NSInteger dnom = (NSInteger)milliseconds([subtractorAverage unsignedLongLongValue]);
  
  float percent = (float)num/dnom;
  
  NSString *contents = [NSString stringWithFormat:@"===\n %@ :%lld \n --- \n %@:%lld \n --- \n difference: %lld \n --- \n percent faster : %f",
                        expectedGreaterDuration,
                        milliseconds([initialAverage unsignedLongValue]),
                        expectedLesserDurationKey,
                        milliseconds([subtractorAverage unsignedLongValue]),
                        (milliseconds([initialAverage unsignedLongValue]) - milliseconds([subtractorAverage unsignedLongValue])),
                        percent*100];

  NSLog(@"\n\n   ==== \n %@ \n   === \n   ---\n\n %@", title, contents);
}

- (NSNumber *)averageOfNumbers:(NSArray *)numbers {
  uint64_t sum = 0;
  NSInteger count = 0;
  for (NSNumber *number in numbers) {
    sum+= [number unsignedLongValue];
    count++;
  }
  
  return @(sum/count);
}

uint64_t milliseconds(uint64_t nanoseconds) {
  return (nanoseconds / 1000000.0);
}

- (void)reset {
  self.dictOfNumberLists = [NSMutableDictionary dictionary];
}

@end
