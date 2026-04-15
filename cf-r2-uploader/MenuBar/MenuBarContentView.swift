import CFR2Core
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CFR2Uploader")
                    .font(.headline)

                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            if viewModel.isConfigured {
                Text("当前 Profile：\(viewModel.activeProfileName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.selectAndUpload()
            } label: {
                Label("选择图片并上传", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)
            .disabled({
                if case .uploading = viewModel.state {
                    return true
                }
                return false
            }())

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
    }
}
