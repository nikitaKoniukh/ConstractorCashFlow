//
//  ScanInvoiceView.swift
//  ContractorCashFlow
//

import SwiftUI
import VisionKit
import SwiftData

// MARK: - Entry sheet: choose camera or photo library

struct ScanInvoiceView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showSourcePicker = true
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var showImagePicker = false
    @State private var showDocumentScanner = false
    @State private var scannedImage: UIImage? = nil
    @State private var isProcessing = false
    @State private var scannedData: ScannedInvoiceData? = nil

    var body: some View {
        Group {
            if isProcessing {
                processingView
            } else if let data = scannedData {
                ScannedExpenseReviewView(scannedData: data, scannedImage: scannedImage) {
                    dismiss()
                }
            } else {
                sourcePickerView
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerRepresentable(sourceType: sourceType) { image in
                processImage(image)
            }
        }
        .fullScreenCover(isPresented: $showDocumentScanner) {
            DocumentScannerRepresentable { image in
                processImage(image)
            }
        }
    }

    // MARK: - Source picker

    private var sourcePickerView: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showDocumentScanner = true
                    } label: {
                        Label("Scan Document (Camera)", systemImage: "doc.viewfinder")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                        Button {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        } label: {
                            Label("Choose from Photos", systemImage: "photo.on.rectangle")
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    Text("Import Invoice or Receipt")
                } footer: {
                    Text("The app will scan the document and automatically fill in the amount, date, and description.")
                }
            }
            .navigationTitle("Scan Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Processing indicator

    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Scanning invoice…")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - OCR

    private func processImage(_ image: UIImage) {
        scannedImage = image
        isProcessing = true
        Task {
            let data = await InvoiceOCRService.extractData(from: image)
            await MainActor.run {
                scannedData = data
                isProcessing = false
            }
        }
    }
}

// MARK: - UIImagePickerController wrapper

private struct ImagePickerRepresentable: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImage: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage) -> Void
        init(onImage: @escaping (UIImage) -> Void) { self.onImage = onImage }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - VisionKit document camera wrapper

private struct DocumentScannerRepresentable: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onImage: (UIImage) -> Void
        init(onImage: @escaping (UIImage) -> Void) { self.onImage = onImage }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true)
            // Use the first page
            let image = scan.imageOfPage(at: 0)
            onImage(image)
        }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }
    }
}
