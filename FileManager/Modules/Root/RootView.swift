//
//  RootView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI
import SwiftyDropbox

struct DataSource {
    let file: File
    let fileSelectedDelegate: FileSelectDelegate
}

struct RootView: View {
    let file: File
    let fileSelectDelegate: FileSelectDelegate?
    @State private var files: [File] = [LocalFileManager().rootFolder, DropboxFileManager().rootFolder]
    @State private var selectedFile: File?
    @State var isShown = false
    
    init(file: File = LocalFileManager().rootFolder, fileSelectDelegate: FileSelectDelegate? = nil){
        self.file = file
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    var body: some View {
        NavigationSplitView {
            List(files, id: \.self, selection: $selectedFile) { file in
                dataSourceSelectionButton(file: file)
            }
        } detail: {
            FolderView(file: selectedFile ?? LocalFileManager().rootFolder, fileSelectDelegate: fileSelectDelegate)
                .id(selectedFile)
            DropboxView(isShown: $isShown)
        }
        .padding()
        .onOpenURL { url in
            let oauthCompletion: DropboxOAuthCompletion = {
                if let authResult = $0 {
                    switch authResult {
                    case .success:
                        print("Success! User is logged into DropboxClientsManager.")
                    case .cancel:
                        print("Authorisation flow was manually canceled by user!")
                    case .error(_, let description):
                        print("Error: \(String(describing: description))")
                    }
                }
            }
            DropboxClientsManager.handleRedirectURL(url, completion: oauthCompletion)
        }
    }
}

private extension RootView {
    func dataSourceSelectionButton(file: File) -> some View {
        Button(action: {
            selectedFile = file
        },
               label: {
            Text(file.displayedName())
                .contextMenu {
                    if file.storageType.isDropbox {
                        Button {
                            self.isShown = true
                        } label: {
                            Text("Connect")
                        }
                        .disabled(DropboxClientsManager.authorizedClient != nil)
                        
                        Button("Disconnect", role: .destructive) {
                            DropboxClientsManager.unlinkClients()
                        }
                        .disabled(DropboxClientsManager.authorizedClient == nil)
                    }
                }
        }).tag(file)
            .buttonStyle(.plain)
    }
    
    func cancelButtonForFolderSelection(chooseAction: @escaping () -> Void) -> some View {
        Group {
            if fileSelectDelegate != nil {
                Button(R.string.localizable.cancel.callAsFunction()) {
                    chooseAction()
                }
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(file: PreviewFiles.rootFolder)
    }
}

struct DropboxView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    @Binding var isShown : Bool
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
        if isShown {
            let scopeRequest = ScopeRequest(scopeType: .user, scopes: ["account_info.read", "files.metadata.write", "files.metadata.read", "files.content.write", "files.content.read"], includeGrantedScopes: false)
            DropboxClientsManager.authorizeFromControllerV2(
                UIApplication.shared,
                controller: uiViewController,
                loadingStatusDelegate: nil,
                openURL: { (url: URL) -> Void in UIApplication.shared.open(url, options: [:], completionHandler: nil) },
                scopeRequest: scopeRequest)
        }
    }
    
    func makeUIViewController(context _: Self.Context) -> UIViewController {
        return UIViewController()
    }
}
