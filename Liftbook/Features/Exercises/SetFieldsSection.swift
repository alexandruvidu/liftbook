import SwiftUI

/// Explains which values a set of the given exercise type records.
struct SetFieldsSection: View {
    let type: ExerciseType

    var body: some View {
        Section {
            ForEach(type.fieldSpecs, id: \.self) { spec in
                LabeledContent {
                    Text(spec.isOptional ? "Optional" : "Required")
                } label: {
                    Label(spec.label, systemImage: spec.field.systemImage)
                }
            }
            LabeledContent("Example set", value: type.example.formatted(for: type))
                .accessibilityIdentifier("exercise.detail.example")
        } header: {
            Text("Logged as \(type.displayName)")
        } footer: {
            Text(type.explanation)
        }
    }
}
