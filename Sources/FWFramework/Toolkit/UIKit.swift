//
//  UIKit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
import CoreTelephony

// MARK: - Wrapper+UIBezierPath
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

// MARK: - Wrapper+UIDevice
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
    
    /// 手机蜂窝网络类型列表，仅区分2G|3G|4G|5G
    public static var networkTypes: [String]? {
        return Base.fw_networkTypes
    }
}

// MARK: - Wrapper+UIView
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

// MARK: - Wrapper+UIImageView
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

// MARK: - Wrapper+UIWindow
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

// MARK: - Wrapper+UILabel
extension Wrapper where Base: UILabel {
    /// 快速设置attributedText样式，设置后调用setText:会自动转发到setAttributedText:方法
    public var textAttributes: [NSAttributedString.Key: Any]? {
        get { return base.fw_textAttributes }
        set { base.fw_textAttributes = newValue }
    }

    /// 快速设置文字的行高，优先级低于fwTextAttributes，设置后调用setText:会自动转发到setAttributedText:方法。小于等于0时恢复默认行高
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
        numberOfLines: Int? = nil,
        lineHeight: CGFloat? = nil
    ) {
        base.fw_setFont(font, textColor: textColor, text: text, textAlignment: textAlignment, numberOfLines: numberOfLines, lineHeight: lineHeight)
    }
    
    /// 快速创建标签并指定文本
    public static func label(
        font: UIFont?,
        textColor: UIColor?,
        text: String? = nil,
        textAlignment: NSTextAlignment? = nil,
        numberOfLines: Int? = nil,
        lineHeight: CGFloat? = nil
    ) -> Base {
        return Base.fw_label(font: font, textColor: textColor, text: text, textAlignment: textAlignment, numberOfLines: numberOfLines, lineHeight: lineHeight)
    }
    
    /// 自适应字体大小，可设置缩放因子等
    public func adjustsFontSize(
        minimumScaleFactor: CGFloat? = nil,
        baselineAdjustment: UIBaselineAdjustment? = nil
    ) {
        base.fw_adjustsFontSize(minimumScaleFactor: minimumScaleFactor, baselineAdjustment: baselineAdjustment)
    }
    
    /// 获取当前标签是否非空，兼容attributedText|text
    public var isNotEmpty: Bool {
        return base.fw_isNotEmpty
    }
    
    /// 计算当前标签实际显示行数，兼容contentInset|lineHeight
    public var actualNumberOfLines: Int {
        return base.fw_actualNumberOfLines
    }
    
    /// 计算指定边界、内边距、行高、行数时，当前标签实际显示行数
    public func actualNumberOfLines(drawSize: CGSize, contentInset: UIEdgeInsets? = nil, lineHeight: CGFloat? = nil, numberOfLines: Int? = nil) -> Int {
        return base.fw_actualNumberOfLines(drawSize: drawSize, contentInset: contentInset, lineHeight: lineHeight, numberOfLines: numberOfLines)
    }
    
    /// 计算当前文本所占尺寸，需frame或者宽度布局完整
    public var textSize: CGSize {
        return base.fw_textSize
    }
    
    /// 计算指定边界时，当前文本所占尺寸
    public func textSize(drawSize: CGSize, contentInset: UIEdgeInsets? = nil) -> CGSize {
        return base.fw_textSize(drawSize: drawSize, contentInset: contentInset)
    }

    /// 计算当前属性文本所占尺寸，需frame或者宽度布局完整，attributedText需指定字体
    public var attributedTextSize: CGSize {
        return base.fw_attributedTextSize
    }

    /// 计算指定边界时，当前属性文本所占尺寸，attributedText需指定字体
    public func attributedTextSize(drawSize: CGSize, contentInset: UIEdgeInsets? = nil) -> CGSize {
        return base.fw_attributedTextSize(drawSize: drawSize, contentInset: contentInset)
    }
}

// MARK: - Wrapper+UIControl
/// 防重复点击可以手工控制enabled或userInteractionEnabled或loading，如request开始时禁用，结束时启用等
extension Wrapper where Base: UIControl {
    // 设置Touch事件触发间隔，防止短时间多次触发事件，默认0
    public var touchEventInterval: TimeInterval {
        get { return base.fw_touchEventInterval }
        set { base.fw_touchEventInterval = newValue }
    }
}

// MARK: - Wrapper+UIButton
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
    
    /// 图文模式时自适应粗体文本，解决图文按钮文本显示不全(...)的兼容性问题
    public func adjustBoldText() {
        base.fw_adjustBoldText()
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

// MARK: - Wrapper+UIScrollView
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
    
    /// 滚动视图完整图片截图
    public var contentSnapshot: UIImage? {
        return base.fw_contentSnapshot
    }
    
    /// 内容视图，子视图需添加到本视图，布局约束完整时可自动滚动
    ///
    /// 当启用等比例缩放布局、且scrollView和contentView都固定高度时，
    /// 为防止浮点数误差导致scrollView拖拽时出现纵向可滚动的兼容问题，解决方案如下：
    /// 1. 设置scrollView属性isDirectionalLockEnabled为true
    /// 2. 设置布局高度为固定ceil高度，如：FW.fixed(ceil(FW.relative(40)))
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

// MARK: - Wrapper+UIGestureRecognizer
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

// MARK: - Wrapper+UIPanGestureRecognizer
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

// MARK: - Wrapper+UIPageControl
extension Wrapper where Base: UIPageControl {
    /// 自定义圆点大小，默认{10, 10}
    public var preferredSize: CGSize {
        get { return base.fw_preferredSize }
        set { base.fw_preferredSize = newValue }
    }
}

// MARK: - Wrapper+UISlider
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

// MARK: - Wrapper+UISwitch
extension Wrapper where Base: UISwitch {
    /// 自定义尺寸大小，默认{51,31}
    public var preferredSize: CGSize {
        get { return base.fw_preferredSize }
        set { base.fw_preferredSize = newValue }
    }
    
    /// 自定义关闭时除圆点外的背景色
    public var offTintColor: UIColor? {
        get { return base.fw_offTintColor }
        set { base.fw_offTintColor = newValue }
    }
}

// MARK: - Wrapper+UITextField
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

// MARK: - Wrapper+UITextView
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
    
    /// 计算指定边界时，当前文本所占尺寸，包含textContainerInset
    public func textSize(drawSize: CGSize, contentInset: UIEdgeInsets? = nil) -> CGSize {
        return base.fw_textSize(drawSize: drawSize, contentInset: contentInset)
    }

    /// 计算当前属性文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整，attributedText需指定字体
    public var attributedTextSize: CGSize {
        return base.fw_attributedTextSize
    }

    /// 计算指定边界时，当前属性文本所占尺寸，包含textContainerInset，attributedText需指定字体
    public func attributedTextSize(drawSize: CGSize, contentInset: UIEdgeInsets? = nil) -> CGSize {
        return base.fw_attributedTextSize(drawSize: drawSize, contentInset: contentInset)
    }
    
    /// 快捷设置行高，兼容placeholder和typingAttributes。小于等于0时恢复默认行高
    public var lineHeight: CGFloat {
        get { return base.fw_lineHeight }
        set { base.fw_lineHeight = newValue }
    }
    
    /// 获取当前文本框是否非空，兼容attributedText|text
    public var isNotEmpty: Bool {
        return base.fw_isNotEmpty
    }
    
    /// 计算当前文本框实际显示行数，兼容textContainerInset|lineHeight
    public var actualNumberOfLines: Int {
        return base.fw_actualNumberOfLines
    }
    
    /// 计算指定边界、内边距、行高时，当前文本框实际显示行数
    public func actualNumberOfLines(drawSize: CGSize, contentInset: UIEdgeInsets? = nil, lineHeight: CGFloat? = nil) -> Int {
        return base.fw_actualNumberOfLines(drawSize: drawSize, contentInset: contentInset, lineHeight: lineHeight)
    }
}

// MARK: - Wrapper+UITableView
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
    
    /// 判断indexPath是否有效
    public func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        return base.fw_isValidIndexPath(indexPath)
    }
    
    /// 简单曝光方案，willDisplay调用即可，表格快速滑动、数据不变等情况不计曝光。如需完整曝光方案，请使用StatisticalView
    public func willDisplay(_ cell: UITableViewCell, at indexPath: IndexPath, key: AnyHashable? = nil, exposure: @escaping () -> Void) {
        base.fw_willDisplay(cell, at: indexPath, key: key, exposure: exposure)
    }
}

// MARK: - Wrapper+UITableViewCell
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
    
    /// 执行所属tableView的批量更新
    public func performBatchUpdates(
        _ updates: ((UITableView, IndexPath?) -> Void)?,
        completion: ((UITableView, IndexPath?, Bool) -> Void)? = nil
    ) {
        base.fw_performBatchUpdates(updates, completion: completion)
    }
}

// MARK: - Wrapper+UICollectionView
extension Wrapper where Base: UICollectionView {
    /// reloadData完成回调
    public func reloadData(completion: (() -> Void)?) {
        base.fw_reloadData(completion: completion)
    }
    
    /// reloadData禁用动画
    public func reloadDataWithoutAnimation() {
        base.fw_reloadDataWithoutAnimation()
    }
    
    /// 判断indexPath是否有效
    public func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        return base.fw_isValidIndexPath(indexPath)
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

// MARK: - Wrapper+UICollectionViewCell
extension Wrapper where Base: UICollectionViewCell {
    /// 获取当前所属collectionView
    public weak var collectionView: UICollectionView? {
        return base.fw_collectionView
    }

    /// 获取当前显示indexPath
    public var indexPath: IndexPath? {
        return base.fw_indexPath
    }
    
    /// 执行所属collectionView的批量更新
    public func performBatchUpdates(
        _ updates: ((UICollectionView, IndexPath?) -> Void)?,
        completion: ((UICollectionView, IndexPath?, Bool) -> Void)? = nil
    ) {
        base.fw_performBatchUpdates(updates, completion: completion)
    }
}

// MARK: - Wrapper+UISearchBar
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
    
    /// 输入框的文字颜色
    public var textColor: UIColor? {
        get { return base.fw_textColor }
        set { base.fw_textColor = newValue }
    }
    
    /// 输入框的字体，会同时影响placeholder的字体
    public var font: UIFont? {
        get { return base.fw_font }
        set { base.fw_font = newValue }
    }
    
    /// 输入框内placeholder的颜色
    public var placeholderColor: UIColor? {
        get { return base.fw_placeholderColor }
        set { base.fw_placeholderColor = newValue }
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

// MARK: - Wrapper+UIViewController
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
    
    /// 弹出popover控制器
    public func presentPopover(
        _ popover: UIViewController,
        sourcePoint: CGPoint,
        size: CGSize? = nil,
        delegate: (any UIPopoverPresentationControllerDelegate)? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        base.fw_presentPopover(popover, sourcePoint: sourcePoint, size: size, delegate: delegate, animated: animated, completion: completion)
    }
}

// MARK: - UIBezierPath+UIKit
@_spi(FW) extension UIBezierPath {
    
    /// 绘制形状图片，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
    public func fw_shapeImage(_ size: CGSize, strokeWidth: CGFloat, strokeColor: UIColor, fillColor: UIColor?) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setLineWidth(strokeWidth)
        context.setLineCap(.round)
        strokeColor.setStroke()
        context.addPath(self.cgPath)
        context.strokePath()
        
        if let fillColor = fillColor {
            fillColor.setFill()
            context.addPath(self.cgPath)
            context.fillPath()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 绘制形状Layer，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
    public func fw_shapeLayer(_ rect: CGRect, strokeWidth: CGFloat, strokeColor: UIColor, fillColor: UIColor?) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.frame = rect
        layer.lineWidth = strokeWidth
        layer.lineCap = .round
        layer.strokeColor = strokeColor.cgColor
        if let fillColor = fillColor {
            layer.fillColor = fillColor.cgColor
        }
        layer.path = self.cgPath
        return layer
    }

    /// 根据点计算折线路径(NSValue点)
    public static func fw_lines(points: [NSValue]) -> UIBezierPath {
        let path = UIBezierPath()
        var value = points.first ?? NSValue(cgPoint: .zero)
        path.move(to: value.cgPointValue)
        
        for i in 1 ..< points.count {
            value = points[i]
            path.addLine(to: value.cgPointValue)
        }
        return path
    }

    /// 根据点计算贝塞尔曲线路径
    public static func fw_quadCurvedPath(points: [NSValue]) -> UIBezierPath {
        let path = UIBezierPath()
        var value = points.first ?? NSValue(cgPoint: .zero)
        var p1 = value.cgPointValue
        path.move(to: p1)
        
        if points.count == 2 {
            value = points[1]
            path.addLine(to: value.cgPointValue)
            return path
        }
        
        for i in 1 ..< points.count {
            value = points[i]
            let p2 = value.cgPointValue
            
            let midPoint = fw_middlePoint(p1, with: p2)
            path.addQuadCurve(to: midPoint, controlPoint: fw_controlPoint(midPoint, with: p1))
            path.addQuadCurve(to: p2, controlPoint: fw_controlPoint(midPoint, with: p2))
            
            p1 = p2
        }
        return path
    }
    
    /// 计算两点的中心点
    public static func fw_middlePoint(_ p1: CGPoint, with p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2.0, y: (p1.y + p2.y) / 2.0)
    }

    /// 计算两点的贝塞尔曲线控制点
    public static func fw_controlPoint(_ p1: CGPoint, with p2: CGPoint) -> CGPoint {
        var controlPoint = fw_middlePoint(p1, with: p2)
        let diffY = abs(p2.y - controlPoint.y)
        if p1.y < p2.y {
            controlPoint.y += diffY
        } else if p1.y > p2.y {
            controlPoint.y -= diffY
        }
        return controlPoint
    }
    
    /// 将角度(0~360)转换为弧度，周长为2*M_PI*r
    public static func fw_radian(degree: CGFloat) -> CGFloat {
        return (CGFloat.pi * degree) / 180.0
    }
    
    /// 将弧度转换为角度(0~360)
    public static func fw_degree(radian: CGFloat) -> CGFloat {
        return (radian * 180.0) / CGFloat.pi
    }
    
    /// 根据滑动方向计算rect的线段起点、终点中心点坐标数组(示范：田)。默认从上到下滑动
    public static func fw_linePoints(rect: CGRect, direction: UISwipeGestureRecognizer.Direction) -> [NSValue] {
        var startPoint: CGPoint = .zero
        var endPoint: CGPoint = .zero
        switch direction {
        case .right:
            startPoint = CGPoint(x: CGRectGetMinX(rect), y: CGRectGetMidY(rect))
            endPoint = CGPoint(x: CGRectGetMaxX(rect), y: CGRectGetMidY(rect))
        case .up:
            startPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMaxY(rect))
            endPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMinY(rect))
        case .left:
            startPoint = CGPoint(x: CGRectGetMaxX(rect), y: CGRectGetMidY(rect))
            endPoint = CGPoint(x: CGRectGetMinX(rect), y: CGRectGetMidY(rect))
        case .down:
            startPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMinY(rect))
            endPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMaxY(rect))
        default:
            startPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMinY(rect))
            endPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMaxY(rect))
        }
        return [NSValue(cgPoint: startPoint), NSValue(cgPoint: endPoint)]
    }
    
}

// MARK: - UIDevice+UIKit
@_spi(FW) extension UIDevice {
    
    /// 设置设备token原始Data，格式化并保存
    public static func fw_setDeviceTokenData(_ tokenData: Data?) {
        if let tokenData = tokenData {
            fw_deviceToken = tokenData.map{ String(format: "%02.0hhx", $0) }.joined()
        } else {
            fw_deviceToken = nil
        }
    }

    /// 获取设备Token格式化后的字符串
    public static var fw_deviceToken: String? {
        get {
            return UserDefaults.standard.string(forKey: "FWDeviceToken")
        }
        set {
            if let deviceToken = newValue {
                UserDefaults.standard.set(deviceToken, forKey: "FWDeviceToken")
                UserDefaults.standard.synchronize()
            } else {
                UserDefaults.standard.removeObject(forKey: "FWDeviceToken")
                UserDefaults.standard.synchronize()
            }
        }
    }

    /// 获取设备模型，格式："iPhone6,1"
    public static var fw_deviceModel: String? {
        #if targetEnvironment(simulator)
        return String(format: "%s", getenv("SIMULATOR_MODEL_IDENTIFIER"))
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let deviceModel = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return deviceModel
        #endif
    }

    /// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
    public static var fw_deviceIDFV: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    /// 获取或设置设备UUID，自动keychain持久化。默认获取IDFV(未使用IDFA，避免额外权限)，失败则随机生成一个
    public static var fw_deviceUUID: String {
        get {
            if let deviceUUID = UIDevice.fw_staticDeviceUUID {
                return deviceUUID
            }
            
            if let deviceUUID = KeychainManager.shared.password(forService: "FWDeviceUUID", account: Bundle.main.bundleIdentifier) {
                UIDevice.fw_staticDeviceUUID = deviceUUID
                return deviceUUID
            }
            
            let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            UIDevice.fw_staticDeviceUUID = deviceUUID
            KeychainManager.shared.setPassword(deviceUUID, forService: "FWDeviceUUID", account: Bundle.main.bundleIdentifier)
            return deviceUUID
        }
        set {
            UIDevice.fw_staticDeviceUUID = newValue
            KeychainManager.shared.setPassword(newValue, forService: "FWDeviceUUID", account: Bundle.main.bundleIdentifier)
        }
    }
    
    private static var fw_staticDeviceUUID: String?
    
    /// 是否越狱
    public static var fw_isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // 1
        let paths = [
            "/Applications/Cydia.app",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // 2
        if let bash = fopen("/bin/bash", "r") {
            fclose(bash)
            return true
        }
        
        // 3
        let uuidString = UUID().uuidString
        let path = "/private/\(uuidString)"
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
        #endif
    }
    
    /// 本地IP地址
    public static var fw_ipAddress: String? {
        var ipAddr: String?
        var addrs: UnsafeMutablePointer<ifaddrs>? = nil
        
        let ret = getifaddrs(&addrs)
        if 0 == ret {
            var cursor = addrs
            
            while cursor != nil {
                if AF_INET == cursor!.pointee.ifa_addr.pointee.sa_family && 0 == (cursor!.pointee.ifa_flags & UInt32(IFF_LOOPBACK)) {
                    ipAddr = String(cString: inet_ntoa(UnsafeMutablePointer<sockaddr_in>(OpaquePointer(cursor!.pointee.ifa_addr)).pointee.sin_addr))
                    break
                }
                
                cursor = cursor!.pointee.ifa_next
            }
            
            freeifaddrs(addrs)
        }
        
        return ipAddr
    }
    
