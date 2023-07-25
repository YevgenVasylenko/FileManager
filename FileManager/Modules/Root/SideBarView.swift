//
//  SideBarView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 23.06.2023.
//

import SwiftUI

struct SideBarView: View {
    let fileSelectDelegate: FileSelectDelegate?

    init(fileSelectDelegate: FileSelectDelegate? = nil) {
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    var body: some View {
        NavigationView {
            Text("My Files")
        }
    }
}

struct SideBarView_Previews: PreviewProvider {
    static var previews: some View {
        SideBarView()
    }
}