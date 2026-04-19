import Foundation
import SwiftUI

@MainActor
final class LocalizationManager: ObservableObject {
    struct LanguageOption: Identifiable, Equatable {
        let code: String
        let displayName: String

        var id: String { code }
    }

    nonisolated static let appLanguageKey = "AppLanguage"
    nonisolated static let supportedLanguages: [LanguageOption] = [
        LanguageOption(code: "en", displayName: "English"),
        LanguageOption(code: "ja", displayName: "日本語"),
        LanguageOption(code: "zh-Hans", displayName: "简体中文"),
        LanguageOption(code: "zh-Hant", displayName: "繁體中文"),
        LanguageOption(code: "zh-HK", displayName: "繁體中文（香港）")
    ]

    @Published private(set) var currentLanguage: String
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let resolvedLanguage = Self.persistedLanguageCode(userDefaults: userDefaults)
        self.currentLanguage = resolvedLanguage
        userDefaults.set(resolvedLanguage, forKey: Self.appLanguageKey)
    }

    func setLanguage(_ languageCode: String) {
        let normalizedLanguage = Self.normalizeLanguageCode(languageCode)
        guard currentLanguage != normalizedLanguage else { return }

        currentLanguage = normalizedLanguage
        userDefaults.set(normalizedLanguage, forKey: Self.appLanguageKey)
    }

    nonisolated static func persistedLanguageCode(userDefaults: UserDefaults = .standard) -> String {
        let preferredLanguage = userDefaults.string(forKey: appLanguageKey) ?? Locale.preferredLanguages.first ?? "en"
        return normalizeLanguageCode(preferredLanguage)
    }

    nonisolated static func normalizeLanguageCode(_ languageCode: String) -> String {
        let normalized = languageCode.lowercased()

        if normalized.hasPrefix("zh-hk") {
            return "zh-HK"
        }

        if normalized.hasPrefix("zh-hant") || normalized.hasPrefix("zh-tw") || normalized.hasPrefix("zh-mo") {
            return "zh-Hant"
        }

        if normalized.hasPrefix("zh") {
            return "zh-Hans"
        }

        if normalized.hasPrefix("ja") {
            return "ja"
        }

        return "en"
    }

    nonisolated static func option(for languageCode: String) -> LanguageOption? {
        supportedLanguages.first { $0.code == normalizeLanguageCode(languageCode) }
    }

    nonisolated static func displayName(for languageCode: String) -> String {
        option(for: languageCode)?.displayName ?? normalizeLanguageCode(languageCode)
    }
}

enum L10n {
    private static let bundle = Bundle.main
    
    static func tr(_ key: String) -> String {
        let languageCode = LocalizationManager.persistedLanguageCode()
        let languageBundle = Bundle(path: bundle.path(
            forResource: languageCode,
            ofType: "lproj"
        ) ?? bundle.path(
            forResource: "en",
            ofType: "lproj"
        ) ?? "") ?? bundle
        
        return NSLocalizedString(
            key,
            tableName: "Localizable",
            bundle: languageBundle,
            value: "",
            comment: ""
        )
    }
    