    /// 本地主机名称
    public static var fw_hostName: String? {
        var hostName = [CChar](repeating: 0, count: 256)
        let success = gethostname(&hostName, 255)
        if success != 0 { return nil }
        hostName[255] = 0

        #if targetEnvironment(simulator)
        return String(cString: hostName)
        #else
        return String(format: "%s.local", hostName)
        #endif
    }
    
    /// 手机蜂窝网络类型列表，仅区分2G|3G|4G|5G
    public static var fw_networkTypes: [String]? {
        guard let currentRadio = fw_networkInfo.serviceCurrentRadioAccessTechnology else {
            return nil
        }
        
        return currentRadio.values.compactMap { fw_networkType($0) }
    }
    
    private static func fw_networkType(_ accessTechnology: String) -> String? {
        let types2G = [
            CTRadioAccessTechnologyGPRS,
            CTRadioAccessTechnologyEdge,
            CTRadioAccessTechnologyCDMA1x
        ]
        let types3G = [
            CTRadioAccessTechnologyWCDMA,
            CTRadioAccessTechnologyHSDPA,
            CTRadioAccessTechnologyHSUPA,
            CTRadioAccessTechnologyCDMAEVDORev0,
            CTRadioAccessTechnologyCDMAEVDORevA,
            CTRadioAccessTechnologyCDMAEVDORevB,
            CTRadioAccessTechnologyeHRPD
        ]
        let types4G = [
            CTRadioAccessTechnologyLTE
        ]
        var types5G: [String] = []
        if #available(iOS 14.1, *) {
            types5G = [
                CTRadioAccessTechnologyNRNSA,
                CTRadioAccessTechnologyNR
            ]
        }
        
        var networkType: String?
        if types5G.contains(accessTechnology) {
            networkType = "5G"
        } else if types4G.contains(accessTechnology) {
            networkType = "4G"
        } else if types3G.contains(accessTechnology) {
            networkType = "3G"
        } else if types2G.contains(accessTechnology) {
            networkType = "2G"
        }
        return networkType
    }
    
    private static var fw_networkInfo = CTTelephonyNetworkInfo()
    
}

// MARK: - UIView+UIKit
/// 事件穿透实现方法：重写-hitTest:withEvent:方法，当为指定视图(如self)时返回nil排除即可
@_spi(FW) extension UIView {
    
    private class SaturationGrayView: UIView {
        
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            return nil
        }
        
    }
    
    /// 视图是否可见，视图hidden为NO、alpha>0.01、window存在且size不为0才认为可见
    public var fw_isViewVisible: Bool {
        if isHidden || alpha <= 0.01 || self.window == nil { return false }
        if bounds.width == 0 || bounds.height == 0 { return false }
        return true
    }

    /// 获取响应的视图控制器
    public var fw_viewController: UIViewController? {
        var responder = self.next
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }

    /// 设置额外热区(点击区域)
    public var fw_touchInsets: UIEdgeInsets {
        get {
            if let value = fw.property(forName: "fw_touchInsets") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            fw.setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_touchInsets")
        }
    }
    
    /// 设置视图是否允许检测子视图pointInside，默认false
    public var fw_pointInsideSubviews: Bool {
        get { return fw.propertyBool(forName: "fw_pointInsideSubviews") }
        set { fw.setPropertyBool(newValue, forName: "fw_pointInsideSubviews") }
    }
    
    /// 设置视图是否可穿透(子视图响应)
    public var fw_isPenetrable: Bool {
        get { return fw.propertyBool(forName: "fw_isPenetrable") }
        set { fw.setPropertyBool(newValue, forName: "fw_isPenetrable") }
    }

    /// 设置自动计算适合高度的frame，需实现sizeThatFits:方法
    public var fw_fitFrame: CGRect {
        get {
            return self.frame
        }
        set {
            var fitFrame = newValue
            fitFrame.size = fw_fitSize(drawSize: CGSize(width: fitFrame.size.width, height: .greatestFiniteMagnitude))
            self.frame = fitFrame
        }
    }

    /// 计算当前视图适合大小，需实现sizeThatFits:方法
    public var fw_fitSize: CGSize {
        if self.frame.size.equalTo(.zero) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: self.frame.size.width, height: .greatestFiniteMagnitude)
        return fw_fitSize(drawSize: drawSize)
    }

    /// 计算指定边界，当前视图适合大小，需实现sizeThatFits:方法
    public func fw_fitSize(drawSize: CGSize) -> CGSize {
        let size = self.sizeThatFits(drawSize)
        return CGSize(width: min(drawSize.width, ceil(size.width)), height: min(drawSize.height, ceil(size.height)))
    }
    
    /// 根据tag查找subview，仅从subviews中查找
    public func fw_subview(tag: Int) -> UIView? {
        var subview: UIView?
        for obj in self.subviews {
            if obj.tag == tag {
                subview = obj
                break
            }
        }
        return subview
    }

    /// 设置阴影颜色、偏移和半径
    public func fw_setShadowColor(_ color: UIColor?, offset: CGSize, radius: CGFloat) {
        self.layer.shadowColor = color?.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = 1.0
    }

    /// 绘制四边边框
    public func fw_setBorderColor(_ color: UIColor?, width: CGFloat) {
        self.layer.borderColor = color?.cgColor
        self.layer.borderWidth = width
    }

    /// 绘制四边边框和四角圆角
    public func fw_setBorderColor(_ color: UIColor?, width: CGFloat, cornerRadius: CGFloat) {
        self.fw_setBorderColor(color, width: width)
        self.fw_setCornerRadius(cornerRadius)
    }

    /// 绘制四角圆角
    public func fw_setCornerRadius(_ radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }

    /// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func fw_setBorderLayer(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        fw_setBorderLayer(edge, color: color, width: width, leftInset: 0, rightInset: 0)
    }

    /// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func fw_setBorderLayer(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        if edge.contains(.top) {
            let borderLayer = fw_borderLayer("fw_borderLayerTop")
            borderLayer.frame = CGRect(x: leftInset, y: 0, width: self.bounds.size.width - leftInset - rightInset, height: width)
            borderLayer.backgroundColor = color?.cgColor
        }
        
        if edge.contains(.left) {
            let borderLayer = fw_borderLayer("fw_borderLayerLeft")
            borderLayer.frame = CGRect(x: 0, y: leftInset, width: width, height: self.bounds.size.height - leftInset - rightInset)
            borderLayer.backgroundColor = color?.cgColor
        }
        
        if edge.contains(.bottom) {
            let borderLayer = fw_borderLayer("fw_borderLayerBottom")
            borderLayer.frame = CGRect(x: leftInset, y: self.bounds.size.height - width, width: self.bounds.size.width - leftInset - rightInset, height: width)
            borderLayer.backgroundColor = color?.cgColor
        }
        
        if edge.contains(.right) {
            let borderLayer = fw_borderLayer("fw_borderLayerRight")
            borderLayer.frame = CGRect(x: self.bounds.size.width - width, y: leftInset, width: width, height: self.bounds.size.height - leftInset - rightInset)
            borderLayer.backgroundColor = color?.cgColor
        }
    }
    
    private func fw_borderLayer(_ edgeKey: String) -> CALayer {
        if let borderLayer = fw.property(forName: edgeKey) as? CALayer {
            return borderLayer
        } else {
            let borderLayer = CALayer()
            self.layer.addSublayer(borderLayer)
            fw.setProperty(borderLayer, forName: edgeKey)
            return borderLayer
        }
    }
    
    /// 绘制四边虚线边框和四角圆角。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func fw_setDashBorderLayer(color: UIColor?, width: CGFloat, cornerRadius: CGFloat, lineLength: CGFloat, lineSpacing: CGFloat) {
        var borderLayer: CAShapeLayer
        if let layer = fw.property(forName: "fw_dashBorderLayer") as? CAShapeLayer {
            borderLayer = layer
        } else {
            borderLayer = CAShapeLayer()
            self.layer.addSublayer(borderLayer)
            fw.setProperty(borderLayer, forName: "fw_dashBorderLayer")
        }
        
        borderLayer.frame = self.bounds
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = color?.cgColor
        borderLayer.lineWidth = width
        borderLayer.lineJoin = .round
        borderLayer.lineDashPattern = [NSNumber(value: lineLength), NSNumber(value: lineSpacing)]
        borderLayer.position = CGPoint(x: CGRectGetMidX(self.bounds), y: CGRectGetMidY(self.bounds))
        borderLayer.path = UIBezierPath(roundedRect: CGRect(x: width / 2.0, y: width / 2.0, width: max(0, CGRectGetWidth(self.bounds) - width), height: max(0, CGRectGetHeight(self.bounds) - width)), cornerRadius: cornerRadius).cgPath
    }

    /// 绘制单个或多个边框圆角，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func fw_setCornerLayer(_ corner: UIRectCorner, radius: CGFloat) {
        let cornerLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: radius, height: radius))
        cornerLayer.frame = self.bounds
        cornerLayer.path = path.cgPath
        self.layer.mask = cornerLayer
    }

    /// 绘制单个或多个边框圆角和四边边框，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func fw_setCornerLayer(_ corner: UIRectCorner, radius: CGFloat, borderColor: UIColor?, width: CGFloat) {
        fw_setCornerLayer(corner, radius: radius)
        
        var borderLayer: CAShapeLayer
        if let layer = fw.property(forName: "fw_borderLayerCorner") as? CAShapeLayer {
            borderLayer = layer
        } else {
            borderLayer = CAShapeLayer()
            self.layer.addSublayer(borderLayer)
            fw.setProperty(borderLayer, forName: "fw_borderLayerCorner")
        }
        
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: radius, height: radius))
        borderLayer.frame = self.bounds
        borderLayer.path = path.cgPath
        borderLayer.strokeColor = borderColor?.cgColor
        borderLayer.lineWidth = width * 2.0
        borderLayer.fillColor = nil
    }
    
    /// 绘制单边或多边边框视图。使用AutoLayout
    public func fw_setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        fw_setBorderView(edge, color: color, width: width, leftInset: 0, rightInset: 0)
    }

    /// 绘制单边或多边边框。使用AutoLayout
    public func fw_setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        if edge.contains(.top) {
            let borderView = fw_borderView("fw_borderViewTop", edge: .top)
            borderView.fw_setDimension(.height, size: width)
            borderView.fw_pinEdge(toSuperview: .left, inset: leftInset)
            borderView.fw_pinEdge(toSuperview: .right, inset: rightInset)
            borderView.backgroundColor = color
        }
        
        if edge.contains(.left) {
            let borderView = fw_borderView("fw_borderViewLeft", edge: .left)
            borderView.fw_setDimension(.width, size: width)
            borderView.fw_pinEdge(toSuperview: .top, inset: leftInset)
            borderView.fw_pinEdge(toSuperview: .bottom, inset: rightInset)
            borderView.backgroundColor = color
        }
        
        if edge.contains(.bottom) {
            let borderView = fw_borderView("fw_borderViewBottom", edge: .bottom)
            borderView.fw_setDimension(.height, size: width)
            borderView.fw_pinEdge(toSuperview: .left, inset: leftInset)
            borderView.fw_pinEdge(toSuperview: .right, inset: rightInset)
            borderView.backgroundColor = color
        }
        
        if edge.contains(.right) {
            let borderView = fw_borderView("fw_borderViewRight", edge: .right)
            borderView.fw_setDimension(.width, size: width)
            borderView.fw_pinEdge(toSuperview: .top, inset: leftInset)
            borderView.fw_pinEdge(toSuperview: .bottom, inset: rightInset)
            borderView.backgroundColor = color
        }
    }
    
    private func fw_borderView(_ edgeKey: String, edge: UIRectEdge) -> UIView {
        if let borderView = fw.property(forName: edgeKey) as? UIView {
            return borderView
        } else {
            let borderView = UIView()
            self.addSubview(borderView)
            fw.setProperty(borderView, forName: edgeKey)
            
            if edge == .top || edge == .bottom {
                borderView.fw_pinEdge(toSuperview: edge == .top ? .top : .bottom, inset: 0)
                borderView.fw_setDimension(.height, size: 0)
                borderView.fw_pinEdge(toSuperview: .left, inset: 0)
                borderView.fw_pinEdge(toSuperview: .right, inset: 0)
            } else {
                borderView.fw_pinEdge(toSuperview: edge == .left ? .left : .right, inset: 0)
                borderView.fw_setDimension(.width, size: 0)
                borderView.fw_pinEdge(toSuperview: .top, inset: 0)
                borderView.fw_pinEdge(toSuperview: .bottom, inset: 0)
            }
            return borderView
        }
    }
    
    /// 开始倒计时，从window移除时自动取消，回调参数为剩余时间
    @discardableResult
    public func fw_startCountDown(_ seconds: Int, block: @escaping (Int) -> Void) -> DispatchSourceTimer {
        let queue = DispatchQueue.global()
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.schedule(wallDeadline: .now(), repeating: 1.0, leeway: .seconds(0))
        
        let startTime = Date.fw_currentTime
        var hasWindow = false
        timer.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                var countDown = seconds - Int(round(Date.fw_currentTime - startTime))
                if countDown <= 0 {
                    timer.cancel()
                }
                
                // 按钮从window移除时自动cancel倒计时
                if !hasWindow && self?.window != nil {
                    hasWindow = true
                } else if hasWindow && self?.window == nil {
                    hasWindow = false
                    countDown = 0
                    timer.cancel()
                }
                
                block(countDown <= 0 ? 0 : countDown)
            }
        }
        timer.resume()
        return timer
    }
    
    /// 设置毛玻璃效果，使用UIVisualEffectView。内容需要添加到UIVisualEffectView.contentView
    @discardableResult
    public func fw_setBlurEffect(_ style: UIBlurEffect.Style) -> UIVisualEffectView? {
        for subview in self.subviews {
            if subview is UIVisualEffectView {
                subview.removeFromSuperview()
            }
        }
        
        if style.rawValue > -1 {
            let effect = UIBlurEffect(style: style)
            let effectView = UIVisualEffectView(effect: effect)
            self.addSubview(effectView)
            effectView.fw_pinEdges()
            return effectView
        }
        return nil
    }
    
    /// 移除所有子视图
    public func fw_removeAllSubviews() {
        self.subviews.forEach { $0.removeFromSuperview() }
    }

    /// 递归查找指定子类的第一个子视图(含自身)
    public func fw_subview(of clazz: AnyClass) -> UIView? {
        return fw_subview { view in
            return view.isKind(of: clazz)
        }
    }

    /// 递归查找指定条件的第一个子视图(含自身)
    public func fw_subview(block: @escaping (UIView) -> Bool) -> UIView? {
        if block(self) { return self }
        
        /* 如果需要顺序查找所有子视图，失败后再递归查找，参考此代码即可
        for subview in self.subviews {
            if block(subview) {
                return subview
            }
        } */
        
        for subview in self.subviews {
            if let resultView = subview.fw_subview(block: block) {
                return resultView
            }
        }
        return nil
    }
    
    /// 递归查找指定父类的第一个父视图(含自身)
    public func fw_superview(of clazz: AnyClass) -> UIView? {
        return fw_superview { view in
            return view.isKind(of: clazz)
        }
    }
    
    /// 递归查找指定条件的第一个父视图(含自身)
    public func fw_superview(block: @escaping (UIView) -> Bool) -> UIView? {
        var resultView: UIView?
        var superview: UIView? = self
        while let view = superview {
            if block(view) {
                resultView = view
                break
            }
            superview = view.superview
        }
        return resultView
    }

    /// 图片截图
    public var fw_snapshotImage: UIImage? {
        return UIImage.fw_image(view: self)
    }

    /// Pdf截图
    public var fw_snapshotPdf: Data? {
        var bounds = self.bounds
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &bounds, nil) else { return nil }
        context.beginPDFPage(nil)
        context.translateBy(x: 0, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        self.layer.render(in: context)
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }
    
    /// 将要设置的frame按照view的anchorPoint(.5, .5)处理后再设置，而系统默认按照(0, 0)方式计算
    public var fw_frameApplyTransform: CGRect {
        get { return self.frame }
        set { self.frame = UIView.fw_rectApplyTransform(newValue, transform: self.transform, anchorPoint: self.layer.anchorPoint) }
    }
    
    /// 计算目标点 targetPoint 围绕坐标点 coordinatePoint 通过 transform 之后此点的坐标。@see https://github.com/Tencent/QMUI_iOS
    private static func fw_pointApplyTransform(_ coordinatePoint: CGPoint, targetPoint: CGPoint, transform: CGAffineTransform) -> CGPoint {
        var p = CGPoint()
        p.x = (targetPoint.x - coordinatePoint.x) * transform.a + (targetPoint.y - coordinatePoint.y) * transform.c + coordinatePoint.x
        p.y = (targetPoint.x - coordinatePoint.x) * transform.b + (targetPoint.y - coordinatePoint.y) * transform.d + coordinatePoint.y
        p.x += transform.tx
        p.y += transform.ty
        return p
    }
    
    /// 系统的 CGRectApplyAffineTransform 只会按照 anchorPoint 为 (0, 0) 的方式去计算，但通常情况下我们面对的是 UIView/CALayer，它们默认的 anchorPoint 为 (.5, .5)，所以增加这个函数，在计算 transform 时可以考虑上 anchorPoint 的影响。@see https://github.com/Tencent/QMUI_iOS
    private static func fw_rectApplyTransform(_ rect: CGRect, transform: CGAffineTransform, anchorPoint: CGPoint) -> CGRect {
        let width = CGRectGetWidth(rect)
        let height = CGRectGetHeight(rect)
        let oPoint = CGPoint(x: rect.origin.x + width * anchorPoint.x, y: rect.origin.y + height * anchorPoint.y)
        let top_left = fw_pointApplyTransform(oPoint, targetPoint: CGPoint(x: rect.origin.x, y: rect.origin.y), transform: transform)
        let bottom_left = fw_pointApplyTransform(oPoint, targetPoint: CGPoint(x: rect.origin.x, y: rect.origin.y + height), transform: transform)
        let top_right = fw_pointApplyTransform(oPoint, targetPoint: CGPoint(x: rect.origin.x + width, y: rect.origin.y), transform: transform)
        let bottom_right = fw_pointApplyTransform(oPoint, targetPoint: CGPoint(x: rect.origin.x + width, y: rect.origin.y + height), transform: transform)
        let minX = min(min(min(top_left.x, bottom_left.x), top_right.x), bottom_right.x)
        let maxX = max(max(max(top_left.x, bottom_left.x), top_right.x), bottom_right.x)
        let minY = min(min(min(top_left.y, bottom_left.y), top_right.y), bottom_right.y)
        let maxY = max(max(max(top_left.y, bottom_left.y), top_right.y), bottom_right.y)
        let newWidth = maxX - minX
        let newHeight = maxY - minY
        let result = CGRect(x: minX, y: minY, width: newWidth, height: newHeight)
        return result
    }
    
    /// 自定义视图排序索引，需结合sortSubviews使用，默认0不处理
    public var fw_sortIndex: Int {
        get { fw.propertyInt(forName: "fw_sortIndex") }
        set { fw.setPropertyInt(newValue, forName: "fw_sortIndex") }
    }

    /// 根据sortIndex排序subviews，需结合sortIndex使用
    public func fw_sortSubviews() {
        var sortViews: [UIView] = []
        for subview in self.subviews {
            if subview.fw_sortIndex != 0 {
                sortViews.append(subview)
            }
        }
        guard sortViews.count > 0 else { return }
        
        sortViews.sort { view1, view2 in
            if view1.fw_sortIndex < 0 && view2.fw_sortIndex < 0 {
                return view2.fw_sortIndex < view1.fw_sortIndex
            } else {
                return view1.fw_sortIndex < view2.fw_sortIndex
            }
        }
        for subview in sortViews {
            if subview.fw_sortIndex < 0 {
                self.sendSubviewToBack(subview)
            } else {
                self.bringSubviewToFront(subview)
            }
        }
    }
    
    /// 是否显示灰色视图，仅支持iOS13+
    public var fw_hasGrayView: Bool {
        let grayView = self.subviews.first { $0 is SaturationGrayView }
        return grayView != nil
    }
    
    /// 显示灰色视图，仅支持iOS13+
    public func fw_showGrayView() {
        fw_hideGrayView()
        
        let overlay = SaturationGrayView()
        overlay.isUserInteractionEnabled = false
        overlay.backgroundColor = UIColor.lightGray
        overlay.layer.compositingFilter = "saturationBlendMode"
        overlay.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
        self.addSubview(overlay)
        overlay.fw_pinEdges()
    }
    
    /// 隐藏灰色视图，仅支持iOS13+
    public func fw_hideGrayView() {
        for subview in self.subviews {
            if subview is SaturationGrayView {
                subview.removeFromSuperview()
            }
        }
    }
    
    fileprivate static func fw_swizzleUIKitView() {
        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.point(inside:with:)),
            methodSignature: (@convention(c) (UIView, Selector, CGPoint, UIEvent?) -> Bool).self,
            swizzleSignature: (@convention(block) (UIView, CGPoint, UIEvent?) -> Bool).self
        ) { store in { selfObject, point, event in
            if let insetsValue = selfObject.fw.property(forName: "fw_touchInsets") as? NSValue {
                let touchInsets = insetsValue.uiEdgeInsetsValue
                var bounds = selfObject.bounds
                bounds = CGRect(x: bounds.origin.x - touchInsets.left, y: bounds.origin.y - touchInsets.top, width: bounds.size.width + touchInsets.left + touchInsets.right, height: bounds.size.height + touchInsets.top + touchInsets.bottom)
                return CGRectContainsPoint(bounds, point)
            }
            
            var pointInside = store.original(selfObject, store.selector, point, event)
            if (!pointInside && selfObject.fw.propertyBool(forName: "fw_pointInsideSubviews")) {
                for subview in selfObject.subviews {
                    if subview.point(inside: CGPoint(x: point.x - subview.frame.origin.x, y: point.y - subview.frame.origin.y), with: event) {
                        pointInside = true
                        break
                    }
                }
            }
            return pointInside
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.hitTest(_:with:)),
            methodSignature: (@convention(c) (UIView, Selector, CGPoint, UIEvent?) -> UIView?).self,
            swizzleSignature: (@convention(block) (UIView, CGPoint, UIEvent?) -> UIView?).self
        ) { store in { selfObject, point, event in
            guard selfObject.fw_isPenetrable else {
                return store.original(selfObject, store.selector, point, event)
            }
            
            guard selfObject.fw_isViewVisible, !selfObject.subviews.isEmpty else { return nil }
            for subview in selfObject.subviews.reversed() {
                guard subview.isUserInteractionEnabled,
                      subview.frame.contains(point),
                      subview.fw_isViewVisible else { continue }
                
                let subPoint = selfObject.convert(point, to: subview)
                guard let hitView = subview.hitTest(subPoint, with: event) else { continue }
                return hitView
            }
            return nil
        }}
    }
    
}

