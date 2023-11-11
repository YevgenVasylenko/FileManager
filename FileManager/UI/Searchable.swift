//
//  Searchable.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 10.11.2023.
//

import SwiftUI

struct Searchable<Content: View>: View {
    let searchInfo: Binding<SearchingInfo>
    let onChanged: (_ searchInfo: SearchingInfo) -> Void

    @ViewBuilder
    let content: () -> Content

    @ViewBuilder
    let searchableSuggestions: () -> Content

    var body: some View {
        SearchView(content: content)
            .searchable(text: searchInfo.searchingName, suggestions: {
                SearchableSuggestions(content: searchableSuggestions)
            })
            .onChange(of: searchInfo.wrappedValue) { _ in
                onChanged(searchInfo.wrappedValue)
            }
    }
}

private struct SearchView<Content: View>: View {
    @ViewBuilder
    let content: () -> Content
    
    @Environment(\.isSearching)
    private var isSearching
    
    @Environment(\.dismissSearch)
    private var dismissSearch
    
    var body: some View {
        content()
    }
}

private struct SearchableSuggestions<Content: View>: View {
    @ViewBuilder
    let content: () -> Content

    var body: some View {
        content()
    }
}
