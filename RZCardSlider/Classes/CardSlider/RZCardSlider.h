//
//  QNCardSlider.h
//  RZCardSlider
//
//  Created by 李庭栋 on 2020/11/8.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class RZCardContentView;
@protocol QNCardSliderDelegate <NSObject>

///可见的卡片数量
- (NSInteger)sliderCardCount;
///每个卡片对应的视图
- (RZCardContentView *)sliderCardViewForIndex:(NSInteger)cardIndex;
///每个卡片的大小
- (CGSize)sliderCardSize;

@optional
///点击了某个卡片
- (void)sliderDidSelectCardAtIndex:(NSInteger)index firstPositionIndex:(NSInteger)firstPositionIndex cardView:(RZCardContentView *)cardView;
///每个卡片的缩放程度
- (CGFloat)sliderCardViewScaleAtIndex:(NSInteger)index;

@end

typedef NS_ENUM(NSUInteger, QNCardSliderVerticalAlignment) {
    kQNCardSliderVerticalAlignmentBottom,
    kQNCardSliderVerticalAlignmentCenter,
    kQNCardSliderVerticalAlignmentTop,
};

@interface RZCardSlider : UIView
@property(nonatomic, weak) id<QNCardSliderDelegate> sliderDelegate;

//是否包含buffer card,buffer card为一张缓冲card
@property(nonatomic, assign) BOOL containsBufferCard;
@property(nonatomic, assign) BOOL needAutoScroll;
@property(nonatomic, assign) QNCardSliderVerticalAlignment verticalAlignment;

/// 当前展示的所有card
- (NSArray<RZCardContentView *> *)allCards;

/// slider结束展示
- (void)sliderDidEndDisplay;

/// slider开始展示
- (void)sliderWillDisplay;


@end

NS_ASSUME_NONNULL_END
