//
//  QNCardSlider.m
//  RZCardSlider
//
//  Created by 李庭栋 on 2020/11/8.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "RZCardSlider.h"
#import "RZCardContentView.h"
#import "UIView+RZUtils.h"
#import "RZWeakTimerTarget.h"
#import <objc/runtime.h>

static NSInteger const QNCardContentViewTagPlus = 1000;

@interface RZCardSlider () <UIScrollViewDelegate>
@property(nonatomic, strong) UIScrollView *sliderScrollView;
@property(nonatomic, assign) NSInteger currentIndex;
@property(nonatomic, assign) CGPoint lastContentOffset;
@property(nonatomic, copy) NSArray *scaleConfig;
@property(nonatomic, copy) NSArray<NSValue *> *cardFrameArray;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, copy) NSArray<RZCardContentView *> *cardContainer;

@end

@implementation RZCardSlider

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.sliderScrollView];
    }
    return self;
}

- (NSArray<RZCardContentView *> *)allCards {
    NSInteger cardCount = [self p_realCardCount];
    NSMutableArray<RZCardContentView *> *cards = [NSMutableArray array];
    for (NSInteger i = 0; i < cardCount; i++) {
        [cards addObject:[self p_viewForIndex:i]];
    }
    return [cards copy];
}

- (void)sliderDidEndDisplay {
    [self p_stopTimer];
}

- (void)sliderWillDisplay {
    
    [self layoutUI];
    
    if (self.needAutoScroll && !_timer) {
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    }
}

- (void)layoutUI {
    if (self.sliderDelegate &&
        [self.sliderDelegate respondsToSelector:@selector(sliderCardCount)] &&
        [self.sliderDelegate respondsToSelector:@selector(sliderCardSize)] &&
        [self.sliderDelegate respondsToSelector:@selector(sliderCardViewForIndex:)]) {

        if (self.cardContainer.count == [self p_realCardCount]) {
            return;
        }
        
        self.cardContainer = @[];
        [self p_initScaleConfig];
        [self p_generateFrames];

        NSInteger cardCount = [self.sliderDelegate sliderCardCount];
        NSMutableArray *cardContainer = [NSMutableArray array];
        CGSize originalSize = [self.sliderDelegate sliderCardSize];

        if (cardCount > 1 && self.containsBufferCard) {
            //缓冲卡片,循环播放的时候不需要
            RZCardContentView *bufferCardView = [self.sliderDelegate sliderCardViewForIndex:cardCount + 1];
            [bufferCardView roundCornersOnTopLeft:YES topRight:YES bottomLeft:YES bottomRight:YES radius:6.f];
            bufferCardView.tag = cardCount + 1 + QNCardContentViewTagPlus;
            bufferCardView.frame = CGRectMake(0, 0, originalSize.width, originalSize.height);
            [bufferCardView layoutUIWithIndex:cardCount + 1];
            CGFloat scaleRatio = [[_scaleConfig objectAtIndex:cardCount + 1] floatValue];
            bufferCardView.transform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
            bufferCardView.scaleRatio = scaleRatio;
            
            CGRect cardFrame = [self.cardFrameArray objectAtIndex:cardCount + 1].CGRectValue;
            bufferCardView.frame = CGRectMake(CGRectGetMinX(cardFrame), CGRectGetMaxY(cardFrame) - CGRectGetHeight(cardFrame), CGRectGetWidth(cardFrame), CGRectGetHeight(cardFrame));
            
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_cardSliderDidClick:)];
            [bufferCardView addGestureRecognizer:tapGesture];
            
            [self addSubview:bufferCardView];
            [cardContainer addObject:bufferCardView];
        }
    
        for (NSInteger index = cardCount; index >= 0; index --) {
            RZCardContentView *cardView = [self.sliderDelegate sliderCardViewForIndex:index];
            CGFloat scaleRatio = [[_scaleConfig objectAtIndex:index] floatValue];
            cardView.scaleRatio = scaleRatio;
            cardView.tag = index + QNCardContentViewTagPlus;
            cardView.frame = CGRectMake(0, 0, originalSize.width, originalSize.height);
            [cardView layoutUIWithIndex:index];
            cardView.transform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
            
            CGRect cardFrame = [self.cardFrameArray objectAtIndex:index].CGRectValue;
            cardView.frame = CGRectMake(CGRectGetMinX(cardFrame), CGRectGetMaxY(cardFrame) - CGRectGetHeight(cardFrame), CGRectGetWidth(cardFrame), CGRectGetHeight(cardFrame));
            [cardView roundCornersOnTopLeft:YES topRight:YES bottomLeft:YES bottomRight:YES radius:6.f];
            
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_cardSliderDidClick:)];
            [cardView addGestureRecognizer:tapGesture];
            
            [self addSubview:cardView];
            [cardContainer addObject:cardView];
        }
        self.cardContainer = cardContainer.copy;
        [self bringSubviewToFront:self.sliderScrollView];
    };
}

