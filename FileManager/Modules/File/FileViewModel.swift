//
//  FileViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 03.12.2023.
//

import Foundation
import SwiftUI

final class FileViewModel: ObservableObject {
    enum Style {
        case grid
        case list
        case info
    }

    struct State {
        var tags: [Tag] = []
    }

    let file: File
    let style: Style
    let infoPresented: Binding<Bool>
    let tagsPresented: Binding<Bool>

    @Published
    var state: State

    private var fileManagerCommutator = FileManagerCommutator()

    init(
        file: File,
        style: Style,
        infoPresented: Binding<Bool>,
        tagsPresented: Binding<Bool>
    ) {
        self.state = State()
        self.file = file
        self.style = style
        self.infoPresented = infoPresented
        self.tagsPresented = tagsPresented
        getTags()
        NotificationCenter.default.addObserver(self, selector: #selector(getTags), name: Notify.tagsUpdated, object: nil)
    }

    @objc
    private func getTags() {
        fileManagerCommutator.getActiveTagNamesOnFile(file: file) { result in
            switch result {
            case .success(let tagNames):
                self.state.tags = tagNames.compactMap { tagName in
                    for tag in TagManager.shared.tags {
                        if tag.name == tagName {
                            return tag
                        }
                    }
                    return nil
                }
            case .failure:
                break
            }
        }
    }
}