// MARK: - UIImageView+UIKit
@_spi(FW) extension UIImageView {
    
    /// 设置图片模式为ScaleAspectFill，自动拉伸不变形，超过区域隐藏
    public func fw_setContentModeAspectFill() {
        self.contentMode = .scaleAspectFill
        self.layer.masksToBounds = true
    }
    
    /// 优化图片人脸显示，参考：https://github.com/croath/UIImageView-BetterFace
    public func fw_faceAware() {
        guard let image = self.image else { return }
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            var ciImage = image.ciImage
            if ciImage == nil, let cgImage = image.cgImage {
                ciImage = CIImage(cgImage: cgImage)
            }
            
            if let ciImage = ciImage,
               let cgImage = image.cgImage,
               let features = UIImageView.fw_faceDetector?.features(in: ciImage),
               !features.isEmpty {
                DispatchQueue.main.async {
                    self?.fw_faceMark(features, size: CGSize(width: cgImage.width, height: cgImage.height))
                }
            } else {
                DispatchQueue.main.async {
                    self?.fw_faceLayer(false)?.removeFromSuperlayer()
                }
            }
        }
    }
    
    private static var fw_faceDetector: CIDetector? = {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        return detector
    }()
    
    private func fw_faceMark(_ features: [CIFeature], size: CGSize) {
        var fixedRect = CGRect(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude, width: 0, height: 0)
        var rightBorder: CGFloat = 0
        var bottomBorder: CGFloat = 0

        for feature in features {
            var oneRect = feature.bounds
            oneRect.origin.y = size.height - oneRect.origin.y - oneRect.size.height

            fixedRect.origin.x = min(oneRect.origin.x, fixedRect.origin.x)
            fixedRect.origin.y = min(oneRect.origin.y, fixedRect.origin.y)

            rightBorder = max(oneRect.origin.x + oneRect.size.width, rightBorder)
            bottomBorder = max(oneRect.origin.y + oneRect.size.height, bottomBorder)
        }

        fixedRect.size.width = rightBorder - fixedRect.origin.x
        fixedRect.size.height = bottomBorder - fixedRect.origin.y

        var fixedCenter = CGPoint(x: fixedRect.origin.x + fixedRect.size.width / 2.0,
                                  y: fixedRect.origin.y + fixedRect.size.height / 2.0)
        var offset = CGPoint.zero
        var finalSize = size

        if size.width / size.height > bounds.size.width / bounds.size.height {
            finalSize.height = bounds.size.height
            finalSize.width = size.width / size.height * finalSize.height
            fixedCenter.x = finalSize.width / size.width * fixedCenter.x
            fixedCenter.y = finalSize.width / size.width * fixedCenter.y

            offset.x = fixedCenter.x - bounds.size.width * 0.5
            if offset.x < 0 {
                offset.x = 0
            } else if offset.x + bounds.size.width > finalSize.width {
                offset.x = finalSize.width - bounds.size.width
            }
            offset.x = -offset.x
        } else {
            finalSize.width = bounds.size.width
            finalSize.height = size.height / size.width * finalSize.width
            fixedCenter.x = finalSize.width / size.width * fixedCenter.x
            fixedCenter.y = finalSize.width / size.width * fixedCenter.y

            offset.y = fixedCenter.y - bounds.size.height * (1 - 0.618)
            if offset.y < 0 {
                offset.y = 0
            } else if offset.y + bounds.size.height > finalSize.height {
                offset.y = finalSize.height - bounds.size.height
            }
            offset.y = -offset.y
        }
        
        let sublayer = fw_faceLayer(true)
        sublayer?.frame = CGRect(origin: offset, size: finalSize)
        sublayer?.contents = self.image?.cgImage
    }
    
    private func fw_faceLayer(_ lazyload: Bool) -> CALayer? {
        if let sublayer = layer.sublayers?.first(where: { $0.name == "FWFaceLayer" }) {
            return sublayer
        }
        
        if lazyload {
            let sublayer = CALayer()
            sublayer.name = "FWFaceLayer"
            sublayer.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull()]
            layer.addSublayer(sublayer)
            return sublayer
        }
        
        return nil
    }

    /// 倒影效果
    public func fw_reflect() {
        var frame = self.frame
        frame.origin.y += frame.size.height + 1
        
        let reflectImageView = UIImageView(frame: frame)
        self.clipsToBounds = true
        reflectImageView.contentMode = self.contentMode
        reflectImageView.image = self.image
        reflectImageView.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
        
        let reflectLayer = reflectImageView.layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.bounds = reflectLayer.bounds
        gradientLayer.position = CGPoint(x: reflectLayer.bounds.size.width / 2.0, y: reflectLayer.bounds.size.height / 2.0)
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        reflectLayer.mask = gradientLayer
        
        self.superview?.addSubview(reflectImageView)
    }

    /// 图片水印
    public func fw_setImage(_ image: UIImage, watermarkImage: UIImage, in rect: CGRect) {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0)
        image.draw(in: self.bounds)
        watermarkImage.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.image = newImage
    }

    /// 文字水印，指定区域
    public func fw_setImage(_ image: UIImage, watermarkString: NSAttributedString, in rect: CGRect) {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0)
        image.draw(in: self.bounds)
        watermarkString.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.image = newImage
    }

    /// 文字水印，指定坐标
    public func fw_setImage(_ image: UIImage, watermarkString: NSAttributedString, at point: CGPoint) {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0)
        image.draw(in: self.bounds)
        watermarkString.draw(at: point)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.image = newImage
    }
    
}

// MARK: - UIWindow+UIKit
@_spi(FW) extension UIWindow {
    
    /// 获取指定索引TabBar根视图控制器(非导航控制器)，找不到返回nil
    public func fw_getTabBarController(index: Int) -> UIViewController? {
        guard let tabBarController = fw_rootTabBarController() else { return nil }
        
        var targetController: UIViewController?
        if (tabBarController.viewControllers?.count ?? 0) > index, index >= 0 {
            targetController = tabBarController.viewControllers?[index]
        }
        
        if let navigationController = targetController as? UINavigationController {
            targetController = navigationController.viewControllers.first
        }
        return targetController
    }
    
    /// 获取指定类TabBar根视图控制器(非导航控制器)，找不到返回nil
    public func fw_getTabBarController(of clazz: AnyClass) -> UIViewController? {
        guard let tabBarController = fw_rootTabBarController() else { return nil }
        
        var targetController: UIViewController?
        let navigationControllers = tabBarController.viewControllers ?? []
        for navigationController in navigationControllers {
            var viewController: UIViewController? = navigationController
            if let navigationController = navigationController as? UINavigationController {
                viewController = navigationController.viewControllers.first
            }
            if let viewController = viewController,
               viewController.isKind(of: clazz) {
                targetController = viewController
                break
            }
        }
        return targetController
    }

    /// 获取指定条件TabBar根视图控制器(非导航控制器)，找不到返回nil
    public func fw_getTabBarController(block: (UIViewController) -> Bool) -> UIViewController? {
        guard let tabBarController = fw_rootTabBarController() else { return nil }
        
        var targetController: UIViewController?
        let navigationControllers = tabBarController.viewControllers ?? []
        for navigationController in navigationControllers {
            var viewController: UIViewController? = navigationController
            if let navigationController = navigationController as? UINavigationController {
                viewController = navigationController.viewControllers.first
            }
            if let viewController = viewController,
               block(viewController) {
                targetController = viewController
                break
            }
        }
        return targetController
    }
    
    /// 选中并获取指定索引TabBar根视图控制器(非导航控制器)，找不到返回nil
    @discardableResult
    public func fw_selectTabBarController(index: Int) -> UIViewController? {
        guard let targetController = fw_getTabBarController(index: index) else { return nil }
        return fw_selectTabBarController(viewController: targetController)
    }

    /// 选中并获取指定类TabBar根视图控制器(非导航控制器)，找不到返回nil
    @discardableResult
    public func fw_selectTabBarController(of clazz: AnyClass) -> UIViewController? {
        guard let targetController = fw_getTabBarController(of: clazz) else { return nil }
        return fw_selectTabBarController(viewController: targetController)
    }

    /// 选中并获取指定条件TabBar根视图控制器(非导航控制器)，找不到返回nil
    @discardableResult
    public func fw_selectTabBarController(block: (UIViewController) -> Bool) -> UIViewController? {
        guard let targetController = fw_getTabBarController(block: block) else { return nil }
        return fw_selectTabBarController(viewController: targetController)
    }
    
    private func fw_rootTabBarController() -> UITabBarController? {
        if let tabBarController = self.rootViewController as? UITabBarController {
            return tabBarController
        }
        
        if let navigationController = self.rootViewController as? UINavigationController,
           let tabBarController = navigationController.viewControllers.first as? UITabBarController {
            return tabBarController
        }
        
        return nil
    }
    
    private func fw_selectTabBarController(viewController: UIViewController) -> UIViewController? {
        guard let tabBarController = fw_rootTabBarController() else { return nil }
        
        let targetNavigation = viewController.navigationController ?? viewController
        let currentNavigation = tabBarController.selectedViewController
        if currentNavigation != targetNavigation {
            if let navigationController = currentNavigation as? UINavigationController,
               navigationController.viewControllers.count > 1 {
                navigationController.popToRootViewController(animated: false)
            }
            tabBarController.selectedViewController = targetNavigation
        }
        
        if let navigationController = targetNavigation as? UINavigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popToRootViewController(animated: false)
            }
        }
        return viewController
    }
    
}

// MARK: - UILabel+UIKit
@_spi(FW) extension UILabel {
    
    /// 快速设置attributedText样式，设置后调用setText:会自动转发到setAttributedText:方法
    public var fw_textAttributes: [NSAttributedString.Key: Any]? {
        get {
            return fw.property(forName: "fw_textAttributes") as? [NSAttributedString.Key : Any]
        }
        set {
            let prevTextAttributes = self.fw_textAttributes
            if (prevTextAttributes as? NSDictionary)?.isEqual(to: newValue ?? [:]) ?? false { return }
            
            fw.setPropertyCopy(newValue, forName: "fw_textAttributes")
            guard (self.text?.count ?? 0) > 0 else { return }
            
            let string = self.attributedText?.mutableCopy() as? NSMutableAttributedString
            let stringLength = string?.length ?? 0
            let fullRange = NSMakeRange(0, stringLength)
            if let prevTextAttributes = prevTextAttributes {
                var removeAttributes: [NSAttributedString.Key] = []
                string?.enumerateAttributes(in: fullRange, using: { attrs, range, _ in
                    if NSEqualRanges(range, NSMakeRange(0, stringLength - 1)),
                       let attrKern = attrs[.kern] as? NSNumber,
                       let prevKern = prevTextAttributes[.kern] as? NSNumber,
                       attrKern.isEqual(to: prevKern) {
                        string?.removeAttribute(.kern, range: NSMakeRange(0, stringLength - 1))
                    }
                    if !NSEqualRanges(range, fullRange) { return }
                    for (attr, value) in attrs {
                        if String.fw.safeString(prevTextAttributes[attr]) == String.fw.safeString(value) {
                            removeAttributes.append(attr)
                        }
                    }
                })
                for attr in removeAttributes {
                    string?.removeAttribute(attr, range: fullRange)
                }
            }
            
            if let textAttributes = newValue {
                string?.addAttributes(textAttributes, range: fullRange)
            }
            fw_swizzleSetAttributedText(fw_adjustedAttributedString(string))
        }
    }
    