- (void)p_initScaleConfig {
    NSInteger realCount = [self p_realCardCount];
    NSMutableArray *scaleConfigs = [NSMutableArray array];
    if (self.sliderDelegate &&
        [self.sliderDelegate respondsToSelector:@selector(sliderCardViewScaleAtIndex:)]) {
        for (NSInteger index = 0; index < realCount; index ++) {
            CGFloat scaleConfig = [self.sliderDelegate sliderCardViewScaleAtIndex:index];
            [scaleConfigs addObject:@(scaleConfig)];
        }
        if (realCount > 0) {
            CGFloat scaleConfig = [self.sliderDelegate sliderCardViewScaleAtIndex:1];
            [scaleConfigs addObject:@(scaleConfig)];
        }
    } else {
        //默认是下一张卡片是上一张的0.9倍
        CGFloat initialScale = 1.f;
        for (NSInteger index = 0; index < realCount; index ++) {
            CGFloat scaleConfig = initialScale * powf(0.9, index);
            [scaleConfigs addObject:@(scaleConfig)];
        }
        
        if (realCount > 0) {
            [scaleConfigs addObject:[scaleConfigs objectAtIndex:1]];
        }
    }
    self.scaleConfig = scaleConfigs.copy;
}

- (void)p_generateFrames {
    
    if (self.sliderDelegate &&
        [self.sliderDelegate respondsToSelector:@selector(sliderCardSize)] &&
        [self.sliderDelegate respondsToSelector:@selector(sliderCardCount)]) {
        NSInteger cardCount = [self.sliderDelegate sliderCardCount];
        NSMutableArray<NSValue *> *cardFrames = [NSMutableArray array];
        CGSize originalSize = [self.sliderDelegate sliderCardSize];
        CGFloat leftSpaceInterval = originalSize.width / 2;
        
        for (NSInteger index = 0; index <= cardCount; index ++) {
            CGFloat contentX = index * leftSpaceInterval;
            CGFloat scaleRatio = [[_scaleConfig objectAtIndex:index] floatValue];
            [cardFrames addObject:[NSValue valueWithCGRect:CGRectMake(contentX, [self p_contentYOfCardHeight:originalSize.height * scaleRatio], originalSize.width * scaleRatio, originalSize.height * scaleRatio)]];
        }

        if (cardCount > 1) {
            CGRect secondToLastCardFrame = [cardFrames objectAtIndex:cardCount - 1].CGRectValue;
            CGRect lastCardFrame = [cardFrames lastObject].CGRectValue;
            lastCardFrame.origin.x = CGRectGetMaxX(secondToLastCardFrame) - CGRectGetWidth(lastCardFrame);
            [cardFrames replaceObjectAtIndex:cardCount withObject:[NSValue valueWithCGRect:lastCardFrame]];
            CGFloat scaleRatio = [[_scaleConfig objectAtIndex:cardCount + 1] floatValue];
            [cardFrames addObject:[NSValue valueWithCGRect:CGRectMake(0, [self p_contentYOfCardHeight:originalSize.height * scaleRatio], originalSize.width * scaleRatio, originalSize.height * scaleRatio)]];
        }
        self.cardFrameArray = cardFrames.copy;
    }
}

