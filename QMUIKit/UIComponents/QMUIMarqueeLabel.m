//
//  QMUIMarqueeLabel.m
//  qmui
//
//  Created by MoLice on 2017/5/31.
//  Copyright © 2017年 QMUI Team. All rights reserved.
//

#import "QMUIMarqueeLabel.h"
#import "QMUICore.h"

@interface QMUIMarqueeLabel ()

@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, assign) CGFloat offsetX;
@property(nonatomic, assign) CGFloat textWidth;
@end

@implementation QMUIMarqueeLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.pauseDurationWhenMoveToEdge = 1.0;
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
        self.displayLink.paused = YES;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    return self;
}

- (void)dealloc {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
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

- (void)handleDisplayLink:(CADisplayLink *)displayLink {
    self.offsetX--;
    [self setNeedsDisplay];
    
    if (self.offsetX - CGRectGetWidth(self.bounds) < -self.textWidth) {
        displayLink.paused = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.pauseDurationWhenMoveToEdge * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.offsetX = 0;
            [self setNeedsDisplay];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.pauseDurationWhenMoveToEdge * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                displayLink.paused = ![self shouldPlayDisplayLink];
            });
        });
    }
}

- (BOOL)shouldPlayDisplayLink {
    BOOL result = self.window && CGRectGetWidth(self.bounds) > 0 && self.textWidth > CGRectGetWidth(self.bounds);
    return result;
}

#pragma mark - Superclass

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    textAlignment = NSTextAlignmentLeft;
    [super setTextAlignment:textAlignment];
}

- (void)setNumberOfLines:(NSInteger)numberOfLines {
    numberOfLines = 1;
    [super setNumberOfLines:numberOfLines];
}

@end
