//
//  LabelView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/12/24.
//

import SwiftUI
import UIKit



class LabelPrintPageRenderer: UIPrintPageRenderer {
    private let patientName: String
    private let barcodeImage: UIImage

    init(patientName: String, barcodeImage: UIImage) {
        self.patientName = patientName
        self.barcodeImage = barcodeImage
        super.init()
    }

    // This is the correct method to override in UIPrintPageRenderer
    override func drawPage(at pageIndex: Int, in printableRect: CGRect) {
        let font = UIFont.systemFont(ofSize: 20)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]

        // Draw the patient name in the label
        let nameText = NSString(string: patientName)
        nameText.draw(in: CGRect(x: 0, y: 40, width: printableRect.width, height: 40), withAttributes: attributes)

        // Draw the barcode image below the name
        let barcodeRect = CGRect(x: (printableRect.width - barcodeImage.size.width) / 2, y: 100, width: barcodeImage.size.width, height: barcodeImage.size.height)
        barcodeImage.draw(in: barcodeRect)
    }
}


func printOrderLabel(patientName: String, barcodeImage: UIImage) {
    let printController = UIPrintInteractionController.shared
    let printInfo = UIPrintInfo(dictionary: nil)
    printInfo.outputType = .general
    printInfo.jobName = "Print Patient Label"
    printController.printInfo = printInfo

    let rendererForPrint = LabelPrintPageRenderer(patientName: patientName, barcodeImage: barcodeImage)
    printController.printPageRenderer = rendererForPrint

    // Save the PDF to a temporary directory
    let pdfUrl = FileManager.default.temporaryDirectory.appendingPathComponent("label.pdf")
    
    let pdfData = NSMutableData()
    UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: 300, height: 150), nil)
    UIGraphicsBeginPDFPage()
    rendererForPrint.drawPage(at: 0, in: CGRect(x: 0, y: 0, width: 300, height: 150))
    UIGraphicsEndPDFContext()

    do {
        try pdfData.write(to: pdfUrl)
        print("PDF saved at: \(pdfUrl)")
        UIApplication.shared.open(pdfUrl, options: [:], completionHandler: nil) // Open the PDF on simulator
    } catch {
        print("Failed to save PDF: \(error)")
    }

    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootViewController = scene.windows.first?.rootViewController {
        printController.present(from: rootViewController.view.bounds, in: rootViewController.view, animated: true, completionHandler: nil)
    }
}

struct PrintHelper: UIViewControllerRepresentable {
    let patientName: String
    let barcodeImage: UIImage

    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if self.getRootViewController() != nil {
                self.printOrderLabel(patientName: patientName, barcodeImage: barcodeImage)
            }
        }
    }

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }

    private func printOrderLabel(patientName: String, barcodeImage: UIImage) {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Print Patient Label"
        printController.printInfo = printInfo

        let rendererForPrint = LabelPrintPageRenderer(patientName: patientName, barcodeImage: barcodeImage)
        printController.printPageRenderer = rendererForPrint

        if let rootViewController = getRootViewController() {
            printController.present(from: rootViewController.view.bounds, in: rootViewController.view, animated: true, completionHandler: nil)
        }
    }
}
