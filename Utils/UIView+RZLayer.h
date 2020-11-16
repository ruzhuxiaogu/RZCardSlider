//
//  UIView+RZLayer.h
//  RZCardSlider
//
//  Created by tingdongli on 2020/11/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (RZLayer)
/**
为UIView增加圆角

@param tl 左上角
@param tr 右上角
@param bl 左下角
@param br 右下角
@param radius 圆角的值

*/
- (void)roundCornersOnTopLeft:(BOOL)tl
                     topRight:(BOOL)tr
                   bottomLeft:(BOOL)bl
                  bottomRight:(BOOL)br
                       radius:(float)radius;

- (void)clearCorners;

- (void)setGradientLayer:(UIColor *)startColor endColor:(UIColor *)endColor;
@end

NS_ASSUME_NONNULL_END