- (RZCardContentView *)p_viewForIndex:(NSInteger)index {
    if ([self p_realCardCount] > 0) {
        NSInteger realIndex = index % [self p_realCardCount];
        RZCardContentView *currentView = [self viewWithTag:realIndex + QNCardContentViewTagPlus];
        return currentView;
    }
    return nil;
}

- (CGFloat)p_contentYOfCardHeight:(CGFloat)cardHeight {
    if (self.verticalAlignment == kQNCardSliderVerticalAlignmentBottom) {
        return CGRectGetHeight(self.bounds) - cardHeight;
    } else if (self.verticalAlignment == kQNCardSliderVerticalAlignmentCenter) {
        return (CGRectGetHeight(self.bounds) - cardHeight) / 2;
    } else {
        return 0.f;
    }
}

- (NSInteger)p_realCardCount {
    NSInteger cardCount = [self.sliderDelegate sliderCardCount];
    return cardCount + (self.containsBufferCard ? 2 : 1);
}

- (void)p_sliderSelectCardAtIndex:(NSInteger)index cardView:(RZCardContentView *)cardView {
    if ([self.sliderDelegate respondsToSelector:@selector(sliderDidSelectCardAtIndex:firstPositionIndex:cardView:)]) {
        [self.sliderDelegate sliderDidSelectCardAtIndex:index firstPositionIndex:self.currentIndex cardView:cardView];
    }
}

- (void)p_stopTimer {
    if ([_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self p_stopScrollWithScrollView:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self p_stopScrollWithScrollView:scrollView];
    }
}


- (void)p_stopScrollWithScrollView:(UIScrollView *)scrollView {
    if (!_needAutoScroll) {
        [self p_scrollToLeft:scrollView.contentOffset.x > self.lastContentOffset.x];
        self.lastContentOffset = scrollView.contentOffset;
    }
}

