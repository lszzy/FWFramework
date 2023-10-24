//
//  AlertController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "AlertController.h"
#import "ObjC.h"
#import <FWFramework/FWFramework-Swift.h>

#pragma mark ---------------------------- __FWAlertController begin --------------------------------

@implementation __FWAlertController
@synthesize title = _title;

// 添加action
- (void)addAction:(__FWAlertAction *)action {
    NSMutableArray *actions = self.actions.mutableCopy;
    [actions addObject:action];
    self.actions = actions;
    if (self.preferredStyle == __FWAlertControllerStyleAlert) { // alert样式不论是否为取消样式的按钮，都直接按顺序添加
        if (action.style != __FWAlertActionStyleCancel) {
            [self.otherActions addObject:action];
        }
        [self.actionSequenceView addAction:action];
    } else { // actionSheet样式
        if (action.style == __FWAlertActionStyleCancel) { // 如果是取消样式的按钮
            [self.actionSequenceView addCancelAction:action];
        } else {
            [self.otherActions addObject:action];
            [self.actionSequenceView addAction:action];
        }
    }
    
    if (!self.isForceLayout) { // 如果为NO,说明外界没有设置actionAxis，此时按照默认方式排列
        if (self.preferredStyle == __FWAlertControllerStyleAlert) {
            if (self.actions.count > 2) { // alert样式下，action的个数大于2时垂直排列
                _actionAxis = UILayoutConstraintAxisVertical; // 本框架任何一处都不允许调用actionAxis的setter方法，如果调用了则无法判断是外界调用还是内部调用
                [self updateActionAxis];
            } else { // action的个数小于等于2，action水平排列
                _actionAxis = UILayoutConstraintAxisHorizontal;
                [self updateActionAxis];
            }
        } else { // actionSheet样式下默认垂直排列
            _actionAxis = UILayoutConstraintAxisVertical;
            [self updateActionAxis];
            
        }
    } else {
        [self updateActionAxis];
    }
    
    // 这个block是保证外界在添加action之后再设置action属性时依然生效；当使用时在addAction之后再设置action的属性时，会回调这个block
    __weak typeof(self) weakSelf = self;
    action.propertyChangedBlock = ^(__FWAlertAction *action, BOOL needUpdateConstraints) {
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.preferredStyle == __FWAlertControllerStyleAlert) {
            // alert样式下：arrangedSubviews数组和actions是对应的
            NSInteger index = [strongSelf.actions indexOfObject:action];
            __FWAlertControllerActionView *actionView = [strongSelf.actionSequenceView.stackView.arrangedSubviews objectAtIndex:index];
            if ([actionView isKindOfClass:[__FWAlertControllerActionView class]]) {
                actionView.action = action;
            }
            if (strongSelf.presentationController.presentingViewController) {
                // 文字显示不全处理
                [strongSelf handleIncompleteTextDisplay];
            }
        } else {
            if (action.style == __FWAlertActionStyleCancel) {
                // cancelView中只有唯一的一个actionView
                __FWAlertControllerActionView *actionView = [strongSelf.actionSequenceView.cancelView.subviews lastObject];
                if ([actionView isKindOfClass:[__FWAlertControllerActionView class]]) { // 这个判断可以不加，加判断是防止有一天改动框架不小心在cancelView中加了新的view产生安全隐患
                    actionView.action = action;
                }
            } else {
                // actionSheet样式下：arrangedSubviews数组和otherActions是对应的
                NSInteger index = [strongSelf.otherActions indexOfObject:action];
                __FWAlertControllerActionView *actionView = [strongSelf.actionSequenceView.stackView.arrangedSubviews objectAtIndex:index];
                if ([actionView isKindOfClass:[__FWAlertControllerActionView class]]) {
                    actionView.action = action;
                }
            }
        }
        if (strongSelf.presentationController.presentingViewController && needUpdateConstraints) { // 如果在present完成后的某个时刻再去设置action的属性，字体等改变需要更新布局
            [strongSelf.actionSequenceView setNeedsUpdateConstraints];
        }
    };
}

// 设置首选action
- (void)setPreferredAction:(__FWAlertAction *)preferredAction {
    _preferredAction = preferredAction;
    
    [self.actions enumerateObjectsUsingBlock:^(__FWAlertAction *obj, NSUInteger idx, BOOL *stop) {
        if (obj.titleFont == self.alertAppearance.actionBoldFont) {
            obj.titleFont = self.alertAppearance.actionFont;
        }
    }];
    preferredAction.titleFont = self.alertAppearance.actionBoldFont;
}

