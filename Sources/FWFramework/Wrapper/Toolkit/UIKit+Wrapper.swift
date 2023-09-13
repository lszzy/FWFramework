//
//  UIKit+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - UIBezierPath+UIKit
extension Wrapper where Base: UIBezierPath {
    
    /// 绘制形状图片，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
    public func shapeImage(_ size: CGSize, strokeWidth: CGFloat, strokeColor: UIColor, fillColor: UIColor?) -> UIImage? {
        return base.fw_shapeImage(size, strokeWidth: strokeWidth, strokeColor: strokeColor, fillColor: fillColor)
    }

    /// 绘制形状Layer，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
    public func shapeLayer(_ rect: CGRect, strokeWidth: CGFloat, strokeColor: UIColor, fillColor: UIColor?) -> CAShapeLayer {
        return base.fw_shapeLayer(rect, strokeWidth: strokeWidth, strokeColor: strokeColor, fillColor: fillColor)
    }

    /// 根据点计算折线路径(NSValue点)
    public static func lines(points: [NSValue]) -> UIBezierPath {
        return Base.fw_lines(points: points)
    }

    /// 根据点计算贝塞尔曲线路径
    public static func quadCurvedPath(points: [NSValue]) -> UIBezierPath {
        return Base.fw_quadCurvedPath(points: points)
    }
    
    /// 计算两点的中心点
    public static func middlePoint(_ p1: CGPoint, with p2: CGPoint) -> CGPoint {
        return Base.fw_middlePoint(p1, with: p2)
    }

    /// 计算两点的贝塞尔曲线控制点
    public static func controlPoint(_ p1: CGPoint, with p2: CGPoint) -> CGPoint {
        return Base.fw_controlPoint(p1, with: p2)
    }
    
    /// 将角度(0~360)转换为弧度，周长为2*M_PI*r
    public static func radian(degree: CGFloat) -> CGFloat {
        return Base.fw_radian(degree: degree)
    }
    
    /// 将弧度转换为角度(0~360)
    public static func degree(radian: CGFloat) -> CGFloat {
        return Base.fw_degree(radian: radian)
    }
    
    /// 根据滑动方向计算rect的线段起点、终点中心点坐标数组(示范：田)。默认从上到下滑动
    public static func linePoints(rect: CGRect, direction: UISwipeGestureRecognizer.Direction) -> [NSValue] {
        return Base.fw_linePoints(rect: rect, direction: direction)
    }
    
}

// MARK: - UIDevice+UIKit
extension Wrapper where Base: UIDevice {
    
    /// 设置设备token原始Data，格式化并保存
    public static func setDeviceTokenData(_ tokenData: Data?) {
        Base.fw_setDeviceTokenData(tokenData)
    }

    /// 获取设备Token格式化后的字符串
    public static var deviceToken: String? {
        get { Base.fw_deviceToken }
        set { Base.fw_deviceToken = newValue }
    }

    /// 获取设备模型，格式："iPhone6,1"
    public static var deviceModel: String? {
        return Base.fw_deviceModel
    }

    /// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
    public static var deviceIDFV: String? {
        return Base.fw_deviceIDFV
    }

    /// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Tracking子模块后生效
    public static var deviceIDFA: String? {
        return Base.fw_deviceIDFA
    }
    
    /// 获取或设置设备UUID，自动keychain持久化。默认获取IDFV(未使用IDFA，避免额外权限)，失败则随机生成一个
    public static var deviceUUID: String {
        get { Base.fw_deviceUUID }
        set { Base.fw_deviceUUID = newValue }
    }
    
    /// 是否越狱
    public static var isJailbroken: Bool {
        return Base.fw_isJailbroken
    }
    
    /// 本地IP地址
    public static var ipAddress: String? {
        return Base.fw_ipAddress
    }
    
    /// 本地主机名称
    public static var hostName: String? {
        return Base.fw_hostName
    }
    
    /// 手机运营商名称
    public static var carrierName: String? {
        return Base.fw_carrierName
    }
    
    /// 手机蜂窝网络类型，仅区分2G|3G|4G|5G
    public static var networkType: String? {
        return Base.fw_networkType
    }
    
}

// MARK: - UIView+UIKit
/// 事件穿透实现方法：重写-hitTest:withEvent:方法，当为指定视图(如self)时返回nil排除即可
extension Wrapper where Base: UIView {
    
    /// 视图是否可见，视图hidden为NO、alpha>0.01、window存在且size不为0才认为可见
    public var isViewVisible: Bool {
        return base.fw_isViewVisible
    }

    /// 获取响应的视图控制器
    public var viewController: UIViewController? {
        return base.fw_viewController
    }

    /// 设置额外热区(点击区域)
    public var touchInsets: UIEdgeInsets {
        get { return base.fw_touchInsets }
        set { base.fw_touchInsets = newValue }
    }
    
    /// 设置视图是否允许检测子视图pointInside，默认false
    public var pointInsideSubviews: Bool {
        get { return base.fw_pointInsideSubviews }
        set { base.fw_pointInsideSubviews = newValue }
    }
    
    /// 设置视图是否可穿透(子视图响应)
    public var isPenetrable: Bool {
        get { return base.fw_isPenetrable }
        set { base.fw_isPenetrable = newValue }
    }

