import SwiftUI
import AVFoundation

// PhotoCaptureDelegate to handle photo capture
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    var didFinishProcessingPhoto: (UIImage?) -> Void
    
    init(didFinishProcessingPhoto: @escaping (UIImage?) -> Void) {
        self.didFinishProcessingPhoto = didFinishProcessingPhoto
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhotoToMemoryBuffer photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            didFinishProcessingPhoto(image)
        }
    }
}

struct CameraView: View {
    @State private var capturedImage: UIImage?
    @State private var showConfirmationPopup = false
    @State private var session = AVCaptureSession()
    @State private var previewLayer: AVCaptureVideoPreviewLayer!
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()

    var body: some View {
        VStack {
            ZStack {
                // Camera preview
                CameraPreview(session: captureSession)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(Color.black.opacity(0.4)) // Overlay for better visibility
                
                // Overlay with custom design
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 80, height: 80)
                                    .shadow(radius: 10)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 80, height: 80)
                            }
                        }
                        .padding(30)
                    }
                }
            }
            
            // Confirmation Popup
            if showConfirmationPopup {
                ConfirmationPopup(capturedImage: $capturedImage, showConfirmationPopup: $showConfirmationPopup)
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            stopCamera()
        }
    }
    
    // Set up camera session
    func setupCamera() {
        captureSession.sessionPreset = .photo
        
        // Check for video device (rear camera)
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("No video device found")
            return
        }
        
        do {
            // Add video input to the session
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            } else {
                print("Unable to add video input.")
                return
            }
            
            // Add photo output to the session
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            } else {
                print("Unable to add photo output.")
                return
            }
            
            // Set up preview layer to show the camera feed
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = UIScreen.main.bounds
            previewLayer.videoGravity = .resizeAspectFill
        } catch {
            print("Error setting up camera: \(error)")
        }
        
        // Start running the session
        captureSession.startRunning()
    }
    
    // Capture photo
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        // Make sure the session is running and has a valid connection
        if let connection = photoOutput.connection(with: .video), connection.isEnabled {
            photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate { image in
                self.capturedImage = image
                self.showConfirmationPopup = true
            })
        } else {
            print("No active connection available for photo capture.")
        }
    }
    
    // Stop camera session
    func stopCamera() {
        captureSession.stopRunning()
        previewLayer.removeFromSuperlayer()
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = UIScreen.main.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ConfirmationPopup: View {
    @Binding var capturedImage: UIImage?
    @Binding var showConfirmationPopup: Bool
    
    var body: some View {
        VStack {
            Text("Do you want to save this photo?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.top, 20)
            
            Image(uiImage: capturedImage ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(radius: 8)
                .padding(.top, 15)
            
            HStack(spacing: 40) {
                Button(action: {
                    savePhoto()
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.green)
                        .shadow(radius: 10)
                }
                
                Button(action: {
                    deletePhoto()
                }) {
                    Image(systemName: "x.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.red)
                        .shadow(radius: 10)
                }
            }
            .padding(.top, 25)
        }
        .frame(width: 300, height: 400)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.bottom, 50)
        .transition(.move(edge: .bottom))
    }
    
    func savePhoto() {
        guard let image = capturedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showConfirmationPopup = false
    }
    
    func deletePhoto() {
        capturedImage = nil
        showConfirmationPopup = false
    }
}

@main
struct CameraApp: App {
    var body: some Scene {
        WindowGroup {
            CameraView()
        }
    }
}
