//
//  WMRESideMenu.m
//  WMRESideMenu
//
//  Created by cheyipai.com on 2017/3/31.
//  Copyright © 2017年 kong. All rights reserved.
//

#import "WMRESideMenu.h"
#import "UIViewController+RESideMenu.h"
#import "RECommonFunctions.h"
@interface WMRESideMenu ()

@end

@implementation WMRESideMenu

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (void)panGestureRecognized:(UIPanGestureRecognizer *)recognizer
{
    if (self.mainViewAnimation) {
        [super panGestureRecognized:recognizer];
        return;
    }
    if ([self.delegate conformsToProtocol:@protocol(RESideMenuDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:didRecognizePanGesture:)])
        [self.delegate sideMenu:self didRecognizePanGesture:recognizer];
    
    if (!self.panGestureEnabled) {
        return;
    }
    CGPoint point = [recognizer translationInView:self.view];
    CGFloat absX = fabs(point.x);
    CGFloat absY = fabs(point.y);
    CGFloat endX = (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? self.contentViewInLandscapeOffsetCenterX + CGRectGetHeight(self.view.frame) : self.contentViewInPortraitOffsetCenterX + CGRectGetWidth(self.view.frame));
    
    if ( self.contentViewContainer.center.x ==endX&&(absX > absY)&&[recognizer translationInView:self.view].x>0) {
        return;
    }else if (([UIScreen mainScreen].bounds.size.width - endX) == self.contentViewContainer.center.x&&(absX > absY)&&[recognizer translationInView:self.view].x<0){
        return;
    }
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self updateContentViewShadow];
        self.originalPoint = CGPointMake(self.contentViewContainer.center.x - CGRectGetWidth(self.contentViewContainer.bounds) / 2.0,
                                         self.contentViewContainer.center.y - CGRectGetHeight(self.contentViewContainer.bounds) / 2.0);
        self.menuViewContainer.transform = CGAffineTransformIdentity;
        if (self.scaleBackgroundImageView) {
            self.backgroundImageView.transform = CGAffineTransformIdentity;
            self.backgroundImageView.frame = self.view.bounds;
        }
        self.menuViewContainer.frame = self.view.bounds;
        [self addContentButton];
        [self.view.window endEditing:YES];
        self.didNotifyDelegate = NO;
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat delta = 0;
        if (self.visible) {
            delta = self.originalPoint.x != 0 ? (point.x + self.originalPoint.x) / self.originalPoint.x : 0;
        } else {
            delta = point.x / self.view.frame.size.width;
        }
        delta = MIN(fabs(delta), 1.6);
        CGFloat contentViewScale = self.scaleContentView ? 1 - ((1 - self.contentViewScaleValue) * delta) : 1;
        CGFloat backgroundViewScale = 1.7f - (0.7f * delta);
        CGFloat menuViewScale = 1.5f - (0.5f * delta);
        
        if (!self.bouncesHorizontally) {
            contentViewScale = MAX(contentViewScale, self.contentViewScaleValue);
            backgroundViewScale = MAX(backgroundViewScale, 1.0);
            menuViewScale = MAX(menuViewScale, 1.0);
        }
        
        self.menuViewContainer.alpha = !self.fadeMenuView ?: delta;
        
        if (self.scaleBackgroundImageView) {
            self.backgroundImageView.transform = CGAffineTransformMakeScale(backgroundViewScale, backgroundViewScale);
        }
        
        if (self.scaleBackgroundImageView) {
            if (backgroundViewScale < 1) {
                self.backgroundImageView.transform = CGAffineTransformIdentity;
            }
        }
        
        if (!self.bouncesHorizontally && self.visible) {
            if (self.contentViewContainer.frame.origin.x > self.contentViewContainer.frame.size.width / 2.0)
                point.x = MIN(0.0, point.x);
            
            if (self.contentViewContainer.frame.origin.x < -(self.contentViewContainer.frame.size.width / 2.0))
                point.x = MAX(0.0, point.x);
        }
        
        // Limit size
        //
        if (point.x < 0) {
            point.x = MAX(point.x, -[UIScreen mainScreen].bounds.size.height);
        } else {
            point.x = MIN(point.x, [UIScreen mainScreen].bounds.size.height);
        }
        [recognizer setTranslation:point inView:self.view];
        
        if (!self.didNotifyDelegate) {
            if (point.x > 0) {
                if (!self.visible && [self.delegate conformsToProtocol:@protocol(RESideMenuDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:willShowMenuViewController:)]) {
                    [self.delegate sideMenu:self willShowMenuViewController:self.leftMenuViewController];
                }
            }
            if (point.x < 0) {
                if (!self.visible && [self.delegate conformsToProtocol:@protocol(RESideMenuDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:willShowMenuViewController:)]) {
                    [self.delegate sideMenu:self willShowMenuViewController:self.rightMenuViewController];
                }
            }
            self.didNotifyDelegate = YES;
        }
        
        
        
        self.contentViewContainer.transform = CGAffineTransformMakeScale(1, 1);
        
        CGFloat endX = (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? self.contentViewInLandscapeOffsetCenterX + CGRectGetHeight(self.view.frame) : self.contentViewInPortraitOffsetCenterX + CGRectGetWidth(self.view.frame));
        if (([UIScreen mainScreen].bounds.size.width/2.0 + point.x) >=endX||([UIScreen mainScreen].bounds.size.width/2.0 - endX)>=point.x) {
            if (([UIScreen mainScreen].bounds.size.width/2.0 + point.x) >=endX) {
                self.contentViewContainer.center = CGPointMake(endX, self.contentViewContainer.center.y);
            }else {
                self.contentViewContainer.center = CGPointMake((UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? -self.contentViewInLandscapeOffsetCenterX : -self.contentViewInPortraitOffsetCenterX), self.contentViewContainer.center.y);
            }
            
            if ([recognizer velocityInView:self.view].x > 0) {
                if (self.contentViewContainer.frame.origin.x < 0) {
                    [self hideMenuViewController];
                } else {
                    if (self.leftMenuViewController) {
                        [self showLeftMenuViewController];
                    }
                }
            } else {
                if (self.contentViewContainer.frame.origin.x < 20) {
                    if (self.rightMenuViewController) {
                        [self showRightMenuViewController];
                    }
                } else {
                    [self hideMenuViewController];
                }
            }
        }else {
            
            NSLog(@"haha");
            CGFloat orignCenter = self.originalPoint.x +[UIScreen mainScreen].bounds.size.width/2.0;
            if (orignCenter == endX ) {
                self.contentViewContainer.center = CGPointMake(endX + point.x, self.contentViewContainer.center.y);
                
            }else if (orignCenter == ([UIScreen mainScreen].bounds.size.width -endX)){
                
                self.contentViewContainer.center = CGPointMake(([UIScreen mainScreen].bounds.size.width -endX) + point.x, self.contentViewContainer.center.y);
                
            }else {
                self.contentViewContainer.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2.0 + point.x, self.contentViewContainer.center.y);
                
            }
            
        }
        
        
        
        self.leftMenuViewController.view.hidden = self.contentViewContainer.frame.origin.x < 0;
        self.rightMenuViewController.view.hidden = self.contentViewContainer.frame.origin.x > 0;
        
        if (!self.leftMenuViewController && self.contentViewContainer.frame.origin.x > 0) {
            self.contentViewContainer.transform = CGAffineTransformIdentity;
            self.contentViewContainer.frame = self.view.bounds;
            self.visible = NO;
            self.leftMenuVisible = NO;
        } else  if (!self.rightMenuViewController && self.contentViewContainer.frame.origin.x < 0) {
            self.contentViewContainer.transform = CGAffineTransformIdentity;
            self.contentViewContainer.frame = self.view.bounds;
            self.visible = NO;
            self.rightMenuVisible = NO;
        }
        
        [self statusBarNeedsAppearanceUpdate];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.didNotifyDelegate = NO;
        if (self.panMinimumOpenThreshold > 0 && (
                                                 (self.contentViewContainer.frame.origin.x < 0 && self.contentViewContainer.frame.origin.x > -((NSInteger)self.panMinimumOpenThreshold)) ||
                                                 (self.contentViewContainer.frame.origin.x > 0 && self.contentViewContainer.frame.origin.x < self.panMinimumOpenThreshold))
            ) {
            [self hideMenuViewController];
        }
        else if (self.contentViewContainer.frame.origin.x == 0) {
            [self hideMenuViewControllerAnimated:NO];
        }
        else {
            if ([recognizer velocityInView:self.view].x > 0) {
                if (self.contentViewContainer.frame.origin.x < 0) {
                    [self hideMenuViewController];
                } else {
                    if (self.leftMenuViewController) {
                        [self showLeftMenuViewController];
                    }
                }
            } else {
                if (self.contentViewContainer.frame.origin.x < 20) {
                    if (self.rightMenuViewController) {
                        [self showRightMenuViewController];
                    }
                } else {
                    [self hideMenuViewController];
                }
            }
        }
    }
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.visible) {
        self.menuViewContainer.bounds = self.view.bounds;
        self.contentViewContainer.transform = CGAffineTransformIdentity;
        self.contentViewContainer.frame = self.view.bounds;
        
        if (self.scaleContentView) {
            if (self.mainViewAnimation) {
                self.contentViewContainer.transform = CGAffineTransformMakeScale(self.contentViewScaleValue, self.contentViewScaleValue);
            }
        } else {
            self.contentViewContainer.transform = CGAffineTransformIdentity;
        }
        
        CGPoint center;
        if (self.leftMenuVisible) {
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
                center = CGPointMake((UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? self.contentViewInLandscapeOffsetCenterX + CGRectGetWidth(self.view.frame) : self.contentViewInPortraitOffsetCenterX + CGRectGetWidth(self.view.frame)), self.contentViewContainer.center.y);
            } else {
                center = CGPointMake((UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? self.contentViewInLandscapeOffsetCenterX + CGRectGetHeight(self.view.frame) : self.contentViewInPortraitOffsetCenterX + CGRectGetWidth(self.view.frame)), self.contentViewContainer.center.y);
            }
        } else {
            center = CGPointMake((UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? -self.contentViewInLandscapeOffsetCenterX : -self.contentViewInPortraitOffsetCenterX), self.contentViewContainer.center.y);
        }
        
        self.contentViewContainer.center = center;
    }
    
    [self updateContentViewShadow];
}
- (void)showLeftMenuViewController
{
    if (!self.leftMenuViewController) {
        return;
    }
    [self.leftMenuViewController beginAppearanceTransition:YES animated:YES];
    self.leftMenuViewController.view.hidden = NO;
    self.rightMenuViewController.view.hidden = YES;
    [self.view.window endEditing:YES];
    [self addContentButton];
    [self updateContentViewShadow];
    [self resetContentViewScale];
    
    [UIView animateWithDuration:self.animationDuration animations:^{
        if (self.scaleContentView) {
            //            self.contentViewContainer.transform = CGAffineTransformMakeScale(self.contentViewScaleValue, self.contentViewScaleValue);
        } else {
            self.contentViewContainer.transform = CGAffineTransformIdentity;
        }
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            self.contentViewContainer.center = CGPointMake((UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? self.contentViewInLandscapeOffsetCenterX + CGRectGetWidth(self.view.frame) : self.contentViewInPortraitOffsetCenterX + CGRectGetWidth(self.view.frame)), self.contentViewContainer.center.y);
        } else {
            self.contentViewContainer.center = CGPointMake((UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? self.contentViewInLandscapeOffsetCenterX + CGRectGetHeight(self.view.frame) : self.contentViewInPortraitOffsetCenterX + CGRectGetWidth(self.view.frame)), self.contentViewContainer.center.y);
        }
        
        self.menuViewContainer.alpha = !self.fadeMenuView ?: 1.0f;
        self.menuViewContainer.transform = CGAffineTransformIdentity;
        if (self.scaleBackgroundImageView)
            self.backgroundImageView.transform = CGAffineTransformIdentity;
        
    } completion:^(BOOL finished) {
        [self addContentViewControllerMotionEffects];
        [self.leftMenuViewController endAppearanceTransition];
        
        if (!self.visible && [self.delegate conformsToProtocol:@protocol(RESideMenuDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:didShowMenuViewController:)]) {
            [self.delegate sideMenu:self didShowMenuViewController:self.leftMenuViewController];
        }
        
        self.visible = YES;
        self.leftMenuVisible = YES;
    }];
    
    [self statusBarNeedsAppearanceUpdate];
}