    /// 设置自动计算适合高度的frame，需实现sizeThatFits:方法
    public var fitFrame: CGRect {
        get { return base.fw_fitFrame }
        set { base.fw_fitFrame = newValue }
    }

    /// 计算当前视图适合大小，需实现sizeThatFits:方法
    public var fitSize: CGSize {
        return base.fw_fitSize
    }

    /// 计算指定边界，当前视图适合大小，需实现sizeThatFits:方法
    public func fitSize(drawSize: CGSize) -> CGSize {
        return base.fw_fitSize(drawSize: drawSize)
    }
    
    /// 根据tag查找subview，仅从subviews中查找
    public func subview(tag: Int) -> UIView? {
        return base.fw_subview(tag: tag)
    }

    /// 设置阴影颜色、偏移和半径
    public func setShadowColor(_ color: UIColor?, offset: CGSize, radius: CGFloat) {
        base.fw_setShadowColor(color, offset: offset, radius: radius)
    }

    /// 绘制四边边框
    public func setBorderColor(_ color: UIColor?, width: CGFloat) {
        base.fw_setBorderColor(color, width: width)
    }

    /// 绘制四边边框和四角圆角
    public func setBorderColor(_ color: UIColor?, width: CGFloat, cornerRadius: CGFloat) {
        base.fw_setBorderColor(color, width: width, cornerRadius: cornerRadius)
    }

    /// 绘制四角圆角
    public func setCornerRadius(_ radius: CGFloat) {
        base.fw_setCornerRadius(radius)
    }

    /// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setBorderLayer(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        base.fw_setBorderLayer(edge, color: color, width: width)
    }

    /// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setBorderLayer(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        base.fw_setBorderLayer(edge, color: color, width: width, leftInset: leftInset, rightInset: rightInset)
    }
    
    /// 绘制四边虚线边框和四角圆角。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setDashBorderLayer(color: UIColor?, width: CGFloat, cornerRadius: CGFloat, lineLength: CGFloat, lineSpacing: CGFloat) {
        base.fw_setDashBorderLayer(color: color, width: width, cornerRadius: cornerRadius, lineLength: lineLength, lineSpacing: lineSpacing)
    }

    /// 绘制单个或多个边框圆角，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setCornerLayer(_ corner: UIRectCorner, radius: CGFloat) {
        base.fw_setCornerLayer(corner, radius: radius)
    }

    /// 绘制单个或多个边框圆角和四边边框，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setCornerLayer(_ corner: UIRectCorner, radius: CGFloat, borderColor: UIColor?, width: CGFloat) {
        base.fw_setCornerLayer(corner, radius: radius, borderColor: borderColor, width: width)
    }
    
    /// 绘制单边或多边边框视图。使用AutoLayout
    public func setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        base.fw_setBorderView(edge, color: color, width: width)
    }

    /// 绘制单边或多边边框。使用AutoLayout
    public func setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        base.fw_setBorderView(edge, color: color, width: width, leftInset: leftInset, rightInset: rightInset)
    }
    
    /// 开始倒计时，从window移除时自动取消，回调参数为剩余时间
    @discardableResult
    public func startCountDown(_ seconds: Int, block: @escaping (Int) -> Void) -> DispatchSourceTimer {
        return base.fw_startCountDown(seconds, block: block)
    }
    
    /// 设置毛玻璃效果，使用UIVisualEffectView。内容需要添加到UIVisualEffectView.contentView
    @discardableResult
    public func setBlurEffect(_ style: UIBlurEffect.Style) -> UIVisualEffectView? {
        return base.fw_setBlurEffect(style)
    }
    
    /// 移除所有子视图
    public func removeAllSubviews() {
        base.fw_removeAllSubviews()
    }

    /// 递归查找指定子类的第一个子视图(含自身)
    public func subview(of clazz: AnyClass) -> UIView? {
        return base.fw_subview(of: clazz)
    }

    /// 递归查找指定条件的第一个子视图(含自身)
    public func subview(block: @escaping (UIView) -> Bool) -> UIView? {
        return base.fw_subview(block: block)
    }
    
    /// 递归查找指定父类的第一个父视图(含自身)
    public func superview(of clazz: AnyClass) -> UIView? {
        return base.fw_superview(of: clazz)
    }
    
    /// 递归查找指定条件的第一个父视图(含自身)
    public func superview(block: @escaping (UIView) -> Bool) -> UIView? {
        return base.fw_superview(block: block)
    }

    /// 图片截图
    public var snapshotImage: UIImage? {
        return base.fw_snapshotImage
    }

    /// Pdf截图
    public var snapshotPdf: Data? {
        return base.fw_snapshotPdf
    }
    
    /// 将要设置的frame按照view的anchorPoint(.5, .5)处理后再设置，而系统默认按照(0, 0)方式计算
    public var frameApplyTransform: CGRect {
        get { return base.fw_frameApplyTransform }
        set { base.fw_frameApplyTransform = newValue }
    }
    
    /// 自定义视图排序索引，需结合sortSubviews使用，默认0不处理
    public var sortIndex: Int {
        get { return base.fw_sortIndex }
        set { base.fw_sortIndex = newValue }
    }

    /// 根据sortIndex排序subviews，需结合sortIndex使用
    public func sortSubviews() {
        base.fw_sortSubviews()
    }
    
    /// 是否显示灰色视图，仅支持iOS13+
    public var hasGrayView: Bool {
        return base.fw_hasGrayView
    }
    
    /// 显示灰色视图，仅支持iOS13+
    public func showGrayView() {
        return base.fw_showGrayView()
    }
    
    /// 隐藏灰色视图，仅支持iOS13+
    public func hideGrayView() {
        base.fw_hideGrayView()
    }
    
}

