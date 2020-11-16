//
//  RZWeakTimerTarget.h
//  RZCardSlider
//
//  Created by tingdongli on 2020/11/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RZWeakTimerTarget : NSObject
- (id)initWithTarget:(id)target selector:(SEL)sel;

- (void)timerDidFire:(NSTimer *)timer;
@end

NS_ASSUME_NONNULL_END
