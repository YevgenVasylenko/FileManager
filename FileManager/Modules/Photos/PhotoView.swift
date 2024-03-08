//
//  PhotoView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 28.01.2024.
//

import SwiftUI

struct PhotoView: UIViewControllerRepresentable {

    typealias UIViewControllerType = AlbumsViewController

    func makeUIViewController(context: Context) -> AlbumsViewController {
        AlbumsViewController()
    }

    func updateUIViewController(_ uiViewController: AlbumsViewController, context: Context) {
        
    }
}
