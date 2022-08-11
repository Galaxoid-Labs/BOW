//
//  ViewModifiers.swift
//  BOW
//
//  Created by Jacob Davis on 7/27/22.
//

import Foundation
import SwiftUI
import Haptica

struct ClearListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowSeparator(.hidden)
            .listRowBackground(Color.background)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

struct KeypadButtonStyle: ViewModifier {
    
    let title: String
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.text.opacity(0.1))
            .padding(6)
            .overlay(
                Text(title)
                    .font(.system(.title2,
                                  design: .monospaced,
                                  weight: .bold))
            )
    }
}

struct BorderStyle: ViewModifier {
    
    let title: String
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .background(
                Rectangle()
                    .strokeBorder(Color.blue, lineWidth: 2)
            )
            .overlay(
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.system(.body,
                                      design: .monospaced,
                                      weight: .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.2)
                        .padding(.horizontal, 4)
                        .foregroundColor(Color.mint)
                        .background(
                            Rectangle()
                                .foregroundColor(Color.background)
                        )
                }
                .foregroundColor(Color.text)

                .offset(x: 6, y: -10)
                , alignment: .topLeading
            )
    }
}

extension View {
    func clearListStyle() -> some View {
        modifier(ClearListStyle())
    }
    
    func keypadButtonStyle(title: String) -> some View {
        modifier(KeypadButtonStyle(title: title))
    }
}
