//
//  DocumentReference+Publisher.swift
//
//  Created by William Wolff on 06.10.20.
//  Copyright © 2020 CityXcape. All rights reserved.
//

import Combine
import Foundation
import FirebaseFirestore

extension DocumentReference {
    
    public var snapshotPublisher: AnyPublisher<DocumentSnapshot, Error> {
        return snapshotPublisher()
    }
    
    public func snapshotPublisher(_ qos: DispatchQoS.QoSClass = .userInitiated) -> AnyPublisher<DocumentSnapshot, Error> {
        return Future<DocumentSnapshot, Error> { promise in
            DispatchQueue.global(qos: qos).async { [weak self] in
                self?.getDocument { (snapshot, error) in
                    DispatchQueue.main.async {
                        guard error == nil else {
                            promise(.failure(error!))
                            return
                        }
                        promise(.success(snapshot!))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}