// 添加文本输入框
- (void)addTextFieldWithConfigurationHandler:(void (^)(UITextField * _Nonnull))configurationHandler {
    NSAssert(self.preferredStyle == __FWAlertControllerStyleAlert,@"FWAlertController does not allow 'addTextFieldWithConfigurationHandler:' to be called in the style of FWAlertControllerStyleActionSheet");
    UITextField *textField = [[UITextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.backgroundColor = [self.alertAppearance textFieldBackgroundColor];
    // 系统的UITextBorderStyleLine样式线条过于黑，所以自己设置
    textField.layer.borderWidth = self.alertAppearance.lineWidth;
    // 这里设置的颜色是静态的，动态设置CGColor,还需要监听深浅模式的切换
    textField.layer.borderColor = [__FWAlertControllerAppearance colorPairsWithStaticLightColor:[self.alertAppearance lineColor] darkColor:[self.alertAppearance darkLineColor]].CGColor;
    textField.layer.cornerRadius = self.alertAppearance.textFieldCornerRadius;
    textField.layer.masksToBounds = YES;
    // 在左边设置一张view，充当光标左边的间距，否则光标紧贴textField不美观
    textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    textField.leftView.userInteractionEnabled = NO;
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.font = [UIFont systemFontOfSize:14];
    // 去掉textField键盘上部的联想条
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    [textField addTarget:self action:@selector(textFieldDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
    if (self.alertAppearance.textFieldCustomBlock) {
        self.alertAppearance.textFieldCustomBlock(textField);
    }
    NSMutableArray *array = self.textFields.mutableCopy;
    [array addObject:textField];
    self.textFields = array;
    [self.headerView addTextField:textField];
    if (configurationHandler) {
        configurationHandler(textField);
    }
}

- (void)setCustomSpacing:(CGFloat)spacing afterAction:(__FWAlertAction *)action {
    if (action == nil) {
        self.customHeaderSpacing = spacing;
        return;
    }
    if (action.style == __FWAlertActionStyleCancel) {
        FWLogDebug(@"*** warning in -[__FWAlertController setCustomSpacing:afterAction:]: 'the -action must not be a action with __FWAlertActionStyleCancel style'");
    } else if (![self.otherActions containsObject:action]) {
        FWLogDebug(@"*** warning in -[__FWAlertController setCustomSpacing:afterAction:]: 'the -action must be contained in the -actions array, not a action with __FWAlertActionStyleCancel style'");
    } else {
        NSInteger index = [self.otherActions indexOfObject:action];
        [self.actionSequenceView setCustomSpacing:spacing afterActionIndex:index];
    }
}

- (CGFloat)customSpacingAfterAction:(__FWAlertAction *)action {
    if (action == nil) {
        return self.customHeaderSpacing;
    }
    if ([self.otherActions containsObject:action]) {
        NSInteger index = [self.otherActions indexOfObject:action];
        return [self.actionSequenceView customSpacingAfterActionIndex:index];
    }
    return 0.0;
}

- (void)setBackgroundViewAppearanceStyle:(UIBlurEffectStyle)style alpha:(CGFloat)alpha {
    _backgroundViewAppearanceStyle = style;
    _backgroundViewAlpha = alpha;
}

- (void)updateCustomViewSize:(CGSize)size {
    _customViewSize = size;
    [self layoutAlertControllerView];
    [self layoutChildViews];
}

- (void)layoutAlertControllerView {
    if (!self.alertControllerView.superview) return;
    if (self.alertControllerViewConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.alertControllerViewConstraints];
        self.alertControllerViewConstraints = nil;
    }
    if (self.preferredStyle == __FWAlertControllerStyleAlert) { // alert样式
        [self layoutAlertControllerViewForAlertStyle];
    } else { // actionSheet样式
        [self layoutAlertControllerViewForActionSheetStyle];
    }
}

- (void)layoutAlertControllerViewForAlertStyle {
    UIView *alertControllerView = self.alertControllerView;
    NSMutableArray *alertControllerViewConstraints = [NSMutableArray array];
    CGFloat topValue = _minDistanceToEdges;
    CGFloat bottomValue = _minDistanceToEdges;
    CGFloat maxWidth = MIN(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)-_minDistanceToEdges * 2;
    CGFloat maxHeight = UIScreen.mainScreen.bounds.size.height-topValue-bottomValue;
    if (!self.customAlertView) {
        // 当屏幕旋转的时候，为了保持alert样式下的宽高不变，因此取MIN(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)
        [alertControllerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:alertControllerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:maxWidth]];
    } else {
        [alertControllerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:alertControllerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:maxWidth]];
        if (_customViewSize.width) { // 如果宽度没有值，则会假定customAlertView水平方向能由子控件撑起
            // 限制最大宽度，且能保证内部约束不报警告
            CGFloat customWidth = MIN(_customViewSize.width, maxWidth);
            [alertControllerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:alertControllerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:customWidth]];
        }
        if (_customViewSize.height) { // 如果高度没有值，则会假定customAlertView垂直方向能由子控件撑起
            CGFloat customHeight = MIN(_customViewSize.height, maxHeight);
            [alertControllerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:alertControllerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:customHeight]];
        }
    }
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:alertControllerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:alertControllerView.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:topValue];
    topConstraint.priority = 999.0;// 这里优先级为999.0是为了小于垂直中心的优先级，如果含有文本输入框，键盘弹出后，特别是旋转到横屏后，对话框的空间比较小，这个时候优先偏移垂直中心，顶部优先级按理说应该会被忽略，但是由于子控件含有scrollView，所以该优先级仍然会被激活，子控件显示不全scrollView可以滑动。如果外界自定义了整个对话框，且自定义的view上含有文本输入框，子控件不含有scrollView，顶部间距会被忽略
    [alertControllerViewConstraints addObject:topConstraint];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:alertControllerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:alertControllerView.superview attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-bottomValue];
    bottomConstraint.priority = 999.0; // 优先级跟顶部同理
    [alertControllerViewConstraints addObject:bottomConstraint];
    [alertControllerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:alertControllerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:alertControllerView.superview attribute:NSLayoutAttributeCenterX multiplier:1.0 constant: _offsetForAlert.x]];
    NSLayoutConstraint *alertControllerViewConstraintCenterY = [NSLayoutConstraint constraintWithItem:alertControllerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:alertControllerView.superview attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:(self.isBeingPresented && !self.isBeingDismissed) ? 0 : _offsetForAlert.y];
    [alertControllerViewConstraints addObject:alertControllerViewConstraintCenterY];
    [NSLayoutConstraint activateConstraints:alertControllerViewConstraints];
    self.alertControllerViewConstraints = alertControllerViewConstraints;
}

