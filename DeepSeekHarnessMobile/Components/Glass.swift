import SwiftUI

/// 明确选择软边缘，避免系统版本变化把滚动正文的渐进模糊切回硬质背景。
struct ConversationScrollEdgeStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            content
        }
    }
}

struct GlassSurface: ViewModifier {
    let radius: CGFloat
    let dark: Bool
    let tint: Color?
    let clear: Bool
    let shadowOpacity: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if clear {
                if let tint {
                    content
                        .glassEffect(.clear.tint(tint), in: .rect(cornerRadius: radius))
                } else {
                    content
                        .glassEffect(.clear, in: .rect(cornerRadius: radius))
                }
            } else {
                if let tint {
                    content
                        .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: radius))
                } else {
                    content
                        .glassEffect(.regular, in: .rect(cornerRadius: radius))
                }
            }
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(dark ? AnyShapeStyle(.ultraThinMaterial.opacity(tint == nil ? 0.75 : 0.82)) : AnyShapeStyle(.thinMaterial))
                        .overlay {
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .fill(tint ?? .clear)
                        }
                }
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(.white.opacity(dark ? 0.2 : 0.7), lineWidth: 0.8))
                .shadow(color: DSHColor.navy.opacity(shadowOpacity), radius: 16, y: 8)
        }
    }
}

extension View {
    func glassSurface(radius: CGFloat = 22, dark: Bool = false, tint: Color? = nil, clear: Bool = false, shadowOpacity: Double = 0.18) -> some View {
        modifier(GlassSurface(radius: radius, dark: dark, tint: tint, clear: clear, shadowOpacity: shadowOpacity))
    }

    /// Button 与 Menu 共用原生圆形液态玻璃交互，旧系统沿用材质样式。
    @ViewBuilder
    func glassCircleButton(onDarkBackground: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if onDarkBackground {
                // 深色动态背景使用透明玻璃，避免默认材质适配时出现浅色实心填充。
                self
                    .buttonStyle(.glass(.clear.tint(DSHColor.navy.opacity(0.22))))
                    .buttonBorderShape(.circle)
            } else {
                self
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
            }
        } else {
            self
                .buttonStyle(.plain)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 0.8))
        }
    }
}

struct ConnectionDot: View {
    let state: ConnectionState

    private var color: Color {
        switch state {
        case .connected:
            DSHColor.success
        case .failed, .connecting, .disconnected:
            .red
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: color.opacity(0.65), radius: 5)
    }
}

/// 品牌字标：`DeepSeek` + `HARNESS` 小标签。
/// 首页（深蓝底）与侧边栏（浅色底）共用；按 `width` 等比缩放，尺寸与旧版字标一致。
struct HarnessMark: View {
    var onDarkBackground = true
    var width: CGFloat = 216

    private var scale: CGFloat { max(0.55, width / 216) }
    private var primaryColor: Color { onDarkBackground ? .white : .black }
    private var tagBackground: Color { onDarkBackground ? .white : .black }
    private var tagForeground: Color { onDarkBackground ? .black : .white }

    var body: some View {
        HStack(spacing: 8 * scale) {
            Text("DeepSeek")
                .font(.system(size: 28 * scale, weight: .bold))
                .foregroundStyle(primaryColor)
                .fixedSize()
            Text("HARNESS")
                .font(.system(size: 11 * scale, weight: .bold))
                .tracking(0.6 * scale)
                .foregroundStyle(tagForeground)
                .padding(.horizontal, 6 * scale)
                .padding(.vertical, 3 * scale)
                .background(
                    RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                        .fill(tagBackground)
                )
                .fixedSize()
        }
        .frame(maxWidth: width, alignment: .leading)
        .accessibilityLabel("DeepSeek Harness")
    }
}

struct WhalenessOrcaIcon: View {
    var size: CGFloat

    var body: some View {
        Image("DshOrcaMark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

extension View {
    @ViewBuilder
    func colorInvertIfNeeded(_ inverted: Bool) -> some View {
        if inverted { colorInvert() } else { self }
    }
}
