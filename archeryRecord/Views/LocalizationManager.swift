import Foundation

enum L10n {
    private static let bundle = Bundle.main
    
    // 添加当前语言的获取和设置
    private static var currentLanguage: String {
        get {
            // 首先检查用户设置的语言
            if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
                return savedLanguage
            }
            // 如果没有用户设置，则使用系统语言
            return Locale.current.languageCode ?? "en"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "AppLanguage")
            UserDefaults.standard.synchronize()
        }
    }
    
    static func tr(_ key: String) -> String {
        // 根据当前语言获取对应的本地化字符串
        let languageBundle = Bundle(path: bundle.path(
            forResource: currentLanguage,
            ofType: "lproj"
        ) ?? bundle.path(
            forResource: "Base",
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
    
    // 添加语言切换方法
    static func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        // 发送语言改变通知
        NotificationCenter.default.post(
            name: Notification.Name("LanguageChanged"),
            object: nil
        )
    }
    
    // 获取当前语言
    static func getCurrentLanguage() -> String {
        return currentLanguage
    }
    
    // 获取支持的语言列表
    static func getSupportedLanguages() -> [String] {
        return ["en", "zh"] // 添加其他支持的语言代码
    }
    
    struct Common {     
        static let save = tr("save")
        static let cancel = tr("cancel")
        static let back = tr("back")
        static let noData = tr("noData")
        static let done = tr("common_done")
        static let delete = tr("common_delete")
        static let addmore = tr("common_addmore")
 
    }
    

    

    struct Nav {
        static let record = tr("nav_title_record")
        static let groupRecord = tr("nav_title_group_record")
        static let analysis = tr("nav_title_analysis")
    }
    
    struct Time {
        static let today = tr("time_today")
        static let week = tr("time_week")
        static let month = tr("time_month")
        static let year = tr("time_year")
    }
    
    struct Basic {
        static let options = tr("basic_options")
        static let bowType = tr("bow_type")
        static let distance = tr("distance")
        static let targetType = tr("target_type")
    }
    
    struct Score {
        static let input = tr("score_input")
        static func groupInput(_ group: Int) -> String {
            return tr("group_score_input", group)
        }
        static func groupTotal(_ score: Int) -> String {
            return tr("group_score_total", score)
        }
    }

    struct ScoreInput {
    static let title = tr("score_input_title")
    static let select = tr("score_input_select")
    static func current(_ score: String) -> String {
        return tr("score_input_current", score)
    }
    static let cancel = tr("score_input_cancel")
}

    struct Analysis {
    static let trend = tr("analysis_trend")
    static let stability = tr("analysis_stability")
    static let accuracy = tr("analysis_accuracy")
    static let comprehensive = tr("analysis_comprehensive")
    static let title = tr("analysis_title")
    static let count = tr("analysis_count")
    static let analysisType = tr("analysis_type")
    static let timeRange = tr("analysis_time_range")
//    static let trend = tr("analysis_trend")
//    static let stability = tr("analysis_stability")
//    static let accuracy = tr("analysis_accuracy")
    static let noData = tr("analysis_no_data")
    static let date = tr("analysis_date")
    static let score = tr("analysis_score")
    static let standardDeviation = tr("analysis_standard_deviation")
    static let trendAnalysis = tr("analysis_trend_analysis")
    static let statsInfo = tr("analysis_stats_info")
    static let hitStats = tr("analysis_hit_stats")
    static let avgScore = tr("analysis_avg_score")
    static let maxScore = tr("analysis_max_score")
    static let minScore = tr("analysis_min_score")
    static let tenRate = tr("analysis_ten_rate")
    static let nineRate = tr("analysis_nine_rate")
    static let eightRate = tr("analysis_eight_rate")
    
    static func ringRate(_ ring: Int, rate: Double) -> String {
        return tr("analysis_ring_rate", ring, rate)
    }
    
    // 新增稳定性分析相关
    static let stabilityLevelHigh = tr("analysis_stability_level_high")
    static let stabilityLevelMedium = tr("analysis_stability_level_medium")
    static let stabilityLevelLow = tr("analysis_stability_level_low")
    static let stabilityDescription = tr("analysis_stability_description")
    static let avgDeviation = tr("analysis_avg_deviation")
    static let maxDeviation = tr("analysis_max_deviation")
    static let minDeviation = tr("analysis_min_deviation")
    
    // 新增命中率分析相关
    static let totalHitRate = tr("analysis_total_hit_rate")
    static let goldRate = tr("analysis_gold_rate")
    static let averageDeviation = tr("analysis_average_deviation")
    
    // 综合分析相关
    static let overallScore = tr("analysis_overall_score")
    static let averagePerArrow = tr("analysis_average_per_arrow")
    static let totalArrows = tr("analysis_total_arrows")
    static let abilityAnalysis = tr("analysis_ability_analysis")
    static let detailedData = tr("analysis_detailed_data")
    static let stabilityLevel = tr("analysis_stability_level")
    static let hitRate = tr("analysis_hit_rate")
    static let consistency = tr("analysis_consistency")
    static let recentTrend = tr("analysis_recent_trend")
}

struct Detail {
    static let totalScore = tr("detail_total_score")
    static func likeCount(_ count: Int) -> String {
        return tr("detail_like_count", count)
    }
    static let ringDistribution = tr("detail_ring_distribution")
    static func averageScore(_ score: Double) -> String {
        return tr("detail_average_score", score)
    }

    static let title = tr("detail_title")
    static let basicInfo = tr("detail_basic_info")
    static let score = tr("detail_score")
    static let scoreDistribution = tr("detail_score_distribution")
    static let arrowScores = tr("detail_arrow_scores")
    static let deleteRecord = tr("detail_delete_record")
    static let recordAgain = tr("detail_record_again")
    static let deleteConfirmTitle = tr("detail_delete_confirm_title")
    static let deleteConfirmMessage = tr("detail_delete_confirm_message")
    static let deleteCancel = tr("detail_delete_cancel")
    static let deleteConfirm = tr("detail_delete_confirm")
    static let likeCount = tr("detail_like_count")

}

struct GroupDetail {
    static let title = tr("group_detail_title")
    static let basicInfo = tr("group_detail_basic_info")
    static let matchInfo = tr("group_detail_match_info")
    static let totalScore = tr("group_detail_total_score")
    static func likeCount(_ count: Int) -> String {
        return tr("group_detail_like_count", count)
    }
    static let groupScores = tr("group_detail_group_scores")
    static func groupNumber(_ number: Int) -> String {
        return tr("group_detail_group_number", number)
    }
    static func groupScore(_ score: Int) -> String {
        return tr("group_detail_group_score", score)
    }
    static func averagePerArrow(_ average: Double) -> String {
        return tr("group_detail_average_per_arrow", average)
    }
    static let ringDistribution = tr("group_detail_ring_distribution")
    static let deleteRecord = tr("group_detail_delete_record")
    static let recordAgain = tr("group_detail_record_again")
    static let deleteConfirm = tr("group_detail_delete_confirm")
    static let deleteMessage = tr("group_detail_delete_message")
}


    struct Format {
    static let dateTime = tr("format_date_time")
    static let shortDate = tr("format_short_date")  // 添加这一行
}

    
    struct Stats {
        static let trend = tr("stats_trend")
        static let info = tr("stats_info")
        static let hit = tr("stats_hit")
        static let avg = tr("stats_avg")
        static let max = tr("stats_max")
        static let min = tr("stats_min")
        static let tenRate = tr("stats_10_rate")
        static let nineRate = tr("stats_9_rate")
        static let eightRate = tr("stats_8_rate")
    }

    struct Tab {
    static let record = tr("tab_record")
    static let analysis = tr("tab_analysis")
}

struct Content {
    static let trainingRecord = tr("content_training_record")
    static let emptyStatePrompt = tr("content_empty_state_prompt")
    static let appTitle = tr("content_app_title")
    static let viewDetail = tr("content_view_detail")
    static let hideDetail = tr("content_hide_detail")
    static let delete = tr("content_delete")
    static let score = tr("content_score")
    static let totalScore = tr("content_total_score")
}
    
    struct Match {
        static func type(groups: Int, arrowsPerGroup: Int, totalArrows: Int) -> String {
            return tr("match_type", groups, arrowsPerGroup, totalArrows)
        }
    }

struct Options {
    struct BowType {
        static let compound = tr("bow_type_compound")
        static let meilie = tr("bow_type_meilie")
        static let guanggong = tr("bow_type_guanggong")
        static let recurve = tr("bow_type_recurve")
        static let traditional = tr("bow_type_traditional")
        
        static let all = [compound, recurve, traditional,guanggong, meilie]
    }
    
    struct Distance {
        static let d10m = tr("distance_10m")
        static let d18m = tr("distance_18m")
        static let d30m = tr("distance_30m")
        static let d50m = tr("distance_50m")
        static let d70m = tr("distance_70m")
        
        static let all = [d10m, d18m, d30m, d50m, d70m]
    }
    
    struct TargetType {
        static let t122cmStandard = tr("target_type_122cm_standard")
        static let t80cmFull = tr("target_type_80cm_full")
        static let t40cmFull = tr("target_type_40cm_full")
        static let t40cmTripleVertical = tr("target_type_40cm_triple_vertical")
        static let t40cmTripleTriangle = tr("target_type_40cm_triple_triangle")
        static let t60cmIndoor = tr("target_type_60cm_indoor")
        static let tCompoundInner10 = tr("target_type_compound_inner10")

        static let all = [t122cmStandard, t80cmFull, t40cmFull, t40cmTripleVertical, t40cmTripleTriangle, t60cmIndoor, tCompoundInner10]
    }
}

struct GroupInput {
    static let title = tr("group_input_title")
    static let basicOptions = tr("group_input_basic_options")
    static let bowType = tr("group_input_bow_type")
     static let numberOfGroups = tr("group_input_number_of_groups")
    static let arrowsPerGroup = tr("group_input_arrows_per_group")
    static let distance = tr("group_input_distance")
    static let targetType = tr("group_input_target_type")
    static let matchType = tr("group_input_match_type")
    static func groupScoreInput(_ group: Int, score: Int) -> String {
        return tr("group_input_score", group, score)
    }
    static let save = tr("group_input_save")
    static let selectBowType = tr("group_input_select_bow_type")
    static let selectDistance = tr("group_input_select_distance")
    static let selectTargetType = tr("group_input_select_target_type")
    static let selectMatchType = tr("group_input_select_match_type")
}

struct SingleInput {
    static let title = tr("single_input_title")
    static let basicOptions = tr("single_input_basic_options")
    static let scoreInput = tr("single_input_score_input")
    static func totalScore(_ score: Int) -> String {
        return tr("single_input_total_score", score)
    }
    static let save = tr("single_input_save")
    static let selectBowType = tr("single_input_select_bow_type")
    static let selectDistance = tr("single_input_select_distance")
    static let selectTargetType = tr("single_input_select_target_type")
    static func arrowNumber(_ number: Int) -> String {
        return tr("single_input_arrow_number", number)
    }
}

struct Settings {
    static let title = tr("settings_title")
    static let language = tr("settings_language")
    static let languageSelection = tr("settings_language_selection")
    static let about = tr("settings_about")
    static let feedback = tr("settings_feedback")
    static let version = tr("settings_version")
}

}
