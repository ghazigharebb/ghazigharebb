// VEX Health — Widget Extension: Live Activity + Dynamic Island + Widget
import SwiftUI
import WidgetKit

@main
struct VexStepsWidgetBundle: WidgetBundle {
    var body: some Widget {
        VexStepsHomeWidget()
        if #available(iOS 16.2, *) {
            VexStepsLiveActivity()
        }
    }
}