- (void)layoutAlertControllerViewForActionSheetStyle {
    switch (self.animationType) {
        case __FWAlertAnimationTypeFromBottom:
        default:
            [self layoutAlertControllerViewForAnimationTypeWithHV:@"H"
                                                   equalAttribute:NSLayoutAttributeBottom
                                                notEqualAttribute:NSLayoutAttributeTop
                                            lessOrGreaterRelation:NSLayoutRelationGreaterThanOrEqual];
            break;
        case __FWAlertAnimationTypeFromTop:
            [self layoutAlertControllerViewForAnimationTypeWithHV:@"H"
                                                   equalAttribute:NSLayoutAttributeTop
                                                notEqualAttribute:NSLayoutAttributeBottom
                                            lessOrGreaterRelation:NSLayoutRelationLessThanOrEqual];
            break;
        case __FWAlertAnimationTypeFromLeft:
            [self layoutAlertControllerViewForAnimationTypeWithHV:@"V"
                                                   equalAttribute:NSLayoutAttributeLeft
                                                notEqualAttribute:NSLayoutAttributeRight
                                            lessOrGreaterRelation:NSLayoutRelationLessThanOrEqual];
            break;
        case __FWAlertAnimationTypeFromRight:
            [self layoutAlertControllerViewForAnimationTypeWithHV:@"V"
                                                   equalAttribute:NSLayoutAttributeRight
                                                notEqualAttribute:NSLayoutAttributeLeft
                                            lessOrGreaterRelation:NSLayoutRelationLessThanOrEqual];
            break;
    }
}

- (void)layoutAlertControllerViewForAnimationTypeWithHV:(NSString *)hv
                                             equalAttribute:(NSLayoutAttribute)equalAttribute
                                      notEqualAttribute:(NSLayoutAttribute)notEqualAttribute
                                               lessOrGreaterRelation:(NSLayoutRelation)relation {
    UIView *alertControllerView = self.alertControllerView;
    NSMutableArray *alertControllerViewConstraints = [NSMutableArray array];
    if (!self.customAlertView) {
        [alertControllerViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"%@:|-0-[alertControllerView]-0-|",hv] options:0 metrics:nil views:NSDictionaryOfVariableBindings(alertControllerView)]];
    } else {
        NSLayoutAttribute centerXorY = [hv isEqualToString:@"H"] ? NSLayoutAttributeCenterX : NSLayoutAttributeCenterY;
        [alertControllerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:alertControllerView attribute:centerXorY relatedBy:NSLayoutRelationEqual toItem:alertControllerView.superview attribute:centerXorY multiplier:1.0 constant:0]];
        if (_customViewSize.width) { // 如果宽度没有值，则会假定customAlertViewh水平方向能由子控件撑起
            CGFloat alertControllerViewWidth = 0.0;
            if ([hv isEqualToString:@"H"]) {
                alertControllerViewWidth = MIN(_customViewSize.width, UIScreen.mainScreen.bounds.size.width);
            } else {
                alertControllerViewWidth = MIN(_customViewSize.width, UIScreen.mainScreen.bounds.size.width-_minDistanceToEdges);
            }
            [alertControllerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:alertControllerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:alertControllerViewWidth]];
        }
        if (_customViewSize.height) { // 如果高度没有值，则会假定customAlertViewh垂直方向能由子控件撑起
            CGFloat alertControllerViewHeight = 0.0;
            if ([hv isEqualToString:@"H"]) {
                alertControllerViewHeight = MIN(_customViewSize.height, UIScreen.mainScreen.bounds.size.height-_minDistanceToEdges);
            } else {
                alertControllerViewHeight = MIN(_customViewSize.height, UIScreen.mainScreen.bounds.size.height);
            }
            [alertControllerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:alertControllerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:alertControllerViewHeight]];
        }
    }
    [alertControllerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:alertControllerView attribute:equalAttribute relatedBy:NSLayoutRelationEqual toItem:alertControllerView.superview attribute:equalAttribute multiplier:1.0 constant:0]];
    NSLayoutConstraint *someSideConstraint = [NSLayoutConstraint constraintWithItem:alertControllerView attribute:notEqualAttribute relatedBy:relation toItem:alertControllerView.superview attribute:notEqualAttribute multiplier:1.0 constant:_minDistanceToEdges];
    someSideConstraint.priority = 999.0;
    [alertControllerViewConstraints addObject:someSideConstraint];
    [NSLayoutConstraint activateConstraints:alertControllerViewConstraints];
    self.alertControllerViewConstraints = alertControllerViewConstraints;
}

