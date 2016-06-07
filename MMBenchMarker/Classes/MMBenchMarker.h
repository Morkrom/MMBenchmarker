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

/**
 Log asynchronous or contextually complex intervals by key.
 @param key - Key for recording interval.
 @param noOverWrite - Avoid over writing if there is an existing interval for this key which has not been terminated.
 @see endInterval: - End recording interval for the respective key.
*/

- (void)beginInterval:(NSString *)key noOverWrite:(BOOL)noOverWrite;

/**
 End a recording interval
 @return bool
 @param key - Key for recording interval.
 @see beginInterval:noOverWrite: - You can't end an interval you didn't start.
 */

- (BOOL)endInterval:(NSString *)key;

/**
  Disregard a recording interval for a given key.
  @param key - Key for recording interval.
 */

- (void)nullifyInterval:(NSString *)key;

/**
 Record a benchmark interval in closure format.
 @param BenchMarkInterval - Do work you wish to record in this block.
 @param key - Key for recording interval.
 */
- (void)beginInterval:(BenchMarkInterval)interval key:(NSString *)key;

/**
 Print the difference of the averages of accumulated number lists by key.
 @param title - the title to be logged.
 @param initialValueKey - the title who's duration i
 */
- (void)printAveragesAndDifferencesWithTitles:(NSString *)title
                   expectedGreaterDurationKey:(NSString *)expectedGreaterDuration
                    expectedLesserDurationKey:(NSString *)expectedLesserDurationKey;

/**
 Clear cache of existing interval data.
 */
- (void)reset;

@end