    static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = tr(key)
        return String(format: format, arguments: args)
    }
    
    static func setLanguage(_ languageCode: String) {
        UserDefaults.standard.set(
            LocalizationManager.normalizeLanguageCode(languageCode),
            forKey: LocalizationManager.appLanguageKey
        )
    }
    
    static func getCurrentLanguage() -> String {
        LocalizationManager.persistedLanguageCode()
    }
    
    static func getSupportedLanguages() -> [String] {
        LocalizationManager.supportedLanguages.map(\.code)
    }
    
    struct Common {     
        static var save: String { tr("save") }
        static var cancel: String { tr("cancel") }
        static var back: String { tr("back") }
        static var noData: String { tr("noData") }
        static var done: String { tr("common_done") }
        static var delete: String { tr("common_delete") }
        static var addmore: String { tr("common_addmore") }
 
    }
    

    

    struct Nav {
        static var record: String { tr("nav_title_record") }
        static var groupRecord: String { tr("nav_title_group_record") }
        static var analysis: String { tr("nav_title_analysis") }
    }
    
    struct Time {
        static var today: String { tr("time_today") }
        static var week: String { tr("time_week") }
        static var month: String { tr("time_month") }
        static var year: String { tr("time_year") }
    }
    
    struct Basic {
        static var options: String { tr("basic_options") }
        static var bowType: String { tr("bow_type") }
        static var distance: String { tr("distance") }
        static var targetType: String { tr("target_type") }
    }
    
    struct Score {
        static var input: String { tr("score_input") }
        static func groupInput(_ group: Int) -> String {
            return tr("group_score_input", group)
        }
        static func groupTotal(_ score: Int) -> String {
            return tr("group_score_total", score)
        }
    }

    struct ScoreInput {
    static var title: String { tr("score_input_title") }
    static var select: String { tr("score_input_select") }
    static func current(_ score: String) -> String {
        return tr("score_input_current", score)
    }
    static var cancel: String { tr("score_input_cancel") }
}

    struct Analysis {
    static var trend: String { tr("analysis_trend") }
    static var stability: String { tr("analysis_stability") }
    static var accuracy: String { tr("analysis_accuracy") }
    static var comprehensive: String { tr("analysis_comprehensive") }
    static var title: String { tr("analysis_title") }
    static var count: String { tr("analysis_count") }
    static var analysisType: String { tr("analysis_type") }
    static var timeRange: String { tr("analysis_time_range") }
//    static var trend: String { tr("analysis_trend") }
//    static var stability: String { tr("analysis_stability") }
//    static var accuracy: String { tr("analysis_accuracy") }
    static var noData: String { tr("analysis_no_data") }
    static var date: String { tr("analysis_date") }
    static var score: String { tr("analysis_score") }
    static var standardDeviation: String { tr("analysis_standard_deviation") }
    static var trendAnalysis: String { tr("analysis_trend_analysis") }
    static var statsInfo: String { tr("analysis_stats_info") }
    static var hitStats: String { tr("analysis_hit_stats") }
    static var avgScore: String { tr("analysis_avg_score") }
    static var maxScore: String { tr("analysis_max_score") }
    static var minScore: String { tr("analysis_min_score") }
    static var tenRate: String { tr("analysis_ten_rate") }
    static var nineRate: String { tr("analysis_nine_rate") }
    static var eightRate: String { tr("analysis_eight_rate") }
    
    static func ringRate(_ ring: Int, rate: Double) -> String {
        return tr("analysis_ring_rate", ring, rate)
    }
    
    // 新增稳定性分析相关
    static var stabilityLevelHigh: String { tr("analysis_stability_level_high") }
    static var stabilityLevelMedium: String { tr("analysis_stability_level_medium") }
    static var stabilityLevelLow: String { tr("analysis_stability_level_low") }
    static var stabilityDescription: String { tr("analysis_stability_description") }
    static var avgDeviation: String { tr("analysis_avg_deviation") }
    static var maxDeviation: String { tr("analysis_max_deviation") }
    static var minDeviation: String { tr("analysis_min_deviation") }
    
    // 新增命中率分析相关
    static var totalHitRate: String { tr("analysis_total_hit_rate") }
    static var goldRate: String { tr("analysis_gold_rate") }
    static var averageDeviation: String { tr("analysis_average_deviation") }
    
    // 综合分析相关
    static var overallScore: String { tr("analysis_overall_score") }
    static var averagePerArrow: String { tr("analysis_average_per_arrow") }
    static var totalArrows: String { tr("analysis_total_arrows") }
    static var abilityAnalysis: String { tr("analysis_ability_analysis") }
    static var detailedData: String { tr("analysis_detailed_data") }
    static var stabilityLevel: String { tr("analysis_stability_level") }
    static var hitRate: String { tr("analysis_hit_rate") }
    static var consistency: String { tr("analysis_consistency") }
    static var recentTrend: String { tr("analysis_recent_trend") }
}