// MARK: - UIImageView+UIKit
extension Wrapper where Base: UIImageView {
    
    /// 设置图片模式为ScaleAspectFill，自动拉伸不变形，超过区域隐藏
    public func setContentModeAspectFill() {
        base.fw_setContentModeAspectFill()
    }
    
    /// 优化图片人脸显示，参考：https://github.com/croath/UIImageView-BetterFace
    public func faceAware() {
        base.fw_faceAware()
    }

    /// 倒影效果
    public func reflect() {
        base.fw_reflect()
    }

    /// 图片水印
    public func setImage(_ image: UIImage, watermarkImage: UIImage, in rect: CGRect) {
        base.fw_setImage(image, watermarkImage: watermarkImage, in: rect)
    }

    /// 文字水印，指定区域
    public func setImage(_ image: UIImage, watermarkString: NSAttributedString, in rect: CGRect) {
        base.fw_setImage(image, watermarkString: watermarkString, in: rect)
    }

    /// 文字水印，指定坐标
    public func setImage(_ image: UIImage, watermarkString: NSAttributedString, at point: CGPoint) {
        base.fw_setImage(image, watermarkString: watermarkString, at: point)
    }
    
}

// MARK: - UIWindow+UIKit
extension Wrapper where Base: UIWindow {
    
    /// 获取指定索引TabBar根视图控制器(非导航控制器)，找不到返回nil
    public func getTabBarController(index: Int) -> UIViewController? {
        return base.fw_getTabBarController(index: index)
    }
    
    /// 获取指定类TabBar根视图控制器(非导航控制器)，找不到返回nil
    public func getTabBarController(of clazz: AnyClass) -> UIViewController? {
        return base.fw_getTabBarController(of: clazz)
    }

    /// 获取指定条件TabBar根视图控制器(非导航控制器)，找不到返回nil
    public func getTabBarController(block: (UIViewController) -> Bool) -> UIViewController? {
        return base.fw_getTabBarController(block: block)
    }
    
    /// 选中并获取指定索引TabBar根视图控制器(非导航控制器)，找不到返回nil
    @discardableResult
    public func selectTabBarController(index: Int) -> UIViewController? {
        return base.fw_selectTabBarController(index: index)
    }

    /// 选中并获取指定类TabBar根视图控制器(非导航控制器)，找不到返回nil
    @discardableResult
    public func selectTabBarController(of clazz: AnyClass) -> UIViewController? {
        return base.fw_selectTabBarController(of: clazz)
    }

    /// 选中并获取指定条件TabBar根视图控制器(非导航控制器)，找不到返回nil
    @discardableResult
    public func selectTabBarController(block: (UIViewController) -> Bool) -> UIViewController? {
        return base.fw_selectTabBarController(block: block)
    }
    
}

// MARK: - UILabel+UIKit
extension Wrapper where Base: UILabel {
    
    /// 快速设置attributedText样式，设置后调用setText:会自动转发到setAttributedText:方法
    public var textAttributes: [NSAttributedString.Key: Any]? {
        get { return base.fw_textAttributes }
        set { base.fw_textAttributes = newValue }
    }

    /// 快速设置文字的行高，优先级低于fwTextAttributes，设置后调用setText:会自动转发到setAttributedText:方法。小于0时恢复默认行高
    public var lineHeight: CGFloat {
        get { return base.fw_lineHeight }
        set { base.fw_lineHeight = newValue }
    }

    /// 自定义内容边距，未设置时为系统默认。当内容为空时不参与intrinsicContentSize和sizeThatFits:计算，方便自动布局
    public var contentInset: UIEdgeInsets {
        get { return base.fw_contentInset }
        set { base.fw_contentInset = newValue }
    }

    /// 纵向分布方式，默认居中
    public var verticalAlignment: UIControl.ContentVerticalAlignment {
        get { return base.fw_verticalAlignment }
        set { base.fw_verticalAlignment = newValue }
    }
    
    /// 添加点击手势并自动识别NSLinkAttributeName|URL属性，点击高亮时回调链接，点击其它区域回调nil
    public func addLinkGesture(block: @escaping (Any?) -> Void) {
        base.fw_addLinkGesture(block: block)
    }
    
    /// 获取手势触发位置的文本属性，可实现行内点击效果等，allowsSpacing默认为NO空白处不可点击。为了识别更准确，attributedText需指定font
    public func attributes(
        gesture: UIGestureRecognizer,
        allowsSpacing: Bool
    ) -> [NSAttributedString.Key: Any] {
        return base.fw_attributes(gesture: gesture, allowsSpacing: allowsSpacing)
    }

    /// 快速设置标签并指定文本
    public func setFont(
        _ font: UIFont?,
        textColor: UIColor?,
        text: String? = nil,
        textAlignment: NSTextAlignment? = nil,
        numberOfLines: Int? = nil
    ) {
        base.fw_setFont(font, textColor: textColor, text: text, textAlignment: textAlignment, numberOfLines: numberOfLines)
    }
    
