import ArgumentParser

struct CFR2UploaderCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cfr2uploader",
        abstract: "上传本地文件到 Cloudflare R2，并读取上传日志。",
        subcommands: [UploadCommand.self, LogsCommand.self],
        defaultSubcommand: UploadCommand.self
    )
}

CFR2UploaderCLI.main()