struct Pro {
    static var badge: String { tr("pro_badge") }
    static var lifetimeTitle: String { tr("pro_lifetime_title") }
    static var lifetimeSubtitle: String { tr("pro_lifetime_subtitle") }
    static var unlockNow: String { tr("pro_unlock_now") }
    static var priceHint: String { tr("pro_lifetime_price_hint") }
    static var restore: String { tr("pro_restore") }
    static var purchaseUnavailable: String { tr("pro_purchase_unavailable") }
    static var purchasePending: String { tr("pro_purchase_pending") }
    static var purchaseFailed: String { tr("pro_purchase_failed") }
    static var benefitICloudTitle: String { tr("pro_benefit_icloud_title") }
    static var benefitICloudBody: String { tr("pro_benefit_icloud_body") }
    static var benefitVisualTitle: String { tr("pro_benefit_visual_title") }
    static var benefitVisualBody: String { tr("pro_benefit_visual_body") }
    static var benefitAnalysisTitle: String { tr("pro_benefit_analysis_title") }
    static var benefitAnalysisBody: String { tr("pro_benefit_analysis_body") }
    static var entryICloudTitle: String { tr("pro_entry_icloud_title") }
    static var entryICloudSubtitle: String { tr("pro_entry_icloud_subtitle") }
    static var entryVisualTitle: String { tr("pro_entry_visual_title") }
    static var entryVisualSubtitle: String { tr("pro_entry_visual_subtitle") }
    static var entryAnalyticsTitle: String { tr("pro_entry_analytics_title") }
    static var entryAnalyticsSubtitle: String { tr("pro_entry_analytics_subtitle") }
    static var ctaPriceFallback: String { tr("pro_cta_price_fallback") }
    static var alreadyUnlocked: String { tr("pro_already_unlocked") }
    /// Prominent copy when the user already has Pro (paywall hero).
    static var memberStatusTitle: String { tr("pro_member_status_title") }
    static var memberStatusSubtitle: String { tr("pro_member_status_subtitle") }
    static var memberStatusBadge: String { tr("pro_member_status_badge") }
    static var memberFooterHint: String { tr("pro_member_footer_hint") }
    static var memberOwnedBanner: String { tr("pro_member_owned_banner") }
    static var memberBenefitsSectionTitle: String { tr("pro_member_benefits_section_title") }
    /// Short label on the home Pro chip when unlocked.
    static var cornerUnlockedLabel: String { tr("pro_corner_unlocked_label") }
    /// Small chip next to each benefit when the user already has Pro.
    static var benefitIncludedChip: String { tr("pro_member_benefit_included") }
}

struct AnalysisUpgrade {
    static var title: String { tr("analysis_pro_title") }
    static var subtitle: String { tr("analysis_pro_subtitle") }
    static var cta: String { tr("analysis_pro_cta") }
    static var accuracy: String { tr("analysis_pro_feature_accuracy") }
    static var stability: String { tr("analysis_pro_feature_stability") }
    static var fatigue: String { tr("analysis_pro_feature_fatigue") }
}

struct Detail {
    static var totalScore: String { tr("detail_total_score") }
    static func likeCount(_ count: Int) -> String {
        return tr("detail_like_count", count)
    }
    static var ringDistribution: String { tr("detail_ring_distribution") }
    static func averageScore(_ score: Double) -> String {
        return tr("detail_average_score", score)
    }

    static var title: String { tr("detail_title") }
    static var basicInfo: String { tr("detail_basic_info") }
    static var score: String { tr("detail_score") }
    static var scoreDistribution: String { tr("detail_score_distribution") }
    static var arrowScores: String { tr("detail_arrow_scores") }
    static var deleteRecord: String { tr("detail_delete_record") }
    static var recordAgain: String { tr("detail_record_again") }
    static var deleteConfirmTitle: String { tr("detail_delete_confirm_title") }
    static var deleteConfirmMessage: String { tr("detail_delete_confirm_message") }
    static var deleteCancel: String { tr("detail_delete_cancel") }
    static var deleteConfirm: String { tr("detail_delete_confirm") }
    static var likeCount: String { tr("detail_like_count") }

}

