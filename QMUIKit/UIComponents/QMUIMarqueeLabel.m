//
//  QMUIMarqueeLabel.m
//  qmui
//
//  Created by MoLice on 2017/5/31.
//  Copyright © 2017年 QMUI Team. All rights reserved.
//

#import "QMUIMarqueeLabel.h"
#import "QMUICore.h"
#import "CALayer+QMUI.h"

@interface QMUIMarqueeLabel ()

@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, assign) CGFloat offsetX;
@property(nonatomic, assign) CGFloat textWidth;

@property(nonatomic, strong) CAGradientLayer *fadeLeftLayer;
@property(nonatomic, strong) CAGradientLayer *fadeRightLayer;
@end

@implementation QMUIMarqueeLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.lineBreakMode = NSLineBreakByClipping;
        self.clipsToBounds = YES;// 显示非英文字符时，滚动的时候字符会稍微露出两端，所以这里直接裁剪掉
        
        self.speed = 1;
        self.pauseDurationWhenMoveToEdge = 1.0;
        self.automaticallyValidateVisibleFrame = YES;
        self.fadeWidth = 20;
        self.fadeStartColor = UIColorMakeWithRGBA(255, 255, 255, 1);
        self.fadeEndColor = UIColorMakeWithRGBA(255, 255, 255, 0);
        self.shouldFadeAtEdge = NO;
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
        self.displayLink.paused = YES;
        
    }
    return self;
}

- (void)dealloc {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) {
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    } else {
        [self.displayLink invalidate];
    }
    self.offsetX = 0;
    self.displayLink.paused = ![self shouldPlayDisplayLink];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    self.offsetX = 0;
    self.textWidth = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].width;
    self.displayLink.paused = ![self shouldPlayDisplayLink];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    self.offsetX = 0;
    self.textWidth = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].width;
    self.displayLink.paused = ![self shouldPlayDisplayLink];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.offsetX = 0;
    self.displayLink.paused = ![self shouldPlayDisplayLink];
}

- (void)drawTextInRect:(CGRect)rect {
    CGRect rectToDrawAfterAnimated = CGRectLimitLeft(rect, self.offsetX);
    [super drawTextInRect:rectToDrawAfterAnimated];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.fadeLeftLayer) {
        self.fadeLeftLayer.frame = CGRectMake(0, 0, self.fadeWidth, CGRectGetHeight(self.bounds));
        [self.layer qmui_bringSublayerToFront:self.fadeLeftLayer];// 显示非英文字符时，UILabel 内部会额外多出一层 layer 盖住了这里的 fadeLayer，所以要手动提到最前面
    }
    if (self.fadeRightLayer) {
        self.fadeRightLayer.frame = CGRectMake(CGRectGetWidth(self.bounds) - self.fadeWidth, 0, self.fadeWidth, CGRectGetHeight(self.bounds));
        [self.layer qmui_bringSublayerToFront:self.fadeRightLayer];// 显示非英文字符时，UILabel 内部会额外多出一层 layer 盖住了这里的 fadeLayer，所以要手动提到最前面
    }
}

- (void)handleDisplayLink:(CADisplayLink *)displayLink {
    if (self.offsetX == 0) {
        displayLink.paused = YES;
        [self setNeedsDisplay];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.pauseDurationWhenMoveToEdge * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            displayLink.paused = ![self shouldPlayDisplayLink];
            if (!displayLink.paused) {
                self.offsetX -= 1.0 * self.speed;
            }
        });
        
        return;
    }
    
    self.offsetX -= 1.0 * self.speed;
    [self setNeedsDisplay];
    
    if (self.offsetX - CGRectGetWidth(self.bounds) < -self.textWidth) {
        displayLink.paused = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.pauseDurationWhenMoveToEdge * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.offsetX = 0;
            [self handleDisplayLink:displayLink];
        });
    }
}

- (BOOL)shouldPlayDisplayLink {
    BOOL result = self.window && CGRectGetWidth(self.bounds) > 0 && self.textWidth > CGRectGetWidth(self.bounds);
    
    // 如果 label.frame 在 window 可视区域之外，也视为不可见，暂停掉 displayLink
    if (result && self.automaticallyValidateVisibleFrame) {
        CGRect rectInWindow = [self.window convertRect:self.frame fromView:self.superview];
        if (!CGRectIntersectsRect(self.window.bounds, rectInWindow)) {
            return NO;
        }
    }
    
    return result;
}

- (void)setOffsetX:(CGFloat)offsetX {
    _offsetX = offsetX;
    [self updateFadeLayersHidden];
}

- (void)setShouldFadeAtEdge:(BOOL)shouldFadeAtEdge {
    _shouldFadeAtEdge = shouldFadeAtEdge;
    if (shouldFadeAtEdge) {
        [self initFadeLayersIfNeeded];
    }
    [self updateFadeLayersHidden];
}

- (void)updateFadeLayersHidden {
    if (!self.fadeLeftLayer || !self.fadeRightLayer) {
        return;
    }
    
    BOOL shouldShowFadeLeftLayer = self.offsetX < 0;
    self.fadeLeftLayer.hidden = !shouldShowFadeLeftLayer;
    
    BOOL shouldShowFadeRightLayer = self.textWidth > CGRectGetWidth(self.bounds) && self.offsetX != self.textWidth - CGRectGetWidth(self.bounds);
    self.fadeRightLayer.hidden = !shouldShowFadeRightLayer;
}

- (void)initFadeLayersIfNeeded {
    if (!self.fadeLeftLayer) {
        self.fadeLeftLayer = [CAGradientLayer layer];// 请保留自带的 hidden 动画
        self.fadeLeftLayer.colors = @[(id)self.fadeStartColor.CGColor,
                                      (id)self.fadeEndColor.CGColor];
        self.fadeLeftLayer.startPoint = CGPointMake(0, .5);
        self.fadeLeftLayer.endPoint = CGPointMake(1, .5);
        [self.layer addSublayer:self.fadeLeftLayer];
        [self setNeedsLayout];
    }
    
    if (!self.fadeRightLayer) {
        self.fadeRightLayer = [CAGradientLayer layer];// 请保留自带的 hidden 动画
        self.fadeRightLayer.colors = @[(id)self.fadeStartColor.CGColor,
                                       (id)self.fadeEndColor.CGColor];
        self.fadeRightLayer.startPoint = CGPointMake(1, .5);
        self.fadeRightLayer.endPoint = CGPointMake(0, .5);
        [self.layer addSublayer:self.fadeRightLayer];
        [self setNeedsLayout];
    }
}

#pragma mark - Superclass

- (void)setNumberOfLines:(NSInteger)numberOfLines {
    numberOfLines = 1;
    [super setNumberOfLines:numberOfLines];
}

@end

@implementation QMUIMarqueeLabel (ReusableView)

- (BOOL)requestToStartAnimation {
    self.automaticallyValidateVisibleFrame = NO;
    BOOL shouldPlayDisplayLink = [self shouldPlayDisplayLink];
    if (shouldPlayDisplayLink) {
        self.displayLink.paused = NO;
    }
    return shouldPlayDisplayLink;
}

- (BOOL)requestToStopAnimation {
    self.displayLink.paused = YES;
    return YES;
}

@end
