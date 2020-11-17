//
//  RZViewController.m
//  RZCardSlider
//
//  Created by ruzhuxiaogu on 11/16/2020.
//  Copyright (c) 2020 ruzhuxiaogu. All rights reserved.
//

#import "RZViewController.h"
#import "RZCardSlider.h"
#import "RZCardContentView.h"

@interface RZViewController () <QNCardSliderDelegate>
@property(nonatomic, strong) RZCardSlider *cardSlider;
@end

@implementation RZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.cardSlider];
    [self.cardSlider sliderWillDisplay];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

///可见的卡片数量
- (NSInteger)sliderCardCount {
    return 3;
}
///每个卡片对应的视图
- (RZCardContentView *)sliderCardViewForIndex:(NSInteger)cardIndex {
    RZCardContentView *contentView = [[RZCardContentView alloc] init];
    if (cardIndex == 0) {
        contentView.backgroundColor = [UIColor redColor];
    } else if (cardIndex == 1) {
        contentView.backgroundColor = [UIColor orangeColor];
    } else if (cardIndex == 2){
        contentView.backgroundColor = [UIColor systemPinkColor];
    } else if (cardIndex == 3) {
        contentView.backgroundColor = [UIColor greenColor];
    }
    return contentView;
}
///每个卡片的大小
- (CGSize)sliderCardSize {
    return CGSizeMake((CGRectGetWidth([UIScreen mainScreen].bounds) - 30) / 1.81f, 112);
}

#pragma mark lazy load
- (RZCardSlider *)cardSlider {
    if (!_cardSlider) {
        _cardSlider = [[RZCardSlider alloc] initWithFrame:CGRectMake(0, 100, CGRectGetWidth([UIScreen mainScreen].bounds), 112)];
        _cardSlider.sliderDelegate = self;
//        _cardSlider.needAutoScroll = YES;
    }
    return _cardSlider;
}

@end
