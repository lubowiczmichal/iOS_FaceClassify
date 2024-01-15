//
//  ImageClassifier.swift
//  FaceClassify
//
//  Created by Michał Lubowicz on 12/11/2023.
//

import Foundation
import TensorFlowLiteTaskVision
import UIKit

struct ImageClassificationResult {
  let inferenceTime: Double
  let classifications: Classifications
}

typealias FileInfo = (name: String, extension: String)

class ImageClassificationHelper {

  private var classifier: ImageClassifier

  private let alphaComponent = (baseOffset: 4, moduloRemainder: 3)

  init?(modelFileInfo: FileInfo) {
    let modelFilename = modelFileInfo.name
    guard
      let modelPath = Bundle.main.path(
        forResource: modelFilename,
        ofType: modelFileInfo.extension
      )
    else {
      print("Failed to load the model file with name: \(modelFilename).")
      return nil
    }

    let options = ImageClassifierOptions(modelPath: modelPath)
    do {
      classifier = try ImageClassifier.classifier(options: options)
    } catch let error {
      print("Failed to create the interpreter with error: \(error.localizedDescription)")
      return nil
    }
  }

    func classify(image: UIImage) -> ImageClassificationResult? {
        
        guard let mlImage = MLImage(image: image) else {
            return nil
        }

    do {
      let startDate = Date()
      let classificationResults = try classifier.classify(mlImage: mlImage)
      let inferenceTime = Date().timeIntervalSince(startDate) * 1000

      guard let classifications = classificationResults.classifications.first else { return nil }
      return ImageClassificationResult(
        inferenceTime: inferenceTime, classifications: classifications)
    } catch let error {
      print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
      return nil
    }
  }
}
