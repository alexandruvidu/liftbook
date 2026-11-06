import SwiftUI

/// Explains which values a set of the given exercise type records.
struct SetFieldsSection: View {
    let type: ExerciseType
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    var body: some View {
        BlockSection("Logged as \(type.displayName)", footer: type.explanation) {
            ForEach(type.fieldSpecs, id: \.self) { spec in
                LabeledContent {
                    Text(spec.isOptional ? "Optional" : "Required")
                } label: {
                    Label(spec.label, systemImage: spec.field.systemImage)
                }
            }
            LabeledContent("Example set", value: type.example.formatted(for: type, unit: unit))
                .accessibilityIdentifier("exercise.detail.example")
        }
    }
}
