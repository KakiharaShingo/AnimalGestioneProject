import SwiftUI

struct IntegratedSupportView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        SupportView()
    }
}

extension EnhancedContentView {
    var supportView: some View {
        IntegratedSupportView()
    }
}