struct CommonAction {
    static var remove: String { tr("common_remove") }
    static var keyboard: String { tr("input_mode_keyboard") }
    static var visualTarget: String { tr("input_mode_visual_target") }
}

struct Completion {
    static var summaryTitle: String { tr("completion_summary_title") }
    static var averageRing: String { tr("completion_average_ring") }
    static var highlightHits: String { tr("completion_highlight_hits") }
    static var bestArrow: String { tr("completion_best_arrow") }
    static var bowType: String { tr("completion_bow_type") }
    static var singleEyebrow: String { tr("completion_single_eyebrow") }
    static var groupEyebrow: String { tr("completion_group_eyebrow") }
    static var singleReviewTitle: String { tr("completion_single_review_title") }
    static var singleReviewCaption: String { tr("completion_single_review_caption") }
    static var groupReviewTitle: String { tr("completion_group_review_title") }
    static var groupReviewCaption: String { tr("completion_group_review_caption") }
    static var singleAgain: String { tr("completion_single_again") }
    static var groupAgain: String { tr("completion_group_again") }
    static var singleResultTitle: String { tr("completion_single_result_title") }
    static var groupResultTitle: String { tr("completion_group_result_title") }
    static var stability: String { tr("completion_stability") }
    static var bestGroup: String { tr("completion_best_group") }
    static var bestInSession: String { tr("completion_best_in_session") }
    static var ringUnit: String { tr("completion_ring_unit") }
    static var arrowUnit: String { tr("completion_arrow_unit") }
    static var pointUnit: String { tr("completion_point_unit") }

    static func singleSubtitle(arrows: Int, averageRing: Double) -> String {
        tr("completion_single_subtitle", arrows, averageRing)
    }

    static func groupSubtitle(groups: Int, arrows: Int, averageRing: Double) -> String {
        tr("completion_group_subtitle", groups, arrows, averageRing)
    }

    static func singleSummary(for averageRing: Double) -> String {
        switch averageRing {
        case 9...:
            return tr("completion_single_summary_high")
        case 7.5...:
            return tr("completion_single_summary_mid")
        default:
            return tr("completion_single_summary_low")
        }
    }

    static func groupSummary(stabilityScore: Double, averageRing: Double) -> String {
        if stabilityScore >= 88 {
            return tr("completion_group_summary_high")
        } else if averageRing >= 8 {
            return tr("completion_group_summary_mid")
        } else {
            return tr("completion_group_summary_low")
        }
    }

    static func arrowLabel(_ number: Int) -> String {
        tr("completion_arrow_label", number)
    }

    static func groupLabel(_ number: Int) -> String {
        tr("completion_group_label", number)
    }

    static func groupScore(_ score: Int) -> String {
        tr("completion_group_score", score)
    }
}

