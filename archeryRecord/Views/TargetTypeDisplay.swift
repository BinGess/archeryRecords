import Foundation

enum TargetTypeDisplay {
    struct Item {
        let rawValue: String
        let primaryTitle: String
        let subtitle: String?
    }

    private enum Kind {
        case standard122
        case full80
        case full40
        case triple40Vertical
        case triple40Triangle
        case indoor60
        case compoundInner10
    }

    static func item(for rawValue: String) -> Item {
        guard let kind = kind(for: rawValue) else {
            return Item(rawValue: rawValue, primaryTitle: rawValue, subtitle: nil)
        }

        return Item(
            rawValue: rawValue,
            primaryTitle: primaryTitle(for: kind),
            subtitle: subtitle(for: kind)
        )
    }

    static func primaryTitle(for rawValue: String) -> String {
        item(for: rawValue).primaryTitle
    }

    static func subtitle(for rawValue: String) -> String? {
        item(for: rawValue).subtitle
    }

    static func isKnownTargetType(_ rawValue: String) -> Bool {
        kind(for: rawValue) != nil
    }

    private static func kind(for rawValue: String) -> Kind? {
        switch rawValue {
        case L10n.Options.TargetType.t122cmStandard:
            return .standard122
        case L10n.Options.TargetType.t80cmFull:
            return .full80
        case L10n.Options.TargetType.t40cmFull:
            return .full40
        case L10n.Options.TargetType.t40cmTripleVertical:
            return .triple40Vertical
        case L10n.Options.TargetType.t40cmTripleTriangle:
            return .triple40Triangle
        case L10n.Options.TargetType.t60cmIndoor:
            return .indoor60
        case L10n.Options.TargetType.tCompoundInner10:
            return .compoundInner10
        default:
            return nil
        }
    }

    private static func primaryTitle(for kind: Kind) -> String {
        switch kind {
        case .standard122:
            return "122cm"
        case .full80, .indoor60:
            switch LocalizationManager.persistedLanguageCode() {
            case "ja":
                return "インドアターゲット"
            case "en":
                return "Indoor Target"
            default:
                return "室内靶"
            }
        case .full40, .triple40Vertical, .triple40Triangle:
            return "40cm"
        case .compoundInner10:
            switch LocalizationManager.persistedLanguageCode() {
            case "ja":
                return "コンパウンド"
            case "en":
                return "Compound"
            default:
                return "复合弓靶"
            }
        }
    }

    private static func subtitle(for kind: Kind) -> String? {
        switch LocalizationManager.persistedLanguageCode() {
        case "ja":
            switch kind {
            case .standard122:
                return "標準屋外"
            case .full80, .indoor60:
                return nil
            case .full40:
                return "標準的"
            case .triple40Vertical:
                return "トリプル・縦"
            case .triple40Triangle:
                return "トリプル・三角"
            case .compoundInner10:
                return "内10点"
            }
        case "en":
            switch kind {
            case .standard122:
                return "Standard Outdoor"
            case .full80, .indoor60:
                return nil
            case .full40:
                return "Standard Target"
            case .triple40Vertical:
                return "Triple Vertical"
            case .triple40Triangle:
                return "Triple Triangle"
            case .compoundInner10:
                return "Inner 10-Ring"
            }
        default:
            switch kind {
            case .standard122:
                return "标准室外"
            case .full80, .indoor60:
                return nil
            case .full40:
                return "标准靶"
            case .triple40Vertical:
                return "三联靶·竖排"
            case .triple40Triangle:
                return "三联靶·三角"
            case .compoundInner10:
                return "内10环"
            }
        }
    }
}
