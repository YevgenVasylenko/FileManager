//
//  Searchable.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 10.11.2023.
//

import SwiftUI

struct Searchable<Content: View, Suggestions: View>: View {
    let searchInfo: Binding<SearchingInfo>

    @ViewBuilder
    let content: () -> Content

    @ViewBuilder
    let searchableSuggestions: () -> Suggestions

    let onChanged: (_ searchInfo: SearchingInfo.SearchingRequest) -> Void

    var body: some View {
        SearchView(content: content)
            .searchable(text: searchInfo.searchingRequest.searchingName, suggestions: {
                searchableSuggestions()
            })
            .onChange(of: searchInfo.searchingRequest.wrappedValue) { _ in
                onChanged(searchInfo.searchingRequest.wrappedValue)
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