    private func fw_adjustedAttributedString(_ string: NSAttributedString?) -> NSAttributedString? {
        guard let string = string, string.length > 0 else { return string }
        var attributedString: NSMutableAttributedString?
        if let mutableString = string as? NSMutableAttributedString {
            attributedString = mutableString
        } else {
            attributedString = string.mutableCopy() as? NSMutableAttributedString
        }
        let attributedLength = attributedString?.length ?? 0
        
        if self.fw_textAttributes?[.kern] != nil {
            attributedString?.removeAttribute(.kern, range: NSMakeRange(string.length - 1, 1))
        }
        
        var shouldAdjustLineHeight = self.fw_issetLineHeight
        attributedString?.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, attributedLength), using: { obj, range, stop in
            guard let style = obj as? NSParagraphStyle else { return }
            if NSEqualRanges(range, NSMakeRange(0, attributedLength)) {
                if style.maximumLineHeight != 0 || style.minimumLineHeight != 0 {
                    shouldAdjustLineHeight = false
                    stop.pointee = true
                }
            }
        })
        if shouldAdjustLineHeight {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.minimumLineHeight = self.fw_lineHeight
            paraStyle.maximumLineHeight = self.fw_lineHeight
            paraStyle.lineBreakMode = self.lineBreakMode
            paraStyle.alignment = self.textAlignment
            attributedString?.addAttribute(.paragraphStyle, value: paraStyle, range: NSMakeRange(0, attributedLength))
            
            let baselineOffset = (self.fw_lineHeight - self.font.lineHeight) / 4.0
            attributedString?.addAttribute(.baselineOffset, value: baselineOffset, range: NSMakeRange(0, attributedLength))
        }
        return attributedString
    }

    /// 快速设置文字的行高，优先级低于fwTextAttributes，设置后调用setText:会自动转发到setAttributedText:方法。小于等于0时恢复默认行高
    public var fw_lineHeight: CGFloat {
        get {
            if self.fw_issetLineHeight {
                return fw.propertyDouble(forName: "fw_lineHeight")
            } else if (self.attributedText?.length ?? 0) > 0 {
                var result: CGFloat = 0
                if let string = self.attributedText?.mutableCopy() as? NSMutableAttributedString {
                    string.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, string.length), using: { obj, range, stop in
                        guard let style = obj as? NSParagraphStyle else { return }
                        if NSEqualRanges(range, NSMakeRange(0, string.length)) {
                            if style.maximumLineHeight != 0 || style.minimumLineHeight != 0 {
                                result = style.maximumLineHeight
                                stop.pointee = true
                            }
                        }
                    })
                }
                return result > 0 ? result : self.font.lineHeight
            } else {
                return self.font.lineHeight
            }
        }
        set {
            if newValue > 0 {
                fw.setPropertyDouble(newValue, forName: "fw_lineHeight")
            } else {
                fw.setProperty(nil, forName: "fw_lineHeight")
            }
            guard let string = self.attributedText?.string else { return }
            let attributedString = NSAttributedString(string: string, attributes: self.fw_textAttributes)
            self.attributedText = fw_adjustedAttributedString(attributedString)
        }
    }
    
    private var fw_issetLineHeight: Bool {
        return fw.property(forName: "fw_lineHeight") != nil
    }

    /// 自定义内容边距，未设置时为系统默认。当内容为空时不参与intrinsicContentSize和sizeThatFits:计算，方便自动布局
    public var fw_contentInset: UIEdgeInsets {
        get {
            if let value = fw.property(forName: "fw_contentInset") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            let insets = UIEdgeInsets(top: UIScreen.fw_flatValue(newValue.top), left: UIScreen.fw_flatValue(newValue.left), bottom: UIScreen.fw_flatValue(newValue.bottom), right: UIScreen.fw_flatValue(newValue.right))
            fw.setProperty(NSValue(uiEdgeInsets: insets), forName: "fw_contentInset")
            self.setNeedsDisplay()
        }
    }

    /// 纵向分布方式，默认居中
    public var fw_verticalAlignment: UIControl.ContentVerticalAlignment {
        get {
            let value = fw.propertyInt(forName: "fw_verticalAlignment")
            return .init(rawValue: value) ?? .center
        }
        set {
            fw.setPropertyInt(newValue.rawValue, forName: "fw_verticalAlignment")
            self.setNeedsDisplay()
        }
    }
    
    /// 添加点击手势并自动识别NSLinkAttributeName|URL属性，点击高亮时回调链接，点击其它区域回调nil
    public func fw_addLinkGesture(block: @escaping (Any?) -> Void) {
        self.isUserInteractionEnabled = true
        self.fw_addTapGesture { gesture in
            guard let gesture = gesture as? UITapGestureRecognizer,
                  let label = gesture.view as? UILabel else { return }
            let attributes = label.fw_attributes(gesture: gesture, allowsSpacing: false)
            let link = attributes[.link] ?? attributes[NSAttributedString.Key("URL")]
            block(link)
        }
    }
    
    /// 获取手势触发位置的文本属性，可实现行内点击效果等，allowsSpacing默认为NO空白处不可点击。为了识别更准确，attributedText需指定font
    public func fw_attributes(
        gesture: UIGestureRecognizer,
        allowsSpacing: Bool
    ) -> [NSAttributedString.Key: Any] {
        guard let attributedString = self.attributedText else { return [:] }
        let textContainer = NSTextContainer(size: self.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = self.numberOfLines
        textContainer.lineBreakMode = self.lineBreakMode
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = NSTextStorage(attributedString: attributedString)
        textStorage.addLayoutManager(layoutManager)
        
        let point = gesture.location(in: self)
        var distance: CGFloat = 0
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: &distance)
        if !allowsSpacing && distance >= 1 { return [:] }
        return attributedString.attributes(at: index, effectiveRange: nil)
    }

    /// 快速设置标签并指定文本
    public func fw_setFont(
        _ font: UIFont?,
        textColor: UIColor?,
        text: String? = nil,
        textAlignment: NSTextAlignment? = nil,
        numberOfLines: Int? = nil,
        lineHeight: CGFloat? = nil
    ) {
        if let font = font { self.font = font }
        if let textColor = textColor { self.textColor = textColor }
        if let text = text { self.text = text }
        if let textAlignment = textAlignment { self.textAlignment = textAlignment }
        if let numberOfLines = numberOfLines { self.numberOfLines = numberOfLines }
        if let lineHeight = lineHeight { 
            if let font = font {
                self.fw_lineHeight = font.fw_lineHeight(expected: lineHeight)
            } else {
                self.fw_lineHeight = lineHeight
            }
        }
    }
    
    /// 快速创建标签并指定文本
    public static func fw_label(
        font: UIFont?,
        textColor: UIColor?,
        text: String? = nil,
        textAlignment: NSTextAlignment? = nil,
        numberOfLines: Int? = nil,
        lineHeight: CGFloat? = nil
    ) -> Self {
        let label = Self()
        label.fw_setFont(font, textColor: textColor, text: text, textAlignment: textAlignment, numberOfLines: numberOfLines, lineHeight: lineHeight)
        return label
    }
    
    /// 自适应字体大小，可设置缩放因子等
    public func fw_adjustsFontSize(
        minimumScaleFactor: CGFloat? = nil,
        baselineAdjustment: UIBaselineAdjustment? = nil
    ) {
        self.adjustsFontSizeToFitWidth = true
        if let minimumScaleFactor = minimumScaleFactor {
            self.minimumScaleFactor = minimumScaleFactor
        }
        if let baselineAdjustment = baselineAdjustment {
            self.baselineAdjustment = baselineAdjustment
        }
    }
    
    /// 获取当前标签是否非空，兼容attributedText|text
    public var fw_isNotEmpty: Bool {
        if (attributedText?.length ?? 0) > 0 { return true }
        if (text?.count ?? 0) > 0 { return true }
        return false
    }
    
    /// 计算当前标签实际显示行数，兼容contentInset|lineHeight
    public var fw_actualNumberOfLines: Int {
        if self.frame.size.equalTo(.zero) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: self.frame.size.width, height: .greatestFiniteMagnitude)
        return fw_actualNumberOfLines(drawSize: drawSize)
    }
    
    /// 计算指定边界、内边距、行高、行数时，当前标签实际显示行数
    public func fw_actualNumberOfLines(drawSize: CGSize, contentInset: UIEdgeInsets? = nil, lineHeight: CGFloat? = nil, numberOfLines: Int? = nil) -> Int {
        guard fw_isNotEmpty else { return 0 }
        
        let inset = contentInset ?? self.fw_contentInset
        let lineHeight = lineHeight ?? self.fw_lineHeight
        let maxLines = numberOfLines ?? self.numberOfLines
        guard lineHeight > 0 else { return 0 }
        
        let height = self.sizeThatFits(drawSize).height - inset.top - inset.bottom
        let lines = Int(round(height / lineHeight))
        return maxLines > 0 ? min(lines, maxLines) : lines
    }
    
    /// 计算当前文本所占尺寸，需frame或者宽度布局完整
    public var fw_textSize: CGSize {
        if self.frame.size.equalTo(.zero) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: self.frame.size.width, height: .greatestFiniteMagnitude)
        return fw_textSize(drawSize: drawSize)
    }
    
    /// 计算指定边界时，当前文本所占尺寸
    public func fw_textSize(drawSize: CGSize, contentInset: UIEdgeInsets? = nil) -> CGSize {
        var attrs: [NSAttributedString.Key: Any] = [:]
        attrs[.font] = self.font
        if self.lineBreakMode != .byWordWrapping {
            let paragraphStyle = NSMutableParagraphStyle()
            // 由于lineBreakMode默认值为TruncatingTail，多行显示时仍然按照WordWrapping计算
            if self.numberOfLines != 1 && self.lineBreakMode == .byTruncatingTail {
                paragraphStyle.lineBreakMode = .byWordWrapping
            } else {
                paragraphStyle.lineBreakMode = self.lineBreakMode
            }
            attrs[.paragraphStyle] = paragraphStyle
        }
        
        let inset = contentInset ?? self.fw_contentInset
        let size = (self.text as? NSString)?.boundingRect(with: CGSize(width: drawSize.width - inset.left - inset.right, height: drawSize.height - inset.top - inset.bottom), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attrs, context: nil).size ?? .zero
        return CGSize(width: min(drawSize.width, ceil(size.width)) + inset.left + inset.right, height: min(drawSize.height, ceil(size.height)) + inset.top + inset.bottom)
    }

    /// 计算当前属性文本所占尺寸，需frame或者宽度布局完整，attributedText需指定字体
    public var fw_attributedTextSize: CGSize {
        if self.frame.size.equalTo(.zero) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: self.frame.size.width, height: .greatestFiniteMagnitude)
        return fw_attributedTextSize(drawSize: drawSize)
    }

    /// 计算指定边界时，当前属性文本所占尺寸，attributedText需指定字体
    public func fw_attributedTextSize(drawSize: CGSize, contentInset: UIEdgeInsets? = nil) -> CGSize {
        let inset = contentInset ?? self.fw_contentInset
        let size = self.attributedText?.boundingRect(with: CGSize(width: drawSize.width - inset.left - inset.right, height: drawSize.height - inset.top - inset.bottom), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size ?? .zero
        return CGSize(width: min(drawSize.width, ceil(size.width)) + inset.left + inset.right, height: min(drawSize.height, ceil(size.height)) + inset.top + inset.bottom)
    }
    
    @objc func fw_swizzleSetText(_ text: String?) {
        guard let text = text else {
            fw_swizzleSetText(text)
            return
        }
        if (self.fw_textAttributes?.count ?? 0) < 1 && !self.fw_issetLineHeight {
            fw_swizzleSetText(text)
            return
        }
        let attributedString = NSAttributedString(string: text, attributes: self.fw_textAttributes)
        self.fw_swizzleSetAttributedText(fw_adjustedAttributedString(attributedString))
    }
    
    @objc func fw_swizzleSetAttributedText(_ text: NSAttributedString?) {
        guard let text = text else {
            self.fw_swizzleSetAttributedText(text)
            return
        }
        if (self.fw_textAttributes?.count ?? 0) < 1 && !self.fw_issetLineHeight {
            self.fw_swizzleSetAttributedText(text)
            return
        }
        var attributedString: NSMutableAttributedString? = NSMutableAttributedString(string: text.string, attributes: self.fw_textAttributes)
        attributedString = fw_adjustedAttributedString(attributedString)?.mutableCopy() as? NSMutableAttributedString
        text.enumerateAttributes(in: NSMakeRange(0, text.length)) { attrs, range, _ in
            attributedString?.addAttributes(attrs, range: range)
        }
        self.fw_swizzleSetAttributedText(attributedString)
    }
    
    @objc func fw_swizzleSetLineBreakMode(_ lineBreakMode: NSLineBreakMode) {
        self.fw_swizzleSetLineBreakMode(lineBreakMode)
        guard var textAttributes = self.fw_textAttributes else { return }
        if let paragraphStyle = textAttributes[.paragraphStyle] as? NSParagraphStyle,
           let mutableStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
            mutableStyle.lineBreakMode = lineBreakMode
            textAttributes[.paragraphStyle] = mutableStyle
            self.fw_textAttributes = textAttributes
        }
    }
    
    @objc func fw_swizzleSetTextAlignment(_ textAlignment: NSTextAlignment) {
        self.fw_swizzleSetTextAlignment(textAlignment)
        guard var textAttributes = self.fw_textAttributes else { return }
        if let paragraphStyle = textAttributes[.paragraphStyle] as? NSParagraphStyle,
           let mutableStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
            mutableStyle.alignment = textAlignment
            textAttributes[.paragraphStyle] = mutableStyle
            self.fw_textAttributes = textAttributes
        }
    }
    
    fileprivate static func fw_swizzleUIKitLabel() {
        NSObject.fw.swizzleInstanceMethod(
            UILabel.self,
            selector: #selector(UILabel.drawText(in:)),
            methodSignature: (@convention(c) (UILabel, Selector, CGRect) -> Void).self,
            swizzleSignature: (@convention(block) (UILabel, CGRect) -> Void).self
        ) { store in { selfObject, aRect in
            var rect = aRect
            if let contentInsetValue = selfObject.fw.property(forName: "fw_contentInset") as? NSValue {
                rect = rect.inset(by: contentInsetValue.uiEdgeInsetsValue)
            }
            
            let verticalAlignment = selfObject.fw_verticalAlignment
            if verticalAlignment == .top {
                let fitsSize = selfObject.sizeThatFits(rect.size)
                rect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: fitsSize.height)
            } else if verticalAlignment == .bottom {
                let fitsSize = selfObject.sizeThatFits(rect.size)
                rect = CGRect(x: rect.origin.x, y: rect.origin.y + (rect.size.height - fitsSize.height), width: rect.size.width, height: fitsSize.height)
            }
            
            store.original(selfObject, store.selector, rect)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UILabel.self,
            selector: #selector(getter: UILabel.intrinsicContentSize),
            methodSignature: (@convention(c) (UILabel, Selector) -> CGSize).self,
            swizzleSignature: (@convention(block) (UILabel) -> CGSize).self
        ) { store in { selfObject in
            if selfObject.fw.property(forName: "fw_contentInset") != nil {
                let preferredMaxLayoutWidth = selfObject.preferredMaxLayoutWidth > 0 ? selfObject.preferredMaxLayoutWidth : .greatestFiniteMagnitude
                return selfObject.sizeThatFits(CGSize(width: preferredMaxLayoutWidth, height: .greatestFiniteMagnitude))
            }
            
            return store.original(selfObject, store.selector)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UILabel.self,
            selector: #selector(UILabel.sizeThatFits(_:)),
            methodSignature: (@convention(c) (UILabel, Selector, CGSize) -> CGSize).self,
            swizzleSignature: (@convention(block) (UILabel, CGSize) -> CGSize).self
        ) { store in { selfObject, aSize in
            var size = aSize
            if let contentInsetValue = selfObject.fw.property(forName: "fw_contentInset") as? NSValue {
                let contentInset = contentInsetValue.uiEdgeInsetsValue
                size = CGSize(width: size.width - contentInset.left - contentInset.right, height: size.height - contentInset.top - contentInset.bottom)
                var fitsSize = store.original(selfObject, store.selector, size)
                if !fitsSize.equalTo(.zero) {
                    fitsSize = CGSize(width: fitsSize.width + contentInset.left + contentInset.right, height: fitsSize.height + contentInset.top + contentInset.bottom)
                }
                return fitsSize
            }
            
            return store.original(selfObject, store.selector, size)
        }}
        
        UILabel.fw.exchangeInstanceMethod(#selector(setter: UILabel.text), swizzleMethod: #selector(UILabel.fw_swizzleSetText(_:)))
        UILabel.fw.exchangeInstanceMethod(#selector(setter: UILabel.attributedText), swizzleMethod: #selector(UILabel.fw_swizzleSetAttributedText(_:)))
        UILabel.fw.exchangeInstanceMethod(#selector(setter: UILabel.lineBreakMode), swizzleMethod: #selector(UILabel.fw_swizzleSetLineBreakMode(_:)))
        UILabel.fw.exchangeInstanceMethod(#selector(setter: UILabel.textAlignment), swizzleMethod: #selector(UILabel.fw_swizzleSetTextAlignment(_:)))
    }
    
}

// MARK: - UIControl+UIKit
/// 防重复点击可以手工控制enabled或userInteractionEnabled或loading，如request开始时禁用，结束时启用等
/// 注意：需要支持appearance的属性必须标记为objc，否则不会生效
@_spi(FW) extension UIControl {
    
    // 设置Touch事件触发间隔，防止短时间多次触发事件，默认0
    @objc dynamic public var fw_touchEventInterval: TimeInterval {
        get { fw.propertyDouble(forName: "fw_touchEventInterval") }
        set { fw.setPropertyDouble(newValue, forName: "fw_touchEventInterval") }
    }
    
    private var fw_touchEventTimestamp: TimeInterval {
        get { fw.propertyDouble(forName: "fw_touchEventTimestamp") }
        set { fw.setPropertyDouble(newValue, forName: "fw_touchEventTimestamp") }
    }
    
    fileprivate static func fw_swizzleUIKitControl() {
        NSObject.fw.swizzleInstanceMethod(
            UIControl.self,
            selector: #selector(UIControl.sendAction(_:to:for:)),
            methodSignature: (@convention(c) (UIControl, Selector, Selector, Any?, UIEvent?) -> Void).self,
            swizzleSignature: (@convention(block) (UIControl, Selector, Any?, UIEvent?) -> Void).self
        ) { store in { selfObject, action, target, event in
            // 仅拦截Touch事件，且配置了间隔时间的Event
            if let event = event, event.type == .touches, event.subtype == .none,
               selfObject.fw_touchEventInterval > 0 {
                if Date().timeIntervalSince1970 - selfObject.fw_touchEventTimestamp < selfObject.fw_touchEventInterval { return }
                selfObject.fw_touchEventTimestamp = Date().timeIntervalSince1970
            }
            
            store.original(selfObject, store.selector, action, target, event)
        }}
    }
    
}

// MARK: - UIButton+UIKit
@_spi(FW) extension UIButton {
    
    /// 全局自定义按钮高亮时的alpha配置，默认0.5
    public static var fw_highlightedAlpha: CGFloat = 0.5
    
    /// 全局自定义按钮禁用时的alpha配置，默认0.3
    public static var fw_disabledAlpha: CGFloat = 0.3
    
    /// 自定义按钮禁用时的alpha，如0.3，默认0不生效
    public var fw_disabledAlpha: CGFloat {
        get {
            return fw.propertyDouble(forName: "fw_disabledAlpha")
        }
        set {
            fw.setPropertyDouble(newValue, forName: "fw_disabledAlpha")
            if newValue > 0 {
                self.alpha = self.isEnabled ? 1 : newValue
            }
        }
    }

    /// 自定义按钮高亮时的alpha，如0.5，默认0不生效
    public var fw_highlightedAlpha: CGFloat {
        get {
            return fw.propertyDouble(forName: "fw_highlightedAlpha")
        }
        set {
            fw.setPropertyDouble(newValue, forName: "fw_highlightedAlpha")
            if self.isEnabled && newValue > 0 {
                self.alpha = self.isHighlighted ? newValue : 1
            }
        }
    }
    
    /// 自定义按钮禁用状态改变时的句柄，默认nil
    public var fw_disabledChanged: ((UIButton, Bool) -> Void)? {
        get {
            return fw.property(forName: "fw_disabledChanged") as? (UIButton, Bool) -> Void
        }
        set {
            fw.setPropertyCopy(newValue, forName: "fw_disabledChanged")
            if newValue != nil {
                newValue?(self, self.isEnabled)
            }
        }
    }

    /// 自定义按钮高亮状态改变时的句柄，默认nil
    public var fw_highlightedChanged: ((UIButton, Bool) -> Void)? {
        get {
            return fw.property(forName: "fw_highlightedChanged") as? (UIButton, Bool) -> Void
        }
        set {
            fw.setPropertyCopy(newValue, forName: "fw_highlightedChanged")
            if self.isEnabled && newValue != nil {
                newValue?(self, self.isHighlighted)
            }
        }
    }

    /// 快速设置文本按钮
    public func fw_setTitle(_ title: String?, font: UIFont?, titleColor: UIColor?) {
        if let title = title { self.setTitle(title, for: .normal) }
        if let font = font { self.titleLabel?.font = font }
        if let titleColor = titleColor { self.setTitleColor(titleColor, for: .normal) }
    }

    /// 快速设置文本
    public func fw_setTitle(_ title: String?) {
        self.setTitle(title, for: .normal)
    }

    /// 快速设置图片
    public func fw_setImage(_ image: UIImage?) {
        self.setImage(image, for: .normal)
    }

    /// 设置图片的居中边位置，需要在setImage和setTitle之后调用才生效，且button大小大于图片+文字+间距
    ///
    /// imageEdgeInsets: 仅有image时相对于button，都有时上左下相对于button，右相对于title
    /// titleEdgeInsets: 仅有title时相对于button，都有时上右下相对于button，左相对于image
    public func fw_setImageEdge(_ edge: UIRectEdge, spacing: CGFloat) {
        let imageSize = self.imageView?.image?.size ?? .zero
        let labelSize = self.titleLabel?.intrinsicContentSize ?? .zero
        switch edge {
        case .left:
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing / 2.0, bottom: 0, right: spacing / 2.0)
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2.0, bottom: 0, right: -spacing / 2.0)
        case .right:
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: labelSize.width + spacing / 2.0, bottom: 0, right: -labelSize.width - spacing / 2.0)
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width - spacing / 2.0, bottom: 0, right: imageSize.width + spacing / 2.0)
        case .top:
            self.imageEdgeInsets = UIEdgeInsets(top: -labelSize.height - spacing / 2.0, left: 0, bottom: spacing / 2.0, right: -labelSize.width)
            self.titleEdgeInsets = UIEdgeInsets(top: spacing / 2.0, left: -imageSize.width, bottom: -imageSize.height - spacing / 2.0, right: 0)
        case .bottom:
            self.imageEdgeInsets = UIEdgeInsets(top: spacing / 2.0, left: 0, bottom: -labelSize.height - spacing / 2.0, right: -labelSize.width)
            self.titleEdgeInsets = UIEdgeInsets(top: -imageSize.height - spacing / 2.0, left: -imageSize.width, bottom: spacing / 2.0, right: 0)
        default:
            break
        }
    }
    
    /// 图文模式时自适应粗体文本，解决图文按钮文本显示不全(...)的兼容性问题
    public func fw_adjustBoldText() {
        titleLabel?.lineBreakMode = .byClipping
    }
    
    /// 设置状态背景色
    public func fw_setBackgroundColor(_ backgroundColor: UIColor?, for state: UIControl.State) {
        var image: UIImage?
        if let backgroundColor = backgroundColor {
            let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
            UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(backgroundColor.cgColor)
            context?.fill(rect)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        self.setBackgroundImage(image, for: state)
    }
    
    /// 快速创建文本按钮
    public static func fw_button(title: String?, font: UIFont?, titleColor: UIColor?) -> Self {
        let button = Self(type: .custom)
        button.fw_setTitle(title, font: font, titleColor: titleColor)
        return button
    }

    /// 快速创建图片按钮
    public static func fw_button(image: UIImage?) -> Self {
        let button = Self(type: .custom)
        button.setImage(image, for: .normal)
        return button
    }
    
    /// 设置按钮倒计时，从window移除时自动取消。等待时按钮disabled，非等待时enabled。时间支持格式化，示例：重新获取(%lds)
    @discardableResult
    public func fw_startCountDown(_ seconds: Int, title: String, waitTitle: String) -> DispatchSourceTimer {
        return self.fw_startCountDown(seconds) { [weak self] countDown in
            // 先设置titleLabel，再设置title，防止闪烁
            if countDown <= 0 {
                self?.titleLabel?.text = title
                self?.setTitle(title, for: .normal)
                self?.isEnabled = true
            } else {
                let waitText = String(format: waitTitle, countDown)
                self?.titleLabel?.text = waitText
                self?.setTitle(waitText, for: .normal)
                self?.isEnabled = false
            }
        }
    }
    
    fileprivate static func fw_swizzleUIKitButton() {
        NSObject.fw.swizzleInstanceMethod(
            UIButton.self,
            selector: #selector(setter: UIButton.isEnabled),
            methodSignature: (@convention(c) (UIButton, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIButton, Bool) -> Void).self
        ) { store in { selfObject, enabled in
            store.original(selfObject, store.selector, enabled)
            
            if selfObject.fw_disabledAlpha > 0 {
                selfObject.alpha = enabled ? 1 : selfObject.fw_disabledAlpha
            }
            if selfObject.fw_disabledChanged != nil {
                selfObject.fw_disabledChanged?(selfObject, enabled)
            }
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UIButton.self,
            selector: #selector(setter: UIButton.isHighlighted),
            methodSignature: (@convention(c) (UIButton, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIButton, Bool) -> Void).self
        ) { store in { selfObject, highlighted in
            store.original(selfObject, store.selector, highlighted)
            
            if selfObject.isEnabled && selfObject.fw_highlightedAlpha > 0 {
                selfObject.alpha = highlighted ? selfObject.fw_highlightedAlpha : 1
            }
            if selfObject.isEnabled && selfObject.fw_highlightedChanged != nil {
                selfObject.fw_highlightedChanged?(selfObject, highlighted)
            }
        }}
    }
    
}

// MARK: - UIScrollView+UIKit
@_spi(FW) extension UIScrollView {
    
    /// 判断当前scrollView内容是否足够滚动
    public var fw_canScroll: Bool {
        return fw_canScrollVertical || fw_canScrollHorizontal
    }

    /// 判断当前的scrollView内容是否足够水平滚动
    public var fw_canScrollHorizontal: Bool {
        if self.bounds.size.width <= 0 { return false }
        return self.contentSize.width + self.adjustedContentInset.left + self.adjustedContentInset.right > CGRectGetWidth(self.bounds)
    }

    /// 判断当前的scrollView内容是否足够纵向滚动
    public var fw_canScrollVertical: Bool {
        if self.bounds.size.height <= 0 { return false }
        return self.contentSize.height + self.adjustedContentInset.top + self.adjustedContentInset.bottom > CGRectGetHeight(self.bounds)
    }

    /// 当前scrollView滚动到指定边
    public func fw_scroll(to edge: UIRectEdge, animated: Bool = true) {
        let contentOffset = fw_contentOffset(of: edge)
        self.setContentOffset(contentOffset, animated: animated)
    }

    /// 是否已滚动到指定边
    public func fw_isScroll(to edge: UIRectEdge) -> Bool {
        let contentOffset = fw_contentOffset(of: edge)
        switch edge {
        case .top:
            return self.contentOffset.y <= contentOffset.y
        case .left:
            return self.contentOffset.x <= contentOffset.x
        case .bottom:
            return self.contentOffset.y >= contentOffset.y
        case .right:
            return self.contentOffset.x >= contentOffset.x
        default:
            return false
        }
    }

    /// 获取当前的scrollView滚动到指定边时的contentOffset(包含contentInset)
    public func fw_contentOffset(of edge: UIRectEdge) -> CGPoint {
        var contentOffset = self.contentOffset
        switch edge {
        case .top:
            contentOffset.y = -self.adjustedContentInset.top
        case .left:
            contentOffset.x = -self.adjustedContentInset.left
        case .bottom:
            contentOffset.y = self.contentSize.height - self.bounds.size.height + self.adjustedContentInset.bottom
        case .right:
            contentOffset.x = self.contentSize.width - self.bounds.size.width + self.adjustedContentInset.right
        default:
            break
        }
        return contentOffset
    }

    /// 总页数，自动识别翻页方向
    public var fw_totalPage: Int {
        if fw_canScrollVertical {
            return Int(ceil(self.contentSize.height / self.frame.size.height))
        } else {
            return Int(ceil(self.contentSize.width / self.frame.size.width))
        }
    }

    /// 当前页数，不支持动画，自动识别翻页方向
    public var fw_currentPage: Int {
        get {
            if fw_canScrollVertical {
                let pageHeight = self.frame.size.height
                return Int(floor((self.contentOffset.y - pageHeight / 2) / pageHeight)) + 1
            } else {
                let pageWidth = self.frame.size.width
                return Int(floor((self.contentOffset.x - pageWidth / 2) / pageWidth)) + 1
            }
        }
        set {
            if fw_canScrollVertical {
                let offset = self.frame.size.height * CGFloat(newValue)
                self.contentOffset = CGPoint(x: 0, y: offset)
            } else {
                let offset = self.frame.size.width * CGFloat(newValue)
                self.contentOffset = CGPoint(x: offset, y: 0)
            }
        }
    }

    /// 设置当前页数，支持动画，自动识别翻页方向
    public func fw_setCurrentPage(_ page: Int, animated: Bool = true) {
        if fw_canScrollVertical {
            let offset = self.frame.size.height * CGFloat(page)
            self.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
        } else {
            let offset = self.frame.size.width * CGFloat(page)
            self.setContentOffset(CGPoint(x: offset, y: 0), animated: animated)
        }
    }

    /// 是否是最后一页，自动识别翻页方向
    public var fw_isLastPage: Bool {
        return self.fw_currentPage == self.fw_totalPage - 1
    }
    
    /// 快捷设置contentOffset.x
    public var fw_contentOffsetX: CGFloat {
        get { return self.contentOffset.x }
        set { self.contentOffset = CGPoint(x: newValue, y: self.contentOffset.y) }
    }

    /// 快捷设置contentOffset.y
    public var fw_contentOffsetY: CGFloat {
        get { return self.contentOffset.y }
        set { self.contentOffset = CGPoint(x: self.contentOffset.x, y: newValue) }
    }
    
    /// 滚动视图完整图片截图
    public var fw_contentSnapshot: UIImage? {
        let size = contentSize
        guard size != .zero else { return nil }

        return UIGraphicsImageRenderer(size: size).image { context in
            let previousFrame = frame
            frame = CGRect(origin: frame.origin, size: size)
            layer.render(in: context.cgContext)
            frame = previousFrame
        }
    }
    
    /// 内容视图，子视图需添加到本视图，布局约束完整时可自动滚动
    ///
    /// 当启用等比例缩放布局、且scrollView和contentView都固定高度时，
    /// 为防止浮点数误差导致scrollView拖拽时出现纵向可滚动的兼容问题，解决方案如下：
    /// 1. 设置scrollView属性isDirectionalLockEnabled为true
    /// 2. 设置布局高度为固定ceil高度，如：FW.fixed(ceil(FW.relative(40)))
    public var fw_contentView: UIView {
        if let contentView = fw.property(forName: "fw_contentView") as? UIView {
            return contentView
        } else {
            let contentView = UIView()
            fw.setProperty(contentView, forName: "fw_contentView")
            self.addSubview(contentView)
            contentView.fw_pinEdges()
            return contentView
        }
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
    public func fw_hoverView(_ view: UIView, fromSuperview: UIView, toSuperview: UIView, toPosition: CGFloat) -> CGFloat {
        let distance = (fromSuperview.superview?.convert(fromSuperview.frame.origin, to: toSuperview) ?? .zero).y - toPosition
        if distance <= 0 {
            if view.superview != toSuperview {
                view.removeFromSuperview()
                toSuperview.addSubview(view)
                view.fw_pinEdge(toSuperview: .left, inset: 0)
                view.fw_pinEdge(toSuperview: .top, inset: toPosition)
                view.fw_setDimensions(view.bounds.size)
            }
        } else {
            if view.superview != fromSuperview {
                view.removeFromSuperview()
                fromSuperview.addSubview(view)
                view.fw_pinEdges()
            }
        }
        return distance
    }
    
    /// 是否开始识别pan手势
    public var fw_shouldBegin: ((UIGestureRecognizer) -> Bool)? {
        get {
            return fw.property(forName: "fw_shouldBegin") as? (UIGestureRecognizer) -> Bool
        }
        set {
            fw.setPropertyCopy(newValue, forName: "fw_shouldBegin")
            UIScrollView.fw_swizzleUIKitScrollView()
        }
    }

    /// 是否允许同时识别多个手势
    public var fw_shouldRecognizeSimultaneously: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get {
            return fw.property(forName: "fw_shouldRecognizeSimultaneously") as? (UIGestureRecognizer, UIGestureRecognizer) -> Bool
        }
        set {
            fw.setPropertyCopy(newValue, forName: "fw_shouldRecognizeSimultaneously")
            UIScrollView.fw_swizzleUIKitScrollView()
        }
    }

    /// 是否另一个手势识别失败后，才能识别pan手势
    public var fw_shouldRequireFailure: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get {
            return fw.property(forName: "fw_shouldRequireFailure") as? (UIGestureRecognizer, UIGestureRecognizer) -> Bool
        }
        set {
            fw.setPropertyCopy(newValue, forName: "fw_shouldRequireFailure")
            UIScrollView.fw_swizzleUIKitScrollView()
        }
    }

    /// 是否pan手势识别失败后，才能识别另一个手势
    public var fw_shouldBeRequiredToFail: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get {
            return fw.property(forName: "fw_shouldBeRequiredToFail") as? (UIGestureRecognizer, UIGestureRecognizer) -> Bool
        }
        set {
            fw.setPropertyCopy(newValue, forName: "fw_shouldBeRequiredToFail")
            UIScrollView.fw_swizzleUIKitScrollView()
        }
    }
    
    @objc private func fw_swizzleGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBlock = self.fw_shouldBegin {
            return shouldBlock(gestureRecognizer)
        }
        
        return fw_swizzleGestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    @objc private func fw_swizzleGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBlock = self.fw_shouldRecognizeSimultaneously {
            return shouldBlock(gestureRecognizer, otherGestureRecognizer)
        }
        
        return fw_swizzleGestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
    
    @objc private func fw_swizzleGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBlock = self.fw_shouldRequireFailure {
            return shouldBlock(gestureRecognizer, otherGestureRecognizer)
        }
        
        return fw_swizzleGestureRecognizer(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer)
    }
    
    @objc private func fw_swizzleGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBlock = self.fw_shouldBeRequiredToFail {
            return shouldBlock(gestureRecognizer, otherGestureRecognizer)
        }
        
        return fw_swizzleGestureRecognizer(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer)
    }
    
    private static var fw_staticPanProxySwizzled = false
    
    private static func fw_swizzleUIKitScrollView() {
        guard !fw_staticPanProxySwizzled else { return }
        fw_staticPanProxySwizzled = true
        
        UIScrollView.fw.exchangeInstanceMethod(#selector(UIGestureRecognizerDelegate.gestureRecognizerShouldBegin(_:)), swizzleMethod: #selector(UIScrollView.fw_swizzleGestureRecognizerShouldBegin(_:)))
        UIScrollView.fw.exchangeInstanceMethod(#selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)), swizzleMethod: #selector(UIScrollView.fw_swizzleGestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)))
        UIScrollView.fw.exchangeInstanceMethod(#selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldRequireFailureOf:)), swizzleMethod: #selector(UIScrollView.fw_swizzleGestureRecognizer(_:shouldRequireFailureOf:)))
        UIScrollView.fw.exchangeInstanceMethod(#selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldBeRequiredToFailBy:)), swizzleMethod: #selector(UIScrollView.fw_swizzleGestureRecognizer(_:shouldBeRequiredToFailBy:)))
    }
    
}

// MARK: - UIGestureRecognizer+UIKit
/// gestureRecognizerShouldBegin：是否继续进行手势识别，默认YES
/// shouldRecognizeSimultaneouslyWithGestureRecognizer: 是否支持多手势触发。默认NO
/// shouldRequireFailureOfGestureRecognizer：是否otherGestureRecognizer触发失败时，才开始触发gestureRecognizer。返回YES，第一个手势失败
/// shouldBeRequiredToFailByGestureRecognizer：在otherGestureRecognizer识别其手势之前，是否gestureRecognizer必须触发失败。返回YES，第二个手势失败
@_spi(FW) extension UIGestureRecognizer {
    
    /// 获取手势直接作用的view，不同于view，此处是view的subview
    public weak var fw_targetView: UIView? {
        return view?.hitTest(location(in: view), with: nil)
    }

    /// 是否正在拖动中：Began || Changed
    public var fw_isTracking: Bool {
        return state == .began || state == .changed
    }

    /// 是否是激活状态: isEnabled && (Began || Changed)
    public var fw_isActive: Bool {
        return isEnabled && (state == .began || state == .changed)
    }
    
    /// 判断手势是否正作用于指定视图
    public func fw_hitTest(view: UIView?) -> Bool {
        return view?.hitTest(location(in: view), with: nil) != nil
    }
    
}

// MARK: - UIPanGestureRecognizer+UIKit
@_spi(FW) extension UIPanGestureRecognizer {
    
    /// 当前滑动方向，如果多个方向滑动，取绝对值较大的一方，失败返回0
    public var fw_swipeDirection: UISwipeGestureRecognizer.Direction {
        let transition = self.translation(in: self.view)
        if abs(transition.x) > abs(transition.y) {
            if transition.x < 0 {
                return .left
            } else if transition.x > 0 {
                return .right
            }
        } else {
            if transition.y > 0 {
                return .down
            } else if transition.y < 0 {
                return .up
            }
        }
        return []
    }

    /// 当前滑动进度，滑动绝对值相对于手势视图的宽或高
    public var fw_swipePercent: CGFloat {
        guard let view = self.view,
              view.bounds.width > 0, view.bounds.height > 0 else { return 0 }
        var percent: CGFloat = 0
        let transition = self.translation(in: view)
        if abs(transition.x) > abs(transition.y) {
            percent = abs(transition.x) / view.bounds.width
        } else {
            percent = abs(transition.y) / view.bounds.height
        }
        return max(0, min(percent, 1))
    }

    /// 计算指定方向的滑动进度
    public func fw_swipePercent(of direction: UISwipeGestureRecognizer.Direction) -> CGFloat {
        guard let view = self.view,
              view.bounds.width > 0, view.bounds.height > 0 else { return 0 }
        var percent: CGFloat = 0
        let transition = self.translation(in: view)
        switch direction {
        case .left:
            percent = -transition.x / view.bounds.width
        case .right:
            percent = transition.x / view.bounds.width
        case .up:
            percent = -transition.y / view.bounds.height
        case .down:
            percent = transition.y / view.bounds.height
        default:
            percent = transition.y / view.bounds.height
        }
        return max(0, min(percent, 1))
    }
    
}

// MARK: - UIPageControl+UIKit
@_spi(FW) extension UIPageControl {
    
    /// 自定义圆点大小，默认{10, 10}
    public var fw_preferredSize: CGSize {
        get {
            var size = self.bounds.size
            if size.height <= 0 {
                size = self.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                if size.height <= 0 { size = CGSize(width: 10, height: 10) }
            }
            return size
        }
        set {
            let height = self.fw_preferredSize.height
            let scale = newValue.height / height
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
}

// MARK: - UISlider+UIKit
@_spi(FW) extension UISlider {
    
    /// 中间圆球的大小，默认zero
    public var fw_thumbSize: CGSize {
        get {
            if let value = fw.property(forName: "fw_thumbSize") as? NSValue {
                return value.cgSizeValue
            }
            return .zero
        }
        set {
            fw.setProperty(NSValue(cgSize: newValue), forName: "fw_thumbSize")
            fw_updateThumbImage()
        }
    }

    /// 中间圆球的颜色，默认nil
    public var fw_thumbColor: UIColor? {
        get {
            return fw.property(forName: "fw_thumbColor") as? UIColor
        }
        set {
            fw.setProperty(newValue, forName: "fw_thumbColor")
            self.fw_updateThumbImage()
        }
    }
    
    private func fw_updateThumbImage() {
        let thumbSize = self.fw_thumbSize
        guard thumbSize.width > 0, thumbSize.height > 0 else { return }
        let thumbColor = self.fw_thumbColor ?? (self.tintColor ?? .white)
        let thumbImage = UIImage.fw_image(size: thumbSize) { context in
            let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: thumbSize.width, height: thumbSize.height))
            context.setFillColor(thumbColor.cgColor)
            path.fill()
        }
        
        self.setThumbImage(thumbImage, for: .normal)
        self.setThumbImage(thumbImage, for: .highlighted)
    }
    
}

// MARK: - UISwitch+UIKit
@_spi(FW) extension UISwitch {
    
    /// 自定义尺寸大小，默认{51,31}
    public var fw_preferredSize: CGSize {
        get {
            var size = self.bounds.size
            if size.height <= 0 {
                size = self.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                if size.height <= 0 { size = CGSize(width: 51, height: 31) }
            }
            return size
        }
        set {
            let height = self.fw_preferredSize.height
            let scale = newValue.height / height
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
    /// 自定义关闭时除圆点外的背景色
    @objc dynamic public var fw_offTintColor: UIColor? {
        get {
            return fw.property(forName: "fw_offTintColor") as? UIColor
        }
        set {
            let switchWellView = value(forKeyPath: "_visualElement._switchWellView") as? UIView
            var defaultOffTintColor = switchWellView?.fw.property(forName: "defaultOffTintColor") as? UIColor
            if defaultOffTintColor == nil {
                defaultOffTintColor = switchWellView?.backgroundColor
                switchWellView?.fw.setProperty(defaultOffTintColor, forName: "defaultOffTintColor")
            }
            switchWellView?.backgroundColor = newValue ?? defaultOffTintColor
            fw.setProperty(newValue, forName: "fw_offTintColor")
        }
    }
    
    fileprivate static func fw_swizzleUIKitSwitch() {
        NSObject.fw.swizzleInstanceMethod(
            UISwitch.self,
            selector: #selector(UISwitch.traitCollectionDidChange(_:)),
            methodSignature: (@convention(c) (UISwitch, Selector, UITraitCollection?) -> Void).self,
            swizzleSignature: (@convention(block) (UISwitch, UITraitCollection?) -> Void).self
        ) { store in { selfObject, previousTraitCollection in
            store.original(selfObject, store.selector, previousTraitCollection)

            guard selfObject.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
            guard let offTintColor = selfObject.fw_offTintColor else { return }
            DispatchQueue.main.async {
                selfObject.fw_offTintColor = offTintColor
            }
        }}
    }
    
}

// MARK: - UITextField+UIKit
@_spi(FW) extension UITextField {
    
    fileprivate class InputTarget {
        weak var textInput: (UIView & UITextInput)?
        var maxLength: Int = 0
        var maxUnicodeLength: Int = 0
        var textChangedBlock: ((String) -> Void)?
        var autoCompleteInterval: TimeInterval = 0.5
        var autoCompleteTimestamp: TimeInterval = 0
        var autoCompleteBlock: ((String) -> Void)?
        
        private var shouldCheckLength: Bool {
            if let markedTextRange = textInput?.markedTextRange,
               textInput?.position(from: markedTextRange.start, offset: 0) != nil {
                return false
            }
            return true
        }
        private var textValue: String? {
            get {
                if let textField = textInput as? UITextField {
                    return textField.text
                } else if let textView = textInput as? UITextView {
                    return textView.text
                }
                return nil
            }
            set {
                if let textField = textInput as? UITextField {
                    textField.text = newValue
                } else if let textView = textInput as? UITextView {
                    textView.text = newValue
                }
            }
        }

        init(textInput: (UIView & UITextInput)?) {
            self.textInput = textInput
        }

        func textLengthChanged() {
            if maxLength > 0, shouldCheckLength {
                if (textValue?.count ?? 0) > maxLength {
                    textValue = textValue?.fw.substring(to: maxLength)
                }
            }

            if maxUnicodeLength > 0, shouldCheckLength {
                if (textValue?.fw.unicodeLength ?? 0) > maxUnicodeLength {
                    textValue = textValue?.fw.unicodeSubstring(maxUnicodeLength)
                }
            }
        }
        
        func filterText(_ text: String) -> String {
            var filterText = text
            if maxLength > 0, shouldCheckLength {
                if filterText.count > maxLength {
                    filterText = filterText.fw.substring(to: maxLength)
                }
            }

            if maxUnicodeLength > 0, shouldCheckLength {
                if filterText.fw.unicodeLength > maxUnicodeLength {
                    filterText = filterText.fw.unicodeSubstring(maxUnicodeLength)
                }
            }
            return filterText
        }

        @objc func textChangedAction() {
            textLengthChanged()
            
            if textChangedBlock != nil {
                let inputText = textValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                textChangedBlock?(inputText)
            }

            if autoCompleteBlock != nil {
                autoCompleteTimestamp = Date().timeIntervalSince1970
                let inputText = textValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if inputText.isEmpty {
                    autoCompleteBlock?("")
                } else {
                    let currentTimestamp = autoCompleteTimestamp
                    DispatchQueue.main.asyncAfter(deadline: .now() + autoCompleteInterval) { [weak self] in
                        if currentTimestamp == self?.autoCompleteTimestamp {
                            self?.autoCompleteBlock?(inputText)
                        }
                    }
                }
            }
        }
    }
    
    /// 最大字数限制，0为无限制，二选一
    public var fw_maxLength: Int {
        get { return fw_inputTarget(false)?.maxLength ?? 0 }
        set { fw_inputTarget(true)?.maxLength = newValue }
    }

    /// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
    public var fw_maxUnicodeLength: Int {
        get { return fw_inputTarget(false)?.maxUnicodeLength ?? 0 }
        set { fw_inputTarget(true)?.maxUnicodeLength = newValue }
    }
    
    /// 自定义文字改变处理句柄，自动trimString，默认nil
    public var fw_textChangedBlock: ((String) -> Void)? {
        get { return fw_inputTarget(false)?.textChangedBlock }
        set { fw_inputTarget(true)?.textChangedBlock = newValue }
    }

    /// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
    public func fw_textLengthChanged() {
        fw_inputTarget(false)?.textLengthChanged()
    }

    /// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
    public func fw_filterText(_ text: String) -> String {
        if let target = fw_inputTarget(false) {
            return target.filterText(text)
        }
        return text
    }

    /// 设置自动完成时间间隔，默认0.5秒，和autoCompleteBlock配套使用
    public var fw_autoCompleteInterval: TimeInterval {
        get { return fw_inputTarget(false)?.autoCompleteInterval ?? 0 }
        set { fw_inputTarget(true)?.autoCompleteInterval = newValue > 0 ? newValue : 0.5 }
    }

    /// 设置自动完成处理句柄，自动trimString，默认nil，注意输入框内容为空时会立即触发
    public var fw_autoCompleteBlock: ((String) -> Void)? {
        get { return fw_inputTarget(false)?.autoCompleteBlock }
        set { fw_inputTarget(true)?.autoCompleteBlock = newValue }
    }
    
    private func fw_inputTarget(_ lazyload: Bool) -> InputTarget? {
        if let target = fw.property(forName: "fw_inputTarget") as? InputTarget {
            return target
        } else if lazyload {
            let target = InputTarget(textInput: self)
            self.addTarget(target, action: #selector(InputTarget.textChangedAction), for: .editingChanged)
            fw.setProperty(target, forName: "fw_inputTarget")
            return target
        }
        return nil
    }
    
    /// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
    public var fw_menuDisabled: Bool {
        get { fw.propertyBool(forName: "fw_menuDisabled") }
        set { fw.setPropertyBool(newValue, forName: "fw_menuDisabled") }
    }

    /// 自定义光标偏移和大小，不为0才会生效，默认zero不生效
    public var fw_cursorRect: CGRect {
        get {
            if let value = fw.property(forName: "fw_cursorRect") as? NSValue {
                return value.cgRectValue
            }
            return .zero
        }
        set {
            fw.setProperty(NSValue(cgRect: newValue), forName: "fw_cursorRect")
        }
    }

    /// 获取及设置当前选中文字范围
    public var fw_selectedRange: NSRange {
        get {
            guard let selectedRange = self.selectedTextRange else {
                return NSRange(location: NSNotFound, length: 0)
            }
            let location = self.offset(from: self.beginningOfDocument, to: selectedRange.start)
            let length = self.offset(from: selectedRange.start, to: selectedRange.end)
            return NSRange(location: location, length: length)
        }
        set {
            guard newValue.location != NSNotFound else {
                self.selectedTextRange = nil
                return
            }
            let start = self.position(from: self.beginningOfDocument, offset: newValue.location)
            let end = self.position(from: self.beginningOfDocument, offset: NSMaxRange(newValue))
            if let start = start, let end = end {
                let selectionRange = self.textRange(from: start, to: end)
                self.selectedTextRange = selectionRange
            }
        }
    }

    /// 移动光标到最后
    public func fw_selectAllRange() {
        let range = self.textRange(from: self.beginningOfDocument, to: self.endOfDocument)
        self.selectedTextRange = range
    }

    /// 移动光标到指定位置，兼容动态text赋值
    public func fw_moveCursor(_ offset: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let position = self.position(from: self.beginningOfDocument, offset: offset) {
                self.selectedTextRange = self.textRange(from: position, to: position)
            }
        }
    }
    
    fileprivate static func fw_swizzleUIKitTextField() {
        NSObject.fw.swizzleInstanceMethod(
            UITextField.self,
            selector: #selector(UITextField.canPerformAction(_:withSender:)),
            methodSignature: (@convention(c) (UITextField, Selector, Selector, Any?) -> Bool).self,
            swizzleSignature: (@convention(block) (UITextField, Selector, Any?) -> Bool).self
        ) { store in { selfObject, action, sender in
            if selfObject.fw_menuDisabled { return false }
            
            return store.original(selfObject, store.selector, action, sender)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UITextField.self,
            selector: #selector(UITextField.caretRect(for:)),
            methodSignature: (@convention(c) (UITextField, Selector, UITextPosition) -> CGRect).self,
            swizzleSignature: (@convention(block) (UITextField, UITextPosition) -> CGRect).self
        ) { store in { selfObject, position in
            var caretRect = store.original(selfObject, store.selector, position)
            guard let rectValue = selfObject.fw.property(forName: "fw_cursorRect") as? NSValue else { return caretRect }
            
            let rect = rectValue.cgRectValue
            if rect.origin.x != 0 { caretRect.origin.x += rect.origin.x }
            if rect.origin.y != 0 { caretRect.origin.y += rect.origin.y }
            if rect.size.width != 0 { caretRect.size.width = rect.size.width }
            if rect.size.height != 0 { caretRect.size.height = rect.size.height }
            return caretRect
        }}
    }
    
}

// MARK: - UITextView+UIKit
@_spi(FW) extension UITextView {
    
    /// 最大字数限制，0为无限制，二选一
    public var fw_maxLength: Int {
        get { return fw_inputTarget(false)?.maxLength ?? 0 }
        set { fw_inputTarget(true)?.maxLength = newValue }
    }

    /// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
    public var fw_maxUnicodeLength: Int {
        get { return fw_inputTarget(false)?.maxUnicodeLength ?? 0 }
        set { fw_inputTarget(true)?.maxUnicodeLength = newValue }
    }
    
    /// 自定义文字改变处理句柄，自动trimString，默认nil
    public var fw_textChangedBlock: ((String) -> Void)? {
        get { return fw_inputTarget(false)?.textChangedBlock }
        set { fw_inputTarget(true)?.textChangedBlock = newValue }
    }

    /// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
    public func fw_textLengthChanged() {
        fw_inputTarget(false)?.textLengthChanged()
    }

    /// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
    public func fw_filterText(_ text: String) -> String {
        if let target = fw_inputTarget(false) {
            return target.filterText(text)
        }
        return text
    }

    /// 设置自动完成时间间隔，默认0.5秒，和autoCompleteBlock配套使用
    public var fw_autoCompleteInterval: TimeInterval {
        get { return fw_inputTarget(false)?.autoCompleteInterval ?? 0 }
        set { fw_inputTarget(true)?.autoCompleteInterval = newValue > 0 ? newValue : 0.5 }
    }

    /// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
    public var fw_autoCompleteBlock: ((String) -> Void)? {
        get { return fw_inputTarget(false)?.autoCompleteBlock }
        set { fw_inputTarget(true)?.autoCompleteBlock = newValue }
    }
    
    private func fw_inputTarget(_ lazyload: Bool) -> UITextField.InputTarget? {
        if let target = fw.property(forName: "fw_inputTarget") as? UITextField.InputTarget {
            return target
        } else if lazyload {
            let target = UITextField.InputTarget(textInput: self)
            self.fw.observeNotification(UITextView.textDidChangeNotification, object: self, target: target, action: #selector(UITextField.InputTarget.textChangedAction))
            fw.setProperty(target, forName: "fw_inputTarget")
            return target
        }
        return nil
    }
    
    /// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
    public var fw_menuDisabled: Bool {
        get { fw.propertyBool(forName: "fw_menuDisabled") }
        set { fw.setPropertyBool(newValue, forName: "fw_menuDisabled") }
    }

    /// 自定义光标偏移和大小，不为0才会生效，默认zero不生效
    public var fw_cursorRect: CGRect {
        get {
            if let value = fw.property(forName: "fw_cursorRect") as? NSValue {
                return value.cgRectValue
            }
            return .zero
        }
        set {
            fw.setProperty(NSValue(cgRect: newValue), forName: "fw_cursorRect")
        }
    }

    /// 获取及设置当前选中文字范围
    public var fw_selectedRange: NSRange {
        get {
            guard let selectedRange = self.selectedTextRange else {
                return NSRange(location: NSNotFound, length: 0)
            }
            let location = self.offset(from: self.beginningOfDocument, to: selectedRange.start)
            let length = self.offset(from: selectedRange.start, to: selectedRange.end)
            return NSRange(location: location, length: length)
        }
        set {
            guard newValue.location != NSNotFound else {
                self.selectedTextRange = nil
                return
            }
            let start = self.position(from: self.beginningOfDocument, offset: newValue.location)
            let end = self.position(from: self.beginningOfDocument, offset: NSMaxRange(newValue))
            if let start = start, let end = end {
                let selectionRange = self.textRange(from: start, to: end)
                self.selectedTextRange = selectionRange
            }
        }
    }

    /// 移动光标到最后
    public func fw_selectAllRange() {
        let range = self.textRange(from: self.beginningOfDocument, to: self.endOfDocument)
        self.selectedTextRange = range
    }

    /// 移动光标到指定位置，兼容动态text赋值
    public func fw_moveCursor(_ offset: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let position = self.position(from: self.beginningOfDocument, offset: offset) {
                self.selectedTextRange = self.textRange(from: position, to: position)
            }
        }
    }

    /// 计算当前文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整
    public var fw_textSize: CGSize {
        if self.frame.size.equalTo(.zero) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: self.frame.size.width, height: .greatestFiniteMagnitude)
        return fw_textSize(drawSize: drawSize)
    }
    
    /// 计算指定边界时，当前文本所占尺寸，包含textContainerInset
    public func fw_textSize(drawSize: CGSize, contentInset: UIEdgeInsets? = nil) -> CGSize {
        var attrs: [NSAttributedString.Key: Any] = [:]
        attrs[.font] = self.font
        
        let inset = contentInset ?? self.textContainerInset
        let size = (self.text as? NSString)?.boundingRect(with: CGSize(width: drawSize.width - inset.left - inset.right, height: drawSize.height - inset.top - inset.bottom), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attrs, context: nil).size ?? .zero
        return CGSize(width: min(drawSize.width, ceil(size.width)) + inset.left + inset.right, height: min(drawSize.height, ceil(size.height)) + inset.top + inset.bottom)
    }

    /// 计算当前属性文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整，attributedText需指定字体
    public var fw_attributedTextSize: CGSize {
        if self.frame.size.equalTo(.zero) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: self.frame.size.width, height: .greatestFiniteMagnitude)
        return fw_attributedTextSize(drawSize: drawSize)
    }

    /// 计算指定边界时，当前属性文本所占尺寸，包含textContainerInset，attributedText需指定字体
    public func fw_attributedTextSize(drawSize: CGSize, contentInset: UIEdgeInsets? = nil) -> CGSize {
        let inset = contentInset ?? self.textContainerInset
        let size = self.attributedText?.boundingRect(with: CGSize(width: drawSize.width - inset.left - inset.right, height: drawSize.height - inset.top - inset.bottom), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size ?? .zero
        return CGSize(width: min(drawSize.width, ceil(size.width)) + inset.left + inset.right, height: min(drawSize.height, ceil(size.height)) + inset.top + inset.bottom)
    }
    
    /// 快捷设置行高，兼容placeholder和typingAttributes。小于等于0时恢复默认行高
    public var fw_lineHeight: CGFloat {
        get {
            if fw.property(forName: "fw_lineHeight") != nil {
                return fw.propertyDouble(forName: "fw_lineHeight")
            }
            
            var result: CGFloat = 0
            if let string = self.attributedText?.mutableCopy() as? NSMutableAttributedString {
                string.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, string.length), using: { obj, range, stop in
                    guard let style = obj as? NSParagraphStyle else { return }
                    if NSEqualRanges(range, NSMakeRange(0, string.length)) {
                        if style.maximumLineHeight != 0 || style.minimumLineHeight != 0 {
                            result = style.maximumLineHeight
                            stop.pointee = true
                        }
                    }
                })
            }
            
            if result <= 0, let style = self.typingAttributes[.paragraphStyle] as? NSParagraphStyle {
                if style.maximumLineHeight != 0 || style.minimumLineHeight != 0 {
                    result = style.maximumLineHeight
                }
            }
            return result > 0 ? result : (self.font?.lineHeight ?? 0)
        }
        set {
            if newValue > 0 {
                fw.setPropertyDouble(newValue, forName: "fw_lineHeight")
            } else {
                fw.setProperty(nil, forName: "fw_lineHeight")
            }
            
            self.fw_placeholderLineHeight = newValue
            
            var typingAttributes = self.typingAttributes
            var paragraphStyle: NSMutableParagraphStyle
            if let style = typingAttributes[.paragraphStyle] as? NSMutableParagraphStyle {
                paragraphStyle = style
            } else if let style = (typingAttributes[.paragraphStyle] as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle {
                paragraphStyle = style
            } else {
                paragraphStyle = NSMutableParagraphStyle()
            }
            paragraphStyle.minimumLineHeight = newValue > 0 ? newValue : 0
            paragraphStyle.maximumLineHeight = newValue > 0 ? newValue : 0
            
            typingAttributes[.paragraphStyle] = paragraphStyle
            self.typingAttributes = typingAttributes
        }
    }
    
    /// 获取当前文本框是否非空，兼容attributedText|text
    public var fw_isNotEmpty: Bool {
        if (attributedText?.length ?? 0) > 0 { return true }
        if (text?.count ?? 0) > 0 { return true }
        return false
    }
    
    /// 计算当前文本框实际显示行数，兼容textContainerInset|lineHeight
    public var fw_actualNumberOfLines: Int {
        if self.frame.size.equalTo(.zero) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: self.frame.size.width, height: .greatestFiniteMagnitude)
        return fw_actualNumberOfLines(drawSize: drawSize)
    }
    
    /// 计算指定边界、内边距、行高时，当前文本框实际显示行数
    public func fw_actualNumberOfLines(drawSize: CGSize, contentInset: UIEdgeInsets? = nil, lineHeight: CGFloat? = nil) -> Int {
        guard fw_isNotEmpty else { return 0 }
        
        let inset = contentInset ?? self.textContainerInset
        let lineHeight = lineHeight ?? self.fw_lineHeight
        guard lineHeight > 0 else { return 0 }
        
        let height = self.sizeThatFits(drawSize).height - inset.top - inset.bottom
        let lines = Int(round(height / lineHeight))
        return lines
    }
    
    fileprivate static func fw_swizzleUIKitTextView() {
        NSObject.fw.swizzleInstanceMethod(
            UITextView.self,
            selector: #selector(UITextView.canPerformAction(_:withSender:)),
            methodSignature: (@convention(c) (UITextView, Selector, Selector, Any?) -> Bool).self,
            swizzleSignature: (@convention(block) (UITextView, Selector, Any?) -> Bool).self
        ) { store in { selfObject, action, sender in
            if selfObject.fw_menuDisabled { return false }
            
            return store.original(selfObject, store.selector, action, sender)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UITextView.self,
            selector: #selector(UITextView.caretRect(for:)),
            methodSignature: (@convention(c) (UITextView, Selector, UITextPosition) -> CGRect).self,
            swizzleSignature: (@convention(block) (UITextView, UITextPosition) -> CGRect).self
        ) { store in { selfObject, position in
            var caretRect = store.original(selfObject, store.selector, position)
            guard let rectValue = selfObject.fw.property(forName: "fw_cursorRect") as? NSValue else { return caretRect }
            
            let rect = rectValue.cgRectValue
            if rect.origin.x != 0 { caretRect.origin.x += rect.origin.x }
            if rect.origin.y != 0 { caretRect.origin.y += rect.origin.y }
            if rect.size.width != 0 { caretRect.size.width = rect.size.width }
            if rect.size.height != 0 { caretRect.size.height = rect.size.height }
            return caretRect
        }}
    }
    
}

// MARK: - UITableView+UIKit
/// 注意：需要支持appearance的属性必须标记为objc，否则不会生效;
/// 启用高度估算：设置rowHeight为automaticDimension并撑开布局即可，再设置estimatedRowHeight可提升性能
@_spi(FW) extension UITableView {
    
    /// 全局清空TableView默认多余边距
    public static func fw_resetTableStyle() {
        if #available(iOS 15.0, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0
        }
    }
    
    /// 是否启动高度估算布局，启用后需要子视图布局完整，无需实现heightForRow方法(iOS11默认启用，会先cellForRow再heightForRow)
    public var fw_estimatedLayout: Bool {
        get {
            return self.estimatedRowHeight == UITableView.automaticDimension
        }
        set {
            if newValue {
                self.estimatedRowHeight = UITableView.automaticDimension
                self.estimatedSectionHeaderHeight = UITableView.automaticDimension
                self.estimatedSectionFooterHeight = UITableView.automaticDimension
            } else {
                self.estimatedRowHeight = 0
                self.estimatedSectionHeaderHeight = 0
                self.estimatedSectionFooterHeight = 0
            }
        }
    }
    
    /// 清除Grouped等样式默认多余边距，注意CGFLOAT_MIN才会生效，0不会生效
    public func fw_resetTableStyle() {
        self.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        self.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        if #available(iOS 15.0, *) {
            self.sectionHeaderTopPadding = 0
        }
        
        UITableView.fw_resetTableConfiguration?(self)
    }
    
    /// 配置全局resetTableStyle钩子句柄，默认nil
    public static var fw_resetTableConfiguration: ((UITableView) -> Void)?
    
    /// reloadData完成回调
    public func fw_reloadData(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0) {
            self.reloadData()
        } completion: { _ in
            completion?()
        }
    }
    
    /// reloadData禁用动画
    public func fw_reloadDataWithoutAnimation() {
        UIView.performWithoutAnimation {
            self.reloadData()
        }
    }
    
    /// 判断indexPath是否有效
    public func fw_isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        guard indexPath.section >= 0, indexPath.row >= 0 else { return false }
        guard indexPath.section < numberOfSections else { return false }
        return indexPath.row < numberOfRows(inSection: indexPath.section)
    }
    
    /// 简单曝光方案，willDisplay调用即可，表格快速滑动、数据不变等情况不计曝光。如需完整曝光方案，请使用StatisticalView
    public func fw_willDisplay(_ cell: UITableViewCell, at indexPath: IndexPath, key: AnyHashable? = nil, exposure: @escaping () -> Void) {
        let identifier = "\(indexPath.section).\(indexPath.row)-\(String.fw.safeString(key))"
        let block: (UITableViewCell) -> Void = { [weak self] cell in
            let previousIdentifier = cell.fw.property(forName: "fw_willDisplayIdentifier") as? String
            guard self?.visibleCells.contains(cell) ?? false,
                  self?.indexPath(for: cell) != nil,
                  identifier != previousIdentifier else { return }
            
            exposure()
            cell.fw.setPropertyCopy(identifier, forName: "fw_willDisplayIdentifier")
        }
        cell.fw.setPropertyCopy(block, forName: "fw_willDisplay")
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fw_willDisplay(_:)), object: cell)
        perform(#selector(fw_willDisplay(_:)), with: cell, afterDelay: 0.2, inModes: [.default])
    }
    
    @objc private func fw_willDisplay(_ cell: UITableViewCell) {
        let block = cell.fw.property(forName: "fw_willDisplay") as? (UITableViewCell) -> Void
        block?(cell)
    }
    
}

