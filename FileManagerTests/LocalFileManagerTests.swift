//
//  LocalFileManagerTests.swift
//  FileManagerTests
//
//  Created by Yevgen Vasylenko on 27.06.2023.
//

import XCTest

// remove comments code or uncomment and fix

final class LocalFileManagerTests: XCTestCase {

    var fileManager: LocalFileManager!
    var conflictResolver: NameConflictResolverMock!

    override func setUp() {
        fileManager = LocalFileManager(fileManagerRootPath: TestFileMangerRootPath())
        conflictResolver = NameConflictResolverMock()
    }
    
    func testDefaultFoldersCreation() {
        let rootFolder = fileManager.rootFolder.makeStubFile()
        let trashFolder = fileManager.trashFolder.makeStubFile()
        let downloadsFolder = fileManager.downloadsFolder.makeStubFile()
        fileManager.createFolder(at: rootFolder) { rootCreateResult in
            XCTAssertTrue(rootCreateResult.isSuccess)
        }
        fileManager.createFolder(at: trashFolder) { trashCreateResult in
            XCTAssertTrue(trashCreateResult.isSuccess)
        }
        fileManager.createFolder(at: downloadsFolder) { downloadsCreateResult in
            XCTAssertTrue(downloadsCreateResult.isSuccess)
        }
    }
    