- (void)p_scrollToLeft:(BOOL)isLeft {
    NSInteger totalCount = [self p_realCardCount];
    
    if (isLeft) {
        //向左滑动
        if (self.containsBufferCard) {
            UIView *bufferCard = [self p_viewForIndex:self.currentIndex + totalCount - 1];
            [self p_updateTransformWithIndex:totalCount - 2 toView:bufferCard];
        }
        
        [UIView animateWithDuration:0.5f
                              delay:0.f
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            
            for (NSInteger index = 0; index < totalCount; index ++) {
                NSInteger realIndex = self.currentIndex + index;
                RZCardContentView *currentCardView = [self p_viewForIndex:realIndex];
                CGRect endFrame = [self.cardFrameArray objectAtIndex:((index + totalCount) - 1) % totalCount].CGRectValue;
                CGFloat scaleRatio = [[self.scaleConfig objectAtIndex:((index + totalCount) - 1) % totalCount] floatValue];
                
                if (!self.containsBufferCard && index == 0) {
                    endFrame = [self.cardFrameArray objectAtIndex:((index + (totalCount + 1)) - 1) % (totalCount + 1)].CGRectValue;
                    scaleRatio = [[self.scaleConfig objectAtIndex:((index + (totalCount + 1)) - 1) % (totalCount + 1)] floatValue];
                }
                //注意顺序，先缩放，后移动
                currentCardView.transform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
                CGRect currentFrame = currentCardView.frame;
                currentFrame.origin.x = CGRectGetMinX(endFrame);
                currentFrame.origin.y = CGRectGetMaxY(endFrame) - CGRectGetHeight(currentFrame);
                currentCardView.frame = currentFrame;
                
                [currentCardView refreshUI];
                [currentCardView didSlideToIndex:((index + totalCount) - 1) % totalCount];
                if (index == 1) {
                    [self bringSubviewToFront:currentCardView];
                } else if (index > 0){
                    UIView *preCardView = [self p_viewForIndex:realIndex - 1];
                    [self insertSubview:currentCardView belowSubview:preCardView];
                }
            }
            
        } completion:^(BOOL finished) {
            [self bringSubviewToFront:self.sliderScrollView];
            if (!self.containsBufferCard) {
                //如果没有缓存卡片，左滑动画之后，需要将最左边的卡片移动到最右边
                RZCardContentView *currentCardView = [self p_viewForIndex:self.currentIndex];
                [self p_updateTransformWithIndex:((0 + totalCount) - 1) % totalCount toView:currentCardView];
                [currentCardView refreshUI];
                [currentCardView didSlideToIndex:((0 + totalCount) - 1) % totalCount];
            }
            self.currentIndex = (self.currentIndex + 1) % totalCount;
        }];
    } else {
        
        if (!self.containsBufferCard) {
            //如果没有缓存卡片，右滑动画之前需要右边最后一张卡片移动到左边
            RZCardContentView *lastCardView = [self p_viewForIndex:self.currentIndex + totalCount - 1];
            [self p_updateTransformWithIndex:totalCount % (totalCount + 1) toView:lastCardView];
            [lastCardView refreshUI];
            [lastCardView didSlideToIndex:totalCount % (totalCount + 1)];
        }
        
        [UIView animateWithDuration:0.5f
                              delay:0.f
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            for (NSInteger index = totalCount - 1; index >= 0; index --) {
                NSInteger realIndex = self.currentIndex + index;
                RZCardContentView *currentCardView = [self p_viewForIndex:realIndex];
                [self p_updateTransformWithIndex:(index + 1) % totalCount toView:currentCardView];
                [currentCardView refreshUI];
                [currentCardView didSlideToIndex:(index + 1) % totalCount];
                if (index == totalCount - 1) {
                    [self bringSubviewToFront:currentCardView];
                }
            }
        } completion:^(BOOL finished) {
            [self bringSubviewToFront:self.sliderScrollView];
            self.currentIndex = (self.currentIndex - 1 + totalCount) % totalCount;
        }];
    }
}

- (void)p_updateTransformWithIndex:(NSInteger)index toView:(UIView *)cardView{
    CGRect endFrame = [self.cardFrameArray objectAtIndex:index].CGRectValue;
    CGFloat scaleRatio = [[self.scaleConfig objectAtIndex:index] floatValue];
    cardView.transform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
    CGRect currentFrame = cardView.frame;
    currentFrame.origin.x = CGRectGetMaxX(endFrame) - CGRectGetWidth(currentFrame);
    currentFrame.origin.y = CGRectGetMaxY(endFrame) - CGRectGetHeight(currentFrame);
    cardView.frame = currentFrame;
}

- (void)p_cardSliderDidClick:(UITapGestureRecognizer *)sender {
    [self p_sliderSelectCardAtIndex:sender.view.tag - QNCardContentViewTagPlus cardView:(RZCardContentView *)sender.view];
}

- (void)autoScroll {
    [self p_scrollToLeft:NO];
}

#pragma mark lazy load
- (UIScrollView *)sliderScrollView {
    if (!_sliderScrollView) {
        _sliderScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _sliderScrollView.showsVerticalScrollIndicator = NO;
        _sliderScrollView.showsHorizontalScrollIndicator = NO;
        _sliderScrollView.bounces = NO;
        _sliderScrollView.delegate = self;
        _sliderScrollView.contentSize = CGSizeMake(CGFLOAT_MAX, CGRectGetHeight(self.bounds));
    }
    return _sliderScrollView;
}

- (NSTimer *)timer {
    if (!_timer) {
        RZWeakTimerTarget *weakTimerTarget = [[RZWeakTimerTarget alloc] initWithTarget:self selector:@selector(autoScroll)];
        _timer = [NSTimer timerWithTimeInterval:3.f target:weakTimerTarget selector:@selector(timerDidFire:) userInfo:nil repeats:YES];
    }
    return _timer;
}

@end
