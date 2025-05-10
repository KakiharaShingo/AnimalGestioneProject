import SwiftUI
import UIKit

class AppIconExporter {
    static func generateIcon(completion: @escaping (UIImage?) -> Void) {
        let iconView = AppIconGenerator()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 1024))
        
        let hostingController = UIHostingController(rootView: iconView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1024, height: 1024)
        
        // UIViewのレンダリングを待つ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let image = renderer.image { ctx in
                hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
            }
            completion(image)
        }
    }
    
    static func saveIconToDocuments() {
        generateIcon { image in
            guard let image = image,
                  let data = image.pngData(),
                  let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Error: Could not generate icon or access documents directory")
                return
            }
            
            let fileURL = documentsDirectory.appendingPathComponent("AppIcon.png")
            
            do {
                try data.write(to: fileURL)
                print("Icon saved to: \(fileURL.path)")
            } catch {
                print("Error saving icon: \(error)")
            }
        }
    }
}

// この関数を呼び出すと、DocumentsディレクトリにAppIcon.pngが保存されます
// 通常はアプリの初期化時やデバッグ時に一度だけ呼び出す
// AppIconExporter.saveIconToDocuments()