// MARK: - UITableViewCell+UIKit
@_spi(FW) extension UITableViewCell {
    
    /// 设置分割线内边距，iOS8+默认15.f，设为UIEdgeInsetsZero可去掉
    public var fw_separatorInset: UIEdgeInsets {
        get {
            return self.separatorInset
        }
        set {
            self.separatorInset = newValue
            self.preservesSuperviewLayoutMargins = false
            self.layoutMargins = separatorInset
        }
    }
    
    /// 调整imageView的位置偏移，默认zero不生效，仅支持default|subtitle样式
    public var fw_imageEdgeInsets: UIEdgeInsets {
        get {
            let value = fw.property(forName: "fw_imageEdgeInsets") as? NSValue
            return value?.uiEdgeInsetsValue ?? .zero
        }
        set {
            fw.setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_imageEdgeInsets")
            UITableViewCell.fw_swizzleUIKitTableViewCell()
        }
    }
    
    /// 调整textLabel的位置偏移，默认zero不生效，仅支持default|subtitle样式
    public var fw_textEdgeInsets: UIEdgeInsets {
        get {
            let value = fw.property(forName: "fw_textEdgeInsets") as? NSValue
            return value?.uiEdgeInsetsValue ?? .zero
        }
        set {
            fw.setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_textEdgeInsets")
            UITableViewCell.fw_swizzleUIKitTableViewCell()
        }
    }
    
