//
//  MMBenchMarker.m
//
//
//  Created by Michael Mork on 5/26/16.
//
//

#import "MMBenchMarker.h"

#include <assert.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>

//
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

@implementation WebPBenchMarker

+ (instancetype)shared {
  static WebPBenchMarker *sharedClient;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedClient = [[WebPBenchMarker alloc] init];
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

  uint64_t duration = 0.0;
  NSNumber *existing = self.intervalsBeingLogged[key];
  if (!existing) {
    return NO;
  } else {
    duration = mach_absolute_time() - [existing unsignedLongValue];
  }
  
  uint64_t        end = mach_absolute_time();
  duration -= (end - start); //subtracting the time it takes to read duration because this is a strive for precision.
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
  uint64_t t_0 = dispatch_benchmark(1, ^{
    @autoreleasepool {
      interval();
    }});
  
  [self storeIntervalValue:t_0 key:key];
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

- (void)printAveragesAndDifferencesWithTitles:(NSString *)title initialValueKey:(NSString *)initial subtractorValueKey:(NSString *)subtractor {

  NSArray *initialList = [self.dictOfNumberLists objectForKey:initial];
  NSArray *subtractorList = [self.dictOfNumberLists objectForKey:subtractor];
  
  NSNumber *initialAverage = [self averageOfNumbers:initialList];
  NSNumber *subtractorAverage = [self averageOfNumbers:subtractorList];
  
  
  //x, y
  //average difference
  //sum of differences from average
  uint64_t average = [initialAverage unsignedLongLongValue];
  for (NSNumber *number in initialList) {
    uint64_t ullNumber = [number unsignedLongLongValue];
    
    if (ullNumber > average) {
      uint64_t difference = ullNumber - average;
      average += difference;
    } else {
      uint64_t difference = average - ullNumber;
      average -= difference;
    }
  }
  
  NSLog(@"\n sum of average difference for subtractor:%@", @(milliseconds(average)));
  
  //x, y
  //average difference
  //sum of differences from average
  uint64_t sAverage = [subtractorAverage unsignedLongLongValue]/[initialAverage unsignedLongLongValue];
  for (NSNumber *number in initialList) {
    uint64_t ullNumber = [number unsignedLongLongValue];
    
    if (ullNumber > sAverage) {
      uint64_t difference = ullNumber - sAverage;
      sAverage += difference;
    } else {
      uint64_t difference = sAverage - ullNumber;
      sAverage -= difference;
    }
  }
  
  NSLog(@"initialCount: %i \n subtractorList: %i \n sum of average difference for initial:%@", initialList.count, subtractorList.count, @(milliseconds(sAverage)));
  
  NSInteger num = (NSInteger)(milliseconds([initialAverage unsignedLongLongValue]) - milliseconds([subtractorAverage unsignedLongLongValue]));
  
  NSInteger dnom = (NSInteger)milliseconds([subtractorAverage unsignedLongLongValue]);
  
  float percent = (float) num/dnom;
  
  NSString *contents = [NSString stringWithFormat:@"===\n %@ :%lld \n --- \n %@:%lld \n --- \n difference: %lld \n --- \n percent faster : %f",
                        initial,
                        milliseconds([initialAverage unsignedLongValue]),
                        subtractor,
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