    /// 快速创建标签并指定文本
    public static func label(
        font: UIFont?,
        textColor: UIColor?,
        text: String? = nil,
        textAlignment: NSTextAlignment? = nil,
        numberOfLines: Int? = nil
    ) -> Base {
        return Base.fw_label(font: font, textColor: textColor, text: text, textAlignment: textAlignment, numberOfLines: numberOfLines)
    }
    
    /// 计算当前文本所占尺寸，需frame或者宽度布局完整
    public var textSize: CGSize {
        return base.fw_textSize
    }

    /// 计算当前属性文本所占尺寸，需frame或者宽度布局完整，attributedText需指定字体
    public var attributedTextSize: CGSize {
        return base.fw_attributedTextSize
    }
    
}

// MARK: - UIControl+UIKit
/// 防重复点击可以手工控制enabled或userInteractionEnabled或loading，如request开始时禁用，结束时启用等
extension Wrapper where Base: UIControl {
    
    // 设置Touch事件触发间隔，防止短时间多次触发事件，默认0
    public var touchEventInterval: TimeInterval {
        get { return base.fw_touchEventInterval }
        set { base.fw_touchEventInterval = newValue }
    }
    
}

// MARK: - UIButton+UIKit
extension Wrapper where Base: UIButton {
    
    /// 全局自定义按钮高亮时的alpha配置，默认0.5
    public static var highlightedAlpha: CGFloat {
        get { return Base.fw_highlightedAlpha }
        set { Base.fw_highlightedAlpha = newValue }
    }
    
    /// 全局自定义按钮禁用时的alpha配置，默认0.3
    public static var disabledAlpha: CGFloat {
        get { return Base.fw_disabledAlpha }
        set { Base.fw_disabledAlpha = newValue }
    }
    
    /// 自定义按钮禁用时的alpha，如0.3，默认0不生效
    public var disabledAlpha: CGFloat {
        get { return base.fw_disabledAlpha }
        set { base.fw_disabledAlpha = newValue }
    }

    /// 自定义按钮高亮时的alpha，如0.5，默认0不生效
    public var highlightedAlpha: CGFloat {
        get { return base.fw_highlightedAlpha }
        set { base.fw_highlightedAlpha = newValue }
    }
    
    /// 自定义按钮禁用状态改变时的句柄，默认nil
    public var disabledChanged: ((UIButton, Bool) -> Void)? {
        get { return base.fw_disabledChanged }
        set { base.fw_disabledChanged = newValue }
    }

    /// 自定义按钮高亮状态改变时的句柄，默认nil
    public var highlightedChanged: ((UIButton, Bool) -> Void)? {
        get { return base.fw_highlightedChanged }
        set { base.fw_highlightedChanged = newValue }
    }

    /// 快速设置文本按钮
    public func setTitle(_ title: String?, font: UIFont?, titleColor: UIColor?) {
        base.fw_setTitle(title, font: font, titleColor: titleColor)
    }

    /// 快速设置文本
    public func setTitle(_ title: String?) {
        base.fw_setTitle(title)
    }

    /// 快速设置图片
    public func setImage(_ image: UIImage?) {
        base.fw_setImage(image)
    }

    /// 设置图片的居中边位置，需要在setImage和setTitle之后调用才生效，且button大小大于图片+文字+间距
    ///
    /// imageEdgeInsets: 仅有image时相对于button，都有时上左下相对于button，右相对于title
    /// titleEdgeInsets: 仅有title时相对于button，都有时上右下相对于button，左相对于image
    public func setImageEdge(_ edge: UIRectEdge, spacing: CGFloat) {
        base.fw_setImageEdge(edge, spacing: spacing)
    }
    
    /// 设置状态背景色
    public func setBackgroundColor(_ backgroundColor: UIColor?, for state: UIControl.State) {
        base.fw_setBackgroundColor(backgroundColor, for: state)
    }
    
    /// 快速创建文本按钮
    public static func button(title: String?, font: UIFont?, titleColor: UIColor?) -> Base {
        return Base.fw_button(title: title, font: font, titleColor: titleColor)
    }

    /// 快速创建图片按钮
    public static func button(image: UIImage?) -> Base {
        return Base.fw_button(image: image)
    }
    
    /// 设置按钮倒计时，从window移除时自动取消。等待时按钮disabled，非等待时enabled。时间支持格式化，示例：重新获取(%lds)
    @discardableResult
    public func startCountDown(_ seconds: Int, title: String, waitTitle: String) -> DispatchSourceTimer {
        return base.fw_startCountDown(seconds, title: title, waitTitle: waitTitle)
    }
    
}

// MARK: - UIScrollView+UIKit
extension Wrapper where Base: UIScrollView {
    
    /// 判断当前scrollView内容是否足够滚动
    public var canScroll: Bool {
        return base.fw_canScroll
    }

    /// 判断当前的scrollView内容是否足够水平滚动
    public var canScrollHorizontal: Bool {
        return base.fw_canScrollHorizontal
    }

    /// 判断当前的scrollView内容是否足够纵向滚动
    public var canScrollVertical: Bool {
        return base.fw_canScrollVertical
    }

    /// 当前scrollView滚动到指定边
    public func scroll(to edge: UIRectEdge, animated: Bool = true) {
        base.fw_scroll(to: edge, animated: animated)
    }

