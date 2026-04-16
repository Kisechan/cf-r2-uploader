import CFR2Core
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    let openSettings: () -> Void
    @State private var didAppear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusCard

            if viewModel.isConfigured {
                Text("当前 Profile：\(viewModel.activeProfileName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            VStack(spacing: 8) {
                Button {
                    viewModel.selectAndUpload()
                } label: {
                    Label("选择图片并上传", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isUploading)

                Button {
                    viewModel.uploadFromClipboard()
                } label: {
                    Label("从剪贴板上传", systemImage: "clipboard")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isUploading || !viewModel.canUploadFromClipboard)
            }

            Divider()

            if viewModel.recentItems.isEmpty {
                Text("暂无上传记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近上传")
                        .font(.subheadline.weight(.medium))

                    ForEach(Array(viewModel.recentItems.prefix(5))) { item in
                        Link(destination: item.publicURL) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.fileName)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text(item.publicURL.absoluteString)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !viewModel.recentLogs.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("最近 API 日志")
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        Button("打开日志文件") {
                            viewModel.openLogFile()
                        }
                        .buttonStyle(.link)
                    }

                    ForEach(viewModel.recentLogs.prefix(3)) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: entry.outcome == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(entry.outcome == .success ? .green : .orange)
                                Text(entry.objectKey)
                                    .font(.caption)
                                    .lineLimit(1)
                            }

                            Text(logSubtitle(entry))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }

            Divider()

            HStack {
                SettingsLink {
                    Label("设置", systemImage: "gearshape")
                }
                .simultaneousGesture(TapGesture().onEnded {
                    openSettings()
                })

                Spacer()

                Button("退出") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(14)
        .frame(width: 360)
        .background(.regularMaterial)
        .opacity(didAppear ? 1 : 0)
        .offset(y: didAppear ? 0 : 10)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: didAppear)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: viewModel.statusText)
        .onAppear {
            didAppear = true
            viewModel.refreshClipboardAvailability()
        }
    }

    private var statusCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: viewModel.statusIconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(statusTint)
                .frame(width: 28)
                .symbolEffect(.pulse.byLayer, isActive: viewModel.isUploading)

            VStack(alignment: .leading, spacing: 4) {
                Text("CFR2Uploader")
                    .font(.headline)

                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                if viewModel.isUploading {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(statusBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.2))
        )
    }

    private var statusTint: Color {
        switch viewModel.state {
        case .idle:
            return viewModel.isConfigured ? .accentColor : .orange
        case .uploading:
            return .accentColor
        case .succeeded:
            return .green
        case .failed:
            return .orange
        }
    }

    private var statusBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                statusTint.opacity(0.18),
                Color.black.opacity(0.06),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func logSubtitle(_ entry: R2RequestLogEntry) -> String {
        let statusText = entry.statusCode.map { "HTTP \($0)" } ?? "无状态码"
        return "\(statusText) · \(entry.durationMilliseconds)ms · \(entry.message)"
    }
}