struct AnalysisCardCopy {
    static var phaseConclusion: String { tr("analysis_phase_conclusion") }
    static var phaseChart: String { tr("analysis_phase_chart") }
    static var phaseAction: String { tr("analysis_phase_action") }
    static var accuracyConclusionTitle: String { tr("analysis_accuracy_conclusion_title") }
    static var accuracyConclusionDetail: String { tr("analysis_accuracy_conclusion_detail") }
    static var impactDistributionTitle: String { tr("analysis_impact_distribution_title") }
    static var impactDistributionDetail: String { tr("analysis_impact_distribution_detail") }
    static var accuracyAdviceTitle: String { tr("analysis_accuracy_advice_title") }
    static var accuracyAdviceDetail: String { tr("analysis_accuracy_advice_detail") }
    static var stabilityConclusionTitle: String { tr("analysis_stability_conclusion_title") }
    static var stabilityConclusionDetail: String { tr("analysis_stability_conclusion_detail") }
    static var stabilityChartTitle: String { tr("analysis_stability_chart_title") }
    static var stabilityChartDetail: String { tr("analysis_stability_chart_detail") }
    static var stabilityAdviceTitle: String { tr("analysis_stability_advice_title") }
    static var stabilityAdviceDetail: String { tr("analysis_stability_advice_detail") }
    static var fatigueConclusionTitle: String { tr("analysis_fatigue_conclusion_title") }
    static var fatigueConclusionDetail: String { tr("analysis_fatigue_conclusion_detail") }
    static var fatigueTrendTitle: String { tr("analysis_fatigue_trend_title") }
    static var fatigueTrendDetail: String { tr("analysis_fatigue_trend_detail") }
    static var fatigueAdviceTitle: String { tr("analysis_fatigue_advice_title") }
    static var fatigueAdviceDetail: String { tr("analysis_fatigue_advice_detail") }
    static var comprehensiveConclusionTitle: String { tr("analysis_comprehensive_conclusion_title") }
    static var coreMetricsTitle: String { tr("analysis_core_metrics_title") }
    static var coreMetricsDetail: String { tr("analysis_core_metrics_detail") }
    static var ringStructureTitle: String { tr("analysis_ring_structure_title") }
    static var ringStructureDetail: String { tr("analysis_ring_structure_detail") }
    static var trainingAdviceTitle: String { tr("analysis_training_advice_title") }
    static var trainingAdviceDetail: String { tr("analysis_training_advice_detail") }
}

struct GroupDetail {
    static var title: String { tr("group_detail_title") }
    static var basicInfo: String { tr("group_detail_basic_info") }
    static var matchInfo: String { tr("group_detail_match_info") }
    static var totalScore: String { tr("group_detail_total_score") }
    static func likeCount(_ count: Int) -> String {
        return tr("group_detail_like_count", count)
    }
    static var groupScores: String { tr("group_detail_group_scores") }
    static func groupNumber(_ number: Int) -> String {
        return tr("group_detail_group_number", number)
    }
    static func groupScore(_ score: Int) -> String {
        return tr("group_detail_group_score", score)
    }
    static func averagePerArrow(_ average: Double) -> String {
        return tr("group_detail_average_per_arrow", average)
    }
    static var ringDistribution: String { tr("group_detail_ring_distribution") }
    static var deleteRecord: String { tr("group_detail_delete_record") }
    static var recordAgain: String { tr("group_detail_record_again") }
    static var deleteConfirm: String { tr("group_detail_delete_confirm") }
    static var deleteMessage: String { tr("group_detail_delete_message") }
}


    struct Format {
    static var dateTime: String { tr("format_date_time") }
    static var shortDate: String { tr("format_short_date") }  // 添加这一行
}

    
    struct Stats {
        static var trend: String { tr("stats_trend") }
        static var info: String { tr("stats_info") }
        static var hit: String { tr("stats_hit") }
        static var avg: String { tr("stats_avg") }
        static var max: String { tr("stats_max") }
        static var min: String { tr("stats_min") }
        static var tenRate: String { tr("stats_10_rate") }
        static var nineRate: String { tr("stats_9_rate") }
        static var eightRate: String { tr("stats_8_rate") }
    }

    struct Tab {
    static var record: String { tr("tab_record") }
    static var analysis: String { tr("tab_analysis") }
}

struct Content {
    static var trainingRecord: String { tr("content_training_record") }
    static var emptyStatePrompt: String { tr("content_empty_state_prompt") }
    static var appTitle: String { tr("content_app_title") }
    static var viewDetail: String { tr("content_view_detail") }
    static var hideDetail: String { tr("content_hide_detail") }
    static var delete: String { tr("content_delete") }
    static var score: String { tr("content_score") }
    static var totalScore: String { tr("content_total_score") }
}
    
    struct Match {
        static func type(groups: Int, arrowsPerGroup: Int, totalArrows: Int) -> String {
            return tr("match_type", groups, arrowsPerGroup, totalArrows)
        }
    }