    /// 是否已滚动到指定边
    public func isScroll(to edge: UIRectEdge) -> Bool {
        return base.fw_isScroll(to: edge)
    }

    /// 获取当前的scrollView滚动到指定边时的contentOffset(包含contentInset)
    public func contentOffset(of edge: UIRectEdge) -> CGPoint {
        return base.fw_contentOffset(of: edge)
    }

    /// 总页数，自动识别翻页方向
    public var totalPage: Int {
        return base.fw_totalPage
    }

    /// 当前页数，不支持动画，自动识别翻页方向
    public var currentPage: Int {
        get { return base.fw_currentPage }
        set { base.fw_currentPage = newValue }
    }

    /// 设置当前页数，支持动画，自动识别翻页方向
    public func setCurrentPage(_ page: Int, animated: Bool = true) {
        base.fw_setCurrentPage(page, animated: animated)
    }

    /// 是否是最后一页，自动识别翻页方向
    public var isLastPage: Bool {
        return base.fw_isLastPage
    }
    
    /// 快捷设置contentOffset.x
    public var contentOffsetX: CGFloat {
        get { return base.fw_contentOffsetX }
        set { base.fw_contentOffsetX = newValue }
    }

    /// 快捷设置contentOffset.y
    public var contentOffsetY: CGFloat {
        get { return base.fw_contentOffsetY }
        set { base.fw_contentOffsetY = newValue }
    }
    
    /// 内容视图，子视图需添加到本视图，布局约束完整时可自动滚动
    public var contentView: UIView {
        return base.fw_contentView
    }
    
    /**
     设置自动布局视图悬停到指定父视图固定位置，在scrollViewDidScroll:中调用即可
     
     @param view 需要悬停的视图，须占满fromSuperview
     @param fromSuperview 起始的父视图，须是scrollView的子视图
     @param toSuperview 悬停的目标视图，须是scrollView的父级视图，一般控制器self.view
     @param toPosition 需要悬停的目标位置，相对于toSuperview的originY位置
     @return 相对于悬浮位置的距离，可用来设置导航栏透明度等
     */
    @discardableResult
    public func hoverView(_ view: UIView, fromSuperview: UIView, toSuperview: UIView, toPosition: CGFloat) -> CGFloat {
        return base.fw_hoverView(view, fromSuperview: fromSuperview, toSuperview: toSuperview, toPosition: toPosition)
    }
    
    /// 是否开始识别pan手势
    public var shouldBegin: ((UIGestureRecognizer) -> Bool)? {
        get { return base.fw_shouldBegin }
        set { base.fw_shouldBegin = newValue }
    }

    /// 是否允许同时识别多个手势
    public var shouldRecognizeSimultaneously: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get { return base.fw_shouldRecognizeSimultaneously }
        set { base.fw_shouldRecognizeSimultaneously = newValue }
    }

    /// 是否另一个手势识别失败后，才能识别pan手势
    public var shouldRequireFailure: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get { return base.fw_shouldRequireFailure }
        set { base.fw_shouldRequireFailure = newValue }
    }

    /// 是否pan手势识别失败后，才能识别另一个手势
    public var shouldBeRequiredToFail: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get { return base.fw_shouldBeRequiredToFail }
        set { base.fw_shouldBeRequiredToFail = newValue }
    }
    
}

// MARK: - UIGestureRecognizer+UIKit
/// gestureRecognizerShouldBegin：是否继续进行手势识别，默认YES
/// shouldRecognizeSimultaneouslyWithGestureRecognizer: 是否支持多手势触发。默认NO
/// shouldRequireFailureOfGestureRecognizer：是否otherGestureRecognizer触发失败时，才开始触发gestureRecognizer。返回YES，第一个手势失败
/// shouldBeRequiredToFailByGestureRecognizer：在otherGestureRecognizer识别其手势之前，是否gestureRecognizer必须触发失败。返回YES，第二个手势失败
extension Wrapper where Base: UIGestureRecognizer {
    
    /// 获取手势直接作用的view，不同于view，此处是view的subview
    public weak var targetView: UIView? {
        return base.fw_targetView
    }

    /// 是否正在拖动中：Began || Changed
    public var isTracking: Bool {
        return base.fw_isTracking
    }

    /// 是否是激活状态: isEnabled && (Began || Changed)
    public var isActive: Bool {
        return base.fw_isActive
    }
    
    /// 判断手势是否正作用于指定视图
    public func hitTest(view: UIView?) -> Bool {
        return base.fw_hitTest(view: view)
    }
    
}

// MARK: - UIPanGestureRecognizer+UIKit
extension Wrapper where Base: UIPanGestureRecognizer {
    
    /// 当前滑动方向，如果多个方向滑动，取绝对值较大的一方，失败返回0
    public var swipeDirection: UISwipeGestureRecognizer.Direction {
        return base.fw_swipeDirection
    }

    /// 当前滑动进度，滑动绝对值相对于手势视图的宽或高
    public var swipePercent: CGFloat {
        return base.fw_swipePercent
    }

    /// 计算指定方向的滑动进度
    public func swipePercent(of direction: UISwipeGestureRecognizer.Direction) -> CGFloat {
        return base.fw_swipePercent(of: direction)
    }
    
}

