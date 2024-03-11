//
//  FolderShowOptionsView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 05.09.2023.
//

import SwiftUI

struct FolderShowOptionsView: View {
    private let options = FileDisplayOptionsManager.options
    private let optionSelected: (FileDisplayOptions) -> Void
    private var sortOptions: [SortOption]
    
    init(optionSelected: @escaping (FileDisplayOptions) -> Void) {
        self.optionSelected = optionSelected
        self.sortOptions = SortOption.Attribute.allCases.map { attribute in
            SortOption(attribute: attribute)
        }
        updateSortOptions(sortOptions: &sortOptions)
    }
    
    var body: some View {
        Menu {
            Section {
                Button {
                    optionSelected(FileDisplayOptions(layout: .grid, sort: options.sort))
                } label: {
                    Label(R.string.localizable.grid(), systemImage: "square.grid.2x2")
                }
                Button {
                    optionSelected(FileDisplayOptions(layout: .list, sort: options.sort))
                } label: {
                    Label(R.string.localizable.list(), systemImage: "list.bullet")
                }
            }
            
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
            optionSelected(FileDisplayOptions(
                layout: options.layout,
                sort: makeSelectedOption(sortOption: sortOption)))
        } label: {
            labelForButton(sortOption: sortOption)
        }
    }
    
    func updateSortOptions(sortOptions: inout [SortOption]) {
        for optionNumber in sortOptions.indices {
            if sortOptions[optionNumber].attribute == options.sort.attribute {
                sortOptions[optionNumber] = options.sort
            }
        }
    }
    
    func makeSelectedOption(sortOption: SortOption) -> SortOption {
        SortOption(
            attribute: sortOption.attribute,
            direction: sortOption.direction.toggled()
        )
    }
    
    func buttonName(sortOptionAttribute: SortOption.Attribute) -> String {
        switch sortOptionAttribute {
        case .name:
           return R.string.localizable.name()
        case .type:
            return R.string.localizable.type()
        case .date:
            return R.string.localizable.date()
        case .size:
            return R.string.localizable.size()
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

    @ViewBuilder
    func labelForButton(sortOption: SortOption) -> some View {
        if self.options.sort == sortOption {
            Label(buttonName(sortOptionAttribute: sortOption.attribute),
                  systemImage: arrowImage(sortOptionDirection: sortOption.direction))
        } else {
            Text(buttonName(sortOptionAttribute: sortOption.attribute))
        }
    }
}
