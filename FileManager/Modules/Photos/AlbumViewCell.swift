//
//  AlbumViewCell.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 29.01.2024.
//

import UIKit
import Photos

final class AlbumViewCell: UICollectionViewCell {

    var source: Source?

    private let image = UIImageView()
    private let name = UILabel()
    private var requestedID: PHImageRequestID?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func willAppear() {
        updateSubviews()
    }

    func didDisappear() {
        let manager = PHImageManager.default()
        guard let requestedID else { return }
        manager.cancelImageRequest(requestedID)
    }

}

private extension AlbumViewCell {

    func updateSubviews() {
        switch source {
        case .collection(let album):
            image.image = album.getCoverImage(size: image.bounds.size, requestedID: &requestedID)
            name.text = album.localizedTitle
        case .photo(let photo):
            image.image = photo.getAssetThumbnail(size: image.bounds.size, requestedID: &requestedID)
        case .none:
            break
        }

        image.backgroundColor = .black
        name.font = .preferredFont(forTextStyle: .headline)
    }

    func setupLayout() {
        contentView.addSubview(image)
        contentView.addSubview(name)

        image.contentMode = .scaleAspectFit

        name.textAlignment = .center
        name.setContentCompressionResistancePriority(.required, for: .vertical)

        image.translatesAutoresizingMaskIntoConstraints = false
        name.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: contentView.topAnchor),
            image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            name.topAnchor.constraint(equalTo: image.bottomAnchor),
            name.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            name.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            name.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}


extension PHAssetCollection {

    func getCoverImage(size: CGSize, requestedID: inout PHImageRequestID?) -> UIImage? {
        let assets = PHAsset.fetchAssets(in: self, options: nil)
        let asset = assets.firstObject
        return asset?.getAssetThumbnail(size: size, requestedID: &requestedID)
    }

    func hasAssets() -> Bool {
        let assets = PHAsset.fetchAssets(in: self, options: nil)
        return assets.count > 0
    }
}

extension PHAsset {

    func getAssetThumbnail(size: CGSize, requestedID: inout PHImageRequestID?) -> UIImage? {
        let manager = PHImageManager.default()
        var thumbnail: UIImage?
        let option = PHImageRequestOptions()

        let requestID = manager.requestImage(
            for: self,
            targetSize: size,
            contentMode: .aspectFill,
            options: option
        ) { image, info in
                thumbnail = image
            }
        requestedID = requestID
        return thumbnail
    }

    func getOriginalImage(completion: @escaping (UIImage) -> Void) {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var image = UIImage()
        manager.requestImage(
            for: self,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .default,
            options: option,
            resultHandler: { (result, info) -> Void in
            image = result!
            completion(image)
        })
    }

    func getImageFromPHAsset() -> UIImage {
        var image = UIImage()
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        requestOptions.isSynchronous = true

        if (self.mediaType == PHAssetMediaType.image) {
            PHImageManager.default().requestImage(
                for: self,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .default,
                options: requestOptions,
                resultHandler: { (pickedImage, info) in
                image = pickedImage!
            })
        }
        return image
    }

}
