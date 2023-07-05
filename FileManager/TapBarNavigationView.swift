//
//  TapBarNavigationView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct TapBarNavigationView: View {
    var body: some View {
        TabView {
           Text("The content of the first view")
             .tabItem {
                Image(systemName: "folder")
                Text("All files")
              }
            Text("The content of the first view")
                .tabItem {
                    Image(systemName: "clock")
                    Text("Recents")
                }
            Text("The content of the first view")
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

struct TapBarNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        TapBarNavigationView()
    }
}
