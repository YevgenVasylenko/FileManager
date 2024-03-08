//
//  PhotosViewController.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 26.01.2024.
//

import UIKit
import Photos

enum Source: Hashable {
    case collection(PHAssetCollection)
    case photo(PHAsset)
}

class AlbumsViewController: UICollectionViewController {

    private var dataSource: UICollectionViewDiffableDataSource<Int, Source>?
    private var selectedCollection: PHAssetCollection?
    private var sources: [Source] = []

    init() {
        super.init(collectionViewLayout: Self.createLayout())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        makeSources()
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let cell = cell as? AlbumViewCell else {
            assertionFailure()
            return
        }
        cell.willAppear()
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let source = sources[indexPath.row]
        switch source {
        case .collection(let collection):
            let albumsViewController = AlbumsViewController()
            albumsViewController.title = collection.localizedTitle
            albumsViewController.selectedCollection = collection
            self.navigationController?.pushViewController(albumsViewController, animated: true)
        case .photo(let photo):
            break
        }

    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let cell = cell as? AlbumViewCell else {
            assertionFailure()
            return
        }
        cell.didDisappear()
    }
}

private extension AlbumsViewController {

    func configureDataSource() {

        let cellRegistration = UICollectionView.CellRegistration<AlbumViewCell, Source> { cell, _, source in
            cell.source = source
        }

        dataSource = UICollectionViewDiffableDataSource<Int, Source>(collectionView: collectionView) { collectionView, indexPath, identifier in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: identifier
            )
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, Source>()
        snapshot.appendSections([1])
        snapshot.appendItems(sources)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in

            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.25),
                                                   heightDimension: .fractionalHeight(1)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

            let containerGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .fractionalHeight(0.2)),
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: containerGroup)

            return section

        }
        return layout
    }

    func makeSources() {
        sources.removeAll()
        if selectedCollection != nil {
            sources = fetchImagesFromGallery()
        } else {
            checkAuthorisationStatus()
        }
        configureDataSource()
    }

    func checkAuthorisationStatus() {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            sources = fetchAlbums()
        } else {
            PHPhotoLibrary.requestAuthorization({ newStatus in
                if newStatus == PHAuthorizationStatus.authorized {
                    self.sources = self.fetchAlbums()
                } else {
                    print("Photo Auth restricted or denied")
                }
            })
        }
    }

    func fetchAlbums() -> [Source] {
        var albums: [PHAssetCollection] = []
        let result = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        result.enumerateObjects({ (collection, _, _) in
            if collection.hasAssets() {
                albums.append(collection)
            }
        })
        return albums.map({ album in
                .collection(album)
        })
    }

    func fetchImagesFromGallery() -> [Source] {
        var photos: [PHAsset] = []
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        if let collection = selectedCollection {
            let _photos = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            photos = _photos.objects(at: IndexSet(0..._photos.count - 1))
        } else {
            let _photos = PHAsset.fetchAssets(with: fetchOptions)
            photos = _photos.objects(at: IndexSet(0..._photos.count - 1))
        }

        return photos.map({ photo in
            .photo(photo)
        })
    }
}


protocol AlbumImageProvider {
    var imageCount: Int { get }
    func image(at index: Int, size: CGSize) -> UIImage?
}

final class ImageProvider {
    let provider: AlbumImageProvider
    let index: Int = 0

    init(provider: AlbumImageProvider) {
        self.provider = provider
    }

    func getImage(size: CGSize) -> UIImage? {
        provider.image(at: index, size: size)
    }
}
