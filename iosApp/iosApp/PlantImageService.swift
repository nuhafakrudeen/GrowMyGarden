import Foundation
import KMPNativeCoroutinesAsync
import Shared
import UIKit

// ===============================================================
// MARK: - PLANT IMAGE SERVICE (Backend placeholder)
// ===============================================================

enum PlantImageService {
    private static let dashboardViewModel = HelperKt.getDashboardViewModel()

    static func fetchSpeciesImage(speciesName: String,
                                  completion: @escaping (UIImage?) -> Void) {
        Task {
            do {
                // Bridge Kotlin suspend function -> Swift async
                let imageUrl: String? = try await asyncFunction(
                    for: dashboardViewModel.getPlantImageUrl(speciesName: speciesName)
                )

                if let imageUrl = imageUrl {
                    let imageBytes: KotlinByteArray? = try await asyncFunction(
                        for: dashboardViewModel.downloadImageFromUrl(imageUrl: imageUrl)
                    )

                    if let imageBytes = imageBytes {
                        // Convert KotlinByteArray -> Data
                        let count = Int(imageBytes.size)
                        var bytes = [UInt8](repeating: 0, count: count)
                        for index in 0..<count {
                            bytes[index] = UInt8(bitPattern: imageBytes.get(index: Int32(index)))
                        }
                        let data = Data(bytes)

                        if let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                completion(uiImage)
                            }
                            return
                        }
                    }
                }

                // If we couldn't get an image, return nil
                await MainActor.run {
                    completion(nil)
                }
            } catch {
                print("❌ Error fetching species image for '\(speciesName)': \(error)")
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }

}