// MARK: - UIPageControl+UIKit
extension Wrapper where Base: UIPageControl {
    
    /// 自定义圆点大小，默认{10, 10}
    public var preferredSize: CGSize {
        get { return base.fw_preferredSize }
        set { base.fw_preferredSize = newValue }
    }
    
}

// MARK: - UISlider+UIKit
extension Wrapper where Base: UISlider {
    
    /// 中间圆球的大小，默认zero
    public var thumbSize: CGSize {
        get { return base.fw_thumbSize }
        set { base.fw_thumbSize = newValue }
    }

    /// 中间圆球的颜色，默认nil
    public var thumbColor: UIColor? {
        get { return base.fw_thumbColor }
        set { base.fw_thumbColor = newValue }
    }
    
}

// MARK: - UISwitch+UIKit
extension Wrapper where Base: UISwitch {
    
    /// 自定义尺寸大小，默认{51,31}
    public var preferredSize: CGSize {
        get { return base.fw_preferredSize }
        set { base.fw_preferredSize = newValue }
    }
    
}

// MARK: - UITextField+UIKit
extension Wrapper where Base: UITextField {
    
    /// 最大字数限制，0为无限制，二选一
    public var maxLength: Int {
        get { return base.fw_maxLength }
        set { base.fw_maxLength = newValue }
    }

    /// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
    public var maxUnicodeLength: Int {
        get { return base.fw_maxUnicodeLength }
        set { base.fw_maxUnicodeLength = newValue }
    }
    
    /// 自定义文字改变处理句柄，自动trimString，默认nil
    public var textChangedBlock: ((String) -> Void)? {
        get { return base.fw_textChangedBlock }
        set { base.fw_textChangedBlock = newValue }
    }

    /// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
    public func textLengthChanged() {
        base.fw_textLengthChanged()
    }

    /// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
    public func filterText(_ text: String) -> String {
        return base.fw_filterText(text)
    }

    /// 设置自动完成时间间隔，默认0.5秒，和autoCompleteBlock配套使用
    public var autoCompleteInterval: TimeInterval {
        get { return base.fw_autoCompleteInterval }
        set { base.fw_autoCompleteInterval = newValue }
    }

    /// 设置自动完成处理句柄，自动trimString，默认nil，注意输入框内容为空时会立即触发
    public var autoCompleteBlock: ((String) -> Void)? {
        get { return base.fw_autoCompleteBlock }
        set { base.fw_autoCompleteBlock = newValue }
    }
    
    /// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
    public var menuDisabled: Bool {
        get { return base.fw_menuDisabled }
        set { base.fw_menuDisabled = newValue }
    }

    /// 自定义光标偏移和大小，不为0才会生效，默认zero不生效
    public var cursorRect: CGRect {
        get { return base.fw_cursorRect }
        set { base.fw_cursorRect = newValue }
    }

    /// 获取及设置当前选中文字范围
    public var selectedRange: NSRange {
        get { return base.fw_selectedRange }
        set { base.fw_selectedRange = newValue }
    }

    /// 移动光标到最后
    public func selectAllRange() {
        base.fw_selectAllRange()
    }

    /// 移动光标到指定位置，兼容动态text赋值
    public func moveCursor(_ offset: Int) {
        base.fw_moveCursor(offset)
    }
    
}

// MARK: - UITextView+UIKit
extension Wrapper where Base: UITextView {
    
    /// 最大字数限制，0为无限制，二选一
    public var maxLength: Int {
        get { return base.fw_maxLength }
        set { base.fw_maxLength = newValue }
    }

    /// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
    public var maxUnicodeLength: Int {
        get { return base.fw_maxUnicodeLength }
        set { base.fw_maxUnicodeLength = newValue }
    }
    
    /// 自定义文字改变处理句柄，自动trimString，默认nil
    public var textChangedBlock: ((String) -> Void)? {
        get { return base.fw_textChangedBlock }
        set { base.fw_textChangedBlock = newValue }
    }

    /// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
    public func textLengthChanged() {
        base.fw_textLengthChanged()
    }

    /// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
    public func filterText(_ text: String) -> String {
        return base.fw_filterText(text)
    }

    /// 设置自动完成时间间隔，默认0.5秒，和autoCompleteBlock配套使用
    public var autoCompleteInterval: TimeInterval {
        get { return base.fw_autoCompleteInterval }
        set { base.fw_autoCompleteInterval = newValue }
    }

    /// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
    public var autoCompleteBlock: ((String) -> Void)? {
        get { return base.fw_autoCompleteBlock }
        set { base.fw_autoCompleteBlock = newValue }
    }
    
    /// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
    public var menuDisabled: Bool {
        get { return base.fw_menuDisabled }
        set { base.fw_menuDisabled = newValue }
    }

    /// 自定义光标偏移和大小，不为0才会生效，默认zero不生效
    public var cursorRect: CGRect {
        get { return base.fw_cursorRect }
        set { base.fw_cursorRect = newValue }
    }

    /// 获取及设置当前选中文字范围
    public var selectedRange: NSRange {
        get { return base.fw_selectedRange }
        set { base.fw_selectedRange = newValue }
    }

    /// 移动光标到最后
    public func selectAllRange() {
        base.fw_selectAllRange()
    }

