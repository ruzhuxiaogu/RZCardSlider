//
//  RZWeakTimerTarget.m
//  RZCardSlider
//
//  Created by tingdongli on 2020/11/16.
//

#import "RZWeakTimerTarget.h"

@implementation RZWeakTimerTarget
{
    id __weak _target;
    SEL _selector;
}

- (id)initWithTarget:(id)target selector:(SEL)sel {
    if (self) {
        _target = target;
        _selector = sel;
    }

    return self;
}

- (void)timerDidFire:(NSTimer *)timer
{
    if(_target && [_target respondsToSelector:_selector])
    {
        [_target performSelector:_selector withObject:timer];
    }
    else
    {
        [timer invalidate];
    }
}

@end
