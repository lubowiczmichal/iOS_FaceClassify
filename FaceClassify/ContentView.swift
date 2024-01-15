//
//  ContentView.swift
//  FaceClassify
//
//  Created by Michał Lubowicz on 12/11/2023.
//

import SwiftUI

struct ContentView: View {
    var model = ["wydajny", "optymlany", "dokładny"]
    @State private var selectedModel = "optymlany"
    @State private var showingCameraView = false
    @State private var showingInfoView = false
    @State private var image: UIImage?
    @State private var classificationResult: String = ""
    @State private var debugField: String = ""
    @State private var testResult: String = ""
    
    //hide test mode
    @State private var mode: Int = 0
    
    @State private var age: Bool = false
    @State private var gender: Bool = false
    @State private var emotions: Bool = false
    @State private var ethnic: Bool = false
    
    
    var body: some View {
        ZStack{
            VStack{
                Button("Tryb normalny") {
                    self.mode = 0
                }
                Button("Tryb testowy") {
                    self.mode = 1
                }
            }
            .padding()
            .opacity(mode == -1 ? 1 : 0)
            VStack {
                HStack {
//                    Button(action: {
//                        self.mode = -1
//                    }) {
//                        Image(systemName: "chevron.left")
//                            .foregroundColor(.blue)
//                    }
//                    .padding()
                    Spacer()
                    Button(action: {
                        self.showingInfoView.toggle()
                    }) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showingInfoView) {
                        InfoView()
                    }
                    .padding()
                }
                Spacer()
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                Button("Zrób zdjęcie") {
                    self.showingCameraView.toggle()
                }
                .padding()
                .sheet(isPresented: $showingCameraView) {
                    CameraView(image: self.$image)
                }
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(100)
                
                HStack {
                    Text("Wybrany tryb: ")
                    Picker("Wybrany tryb: ", selection: $selectedModel) {
                        ForEach(model, id: \.self) {
                            Text($0)
                        }
                    }
                    .foregroundColor(.black)
                }
                HStack {
                    CheckboxView(checked: $age, label: "\n Płeć")
                    Spacer()
                    CheckboxView(checked: $gender, label: "\n Wiek")
                    Spacer()
                    CheckboxView(checked: $emotions, label: "\n Emocje")
                    Spacer()
                    CheckboxView(checked: $ethnic, label: "Pochodzenie \netniczne")
                }
                .padding()
                Button(action: {
                    if let unwrappedImage = image {
                        classify(image: unwrappedImage, mode: selectedModel, classes: [age, gender, emotions, ethnic])
                    }
                }
                ) {
                    Text("Klasyfikuj")
                }
                .opacity(image == nil ? 0 : 1)
                .padding()
                .foregroundColor(.white)
                .background(image == nil ? nil : Color.blue)
                .cornerRadius(100)
                
                Text(classificationResult)
                Spacer()
                Text(debugField)
            }
            .padding()
            .opacity(mode == 0 ? 1 : 0)
            VStack {
                HStack {
                    Button(action: {
                        self.mode = -1
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
                HStack {
                    Text("Wybrany model: ")
                    Picker("Wybrany model: ", selection: $selectedModel) {
                        ForEach(model, id: \.self) {
                            Text($0)
                        }
                    }
                }
                Button(action: {
                    classifyTest()
                    }
                ) {
                    Text("Uruchom test")
                }
                Text(testResult)
                Spacer()
            }
            .padding()
            .opacity(mode == 1 ? 1 : 0)
        }
       
    }
    
    func classify(image:UIImage, mode: String, classes: Array<Bool>)  {
        var start2 = Int64(Date().timeIntervalSince1970 * 1000)
        debugField = ""
        var selectedModel:String = ""
        switch mode {
        case "wydajny":
            selectedModel = "MobileNetV3Small"
        case "optymlany":
            selectedModel = "EfficientNetV2B3"
        case "dokładny":
            selectedModel = "EfficientNetB6"
        default:
            selectedModel = ""
        }
        
        let resized = resizeImage(image: image,targetSize: CGSize(width: 224, height: 224))
        let a = ["Gender", "Age", "Emo", "Eth"]
        var results = [String:String]()
        for num in 0..<4 {
            if classes[num] {
                var start = Int64(Date().timeIntervalSince1970 * 1000)
                let result = runClassify(image: resized, selectedModel: selectedModel + a[num])
                var end = Int64(Date().timeIntervalSince1970 * 1000)
                //debugField += String(end-start) + " "
                
                var label = result.classifications.categories.first!.label!
                if a[num] == "Gender" {
                    label = mapGender(org: label)
                } else if a[num] == "Age" {
                    label = mapAge(org: label)
                } else if a[num] == "Emo" {
                    label = mapEmo(org: label)
                } else if a[num] == "Eth" {
                    label = mapEth(org: label)
                }
                results[a[num]] = label
            }
        }
        classificationResult = handleResult(map: results)
        var end2 = Int64(Date().timeIntervalSince1970 * 1000)
        //debugField += String(end2-start2) + " "
    }
    
    func runClassify(image: UIImage, selectedModel: String) -> ImageClassificationResult {
        let file = FileInfo(selectedModel, "tflite")
        let imageClassificationHelper: ImageClassificationHelper? =
        ImageClassificationHelper(modelFileInfo: file)

        let result = imageClassificationHelper?.classify(image: image)

        return result!
    }
    
    
    func classifyTest() {
        print("Start")
        var totalTime = 0.0
        var correct = 0
        var size = 25
        var categories = 2
        let startTimeTotal = Int(Date().timeIntervalSince1970 * 1000)
        let file = FileInfo("EfficientNetB1Gender", "tflite")
        let imageClassificationHelper: ImageClassificationHelper? =
        ImageClassificationHelper(modelFileInfo: file)
        print(file.name)
        GenderData().FEMALES_LIST.shuffled().prefix(size).forEach{name in
            let bundlePath = Bundle.main.path(forResource: name, ofType: "jpg")
            let image = UIImage(contentsOfFile: bundlePath!)!
            let resized = resizeImage(image: image,targetSize: CGSize(width: 224, height: 224))
            let milliseconds = Date().timeIntervalSince1970 * 1000
            let result = imageClassificationHelper?.classify(image: resized)
            let milliseconds2 = Date().timeIntervalSince1970 * 1000
            let time = milliseconds2 - milliseconds
            print(result!.classifications.categories[0].label!)
            if (result!.classifications.categories[0].label! == "Females") {
                correct += 1
            }
            totalTime += time
            print(time)
        }
        GenderData().MALES_LIST.shuffled().prefix(size).forEach{name in
            let bundlePath = Bundle.main.path(forResource: name, ofType: "jpg")
            let image = UIImage(contentsOfFile: bundlePath!)!
            let resized = resizeImage(image: image,targetSize: CGSize(width: 224, height: 224))
            let milliseconds = Date().timeIntervalSince1970 * 1000
            let result = imageClassificationHelper?.classify(image: resized)
            let milliseconds2 = Date().timeIntervalSince1970 * 1000
            let time = milliseconds2 - milliseconds
            print(result!.classifications.categories[0].label!)
            if (result!.classifications.categories[0].label! == "Males") {
                correct += 1
            }
            totalTime += time
            print(time)
        }
        print(Int(Date().timeIntervalSince1970 * 1000) - startTimeTotal)
        
        testResult = "\(Double(correct)/Double(size*categories))  \(totalTime)"

    }
}

struct InfoView: View {
    var body: some View {
        VStack{
            Text("Instrukcja")
                .padding()
            Text("Do poprawnego działania aplikacji wymangany jest dostęp do kamery telefonu, możesz jej udzielić w ustawieniach aplikacji.\nTwoje zdjęcia są przetwarzane lokalnie z wykorzystaniem zasobów telefonu nie są nigdzie udostępnianie, a aplikacja nie korzysta z Internetu.\nAplikacja umożliwia klasyfikacje zdjęć twarzy pod kątem płci płci, wieku, emocji oraz pochodzenia etnicznego.\nDostępne są trzy tryby klasyfikacji z wykorzystaniem głębokich sieci neuronowych:\n- wydajny (model sieci MobileNetV3Small),\n- optymalny (model sieci EfficientNetV2B3),\n- dokładny (model sieci EfficientNetB6).\nW celu poprawnej klasyfikacji należy zrobić zdjęcie tak, aby twarz zajmowała jak największą powierzchnie zdjęcia.")
                .padding()
        }
    }
}

func mapGender(org: String) -> String {
    var gender = [String:String]()
    gender["Males"] = "mężczyzna"
    gender["Females"] = "kobieta"
    return gender[org]!
}

func mapAge(org: String) -> String {
    var age = [String:String]()
    age["folder0"] = "0-6"
    age["folder1"] = "7-18"
    age["folder2"] = "19-26"
    age["folder3"] = "27-40"
    age["folder4"] = "41-60"
    age["folder5"] = "60+"
    return age[org]!
}

func mapEth(org: String) -> String {
    var eth = [String:String]()
    eth["Asian"] = "azjatyckie"
    eth["Black"] = "czarnoskórzy"
    eth["Indian"] = "indyjskie"
    eth["Others"] = "inne"
    eth["White"] = "biali"
    return eth[org]!
}

func mapEmo(org: String) -> String {
    var eth = [String:String]()
    eth["angry"] = "złość"
    eth["disgust"] = "zdegustowanie"
    eth["fear"] = "strach"
    eth["happy"] = "radość"
    eth["neutral"] = "neutralny"
    eth["sad"] = "smutek"
    eth["surprise"] = "zdziwienie"
    return eth[org]!
}

func handleResult(map: [String:String]) -> String {
    var result = ""
    if (map["Gender"] != nil) {
        result += "Płeć: " + map["Gender"]! + "\n"
    }
    if (map["Age"] != nil) {
        result += "Grupa wiekowa: " + map["Age"]! + "\n"
    }
    if (map["Emo"] != nil) {
        result += "Emocje: " + map["Emo"]! + "\n"
    }
    if (map["Eth"] != nil) {
        result += "Pochodzenie etniczne: " + map["Eth"]! + "\n"
    }
    return result
}

func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
    
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    
    let scaleFactor = min(widthRatio, heightRatio)
    
    let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
    
    UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0)
    image.draw(in: CGRect(origin: .zero, size: scaledSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage ?? UIImage()
}
struct CheckboxView: View {
    @Binding var checked: Bool
    var label: String

    var body: some View {
        Button(action: {
            self.checked.toggle()
        }) {
            VStack(alignment: .center, spacing: 10) {
                Text(label)
                Image(systemName: checked ? "checkmark.square" : "square")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .foregroundColor(.primary)
            .font(.body)
        }
    }
}

#Preview {
    ContentView()
}