    /// 移动光标到指定位置，兼容动态text赋值
    public func moveCursor(_ offset: Int) {
        base.fw_moveCursor(offset)
    }

    /// 计算当前文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整
    public var textSize: CGSize {
        return base.fw_textSize
    }

    /// 计算当前属性文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整，attributedText需指定字体
    public var attributedTextSize: CGSize {
        return base.fw_attributedTextSize
    }
    
}

// MARK: - UITableView+UIKit
extension Wrapper where Base: UITableView {
    
    /// 全局清空TableView默认多余边距
    public static func resetTableStyle() {
        Base.fw_resetTableStyle()
    }
    
    /// 是否启动高度估算布局，启用后需要子视图布局完整，无需实现heightForRow方法(iOS11默认启用，会先cellForRow再heightForRow)
    public var estimatedLayout: Bool {
        get { return base.fw_estimatedLayout }
        set { base.fw_estimatedLayout = newValue }
    }
    
    /// 清除Grouped等样式默认多余边距，注意CGFLOAT_MIN才会生效，0不会生效
    public func resetTableStyle() {
        base.fw_resetTableStyle()
    }
    
    /// 配置全局resetTableStyle钩子句柄，默认nil
    public static var resetTableConfiguration: ((UITableView) -> Void)? {
        get { Base.fw_resetTableConfiguration }
        set { Base.fw_resetTableConfiguration = newValue }
    }
    
    /// reloadData完成回调
    public func reloadData(completion: (() -> Void)?) {
        base.fw_reloadData(completion: completion)
    }
    
    /// reloadData禁用动画
    public func reloadDataWithoutAnimation() {
        base.fw_reloadDataWithoutAnimation()
    }
    
    /// 简单曝光方案，willDisplay调用即可，表格快速滑动、数据不变等情况不计曝光。如需完整曝光方案，请使用StatisticalView
    public func willDisplay(_ cell: UITableViewCell, at indexPath: IndexPath, key: AnyHashable? = nil, exposure: @escaping () -> Void) {
        base.fw_willDisplay(cell, at: indexPath, key: key, exposure: exposure)
    }
    
}

// MARK: - UITableViewCell+UIKit
extension Wrapper where Base: UITableViewCell {
    
    /// 设置分割线内边距，iOS8+默认15.f，设为UIEdgeInsetsZero可去掉
    public var separatorInset: UIEdgeInsets {
        get { return base.fw_separatorInset }
        set { base.fw_separatorInset = newValue }
    }
    
    /// 调整imageView的位置偏移，默认zero不生效，仅支持default|subtitle样式
    public var imageEdgeInsets: UIEdgeInsets {
        get { return base.fw_imageEdgeInsets }
        set { base.fw_imageEdgeInsets = newValue }
    }
    
    /// 调整textLabel的位置偏移，默认zero不生效，仅支持default|subtitle样式
    public var textEdgeInsets: UIEdgeInsets {
        get { return base.fw_textEdgeInsets }
        set { base.fw_textEdgeInsets = newValue }
    }
    
    /// 调整detailTextLabel的位置偏移，默认zero不生效，仅支持subtitle样式
    public var detailTextEdgeInsets: UIEdgeInsets {
        get { return base.fw_detailTextEdgeInsets }
        set { base.fw_detailTextEdgeInsets = newValue }
    }
    
    /// 调整accessoryView的位置偏移，默认zero不生效，仅对自定义accessoryView生效
    public var accessoryEdgeInsets: UIEdgeInsets {
        get { return base.fw_accessoryEdgeInsets }
        set { base.fw_accessoryEdgeInsets = newValue }
    }

    /// 获取当前所属tableView
    public weak var tableView: UITableView? {
        return base.fw_tableView
    }

    /// 获取当前显示indexPath
    public var indexPath: IndexPath? {
        return base.fw_indexPath
    }
    
}

// MARK: - UICollectionView+UIKit
extension Wrapper where Base: UICollectionView {
    
    /// reloadData完成回调
    public func reloadData(completion: (() -> Void)?) {
        base.fw_reloadData(completion: completion)
    }
    
    /// reloadData禁用动画
    public func reloadDataWithoutAnimation() {
        base.fw_reloadDataWithoutAnimation()
    }
    
    /// 计算指定indexPath的frame，并转换为指定视图坐标(nil时默认window)
    public func layoutFrame(at indexPath: IndexPath, to view: UIView?) -> CGRect? {
        return base.fw_layoutFrame(at: indexPath, to: view)
    }
    
    /// 添加拖动排序手势，需结合canMove、moveItem、targetIndexPath使用
    @discardableResult
    public func addMovementGesture(customBlock: ((UILongPressGestureRecognizer) -> Bool)? = nil) -> UILongPressGestureRecognizer {
        return base.fw_addMovementGesture(customBlock: customBlock)
    }
    
    /// 简单曝光方案，willDisplay调用即可，集合快速滑动、数据不变等情况不计曝光。如需完整曝光方案，请使用StatisticalView
    public func willDisplay(_ cell: UICollectionViewCell, at indexPath: IndexPath, key: AnyHashable? = nil, exposure: @escaping () -> Void) {
        base.fw_willDisplay(cell, at: indexPath, key: key, exposure: exposure)
    }
    
}

// MARK: - UICollectionViewCell+UIKit
extension Wrapper where Base: UICollectionViewCell {
    
