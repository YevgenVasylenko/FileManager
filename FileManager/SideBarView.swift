//
//  SideBarView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 23.06.2023.
//

import SwiftUI

struct SideBarView: View {
    var body: some View {
        
        List {
            NavigationView {
                Text("My files")
            }
        }
        .navigationTitle("My files")
//        .searchable(text: $searchText)
    }
}

struct SideBarView_Previews: PreviewProvider {
    static var previews: some View {
        SideBarView()
    }
}
