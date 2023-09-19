//
//  FolderShowOptionsView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 05.09.2023.
//

import SwiftUI

struct FolderShowOptionsView: View {
    private let sortedOption: SortOption?
    private let selectedOption: (SortOption) -> Void
    private var sortOptions: [SortOption]
    
    init(sortedOption: SortOption?, selectedOption: @escaping (SortOption) -> Void) {
        self.sortedOption = sortedOption
        self.selectedOption = selectedOption
        self.sortOptions = SortOption.Attribute.allCases.map { attribute in
            SortOption(attribute: attribute)
        }
        updateSortOptions(sortOptions: &sortOptions)
    }
    
    var body: some View {
        Menu {
            ForEach(sortOptions, id: \.self) { option in
                button(sortOption: option)
            }
        } label: {
            Image(systemName: "square.grid.3x3.square")
        }
    }
}
  
// MARK: - Private

private extension FolderShowOptionsView {
    func button(sortOption: SortOption) -> some View {
        Button {
            selectedOption(makeSelectedOption(sortOption: sortOption))
        } label: {
            labelForButton(sortOption: sortOption)
        }
    }
    
    func updateSortOptions(sortOptions: inout [SortOption]) {
        guard let sortedOption = sortedOption else { return }
        for optionNumber in sortOptions.indices {
            if sortOptions[optionNumber].attribute == sortedOption.attribute {
                sortOptions[optionNumber] = sortedOption
            }
        }
    }
    
    func makeSelectedOption(sortOption: SortOption) -> SortOption {
        SortOption(
            attribute: sortOption.attribute,
            direction: sortOption.direction?.toggled() ?? .ascending
        )
    }
    
    func buttonName(sortOptionAttribute: SortOption.Attribute) -> String {
        switch sortOptionAttribute {
        case .name:
           return R.string.localizable.name.callAsFunction()
        case .type:
            return R.string.localizable.type.callAsFunction()
        case .date:
            return R.string.localizable.date.callAsFunction()
        case .size:
            return R.string.localizable.size.callAsFunction()
        }
    }
    
    func arrowImage(sortOptionDirection: SortOption.Direction) -> String {
        switch sortOptionDirection {
        case .ascending:
            return "arrow.up"
        case .descending:
            return "arrow.down"
        }
    }
    
    func labelForButton(sortOption: SortOption) -> some View {
        Group {
            if let direction = sortOption.direction {
                 Label(buttonName(sortOptionAttribute: sortOption.attribute),
                             systemImage: arrowImage(sortOptionDirection: direction))
            } else {
                 Text(buttonName(sortOptionAttribute: sortOption.attribute))
            }
        }
    }
}
//
//struct FolderShowOptionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        FolderShowOptionsView()
//    }
//}