    /// 调整detailTextLabel的位置偏移，默认zero不生效，仅支持subtitle样式
    public var fw_detailTextEdgeInsets: UIEdgeInsets {
        get {
            let value = fw.property(forName: "fw_detailTextEdgeInsets") as? NSValue
            return value?.uiEdgeInsetsValue ?? .zero
        }
        set {
            fw.setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_detailTextEdgeInsets")
            UITableViewCell.fw_swizzleUIKitTableViewCell()
        }
    }
    
    /// 调整accessoryView的位置偏移，默认zero不生效，仅对自定义accessoryView生效
    public var fw_accessoryEdgeInsets: UIEdgeInsets {
        get {
            let value = fw.property(forName: "fw_accessoryEdgeInsets") as? NSValue
            return value?.uiEdgeInsetsValue ?? .zero
        }
        set {
            fw.setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_accessoryEdgeInsets")
            UITableViewCell.fw_swizzleUIKitTableViewCell()
        }
    }

    /// 获取当前所属tableView
    public weak var fw_tableView: UITableView? {
        var superview = self.superview
        while superview != nil {
            if let tableView = superview as? UITableView {
                return tableView
            }
            superview = superview?.superview
        }
        return nil
    }

    /// 获取当前显示indexPath
    public var fw_indexPath: IndexPath? {
        return fw_tableView?.indexPath(for: self)
    }
    