- (void)layoutChildViews {
    // 对头部布局
    [self layoutHeaderView];
    
    // 对头部和action部分之间的分割线布局
    [self layoutHeaderActionLine];
    
    // 对组件view布局
    [self layoutComponentView];

    // 对组件view与action部分之间的分割线布局
    [self layoutComponentActionLine];
    
    // 对action部分布局
    [self layoutActionSequenceView];
}

// 对头部布局，高度由子控件撑起
- (void)layoutHeaderView {
    UIView *headerView = self.customHeaderView ? self.customHeaderView : self.headerView;
    if (!headerView.superview) return;
    if (_preferredStyle == __FWAlertControllerStyleActionSheet && self.alertAppearance.sheetContainerTransparent) {
        headerView.backgroundColor = self.alertAppearance.containerBackgroundColor;
        headerView.layer.cornerRadius = self.cornerRadius;
        headerView.layer.masksToBounds = YES;
    }
    UIView *alertView = self.alertView;
    NSMutableArray *headerViewConstraints = [NSMutableArray array];
    if (self.headerViewConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.headerViewConstraints];
        self.headerViewConstraints = nil;
    }
    if (!self.customHeaderView) {
        [headerViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[headerView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(headerView)]];
    } else {
        if (_customViewSize.width) {
            CGFloat maxWidth = [self maxWidth];
            CGFloat headerViewWidth = MIN(maxWidth, _customViewSize.width);
            [headerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:headerViewWidth]];
        }
        if (_customViewSize.height) {
            NSLayoutConstraint *customHeightConstraint = [NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customViewSize.height];
            customHeightConstraint.priority = UILayoutPriorityDefaultHigh;
            [headerViewConstraints addObject:customHeightConstraint];
        }
        [headerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:alertView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    }
    [headerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:alertView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    if (!self.headerActionLine.superview) {
        [headerViewConstraints addObject:[NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:alertView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    }
    [NSLayoutConstraint activateConstraints:headerViewConstraints];
    self.headerViewConstraints = headerViewConstraints;
}

// 对头部和action部分之间的分割线布局
- (void)layoutHeaderActionLine {
    if (!self.headerActionLine.superview) return;
    UIView *headerActionLine = self.headerActionLine;
    UIView *headerView = self.customHeaderView ? self.customHeaderView : self.headerView;
    UIView *actionSequenceView = self.customActionSequenceView ? self.customActionSequenceView : self.actionSequenceView;
    NSMutableArray *headerActionLineConstraints = [NSMutableArray array];
    if (self.headerActionLineConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.headerActionLineConstraints];
        self.headerActionLineConstraints = nil;
    }
    [headerActionLineConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[headerActionLine]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(headerActionLine)]];
    [headerActionLineConstraints addObject:[NSLayoutConstraint constraintWithItem:headerActionLine attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:headerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    if (!self.componentView.superview) {
        [headerActionLineConstraints addObject:[NSLayoutConstraint constraintWithItem:headerActionLine attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:actionSequenceView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    }
    CGFloat headerSpacing = self.alertAppearance.lineWidth;
    if (self.customHeaderSpacing > 0) {
        headerSpacing = self.customHeaderSpacing;
    } else if (_preferredStyle == __FWAlertControllerStyleActionSheet &&
               self.alertAppearance.sheetContainerTransparent) {
        headerSpacing = self.alertAppearance.cancelLineWidth;
    }
    [headerActionLineConstraints addObject:[NSLayoutConstraint constraintWithItem:headerActionLine attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:headerSpacing]];

    [NSLayoutConstraint activateConstraints:headerActionLineConstraints];
    self.headerActionLineConstraints = headerActionLineConstraints;
}

// 对组件view布局
- (void)layoutComponentView {
    if (!self.componentView.superview) return;
    UIView *componentView = self.componentView;
    UIView *headerActionLine = self.headerActionLine;
    UIView *componentActionLine = self.componentActionLine;
    if (_preferredStyle == __FWAlertControllerStyleActionSheet && self.alertAppearance.sheetContainerTransparent) {
        componentView.backgroundColor = self.alertAppearance.containerBackgroundColor;
        componentView.layer.cornerRadius = self.cornerRadius;
        componentView.layer.masksToBounds = YES;
    }
    NSMutableArray *componentViewConstraints = [NSMutableArray array];
    if (self.componentViewConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.componentViewConstraints];
        self.componentViewConstraints = nil;
    }
    [componentViewConstraints addObject:[NSLayoutConstraint constraintWithItem:componentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:headerActionLine attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [componentViewConstraints addObject:[NSLayoutConstraint constraintWithItem:componentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:componentActionLine attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [componentViewConstraints addObject:[NSLayoutConstraint constraintWithItem:componentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.alertView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    if (_customViewSize.height) {
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:componentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customViewSize.height];
        heightConstraint.priority = UILayoutPriorityDefaultHigh; // 750
        [componentViewConstraints addObject:heightConstraint];
    }
    if (_customViewSize.width) {
        CGFloat maxWidth = [self maxWidth];
        CGFloat componentViewWidth = MIN(maxWidth, _customViewSize.width);
        [componentViewConstraints addObject:[NSLayoutConstraint constraintWithItem:componentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:componentViewWidth]];
    }
    [NSLayoutConstraint activateConstraints:componentViewConstraints];
    self.componentViewConstraints = componentViewConstraints;
}

// 对组件view和action部分之间的分割线布局
- (void)layoutComponentActionLine {
    if (!self.componentActionLine.superview) return;
    UIView *componentActionLine = self.componentActionLine;
    NSMutableArray *componentActionLineConstraints = [NSMutableArray array];
    if (self.componentActionLineConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.componentActionLineConstraints];
        self.componentActionLineConstraints = nil;
    }
    [componentActionLineConstraints addObject:[NSLayoutConstraint constraintWithItem:componentActionLine attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.actionSequenceView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [componentActionLineConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[componentActionLine]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(componentActionLine)]];
    [componentActionLineConstraints addObject:[NSLayoutConstraint constraintWithItem:componentActionLine attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.alertAppearance.lineWidth]];
    [NSLayoutConstraint activateConstraints:componentActionLineConstraints];
    self.componentActionLineConstraints = componentActionLineConstraints;
}

// 对action部分布局，高度由子控件撑起
- (void)layoutActionSequenceView {
    UIView *actionSequenceView = self.customActionSequenceView ? self.customActionSequenceView : self.actionSequenceView;
    if (!actionSequenceView.superview) return;
    UIView *alertView = self.alertView;
    UIView *headerActionLine = self.headerActionLine;

    NSMutableArray *actionSequenceViewConstraints = [NSMutableArray array];
    if (self.actionSequenceViewConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.actionSequenceViewConstraints];
        self.actionSequenceViewConstraints = nil;
    }
    if (!self.customActionSequenceView) {
        [actionSequenceViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[actionSequenceView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(actionSequenceView)]];
    } else {

        if (_customViewSize.width) {
            CGFloat maxWidth = [self maxWidth];
            if (_customViewSize.width > maxWidth) _customViewSize.width = maxWidth;
            [actionSequenceViewConstraints addObject:[NSLayoutConstraint constraintWithItem:actionSequenceView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customViewSize.width]];
        }
        if (_customViewSize.height) {
            NSLayoutConstraint *customHeightConstraint = [NSLayoutConstraint constraintWithItem:actionSequenceView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customViewSize.height];
            customHeightConstraint.priority = UILayoutPriorityDefaultHigh;
            [actionSequenceViewConstraints addObject:customHeightConstraint];
        }
        [actionSequenceViewConstraints addObject:[NSLayoutConstraint constraintWithItem:actionSequenceView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:alertView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    }
    if (!headerActionLine) {
        [actionSequenceViewConstraints addObject:[NSLayoutConstraint constraintWithItem:actionSequenceView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:alertView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    }
    [actionSequenceViewConstraints addObject:[NSLayoutConstraint constraintWithItem:actionSequenceView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:alertView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];

    [NSLayoutConstraint activateConstraints:actionSequenceViewConstraints];
    self.actionSequenceViewConstraints = actionSequenceViewConstraints;
}

// 文字显示不全处理
- (void)handleIncompleteTextDisplay {
    // alert样式下水平排列时如果文字显示不全则垂直排列
    if (!self.isForceLayout) { // 外界没有设置排列方式
        if (self.preferredStyle == __FWAlertControllerStyleAlert) {
            for (__FWAlertAction *action in self.actions) {
                // 预估按钮宽度
                CGFloat preButtonWidth = (MIN(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height) - _minDistanceToEdges * 2 - self.alertAppearance.lineWidth * (self.actions.count - 1)) / self.actions.count - action.titleEdgeInsets.left - action.titleEdgeInsets.right;
                // 如果action的标题文字总宽度，大于按钮的contentRect的宽度，则说明水平排列会导致文字显示不全，此时垂直排列
                if (action.attributedTitle) {
                    if (ceil([action.attributedTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.alertAppearance.actionHeight) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.width) > preButtonWidth) {
                        _actionAxis = UILayoutConstraintAxisVertical;
                        [self updateActionAxis];
                        [self.actionSequenceView setNeedsUpdateConstraints];
                        break; // 一定要break，只要有一个按钮文字过长就垂直排列
                    }
                } else {
                    if (ceil([action.title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.alertAppearance.actionHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:action.titleFont} context:nil].size.width) > preButtonWidth) {
                        _actionAxis = UILayoutConstraintAxisVertical;
                        [self updateActionAxis];
                        [self.actionSequenceView setNeedsUpdateConstraints];
                        break;
                    }
                }
            }
        }
    }
}

- (void)configureHeaderView {
    if (self.image) {
        self.headerView.imageLimitSize = _imageLimitSize;
        self.headerView.imageView.image = _image;
        self.headerView.imageView.tintColor = _imageTintColor;
        [self.headerView setNeedsUpdateConstraints];
    }
    if(self.attributedTitle.length) {
        self.headerView.titleLabel.attributedText = self.attributedTitle;
        [self setupPreferredMaxLayoutWidthForLabel:self.headerView.titleLabel];
    } else if(self.title.length) {
        self.headerView.titleLabel.text = _title;
        self.headerView.titleLabel.font = _titleFont;
        self.headerView.titleLabel.textColor = _titleColor;
        self.headerView.titleLabel.textAlignment = _textAlignment;
        [self setupPreferredMaxLayoutWidthForLabel:self.headerView.titleLabel];
    }
    if (self.attributedMessage.length) {
        self.headerView.messageLabel.attributedText = self.attributedMessage;
        [self setupPreferredMaxLayoutWidthForLabel:self.headerView.messageLabel];
    } else if (self.message.length) {
        self.headerView.messageLabel.text = _message;
        self.headerView.messageLabel.font = _messageFont;
        self.headerView.messageLabel.textColor = _messageColor;
        self.headerView.messageLabel.textAlignment = _textAlignment;
        [self setupPreferredMaxLayoutWidthForLabel:self.headerView.messageLabel];
    }
}

- (void)setupPreferredMaxLayoutWidthForLabel:(UILabel *)textLabel {
    if (self.preferredStyle == __FWAlertControllerStyleAlert) {
        textLabel.preferredMaxLayoutWidth = MIN(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height) - self.minDistanceToEdges * 2 - self.headerView.contentEdgeInsets.left - self.headerView.contentEdgeInsets.right;
    } else {
        textLabel.preferredMaxLayoutWidth  = UIScreen.mainScreen.bounds.size.width - self.headerView.contentEdgeInsets.left - self.headerView.contentEdgeInsets.right;
    }
}

// 这个方法是实现点击回车切换到下一个textField，如果没有下一个，会自动退出键盘. 不能在代理方法里实现，因为如果设置了代理，外界就不能成为textFiled的代理了，通知也监听不到回车
- (void)textFieldDidEndOnExit:(UITextField *)textField {
    NSInteger index = [self.textFields indexOfObject:textField];
    if (self.textFields.count > index + 1) {
        UITextField *nextTextField = [self.textFields objectAtIndex:index + 1];
        [textField resignFirstResponder];
        [nextTextField becomeFirstResponder];
    }
}

// 更新action的排列方式
- (void)updateActionAxis {
    self.actionSequenceView.axis = _actionAxis;
    if (_actionAxis == UILayoutConstraintAxisVertical) {
        self.actionSequenceView.stackViewDistribution = UIStackViewDistributionFillProportionally;// 布局方式为子控件自适应内容高度
    } else {
        self.actionSequenceView.stackViewDistribution = UIStackViewDistributionFillEqually; // 布局方式为子控件等宽
    }
}

- (void)makeViewOffsetWithAnimated:(BOOL)animated {
    if (!self.beingPresented && !self.beingDismissed) {
        [self layoutAlertControllerView];
        if (animated) {
            [UIView animateWithDuration:0.25 animations:^{
                [self.view.superview layoutIfNeeded];
            }];
        }
    }
}

// 获取自定义view的大小
- (CGSize)sizeForCustomView:(UIView *)customView {
    [customView layoutIfNeeded];
    CGSize settingSize = customView.frame.size;
    CGSize fittingSize = [customView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return CGSizeMake(MAX(settingSize.width, fittingSize.width), MAX(settingSize.height, fittingSize.height));
}

#pragma mark - system methods

- (void)loadView {
    // 重新创建self.view，这样可以采用自己的一套布局，轻松改变控制器view的大小
    self.view = self.alertControllerView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureHeaderView];
    self.needDialogBlur = _needDialogBlur;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_isForceOffset && ((!_customAlertView && !_customHeaderView && !_customActionSequenceView && !_componentView) || _customTextField)) {
        // 监听键盘改变frame，键盘frame改变需要移动对话框
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    if (self.textFields.count) {
        UITextField *firstTextfield = [self.textFields firstObject];
        if (!firstTextfield.isFirstResponder) {
            [firstTextfield becomeFirstResponder];
        }
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    // 屏幕旋转后宽高发生了交换，头部的label最大宽度需要重新计算
    [self setupPreferredMaxLayoutWidthForLabel:self.headerView.titleLabel];
    [self setupPreferredMaxLayoutWidthForLabel:self.headerView.messageLabel];
    // 对自己创建的alertControllerView布局，在这个方法里，self.view才有父视图，有父视图才能改变其约束
    [self layoutAlertControllerView];
    [self layoutChildViews];
    
    if (self.preferredStyle == __FWAlertControllerStyleActionSheet) {
        [self setCornerRadius:_cornerRadius];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self handleIncompleteTextDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 键盘通知

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    if (!_isForceOffset && (_offsetForAlert.y == 0.0 || _textFields.lastObject.isFirstResponder || _customTextField)) {
        CGRect keyboardEndFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat keyboardEndY = keyboardEndFrame.origin.y;
        CGFloat diff = fabs((UIScreen.mainScreen.bounds.size.height - keyboardEndY) * 0.5);
        _offsetForAlert.y = -diff;
        [self makeViewOffsetWithAnimated:YES];
    }
}

#pragma mark - setterx

- (void)setTitle:(NSString *)title {
    _title = title;
    if (self.isViewLoaded) { // 如果条件为真，说明外界在对title赋值之前就已经使用了self.view，先走了viewDidLoad方法，如果先走的viewDidLoad，需要在title的setter方法中重新设置数据,以下setter方法中的条件同理
        self.headerView.titleLabel.text = title;
        // 文字发生变化后再更新布局，这里更新布局也不是那么重要，因为headerView中的布局方法只有当__FWAlertController被present后才会走一次，而那时候，一般title,titleFont、message、messageFont等都是最新值，这里防止的是：在__FWAlertController被present后的某个时刻再去设置title,titleFont等，我们要更新布局
        if (self.presentationController.presentingViewController) { // 这个if条件的意思是当__FWAlertController被present后的某个时刻设置了title，如果在present之前设置的就不用更新，系统会主动更新
            [self.headerView setNeedsUpdateConstraints];
        }
    }
}

- (void)setTitleFont:(UIFont *)titleFont {
    _titleFont = titleFont;
    if (self.isViewLoaded) {
        self.headerView.titleLabel.font = titleFont;
        if (self.presentationController.presentingViewController) {
            [self.headerView setNeedsUpdateConstraints];
        }
    }
}

- (void)setTitleColor:(UIColor *)titleColor {
    _titleColor = titleColor;
    if (self.isViewLoaded) {
        self.headerView.titleLabel.textColor = titleColor;
    }
}

- (void)setMessage:(NSString *)message {
    _message = message;
    if (self.isViewLoaded) {
        self.headerView.messageLabel.text = message;
        if (self.presentationController.presentingViewController) {
            [self.headerView setNeedsUpdateConstraints];
        }
    }
}

- (void)setMessageFont:(UIFont *)messageFont {
    _messageFont = messageFont;
    if (self.isViewLoaded) {
        self.headerView.messageLabel.font = messageFont;
        if (self.presentationController.presentingViewController) {
            [self.headerView setNeedsUpdateConstraints];
        }
    }
}

- (void)setMessageColor:(UIColor *)messageColor {
    _messageColor = messageColor;
    if (self.isViewLoaded) {
        self.headerView.messageLabel.textColor = messageColor;
    }
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    _textAlignment = textAlignment;
    self.headerView.titleLabel.textAlignment = _textAlignment;
    self.headerView.messageLabel.textAlignment = _textAlignment;
}

- (void)setIcon:(UIImage *)image {
    _image = image;
    if (self.isViewLoaded) {
        self.headerView.imageView.image = _image;
        if (self.presentationController.presentingViewController) {
            [self.headerView setNeedsUpdateConstraints];
        }
    }
}

- (void)setIconLimitSize:(CGSize)imageLimitSize {
    _imageLimitSize = imageLimitSize;
    if (self.isViewLoaded) {
        self.headerView.imageLimitSize = _imageLimitSize;
        if (self.presentationController.presentingViewController) {
            [self.headerView setNeedsUpdateConstraints];
        }
    }
}

- (void)setImageTintColor:(UIColor *)imageTintColor {
    _imageTintColor = imageTintColor;
    if (self.isViewLoaded) {
        self.headerView.imageView.tintColor = imageTintColor;
    }
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle {
    _attributedTitle = attributedTitle;
    if (self.isViewLoaded) {
        self.headerView.titleLabel.attributedText = _attributedTitle;
        if (self.presentationController.presentingViewController) {
            [self.headerView setNeedsUpdateConstraints];
        }
    }
}

- (void)setAttributedMessage:(NSAttributedString *)attributedMessage {
    _attributedMessage = attributedMessage;
    if (self.isViewLoaded) {
        self.headerView.messageLabel.attributedText = _attributedMessage;
        if (self.presentationController.presentingViewController) {
            [self.headerView setNeedsUpdateConstraints];
        }
    }
}

- (void)setMinDistanceToEdges:(CGFloat)minDistanceToEdges {
    _minDistanceToEdges = minDistanceToEdges;
    if (self.isViewLoaded) {
        [self setupPreferredMaxLayoutWidthForLabel:self.headerView.titleLabel];
        [self setupPreferredMaxLayoutWidthForLabel:self.headerView.messageLabel];
        if (self.presentationController.presentingViewController) {
            [self layoutAlertControllerView];
            [self.headerView setNeedsUpdateConstraints];
            [self.actionSequenceView setNeedsUpdateConstraints];
        }
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    if (self.preferredStyle == __FWAlertControllerStyleAlert) {
        self.containerView.layer.cornerRadius = _cornerRadius;
        self.containerView.layer.masksToBounds = YES;
    } else {
        if (_cornerRadius > 0.0) {
            UIRectCorner corner = UIRectCornerTopLeft | UIRectCornerTopRight;
            switch (_animationType) {
                case __FWAlertAnimationTypeFromBottom:
                    corner = UIRectCornerTopLeft | UIRectCornerTopRight;
                    break;
                case __FWAlertAnimationTypeFromTop:
                    corner = UIRectCornerBottomLeft | UIRectCornerBottomRight;
                    break;
                case __FWAlertAnimationTypeFromLeft:
                    corner = UIRectCornerTopRight | UIRectCornerBottomRight;
                    break;
                case __FWAlertAnimationTypeFromRight:
                    corner = UIRectCornerTopLeft | UIRectCornerBottomLeft;
                    break;
                default:
                    break;
            }
            CAShapeLayer *maskLayer = (CAShapeLayer *)_containerView.layer.mask;
            maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:_containerView.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(_cornerRadius, _cornerRadius)].CGPath;
            maskLayer.frame = _containerView.bounds;
        } else {
            _containerView.layer.mask = nil;
        }
    }
}

- (void)setActionAxis:(UILayoutConstraintAxis)actionAxis {
    _actionAxis = actionAxis;
    // 调用该setter方法则认为是强制布局，该setter方法只有外界能调，这样才能判断外界有没有调用actionAxis的setter方法，从而是否按照外界的指定布局方式进行布局
    _isForceLayout = YES;

    if (self.isViewLoaded) {
        [self updateActionAxis];
    }
}

- (void)setNeedDialogBlur:(BOOL)needDialogBlur {
    _needDialogBlur = needDialogBlur;
    if (_needDialogBlur) {
        self.containerView.backgroundColor = [UIColor clearColor];
        if (!self.dimmingKnockoutBackdropView) {
            self.dimmingKnockoutBackdropView = [NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"_U", @"IDimmingKnockou", @"tBackdropView"]) alloc];
            if (self.dimmingKnockoutBackdropView) {
                // 下面4行相当于self.dimmingKnockoutBackdropView = [self.dimmingKnockoutBackdropView performSelector:NSSelectorFromString(@"initWithStyle:") withObject:@(UIBlurEffectStyleLight)];
                SEL selector = NSSelectorFromString(@"initWithStyle:");
                IMP imp = [self.dimmingKnockoutBackdropView methodForSelector:selector];
                if (imp != NULL) {
                    UIView *(*func)(id, SEL,UIBlurEffectStyle) = (void *)imp;
                    self.dimmingKnockoutBackdropView = func(self.dimmingKnockoutBackdropView, selector, UIBlurEffectStyleLight);
                    self.dimmingKnockoutBackdropView.frame = self.containerView.bounds;
                    self.dimmingKnockoutBackdropView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    [self.containerView insertSubview:self.dimmingKnockoutBackdropView atIndex:0];
                }
            } else { // 这个else是防止假如_UIDimmingKnockoutBackdropView这个类不存在了的时候，做一个备案
                UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
                self.dimmingKnockoutBackdropView = [[UIVisualEffectView alloc] initWithEffect:blur];
                self.dimmingKnockoutBackdropView.frame = self.containerView.bounds;
                self.dimmingKnockoutBackdropView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
                [self.containerView insertSubview:self.dimmingKnockoutBackdropView atIndex:0];
            }
        }
    } else {
        [self.dimmingKnockoutBackdropView removeFromSuperview];
        self.dimmingKnockoutBackdropView = nil;
        if (_customAlertView) {
            self.containerView.backgroundColor = [UIColor clearColor];
        } else if (_preferredStyle == __FWAlertControllerStyleActionSheet && self.alertAppearance.sheetContainerTransparent) {
            self.containerView.backgroundColor = [UIColor clearColor];
        } else {
            self.containerView.backgroundColor = [self.alertAppearance containerBackgroundColor];
        }
    }
}

@end

#pragma mark ---------------------------- __FWAlertController end --------------------------------
