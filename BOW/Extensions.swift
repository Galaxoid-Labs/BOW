//
//  Extensions.swift
//  BOW
//
//  Created by Jacob Davis on 7/27/22.
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins

extension Color {
    
    static let text = Color("Text")
    static let background = Color("Background")
    
}

extension String {
    
    func isValidTestnetAddress() -> Bool {
        let regex = /^(tb1|[mn2])[a-zA-HJ-NP-Z0-9]{25,39}$/
        return self.firstMatch(of: regex) != nil
    }
    
    func generateQRCode() -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(self.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}


struct Stack<Element> {
    var items: [Element] = []
    mutating func push(_ item: Element) {
        items.append(item)
    }
    mutating func pop() -> Element {
        return items.removeLast()
    }
    var topItem: Element? {
        return items.isEmpty ? nil : items[items.count - 1]
    }
}

extension Animation {
    func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation {
        if expression {
            return self.repeatForever(autoreverses: autoreverses)
        } else {
            return self
        }
    }
}