struct Options {
    struct BowType {
        static var compound: String { tr("bow_type_compound") }
        static var meilie: String { tr("bow_type_meilie") }
        static var guanggong: String { tr("bow_type_guanggong") }
        static var recurve: String { tr("bow_type_recurve") }
        static var traditional: String { tr("bow_type_traditional") }
        
        static var all: [String] { [compound, recurve, traditional, guanggong, meilie] }
    }
    
    struct Distance {
        static var d10m: String { tr("distance_10m") }
        static var d18m: String { tr("distance_18m") }
        static var d30m: String { tr("distance_30m") }
        static var d50m: String { tr("distance_50m") }
        static var d70m: String { tr("distance_70m") }
        
        static var all: [String] { [d10m, d18m, d30m, d50m, d70m] }
    }
    
    struct TargetType {
        static var t122cmStandard: String { tr("target_type_122cm_standard") }
        static var t80cmFull: String { tr("target_type_80cm_full") }
        static var t40cmFull: String { tr("target_type_40cm_full") }
        static var t40cmTripleVertical: String { tr("target_type_40cm_triple_vertical") }
        static var t40cmTripleTriangle: String { tr("target_type_40cm_triple_triangle") }
        static var t60cmIndoor: String { tr("target_type_60cm_indoor") }
        static var tCompoundInner10: String { tr("target_type_compound_inner10") }

        static var all: [String] { [t122cmStandard, t80cmFull, t40cmFull, t40cmTripleVertical, t40cmTripleTriangle, t60cmIndoor, tCompoundInner10] }
    }
}

struct GroupInput {
    static var title: String { tr("group_input_title") }
    static var basicOptions: String { tr("group_input_basic_options") }
    static var bowType: String { tr("group_input_bow_type") }
     static var numberOfGroups: String { tr("group_input_number_of_groups") }
    static var arrowsPerGroup: String { tr("group_input_arrows_per_group") }
    static var distance: String { tr("group_input_distance") }
    static var targetType: String { tr("group_input_target_type") }
    static var matchType: String { tr("group_input_match_type") }
    static func groupScoreInput(_ group: Int, score: Int) -> String {
        return tr("group_input_score", group, score)
    }
    static var save: String { tr("group_input_save") }
    static var selectBowType: String { tr("group_input_select_bow_type") }
    static var selectDistance: String { tr("group_input_select_distance") }
    static var selectTargetType: String { tr("group_input_select_target_type") }
    static var selectMatchType: String { tr("group_input_select_match_type") }
}

struct SingleInput {
    static var title: String { tr("single_input_title") }
    static var basicOptions: String { tr("single_input_basic_options") }
    static var scoreInput: String { tr("single_input_score_input") }
    static func totalScore(_ score: Int) -> String {
        return tr("single_input_total_score", score)
    }
    static var save: String { tr("single_input_save") }
    static var selectBowType: String { tr("single_input_select_bow_type") }
    static var selectDistance: String { tr("single_input_select_distance") }
    static var selectTargetType: String { tr("single_input_select_target_type") }
    static func arrowNumber(_ number: Int) -> String {
        return tr("single_input_arrow_number", number)
    }
}

struct Settings {
    static var title: String { tr("settings_title") }
    static var language: String { tr("settings_language") }
    static var languageSelection: String { tr("settings_language_selection") }
    static var dataSync: String { tr("settings_data_sync") }
    static var iCloudSync: String { tr("settings_icloud_sync") }
    static var iCloudSyncDescription: String { tr("settings_icloud_sync_description") }
    static var about: String { tr("settings_about") }
    static var feedback: String { tr("settings_feedback") }
    static var version: String { tr("settings_version") }
}

}
