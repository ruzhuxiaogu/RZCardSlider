//
//  QNCardContentView.h
//  RZCardSlider
//
//  Created by 李庭栋 on 2020/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QNCardContentView : UIView

@property(nonatomic, assign) CGFloat scaleRatio;

- (void)updateWithDate:(NSDate *)date;
- (void)layoutUIWithIndex:(NSInteger)index;
- (void)refreshUI;
- (void)didSlideToIndex:(NSInteger)index;
@end

NS_ASSUME_NONNULL_END
