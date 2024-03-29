//
//  DropboxLoginManager.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 03.08.2023.
//

import UIKit
import SwiftyDropbox

enum DropboxLoginManager {

    static var isLogged: Bool {
        DropboxClientsManager.authorizedClient != nil
    }
    
    static func login() {
        guard let controller = UIApplication.shared.firstKeyWindow()?.rootViewController else {
            return
        }
        let scopeRequest = ScopeRequest(
            scopeType: .user,
            scopes: [
                "account_info.read",
                "files.metadata.write",
                "files.metadata.read",
                "files.content.write",
                "files.content.read"
            ],
            includeGrantedScopes: false
        )
        DropboxClientsManager.authorizeFromControllerV2(
            UIApplication.shared,
            controller: controller,
            loadingStatusDelegate: nil,
            openURL: { url in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            },
            scopeRequest: scopeRequest
        )
    }
    
    static func  logout() {
        DropboxClientsManager.unlinkClients()
    }
    
    static func openUrl(url: URL) {
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
