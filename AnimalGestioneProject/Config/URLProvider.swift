import Foundation

/// アプリで使用するURLを一元管理するクラス
public struct URLProvider {
    
    /// GitHubで公開しているプライバシーポリシーのURL
    /// Appleのアプリリリース用プライバシーポリシーURLとして使用
    public static let privacyPolicyURL = "https://[GitHubユーザー名].github.io/AnimalGestioneProject/"
    
    /// GitHubで公開しているサポートページのURL
    /// Appleのアプリリリース用サポートURLとして使用
    public static let supportURL = "https://[GitHubユーザー名].github.io/AnimalGestioneProject/support.html"
    
    /// GitHub上のプライバシーポリシーの元リポジトリURL
    public static let gitHubRepoURL = "https://github.com/[GitHubユーザー名]/AnimalGestioneProject"
    
    /// サポートメール問い合わせ先
    public static let supportEmail = "sk.shingo.10@gmail.com"
    
    /// メールリンクURL生成
    public static func mailToURL(subject: String) -> URL? {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:\(supportEmail)?subject=\(encodedSubject)")
    }
}