    /// 执行所属tableView的批量更新
    public func fw_performBatchUpdates(
        _ updates: ((UITableView, IndexPath?) -> Void)?,
        completion: ((UITableView, IndexPath?, Bool) -> Void)? = nil
    ) {
        guard let tableView = fw_tableView else { return }
        
        tableView.performBatchUpdates(updates != nil ? { [weak self] in
            let indexPath = self != nil ? tableView.indexPath(for: self!) : nil
            updates?(tableView, indexPath)
        } : nil, completion: completion != nil ? { [weak self] finished in
            let indexPath = self != nil ? tableView.indexPath(for: self!) : nil
            completion?(tableView, indexPath, finished)
        } : nil)
    }
    
    private static var fw_staticTableViewCellSwizzled = false
    
    private static func fw_swizzleUIKitTableViewCell() {
        guard !fw_staticTableViewCellSwizzled else { return }
        fw_staticTableViewCellSwizzled = true
        
        NSObject.fw.swizzleInstanceMethod(
            UITableViewCell.self,
            selector: #selector(UITableViewCell.layoutSubviews),
            methodSignature: (@convention(c) (UITableViewCell, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableViewCell) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            let hasAccessoryInset = selfObject.accessoryView?.superview != nil && selfObject.fw_accessoryEdgeInsets != .zero
            let hasImageInset = selfObject.imageView?.image != nil && selfObject.fw_imageEdgeInsets != .zero
            let hasTextInset = (selfObject.textLabel?.text?.count ?? 0) > 0 && selfObject.fw_textEdgeInsets != .zero
            let hasDetailTextInset = (selfObject.detailTextLabel?.text?.count ?? 0) > 0 && selfObject.fw_detailTextEdgeInsets != .zero
            guard hasAccessoryInset || hasImageInset || hasTextInset || hasDetailTextInset else {
                return
            }
            
            if hasAccessoryInset {
                var accessoryFrame = selfObject.accessoryView?.frame ?? .zero
                accessoryFrame.origin.x = accessoryFrame.minX - selfObject.fw_accessoryEdgeInsets.right
                accessoryFrame.origin.y = accessoryFrame.minY + selfObject.fw_accessoryEdgeInsets.top - selfObject.fw_accessoryEdgeInsets.bottom
                selfObject.accessoryView?.frame = accessoryFrame
                
                var contentFrame = selfObject.contentView.frame
                contentFrame.size.width = accessoryFrame.minX - selfObject.fw_accessoryEdgeInsets.left
                selfObject.contentView.frame = contentFrame
            }
            
            var imageFrame = selfObject.imageView?.frame ?? .zero
            var textFrame = selfObject.textLabel?.frame ?? .zero
            var detailTextFrame = selfObject.detailTextLabel?.frame ?? .zero
            
            if hasImageInset {
                imageFrame.origin.x += selfObject.fw_imageEdgeInsets.left - selfObject.fw_imageEdgeInsets.right
                imageFrame.origin.y += selfObject.fw_imageEdgeInsets.top - selfObject.fw_imageEdgeInsets.bottom
                
                textFrame.origin.x += selfObject.fw_imageEdgeInsets.left
                textFrame.size.width = min(textFrame.width, selfObject.contentView.bounds.width - textFrame.minX)
                
                detailTextFrame.origin.x += selfObject.fw_imageEdgeInsets.left
                detailTextFrame.size.width = min(detailTextFrame.width, selfObject.contentView.bounds.width - detailTextFrame.minX)
            }
            if hasTextInset {
                textFrame.origin.x += selfObject.fw_textEdgeInsets.left - selfObject.fw_textEdgeInsets.right
                textFrame.origin.y += selfObject.fw_textEdgeInsets.top - selfObject.fw_textEdgeInsets.bottom
                textFrame.size.width = min(textFrame.width, selfObject.contentView.bounds.width - textFrame.minX)
            }
            if hasDetailTextInset {
                detailTextFrame.origin.x += selfObject.fw_detailTextEdgeInsets.left - selfObject.fw_detailTextEdgeInsets.right
                detailTextFrame.origin.y += selfObject.fw_detailTextEdgeInsets.top - selfObject.fw_detailTextEdgeInsets.bottom
                detailTextFrame.size.width = min(detailTextFrame.width, selfObject.contentView.bounds.width - detailTextFrame.minX)
            }
            
            if hasImageInset {
                selfObject.imageView?.frame = imageFrame
            }
            if hasImageInset || hasTextInset {
                selfObject.textLabel?.frame = textFrame
            }
            if hasImageInset || hasDetailTextInset {
                selfObject.detailTextLabel?.frame = detailTextFrame
            }
            
            if hasAccessoryInset {
                if let textLabel = selfObject.textLabel, textLabel.frame.maxX > selfObject.contentView.bounds.width {
                    var textLabelFrame = textLabel.frame
                    textLabelFrame.size.width = selfObject.contentView.bounds.width - textLabelFrame.minX
                    textLabel.frame = textLabelFrame
                }
                if let detailTextLabel = selfObject.detailTextLabel, detailTextLabel.frame.maxX > selfObject.contentView.bounds.width {
                    var detailTextLabelFrame = detailTextLabel.frame
                    detailTextLabelFrame.size.width = selfObject.contentView.bounds.width - detailTextLabelFrame.minX
                    detailTextLabel.frame = detailTextLabelFrame
                }
            }
        }}
    }
    
}

// MARK: - UICollectionView+UIKit
@_spi(FW) extension UICollectionView {
    
