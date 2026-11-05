import Foundation
import Testing
import UIKit
@testable import Liftbook

struct PhotoStoreTests {
    private let store = PhotoStore(directory: FileManager.default.temporaryDirectory
        .appending(path: "PhotoStoreTests-\(UUID().uuidString)", directoryHint: .isDirectory))

    private func image(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    @Test func savesLoadsAndDeletes() throws {
        let name = try store.save(image(width: 300, height: 400))
        #expect(name.hasSuffix(".jpg"))
        let loaded = try #require(store.load(name))
        #expect(loaded.size == CGSize(width: 300, height: 400))
        store.delete(name)
        #expect(store.load(name) == nil)
    }

    @Test func largeImagesAreDownscaledKeepingTheirShape() {
        let scaled = PhotoStore.downscaled(image(width: 4000, height: 3000))
        #expect(scaled.size == CGSize(width: 1600, height: 1200))
    }

    @Test func smallImagesAreLeftAlone() {
        let small = image(width: 800, height: 600)
        #expect(PhotoStore.downscaled(small).size == small.size)
    }

    @Test func groupsByMonthNewestFirst() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        func photo(_ month: Int, _ day: Int) -> ProgressPhoto {
            ProgressPhoto(date: calendar.date(from: DateComponents(year: 2026, month: month, day: day))!, fileName: "x")
        }
        let months = PhotoStore.months(of: [photo(10, 3), photo(11, 1), photo(10, 20)], calendar: calendar)
        #expect(months.count == 2)
        #expect(months[0].photos.count == 1)
        #expect(calendar.component(.day, from: months[1].photos[0].date) == 20)
    }
}