- (void)showRightMenuViewController
{
    if (!self.rightMenuViewController) {
        return;
    }
    [self.rightMenuViewController beginAppearanceTransition:YES animated:YES];
    self.leftMenuViewController.view.hidden = YES;
    self.rightMenuViewController.view.hidden = NO;
    [self.view.window endEditing:YES];
    [self addContentButton];
    [self updateContentViewShadow];
    [self resetContentViewScale];
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView animateWithDuration:self.animationDuration animations:^{
        if (self.scaleContentView) {
            //            self.contentViewContainer.transform = CGAffineTransformMakeScale(self.contentViewScaleValue, self.contentViewScaleValue);
        } else {
            self.contentViewContainer.transform = CGAffineTransformIdentity;
        }
        self.contentViewContainer.center = CGPointMake((UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? -self.contentViewInLandscapeOffsetCenterX : -self.contentViewInPortraitOffsetCenterX), self.contentViewContainer.center.y);
        
        self.menuViewContainer.alpha = !self.fadeMenuView ?: 1.0f;
        self.menuViewContainer.transform = CGAffineTransformIdentity;
        if (self.scaleBackgroundImageView)
            self.backgroundImageView.transform = CGAffineTransformIdentity;
        
    } completion:^(BOOL finished) {
        [self.rightMenuViewController endAppearanceTransition];
        if (!self.rightMenuVisible && [self.delegate conformsToProtocol:@protocol(RESideMenuDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:didShowMenuViewController:)]) {
            [self.delegate sideMenu:self didShowMenuViewController:self.rightMenuViewController];
        }
        
        self.visible = !(self.contentViewContainer.frame.size.width == self.view.bounds.size.width && self.contentViewContainer.frame.size.height == self.view.bounds.size.height && self.contentViewContainer.frame.origin.x == 0 && self.contentViewContainer.frame.origin.y == 0);
        self.rightMenuVisible = self.visible;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        [self addContentViewControllerMotionEffects];
    }];
    
    [self statusBarNeedsAppearanceUpdate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
