// Copyright 2017 Sergey Zolotarev
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
// following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
// disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
//    following disclaimer in the documentation and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote
//    products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
// USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "SwipeTableViewCell.h"

@interface SwipeTableViewRowAction ()

@property (nonatomic) UIView *view;

@end

@implementation SwipeTableViewRowAction

@end

@interface SwipeTableViewCell ()

@property (nonatomic) UIView *swipeActionContainerView;
@property (nonatomic) UISwipeGestureRecognizer *leftSwipeGestureRecognizer;
@property (nonatomic) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) BOOL didPresentLeftActions;
@property (nonatomic) BOOL didPresentRightActions;
@property (nonatomic, getter=isDismissigActions) BOOL dismissingActions;

@end

@implementation SwipeTableViewCell

+ (UIView *)viewForAction:(SwipeTableViewRowAction *)action {
    UIImageView *view = [[UIImageView alloc] init];
    view.contentMode = UIViewContentModeScaleToFill;
    view.image = action.image;
    view.userInteractionEnabled = YES;
    return view;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.swipeAnimationDuration = 0.30;

    self.backgroundView = [[UIView alloc] init];

    self.swipeActionContainerView = [[UIView alloc] initWithFrame:self.bounds];
    self.swipeActionContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:self.swipeActionContainerView aboveSubview:self.backgroundView];
    
    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(handleRightCellSwipe:)];
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.rightSwipeGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.rightSwipeGestureRecognizer];
    
    self.leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(handleLeftCellSwipe:)];
    self.leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    self.leftSwipeGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.leftSwipeGestureRecognizer];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                 initWithTarget:self action:@selector(handleCellTap:)];
    self.tapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self dismissActionsAnimated:NO];
}

- (BOOL)canPresentSwipeActions {
    return ![self.delegate respondsToSelector:@selector(cellCanSwipe:)] || [self.delegate cellCanSwipe:self];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.dismissingActions || self.highlighted || self.selected) {
        return NO;
    }
    if (gestureRecognizer == self.tapGestureRecognizer) {
        return self.didPresentLeftActions || self.didPresentRightActions;
    }
    if (gestureRecognizer == self.leftSwipeGestureRecognizer) {
        return [self canPresentSwipeActions] && !self.didPresentLeftActions;
    }
    if (gestureRecognizer == self.rightSwipeGestureRecognizer) {
        return [self canPresentSwipeActions] && !self.didPresentRightActions;
    }
    return YES;
}

- (void)handleRightCellSwipe:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (self.didPresentRightActions) {
        [self dismissActionsAnimated:YES];
    } else {
        [self presentLeftActionsAnimated:YES];
    }
}

- (void)handleLeftCellSwipe:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (self.didPresentLeftActions) {
        [self dismissActionsAnimated:YES];
    } else {
        [self presentRightActionsAnimated:YES];
    }
}

- (void)handleCellTap:(UITapGestureRecognizer *)gestureReecognizer {
    UIView *tappedView = [self hitTest:[gestureReecognizer locationInView:self] withEvent:nil];
    SwipeTableViewRowAction *tappedAction;
    
    for (SwipeTableViewRowAction *action in self.leftActions) {
        if (tappedView == action.view) {
            tappedAction = action;
            break;
        }
    }
    for (SwipeTableViewRowAction *action in self.rightActions) {
        if (tappedView == action.view) {
            tappedAction = action;
            break;
        }
    }
    
    if (tappedAction != nil) {
        [self executeAction:tappedAction];
    } else {
        [self dismissActionsAnimated:YES];
    }
}

- (void)presentLeftActionsAnimated:(BOOL)animated {
    CGFloat xOffset = 0;
    CGFloat actionViewSize = self.contentView.frame.size.height;
    
    for (SwipeTableViewRowAction *action in self.leftActions) {
        UIView *view = [self.class viewForAction:action];
        view.frame = CGRectMake(xOffset, 0, actionViewSize, actionViewSize);
        view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        action.view = view;
        [self.swipeActionContainerView addSubview:view];
        xOffset += actionViewSize;
    }

    [UIView animateWithDuration:animated ? self.swipeAnimationDuration : 0 animations:^{
        self.contentView.frame = CGRectOffset(self.contentView.bounds, xOffset, 0);
    }];

    self.didPresentLeftActions = YES;
}

- (void)presentRightActionsAnimated:(BOOL)animated {
    CGFloat xOffset = 0;
    CGFloat actionViewSize = self.contentView.frame.size.height;
    
    for (SwipeTableViewRowAction *action in self.rightActions) {
        xOffset -= actionViewSize;
        UIView *view = [self.class viewForAction:action];
        view.frame = CGRectMake(self.frame.size.width + xOffset, 0, actionViewSize, actionViewSize);
        view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        action.view = view;
        [self.swipeActionContainerView addSubview:view];
    }

    [UIView animateWithDuration:animated ? self.swipeAnimationDuration : 0 animations:^{
        self.contentView.frame = CGRectOffset(self.contentView.bounds, xOffset, 0);
    }];

    self.didPresentRightActions = YES;
}

- (void)executeAction:(SwipeTableViewRowAction *)action {
    NSAssert(action.handler != nil, @"Action must have a handler");
    action.handler();
}

- (void)dismissActionsAnimated:(BOOL)animated {
    self.dismissingActions = YES;
    
    [UIView animateWithDuration:animated ? self.swipeAnimationDuration : 0 animations:^{
        self.contentView.frame = self.contentView.bounds;
    } completion:^(BOOL finished) {
        self.didPresentLeftActions = NO;
        self.didPresentRightActions = NO;
        self.dismissingActions = NO;
        for (UIView *view in self.swipeActionContainerView.subviews) {
            [view removeFromSuperview];
        }
    }];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (self.didPresentLeftActions || self.didPresentRightActions) {
        return;
    }
    [super setHighlighted:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if (self.didPresentLeftActions || self.didPresentRightActions) {
        return;
    }
    [super setSelected:selected animated:animated];
}

@end