    func testContentOfFolder() {
        let file = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: file) { rootCreateResult in
            XCTAssertTrue(rootCreateResult.isSuccess)
        }
        let file1 = file.makeStubFile()
        fileManager.createFolder(at: file1) { rootCreateResult in
            XCTAssertTrue(rootCreateResult.isSuccess)
        }
        let file2 = file.makeStubFile()
        fileManager.createFolder(at: file2) { rootCreateResult in
            XCTAssertTrue(rootCreateResult.isSuccess)
        }
        fileManager.contents(of: file) { result in
            switch result {
            case .success(let files):
                XCTAssertTrue(files.count == 2)
                // uncomment?
//                XCTAssertTrue(files.contains(file1))
//                XCTAssertTrue(files.contains(file2))
            case .failure:
                XCTFail()
            }
        }
    }
    
    func testContentOfNonExistingFolder() {
        let file = fileManager.rootFolder.makeStubFile()
                                                                // Folder not created
        fileManager.contents(of: file) { contentResult in
            XCTAssertTrue(contentResult.isFailure)
        }
    }
        
    func testCreateFolder() {
        let file = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: file) { createResult in
            switch createResult {
            case .success:
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: file.path.path))
            case .failure:
                XCTFail()
            }
        }
    }
    
    func testCreateFolderWithSameName() {
        let file = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: file) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        fileManager.createFolder(at: file) { contentResult in
                XCTAssertTrue(contentResult.isFailure)
        }
    }
    
    func testFailCreateFolderWithInvalidPath() {
        let folder1 = fileManager.rootFolder.makeStubFile()
        let folder2 = folder1.makeStubFile()
        fileManager.createFolder(at: folder2) { contentResult in
            XCTAssertTrue(contentResult.isFailure)
        }
    }
    
    func testMoveFile() {
        conflictResolver.mockResult = .cancel
        let fileToMove = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToMove) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let destinationFolder = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: destinationFolder) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let fileAfterMove = destinationFolder.makeSubfile(name: fileToMove.name)
        fileManager.move(files: [fileToMove], destination: destinationFolder, conflictResolver: conflictResolver) { result in
            switch result {
            case .success:
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileAfterMove.path.path))
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileToMove.path.path))
            case .failure:
                XCTFail()
            }
        }
    }

    func testMoveFileToNonExistingFolder() {
        conflictResolver.mockResult = .cancel
        let fileToMove = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToMove) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let destinationFolder = fileManager.rootFolder.makeStubFile()
        fileManager.move(files: [fileToMove], destination: destinationFolder, conflictResolver: conflictResolver) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: destinationFolder.path.path))
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileToMove.path.path))
            }
        }
    }

    func testMoveNonExistingFile() {
        conflictResolver.mockResult = .cancel
        let fileToMove = fileManager.rootFolder.makeStubFile()
        let destinationFolder = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: destinationFolder) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let fileAfterMove = destinationFolder.makeSubfile(name: fileToMove.name)
        fileManager.move(files: [fileToMove], destination: destinationFolder, conflictResolver: conflictResolver) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileAfterMove.path.path))
            }
        }
    }

    func testMoveFileToFolderWithSameNamedFileAndReplaceIt() {
        conflictResolver.mockResult = .replace
        let fileToMove = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToMove) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let destinationFolder = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: destinationFolder) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let fileAfterMove = destinationFolder.makeSubfile(name: fileToMove.name)
        fileManager.createFolder(at: fileAfterMove) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        fileManager.move(files: [fileToMove], destination: destinationFolder, conflictResolver: conflictResolver) { result in
            switch result {
            case .success:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileToMove.path.path))
            case .failure:
                XCTFail()
            }
        }
    }

    func testMoveFileToFolderWithSameNamedFileAndMakeCopyWithNewName() {
        conflictResolver.mockResult = .newName
        let fileToMove = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToMove) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let destinationFolder = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: destinationFolder) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let fileAfterMove = destinationFolder.makeSubfile(name: fileToMove.name)
        fileManager.createFolder(at: fileAfterMove) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }

        fileManager.move(files: [fileToMove], destination: destinationFolder, conflictResolver: conflictResolver) { result in
            switch result {
            case .success:
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileAfterMove.path.path + " (1)"))
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileToMove.path.path))
            case .failure:
                XCTFail()
            }
        }
    }


    func testCopyFile() {
        let fileToCopy = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToCopy) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let destinationFolder = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: destinationFolder) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let copiedFile = destinationFolder.makeSubfile(name: fileToCopy.name)
        fileManager.copy(files: [fileToCopy], destination: destinationFolder, conflictResolver: conflictResolver) { copyFileResult in
            switch copyFileResult {
            case .success:
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileToCopy.path.path))
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: copiedFile.path.path))
                XCTAssertTrue(fileToCopy.name == copiedFile.name)
            case .failure:
                XCTFail()
            }
        }
    }

    func testCopyFileToNonExistingFolder() {
        let fileToCopy = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToCopy) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let destinationFolder = fileManager.rootFolder.makeStubFile()
        let copiedFile = destinationFolder.makeSubfile(name: fileToCopy.name)
        fileManager.copy(files: [fileToCopy], destination: destinationFolder, conflictResolver: conflictResolver) { copyFileResult in
            switch copyFileResult {
            case .success:
                XCTFail()
            case .failure:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: copiedFile.path.path))
            }
        }
    }

    func testCopyNonExistingFile() {
        let fileToCopy = fileManager.rootFolder.makeStubFile()
        let destinationFolder = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: destinationFolder) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let copiedFile = destinationFolder.makeSubfile(name: fileToCopy.name)
        fileManager.copy(files: [fileToCopy], destination: destinationFolder, conflictResolver: conflictResolver) { copyFileResult in
            switch copyFileResult {
            case .success:
                XCTFail()
            case .failure:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: copiedFile.path.path))
            }
        }
    }

    func testCopyFileToFolderWithSameNamedFileAndReplaceIt() {
        conflictResolver.mockResult = .replace
        let fileToCopy = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToCopy) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let destinationFolder = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: destinationFolder) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let folderInDestinationWithSameName = destinationFolder.makeSubfile(name: fileToCopy.name)
        fileManager.createFolder(at: folderInDestinationWithSameName) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let fileInConflictedFolder = folderInDestinationWithSameName.makeSubfile(name: fileToCopy.name)
        fileManager.createFolder(at: fileInConflictedFolder) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        fileManager.copy(files: [fileToCopy], destination: destinationFolder, conflictResolver: conflictResolver) { result in
            switch result {
            case .success:
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileToCopy.path.path))
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileInConflictedFolder.path.path))
            case .failure:
                XCTFail()
            }
        }
    }

    func testCopyFileToFolderWithSameNamedFileAndMakeCopyWithNewName() {
        conflictResolver.mockResult = .newName
        let fileToCopy = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToCopy) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let destinationFolder = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: destinationFolder) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let folderInDestinationWithSameName = destinationFolder.makeSubfile(name: fileToCopy.name)
        fileManager.createFolder(at: folderInDestinationWithSameName) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        fileManager.copy(files: [fileToCopy], destination: destinationFolder, conflictResolver: conflictResolver) { result in
            switch result {
            case .success:
                SystemFileManger.default.fileExists(atPath: folderInDestinationWithSameName.path.path + " (1)")
            case .failure:
                XCTFail()
            }
        }
    }

    func testRenameFile() {
        let fileToRename = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToRename) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let newName = UUID().uuidString
        fileManager.rename(file: fileToRename, newName: newName) { renameFileResult in
            switch renameFileResult {
            case .success:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileToRename.path.path))
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileToRename.rename(name: newName).path.path))
            case .failure:
                XCTFail()
            }
        }
    }

    func testRenameNonExistingFile() {
        let fileToRename = fileManager.rootFolder.makeStubFile()
        let newName = UUID().uuidString
        fileManager.rename(file: fileToRename, newName: newName) { renameFileResult in
            switch renameFileResult {
            case .success:
                XCTFail()
            case .failure:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileToRename.rename(name: newName).path.path))
            }
        }
    }

    func testRenameFileWithExistingName() {
        let file = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: file) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let fileToRename = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToRename) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        fileManager.rename(file: file, newName: fileToRename.name) { renameFileResult in
            switch renameFileResult {
            case .success:
                XCTFail()
            case .failure:
                break
            }
        }
    }

    func testMoveToTrash() {
        let fileToTrash = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToTrash) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let fileInTrash = fileManager.trashFolder.makeSubfile(name: fileToTrash.name)
        fileManager.moveToTrash(filesToTrash: [fileToTrash]) { moveToTrashResult in
            switch moveToTrashResult {
            case .success:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileToTrash.path.path))
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileInTrash.path.path))
            case .failure:
                XCTFail()
            }
        }
    }

    func testMoveToTrashWithSameName() {
        let fileToTrash = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToTrash) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let trashedFile = fileManager.trashFolder.makeSubfile(name: fileToTrash.name)
        fileManager.createFolder(at: trashedFile) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        fileManager.moveToTrash(filesToTrash: [fileToTrash]) { moveToTrashResult in
            switch moveToTrashResult {
            case .success:
                fileManager.contents(of: fileManager.trashFolder) { result in
                        switch result {
                        case .success(let files):
                            for file in files {
                                if file.name.contains(fileToTrash.name) {
                                    return
                                }
                            }
                            XCTFail()
                        case .failure:
                            XCTFail()
                        }
                }
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: trashedFile.path.path))
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileToTrash.path.path))
            case .failure:
                XCTFail()
            }
        }
    }

    func testMoveToTrashNonExisting() {
        let fileToTrash = fileManager.rootFolder.makeStubFile()
        fileManager.moveToTrash(filesToTrash: [fileToTrash]) { result in
            XCTAssertTrue(result.isFailure)
        }
    }

    func testDelete() {
        let file = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: file, completion: { createFolderResult in
            XCTAssertTrue(createFolderResult.isSuccess)
        })
        fileManager.deleteFile(files: [file]) { deleteResult in
            switch deleteResult {
            case .success:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: file.path.path))
            case .failure:
                XCTFail()
            }
        }
    }
    
    func testDeleteNonExisting() {
        let file = fileManager.rootFolder.makeStubFile()
        fileManager.deleteFile(files: [file]) { result in
            XCTAssertTrue(result.isFailure)
        }
    }

    func testRestoreFromTrash() {
        let fileToTrash = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToTrash) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let fileInTrash = fileManager.trashFolder.makeSubfile(name: fileToTrash.name)
        fileManager.moveToTrash(filesToTrash: [fileToTrash]) { moveToTrashResult in
            switch moveToTrashResult {
            case .success:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileToTrash.path.path))
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileInTrash.path.path))
            case .failure:
                XCTFail()
            }
        }

        fileManager.restoreFromTrash(
            filesToRestore: [fileInTrash],
            conflictResolver: conflictResolver
        ) { restoreFromTrashResult in
            switch restoreFromTrashResult {
            case .success:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileInTrash.path.path))
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileToTrash.path.path))
            case .failure:
                XCTFail()
            }
        }
    }

    func testRestoreFromTrashNonEmptyFolder() {
        let fileToTrash = fileManager.rootFolder.makeStubFile()
        fileManager.createFolder(at: fileToTrash) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }
        let fileInsideFileToTrash = fileToTrash.makeStubFile()
        fileManager.createFolder(at: fileInsideFileToTrash) { contentResult in
            XCTAssertTrue(contentResult.isSuccess)
        }

        let fileInTrash = fileManager.trashFolder.makeSubfile(name: fileToTrash.name)
        fileManager.moveToTrash(filesToTrash: [fileToTrash]) { moveToTrashResult in
            switch moveToTrashResult {
            case .success:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileToTrash.path.path))
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileInsideFileToTrash.path.path))
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileInTrash.path.path))
            case .failure:
                XCTFail()
            }
        }

        fileManager.restoreFromTrash(
            filesToRestore: [fileInTrash],
            conflictResolver: conflictResolver
        ) { restoreFromTrashResult in
            switch restoreFromTrashResult {
            case .success:
                XCTAssertFalse(SystemFileManger.default.fileExists(atPath: fileInTrash.path.path))
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileToTrash.path.path))
                XCTAssertTrue(SystemFileManger.default.fileExists(atPath: fileInsideFileToTrash.path.path))
            case .failure:
                XCTFail()
            }
        }
    }
}

