import SwiftUI

struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isSubmitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Short summary of the bug", text: $title)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 140)
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Steps to reproduce, what happened, what you expected...")
                                    .foregroundStyle(.tertiary)
                                    .font(.body)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section {
                    Text("Device info, iOS version, and app version will be attached automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Report a Bug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Submit") { submit() }
                            .disabled(!canSubmit)
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert("Issue Created!", isPresented: .constant(successMessage != nil)) {
                Button("Done") { dismiss() }
            } message: {
                Text(successMessage ?? "")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            do {
                try await GitHubService.createIssue(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: description.trimmingCharacters(in: .whitespaces)
                )
                successMessage = "Your bug report has been filed on GitHub."
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

#Preview {
    BugReportView()
}
