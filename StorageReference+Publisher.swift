//
//  StorageReference+Publisher.swift
//
//  Created by William Wolff on 09.10.20.
//  Copyright © 2020 CityXcape. All rights reserved.
//

import Combine
import Foundation
import FirebaseStorage

extension StorageReference {
    
    public func uploadPublisher(_ data: Any,
                                metadata: StorageMetadata? = nil) -> AnyPublisher<URL, Error> {
        
        let dataPublisher: AnyPublisher<Data, Error>
        if
            let rawUrl = data as? NSURL,
            let rawUrlString = rawUrl.absoluteString,
            let url = URL(string: rawUrlString)
        {
            
            dataPublisher = filePublisher(from: url, metadata: metadata)
        } else if let image = data as? UIImage {
            dataPublisher = imagePublisher(image, metadata: metadata)
        } else {
            return Fail(error: UploadError.invalidDataType).eraseToAnyPublisher()
        }
        
        let ref = self
        return dataPublisher
            .flatMap {
                ref.upload(data: $0, metadata: metadata)
            }
            .flatMap {
                ref.downloadURL
            }
            .mapError({ (error) -> Error in
                print(error)
                return WebRepositoryError.invalidData
            })
            .eraseToAnyPublisher()
    }
    
    public func filePublisher(from url: URL,
                              metadata: StorageMetadata? = nil) -> AnyPublisher<Data, Error> {
        return Future<Data, Error> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    promise(.success(try Data(contentsOf: url)))
                } catch let e {
                    promise(.failure(e))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    public func imagePublisher(_ image: UIImage,
                               metadata: StorageMetadata? = nil) -> AnyPublisher<Data, Error> {
        return Future<Data, Error> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = image.pngData() {
                    promise(.success(data))
                } else {
                    promise(.failure(SpotService.APIError.invalidImageData))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Private
    
    private func upload(data: Data,
                        metadata: StorageMetadata? = nil) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            self?.putData(data,
                          metadata: metadata,
                          completion: { (newMetadata, error) in
                            if let error = error {
                                promise(.failure(error))
                            } else if let _ = newMetadata {
                                promise(.success(()))
                            } else {
                                promise(.failure(UploadError.failedUpload))
                            }
                          })
                .resume()
        }.eraseToAnyPublisher()
    }
    
    private var downloadURL: AnyPublisher<URL, Error> {
        return Future<URL, Error> { [weak self] promise in
            self?.downloadURL(completion: { (url, error) in
                if let url = url {
                    promise(.success(url))
                } else if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.failure(StorageReference.UploadError.failedGeneratingURL))
                }
            })
        }
        .eraseToAnyPublisher()
    }
}

extension StorageReference {
    
    enum UploadError: Error {
        case invalidDataType
        case failedUpload
        case failedGeneratingURL
    }
}
