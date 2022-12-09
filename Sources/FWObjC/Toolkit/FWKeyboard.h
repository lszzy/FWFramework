//
//  FWKeyboard.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __KeyboardTarget

@interface __KeyboardTarget : NSObject

@property (nonatomic, assign) BOOL keyboardManager;

@property (nonatomic, assign) CGFloat keyboardDistance;

@property (nonatomic, assign) CGFloat reboundDistance;

@property (nonatomic, assign) BOOL keyboardResign;

@property (nonatomic, assign) BOOL touchResign;

@property (nonatomic, assign) BOOL returnResign;

@property (nonatomic, assign) BOOL returnNext;

@property (nonatomic, copy, nullable) void (^returnBlock)(id textInput);

@property (nonatomic, strong) UIToolbar *keyboardToolbar;

@property (nonatomic, strong, nullable) id toolbarPreviousButton;

@property (nonatomic, strong, nullable) id toolbarNextButton;

@property (nonatomic, strong, nullable) id toolbarDoneButton;

@property (nonatomic, assign) BOOL previousButtonInitialized;

@property (nonatomic, assign) BOOL nextButtonInitialized;

@property (nonatomic, assign) BOOL doneButtonInitialized;

@property (nonatomic, copy, nullable) UIResponder * _Nullable (^previousResponder)(id textInput);

@property (nonatomic, copy, nullable) UIResponder * _Nullable (^nextResponder)(id textInput);

@property (nonatomic, assign) NSInteger previousResponderTag;

@property (nonatomic, assign) NSInteger nextResponderTag;

@property (nonatomic, weak, nullable) UIScrollView *scrollView;

- (instancetype)initWithTextInput:(nullable UIView<UITextInput> *)textInput;

- (void)innerReturnAction;

- (void)goPrevious;

- (void)goNext;

- (CGFloat)keyboardHeight:(NSNotification *)notification;

- (void)keyboardAnimate:(NSNotification *)notification
             animations:(void (^)(void))animations
             completion:(void (^ __nullable)(BOOL finished))completion;

- (void)addToolbarWithTitle:(nullable id)title
                  doneBlock:(nullable void (^)(id sender))doneBlock;

- (void)addToolbarWithTitleItem:(nullable UIBarButtonItem *)titleItem
                   previousItem:(nullable UIBarButtonItem *)previousItem
                       nextItem:(nullable UIBarButtonItem *)nextItem
                       doneItem:(nullable UIBarButtonItem *)doneItem;
@end

NS_ASSUME_NONNULL_END
