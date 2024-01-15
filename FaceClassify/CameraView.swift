import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraView

        init(parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.editedImage] as? UIImage {
                let flippedImage = UIImage(cgImage: uiImage.cgImage!, scale: uiImage.scale, orientation: .upMirrored)
                parent.image = flippedImage
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.cameraCaptureMode = .photo
        picker.mediaTypes = ["public.image"]
        picker.cameraFlashMode = .off
        picker.allowsEditing = true
        
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCameraOverlay() -> some View {
        return ZStack {
            Rectangle()
                .fill(Color.black)
                .opacity(0.7)
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .padding(20)
        }
    }
}