    /// 获取当前所属collectionView
    public weak var collectionView: UICollectionView? {
        return base.fw_collectionView
    }

    /// 获取当前显示indexPath
    public var indexPath: IndexPath? {
        return base.fw_indexPath
    }
    
}

// MARK: - UISearchBar+UIKit
extension Wrapper where Base: UISearchBar {
    
    /// 自定义内容边距，可调整左右距离和TextField高度，未设置时为系统默认
    ///
    /// 如需设置UISearchBar为navigationItem.titleView，请使用ExpandedTitleView
    public var contentInset: UIEdgeInsets {
        get { return base.fw_contentInset }
        set { base.fw_contentInset = newValue }
    }

    /// 自定义取消按钮边距，未设置时为系统默认
    public var cancelButtonInset: UIEdgeInsets {
        get { return base.fw_cancelButtonInset }
        set { base.fw_cancelButtonInset = newValue }
    }

    /// 输入框内部视图
    public var textField: UISearchTextField {
        return base.fw_textField
    }

    /// 取消按钮内部视图，showsCancelButton开启后才存在
    public weak var cancelButton: UIButton? {
        return base.fw_cancelButton
    }

    /// 设置整体背景色
    public var backgroundColor: UIColor? {
        get { return base.fw_backgroundColor }
        set { base.fw_backgroundColor = newValue }
    }

    /// 设置输入框背景色
    public var textFieldBackgroundColor: UIColor? {
        get { return base.fw_textFieldBackgroundColor }
        set { base.fw_textFieldBackgroundColor = newValue }
    }

    /// 设置搜索图标离左侧的偏移位置，非居中时生效
    public var searchIconOffset: CGFloat {
        get { return base.fw_searchIconOffset }
        set { base.fw_searchIconOffset = newValue }
    }
    
    /// 设置清空图标离右侧的偏移位置
    public var clearIconOffset: CGFloat {
        get { return base.fw_clearIconOffset }
        set { base.fw_clearIconOffset = newValue }
    }

    /// 设置搜索文本离左侧图标的偏移位置
    public var searchTextOffset: CGFloat {
        get { return base.fw_searchTextOffset }
        set { base.fw_searchTextOffset = newValue }
    }

    /// 设置TextField搜索图标(placeholder)是否居中，否则居左
    public var searchIconCenter: Bool {
        get { return base.fw_searchIconCenter }
        set { base.fw_searchIconCenter = newValue }
    }

    /// 强制取消按钮一直可点击，需在showsCancelButton设置之后生效。默认SearchBar失去焦点之后取消按钮不可点击
    public var forceCancelButtonEnabled: Bool {
        get { return base.fw_forceCancelButtonEnabled }
        set { base.fw_forceCancelButtonEnabled = newValue }
    }
    
}

// MARK: - UIViewController+UIKit
extension Wrapper where Base: UIViewController {
    
    /// 判断当前控制器是否是头部控制器。如果是导航栏的第一个控制器或者不含有导航栏，则返回YES
    public var isHead: Bool {
        return base.fw_isHead
    }
    
    /// 判断当前控制器是否是尾部控制器。如果是导航栏的最后一个控制器或者不含有导航栏，则返回YES
    public var isTail: Bool {
        return base.fw_isTail
    }

    /// 判断当前控制器是否是子控制器。如果父控制器存在，且不是导航栏或标签栏控制器，则返回YES
    public var isChild: Bool {
        return base.fw_isChild
    }

    /// 判断当前控制器是否是present弹出。如果是导航栏的第一个控制器且导航栏是present弹出，也返回YES
    public var isPresented: Bool {
        return base.fw_isPresented
    }

    /// 判断当前控制器是否是iOS13+默认pageSheet弹出样式。该样式下导航栏高度等与默认样式不同
    public var isPageSheet: Bool {
        return base.fw_isPageSheet
    }

    /// 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
    public var isViewVisible: Bool {
        return base.fw_isViewVisible
    }
    
    /// 控制器是否可见，视图可见、尾部控制器、且不含presented控制器时为YES
    public var isVisible: Bool {
        return base.fw_isVisible
    }
    
    /// 获取祖先视图，标签栏存在时为标签栏根视图，导航栏存在时为导航栏根视图，否则为控制器根视图
    public var ancestorView: UIView {
        return base.fw_ancestorView
    }

    /// 是否已经加载完数据，默认NO，加载数据完成后可标记为YES，可用于第一次加载时显示loading等判断
    public var isDataLoaded: Bool {
        get { return base.fw_isDataLoaded }
        set { base.fw_isDataLoaded = newValue }
    }
    
    /// 移除子控制器，解决不能触发viewWillAppear等的bug
    public func removeChild(_ viewController: UIViewController) {
        base.fw_removeChild(viewController)
    }
    
    /// 添加子控制器到当前视图，解决不能触发viewWillAppear等的bug
    public func addChild(_ viewController: UIViewController, layout: ((UIView) -> Void)? = nil) {
        base.fw_addChild(viewController, layout: layout)
    }

    /// 添加子控制器到指定视图，解决不能触发viewWillAppear等的bug
    public func addChild(_ viewController: UIViewController, in view: UIView?, layout: ((UIView) -> Void)? = nil) {
        base.fw_addChild(viewController, in: view, layout: layout)
    }
    
}
