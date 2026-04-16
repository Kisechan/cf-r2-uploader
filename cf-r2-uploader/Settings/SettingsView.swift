import CFR2Core
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let didSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Form {
                TextField("Profile 名称", text: $viewModel.profileName)
                TextField("Account ID", text: $viewModel.accountID)
                TextField("Bucket", text: $viewModel.bucket)
                TextField("公开域名", text: $viewModel.publicBaseURL)
                TextField("Key 前缀", text: $viewModel.keyPrefix)
                TextField("Cache-Control", text: $viewModel.cacheControl)

                Picker("默认输出", selection: $viewModel.defaultOutput) {
                    Text("URL").tag(UploadOutputFormat.url)
                    Text("Markdown").tag(UploadOutputFormat.markdown)
                }
                TextField("Access Key ID", text: $viewModel.accessKeyID)
                SecureField("Secret Access Key", text: $viewModel.secretAccessKey)
            }
            .formStyle(.grouped)

            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            HStack {
                Spacer()

                Button("重新加载") {
                    viewModel.reload()
                }

                Button("保存") {
                    viewModel.save()
                    didSave()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }
}