    /// reloadData完成回调
    public func fw_reloadData(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0) {
            self.reloadData()
        } completion: { _ in
            completion?()
        }
    }
    
    /// reloadData禁用动画
    public func fw_reloadDataWithoutAnimation() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.reloadData()
        CATransaction.commit()
    }
    
    /// 判断indexPath是否有效
    public func fw_isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        guard indexPath.section >= 0, indexPath.item >= 0 else { return false }
        guard indexPath.section < numberOfSections else { return false }
        return indexPath.item < numberOfItems(inSection: indexPath.section)
    }
    
    /// 计算指定indexPath的frame，并转换为指定视图坐标(nil时默认window)
    public func fw_layoutFrame(at indexPath: IndexPath, to view: UIView?) -> CGRect? {
        guard var layoutFrame = layoutAttributesForItem(at: indexPath)?.frame else {
            return nil
        }
        
        layoutFrame = convert(layoutFrame, to: view)
        return layoutFrame
    }
    
    /// 添加拖动排序手势，需结合canMove、moveItem、targetIndexPath使用
    @discardableResult
    public func fw_addMovementGesture(customBlock: ((UILongPressGestureRecognizer) -> Bool)? = nil) -> UILongPressGestureRecognizer {
        fw_movementGestureBlock = customBlock
        
        let movementGesture = UILongPressGestureRecognizer(target: self, action: #selector(fw_movementGestureAction(_:)))
        addGestureRecognizer(movementGesture)
        return movementGesture
    }
    
    private var fw_movementGestureBlock: ((UILongPressGestureRecognizer) -> Bool)? {
        get { return fw.property(forName: #function) as? (UILongPressGestureRecognizer) -> Bool }
        set { fw.setPropertyCopy(newValue, forName: #function) }
    }
    
    @objc private func fw_movementGestureAction(_ gesture: UILongPressGestureRecognizer) {
        if let customBlock = fw_movementGestureBlock,
           !customBlock(gesture) { return }
        
        switch gesture.state {
        case .began:
            if let indexPath = indexPathForItem(at: gesture.location(in: self)) {
                beginInteractiveMovementForItem(at: indexPath)
            }
        case .changed:
            updateInteractiveMovementTargetPosition(gesture.location(in: self))
        case .ended:
            endInteractiveMovement()
        default:
            cancelInteractiveMovement()
        }
    }
    
    /// 简单曝光方案，willDisplay调用即可，集合快速滑动、数据不变等情况不计曝光。如需完整曝光方案，请使用StatisticalView
    public func fw_willDisplay(_ cell: UICollectionViewCell, at indexPath: IndexPath, key: AnyHashable? = nil, exposure: @escaping () -> Void) {
        let identifier = "\(indexPath.section).\(indexPath.row)-\(String.fw.safeString(key))"
        let block: (UICollectionViewCell) -> Void = { [weak self] cell in
            let previousIdentifier = cell.fw.property(forName: "fw_willDisplayIdentifier") as? String
            guard self?.visibleCells.contains(cell) ?? false,
                  self?.indexPath(for: cell) != nil,
                  identifier != previousIdentifier else { return }
            
            exposure()
            cell.fw.setPropertyCopy(identifier, forName: "fw_willDisplayIdentifier")
        }
        cell.fw.setPropertyCopy(block, forName: "fw_willDisplay")
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fw_willDisplay(_:)), object: cell)
        perform(#selector(fw_willDisplay(_:)), with: cell, afterDelay: 0.2, inModes: [.default])
    }
    
    @objc private func fw_willDisplay(_ cell: UICollectionViewCell) {
        let block = cell.fw.property(forName: "fw_willDisplay") as? (UICollectionViewCell) -> Void
        block?(cell)
    }
    
}

// MARK: - UICollectionViewCell+UIKit
@_spi(FW) extension UICollectionViewCell {
    
    /// 获取当前所属collectionView
    public weak var fw_collectionView: UICollectionView? {
        var superview = self.superview
        while superview != nil {
            if let collectionView = superview as? UICollectionView {
                return collectionView
            }
            superview = superview?.superview
        }
        return nil
    }

    /// 获取当前显示indexPath
    public var fw_indexPath: IndexPath? {
        return fw_collectionView?.indexPath(for: self)
    }
    
    /// 执行所属collectionView的批量更新
    public func fw_performBatchUpdates(
        _ updates: ((UICollectionView, IndexPath?) -> Void)?,
        completion: ((UICollectionView, IndexPath?, Bool) -> Void)? = nil
    ) {
        guard let collectionView = fw_collectionView else { return }
        
        collectionView.performBatchUpdates(updates != nil ? { [weak self] in
            let indexPath = self != nil ? collectionView.indexPath(for: self!) : nil
            updates?(collectionView, indexPath)
        } : nil, completion: completion != nil ? { [weak self] finished in
            let indexPath = self != nil ? collectionView.indexPath(for: self!) : nil
            completion?(collectionView, indexPath, finished)
        } : nil)
    }
    
}

// MARK: - UISearchBar+UIKit
@_spi(FW) extension UISearchBar {
    
    /// 自定义内容边距，可调整左右距离和TextField高度，未设置时为系统默认
    ///
    /// 如需设置UISearchBar为navigationItem.titleView，请使用ExpandedTitleView
    public var fw_contentInset: UIEdgeInsets {
        get {
            if let value = fw.property(forName: "fw_contentInset") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            fw.setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_contentInset")
            self.setNeedsLayout()
        }
    }

    /// 自定义取消按钮边距，未设置时为系统默认
    public var fw_cancelButtonInset: UIEdgeInsets {
        get {
            if let value = fw.property(forName: "fw_cancelButtonInset") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            fw.setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_cancelButtonInset")
            self.setNeedsLayout()
        }
    }

    /// 输入框内部视图
    public var fw_textField: UISearchTextField {
        return searchTextField
    }

    /// 取消按钮内部视图，showsCancelButton开启后才存在
    public weak var fw_cancelButton: UIButton? {
        return fw.invokeGetter("cancelButton") as? UIButton
    }
    
    /// 输入框的文字颜色
    public var fw_textColor: UIColor? {
        get {
            fw.property(forName: #function) as? UIColor
        }
        set {
            fw.setProperty(newValue, forName: #function)
            searchTextField.textColor = newValue
        }
    }
    
    /// 输入框的字体，会同时影响placeholder的字体
    public var fw_font: UIFont? {
        get {
            fw.property(forName: #function) as? UIFont
        }
        set {
            fw.setProperty(newValue, forName: #function)
            if let placeholder = self.placeholder {
                self.placeholder = placeholder
            }
            searchTextField.font = newValue
        }
    }
    
    /// 输入框内placeholder的颜色
    public var fw_placeholderColor: UIColor? {
        get {
            fw.property(forName: #function) as? UIColor
        }
        set {
            fw.setProperty(newValue, forName: #function)
            if let placeholder = self.placeholder {
                self.placeholder = placeholder
            }
        }
    }

    /// 设置整体背景色
    public var fw_backgroundColor: UIColor? {
        get {
            return fw.property(forName: "fw_backgroundColor") as? UIColor
        }
        set {
            fw.setProperty(newValue, forName: "fw_backgroundColor")
            self.backgroundImage = UIImage.fw_image(color: newValue)
        }
    }

    /// 设置输入框背景色
    public var fw_textFieldBackgroundColor: UIColor? {
        get { fw_textField.backgroundColor }
        set { fw_textField.backgroundColor = newValue }
    }

    /// 设置搜索图标离左侧的偏移位置，非居中时生效
    public var fw_searchIconOffset: CGFloat {
        get {
            if let value = fw.propertyNumber(forName: "fw_searchIconOffset") {
                return value.doubleValue
            }
            return self.positionAdjustment(for: .search).horizontal
        }
        set {
            fw.setPropertyNumber(NSNumber(value: newValue), forName: "fw_searchIconOffset")
            self.setPositionAdjustment(UIOffset(horizontal: newValue, vertical: 0), for: .search)
        }
    }
    
    /// 设置清空图标离右侧的偏移位置
    public var fw_clearIconOffset: CGFloat {
        get {
            if let value = fw.propertyNumber(forName: "fw_clearIconOffset") {
                return value.doubleValue
            }
            return self.positionAdjustment(for: .clear).horizontal
        }
        set {
            fw.setPropertyNumber(NSNumber(value: newValue), forName: "fw_clearIconOffset")
            self.setPositionAdjustment(UIOffset(horizontal: newValue, vertical: 0), for: .clear)
        }
    }

    /// 设置搜索文本离左侧图标的偏移位置
    public var fw_searchTextOffset: CGFloat {
        get { return self.searchTextPositionAdjustment.horizontal }
        set { self.searchTextPositionAdjustment = UIOffset(horizontal: newValue, vertical: 0) }
    }

    /// 设置TextField搜索图标(placeholder)是否居中，否则居左
    public var fw_searchIconCenter: Bool {
        get {
            return fw.propertyBool(forName: "fw_searchIconCenter")
        }
        set {
            fw.setPropertyBool(newValue, forName: "fw_searchIconCenter")
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    /// 强制取消按钮一直可点击，需在showsCancelButton设置之后生效。默认SearchBar失去焦点之后取消按钮不可点击
    public var fw_forceCancelButtonEnabled: Bool {
        get {
            return fw.propertyBool(forName: "fw_forceCancelButtonEnabled")
        }
        set {
            fw.setPropertyBool(newValue, forName: "fw_forceCancelButtonEnabled")
            guard let cancelButton = fw_cancelButton else { return }
            if newValue {
                cancelButton.isEnabled = true
                cancelButton.fw.observeProperty(\.isEnabled) { object, _ in
                    if !object.isEnabled { object.isEnabled = true }
                }
            } else {
                cancelButton.fw.unobserveProperty(\.isEnabled)
            }
        }
    }
    
    fileprivate static func fw_swizzleUIKitSearchBar() {
        NSObject.fw.swizzleInstanceMethod(
            UISearchBar.self,
            selector: #selector(UISearchBar.layoutSubviews),
            methodSignature: (@convention(c) (UISearchBar, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UISearchBar) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if let isCenterValue = selfObject.fw.propertyNumber(forName: "fw_searchIconCenter") {
                if !isCenterValue.boolValue {
                    let offset = selfObject.fw.propertyNumber(forName: "fw_searchIconOffset")
                    selfObject.setPositionAdjustment(UIOffset(horizontal: offset?.doubleValue ?? 0, vertical: 0), for: .search)
                } else {
                    let textField = selfObject.fw_textField
                    var attributes: [NSAttributedString.Key: Any]?
                    if let font = textField.font {
                        attributes = [.font: font]
                    }
                    let placeholderWidth = (selfObject.placeholder as? NSString)?.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attributes, context: nil).size.width ?? .zero
                    let textOffset = 4 + selfObject.searchTextPositionAdjustment.horizontal
                    let iconWidth = textField.leftView?.frame.size.width ?? 0
                    let targetWidth = textField.frame.size.width - ceil(placeholderWidth) - textOffset - iconWidth
                    let position = targetWidth / 2.0 - 6.0
                    selfObject.setPositionAdjustment(UIOffset(horizontal: position > 0 ? position : 0, vertical: 0), for: .search)
                }
            }
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UISearchBar.self,
            selector: #selector(setter: UISearchBar.placeholder),
            methodSignature: (@convention(c) (UISearchBar, Selector, String?) -> Void).self,
            swizzleSignature: (@convention(block) (UISearchBar, String?) -> Void).self
        ) { store in { selfObject, placeholder in
            store.original(selfObject, store.selector, placeholder)
            
            if selfObject.fw_placeholderColor != nil || selfObject.fw_font != nil {
                guard let attrString = selfObject.searchTextField.attributedPlaceholder?.mutableCopy() as? NSMutableAttributedString else { return }
                
                if let placeholderColor = selfObject.fw_placeholderColor {
                    attrString.addAttribute(.foregroundColor, value: placeholderColor, range: NSMakeRange(0, attrString.length))
                }
                if let font = selfObject.fw_font {
                    attrString.addAttribute(.font, value: font, range: NSMakeRange(0, attrString.length))
                }
                // 默认移除文字阴影
                attrString.removeAttribute(.shadow, range: NSMakeRange(0, attrString.length))
                selfObject.searchTextField.attributedPlaceholder = attrString
            }
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UISearchBar.self,
            selector: #selector(UISearchBar.didMoveToWindow),
            methodSignature: (@convention(c) (UISearchBar, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UISearchBar) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.fw_placeholderColor != nil {
                let placeholder = selfObject.placeholder
                selfObject.placeholder = placeholder
            }
        }}
        
        // iOS13因为层级关系变化，兼容处理
        NSObject.fw.swizzleMethod(
            objc_getClass("UISearchBarTextField"),
            selector: #selector(setter: UITextField.frame),
            methodSignature: (@convention(c) (UITextField, Selector, CGRect) -> Void).self,
            swizzleSignature: (@convention(block) (UITextField, CGRect) -> Void).self
        ) { store in { selfObject, aFrame in
            var frame = aFrame
            let searchBar = selfObject.superview?.superview?.superview as? UISearchBar
            if let searchBar = searchBar {
                var textFieldMaxX = searchBar.bounds.size.width
                if let cancelInsetValue = searchBar.fw.property(forName: "fw_cancelButtonInset") as? NSValue,
                   let cancelButton = searchBar.fw_cancelButton {
                    let cancelInset = cancelInsetValue.uiEdgeInsetsValue
                    let cancelWidth = cancelButton.sizeThatFits(searchBar.bounds.size).width
                    textFieldMaxX = searchBar.bounds.size.width - cancelWidth - cancelInset.left - cancelInset.right
                    frame.size.width = textFieldMaxX - frame.origin.x
                }
                
                if let contentInsetValue = searchBar.fw.property(forName: "fw_contentInset") as? NSValue {
                    let contentInset = contentInsetValue.uiEdgeInsetsValue
                    frame = CGRect(x: contentInset.left, y: contentInset.top, width: textFieldMaxX - contentInset.left - contentInset.right, height: searchBar.bounds.size.height - contentInset.top - contentInset.bottom)
                }
            }
            
            store.original(selfObject, store.selector, frame)
        }}
        
        NSObject.fw.swizzleMethod(
            objc_getClass("UINavigationButton"),
            selector: #selector(setter: UIButton.frame),
            methodSignature: (@convention(c) (UIButton, Selector, CGRect) -> Void).self,
            swizzleSignature: (@convention(block) (UIButton, CGRect) -> Void).self
        ) { store in { selfObject, aFrame in
            var frame = aFrame
            let searchBar: UISearchBar? = selfObject.superview?.superview?.superview as? UISearchBar
            if let searchBar = searchBar,
               let cancelInsetValue = searchBar.fw.property(forName: "fw_cancelButtonInset") as? NSValue {
                let cancelInset = cancelInsetValue.uiEdgeInsetsValue
                let cancelWidth = selfObject.sizeThatFits(searchBar.bounds.size).width
                frame.origin.x = searchBar.bounds.size.width - cancelWidth - cancelInset.right
                frame.origin.y = cancelInset.top
                frame.size.height = searchBar.bounds.size.height - cancelInset.top - cancelInset.bottom
            }
            
            store.original(selfObject, store.selector, frame)
        }}
    }
    
}

// MARK: - UIViewController+UIKit
@_spi(FW) extension UIViewController {
    
    /// 判断当前控制器是否是头部控制器。如果是导航栏的第一个控制器或者不含有导航栏，则返回YES
    public var fw_isHead: Bool {
        return self.navigationController == nil ||
            self.navigationController?.viewControllers.first == self
    }
    
    /// 判断当前控制器是否是尾部控制器。如果是导航栏的最后一个控制器或者不含有导航栏，则返回YES
    public var fw_isTail: Bool {
        return self.navigationController == nil ||
            self.navigationController?.viewControllers.last == self
    }

    /// 判断当前控制器是否是子控制器。如果父控制器存在，且不是导航栏或标签栏控制器，则返回YES
    public var fw_isChild: Bool {
        if let parent = self.parent,
           !(parent is UINavigationController),
           !(parent is UITabBarController) {
            return true
        }
        return false
    }

    /// 判断当前控制器是否是present弹出。如果是导航栏的第一个控制器且导航栏是present弹出，也返回YES
    public var fw_isPresented: Bool {
        var viewController: UIViewController = self
        if let navigationController = self.navigationController {
            if navigationController.viewControllers.first != self { return false }
            viewController = navigationController
        }
        return viewController.presentingViewController?.presentedViewController == viewController
    }

    /// 判断当前控制器是否是iOS13+默认pageSheet弹出样式。该样式下导航栏高度等与默认样式不同
    public var fw_isPageSheet: Bool {
        let controller: UIViewController = self.navigationController ?? self
        if controller.presentingViewController == nil { return false }
        let style = controller.modalPresentationStyle
        if style == .automatic || style == .pageSheet { return true }
        return false
    }

    /// 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
    public var fw_isViewVisible: Bool {
        return self.isViewLoaded && self.view.window != nil
    }
    
    /// 控制器是否可见，视图可见、尾部控制器、且不含presented控制器时为YES
    public var fw_isVisible: Bool {
        return fw_isViewVisible && fw_isTail && presentedViewController == nil
    }
    
    /// 获取祖先视图，标签栏存在时为标签栏根视图，导航栏存在时为导航栏根视图，否则为控制器根视图
    public var fw_ancestorView: UIView {
        if let navigationController = self.tabBarController?.navigationController {
            return navigationController.view
        } else if let tabBarController = self.tabBarController {
            return tabBarController.view
        } else if let navigationController = self.navigationController {
            return navigationController.view
        } else {
            return self.view
        }
    }

    /// 是否已经加载完数据，默认NO，加载数据完成后可标记为YES，可用于第一次加载时显示loading等判断
    public var fw_isDataLoaded: Bool {
        get { return fw.propertyBool(forName: "fw_isDataLoaded") }
        set { fw.setPropertyBool(newValue, forName: "fw_isDataLoaded") }
    }
    
    /// 移除子控制器，解决不能触发viewWillAppear等的bug
    public func fw_removeChild(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.removeFromParent()
        viewController.view.removeFromSuperview()
    }
    
    /// 添加子控制器到当前视图，解决不能触发viewWillAppear等的bug
    public func fw_addChild(_ viewController: UIViewController, layout: ((UIView) -> Void)? = nil) {
        fw_addChild(viewController, in: nil, layout: layout)
    }

    /// 添加子控制器到指定视图，解决不能触发viewWillAppear等的bug
    public func fw_addChild(_ viewController: UIViewController, in view: UIView?, layout: ((UIView) -> Void)? = nil) {
        self.addChild(viewController)
        let superview: UIView = view ?? self.view
        superview.addSubview(viewController.view)
        if layout != nil {
            layout?(viewController.view)
        } else {
            viewController.view.fw_pinEdges()
        }
        viewController.didMove(toParent: self)
    }
    
    /// 弹出popover控制器
    public func fw_presentPopover(
        _ popover: UIViewController,
        sourcePoint: CGPoint,
        size: CGSize? = nil,
        delegate: (any UIPopoverPresentationControllerDelegate)? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        popover.modalPresentationStyle = .popover
        if let size = size {
            popover.preferredContentSize = size
        }
        
        if let presentation = popover.popoverPresentationController {
            presentation.sourceView = view
            presentation.sourceRect = CGRect(origin: sourcePoint, size: .zero)
            presentation.delegate = delegate
        }
        
        present(popover, animated: animated, completion: completion)
    }
    
}

// MARK: - FrameworkAutoloader+UIKit
@objc extension FrameworkAutoloader {
    
    static func loadToolkit_UIKit() {
        UIView.fw_swizzleUIKitView()
        UILabel.fw_swizzleUIKitLabel()
        UIControl.fw_swizzleUIKitControl()
        UIButton.fw_swizzleUIKitButton()
        UISwitch.fw_swizzleUIKitSwitch()
        UITextField.fw_swizzleUIKitTextField()
        UITextView.fw_swizzleUIKitTextView()
        UISearchBar.fw_swizzleUIKitSearchBar()
    }
    
}
