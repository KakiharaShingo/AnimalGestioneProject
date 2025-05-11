import SwiftUI

// AnimalGestioneProjectモジュールのパブリックビュー

public struct EmbeddedPrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    public var body: some View {
        NavigationView {
            PrivacyPolicyView()
                .navigationBarItems(leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("閉じる")
                })
        }
    }
}

struct EmbeddedPrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        EmbeddedPrivacyPolicyView()
    }
}
