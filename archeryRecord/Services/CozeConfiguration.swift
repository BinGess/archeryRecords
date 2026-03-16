import Foundation

struct CozeConfiguration {
    let accessToken: String
    let botId: String
    let baseURL: String

    var isConfigured: Bool {
        !accessToken.isEmpty && !botId.isEmpty && !baseURL.isEmpty
    }

    static let empty = CozeConfiguration(accessToken: "", botId: "", baseURL: "")

    static func load(bundle: Bundle = .main) -> CozeConfiguration? {
        guard let url = bundle.url(forResource: "CozeSecrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        struct Secrets: Decodable {
            let AccessToken: String
            let BotID: String
            let BaseURL: String
        }

        guard let secrets = try? PropertyListDecoder().decode(Secrets.self, from: data) else {
            return nil
        }

        return CozeConfiguration(
            accessToken: secrets.AccessToken.trimmingCharacters(in: .whitespacesAndNewlines),
            botId: secrets.BotID.trimmingCharacters(in: .whitespacesAndNewlines),
            baseURL: secrets.BaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
