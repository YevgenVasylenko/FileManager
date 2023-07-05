//
//  FileView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FileView: View {
    var file: File
        
    var body: some View {

            VStack {
//                Image(file.imageName)
//                    .resizable()
//                    .frame(width: 50, height: 50)
                
                Text(file.name)
                    .font(.headline)
                
//                Text(file.details)
//                    .font(.subheadline)
            }
//            Spacer()
    }
}

struct FileView_Previews: PreviewProvider {
    static var object = File(path: SystemFileManger.default.urls(for: .documentDirectory, in: .userDomainMask).first!)
    
    static var previews: some View {
        FileView(file: self.object)
    }
//        .previewLayout(.fixed(width: 300, height: 70))
}
