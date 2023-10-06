//
//  ListViewItemWithoutDisclosureIndicator.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 29.09.2023.
//

import SwiftUI

struct ListViewItemWithoutDisclosureIndicator<Value, Label>: View
where Value: Hashable,
      Label : View

{
    let value: Value
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        ZStack {
            label()
            NavigationLink(value: value) {
                EmptyView()
            }
            .frame(width: 0)
            .opacity(0)
        }
    }
}
