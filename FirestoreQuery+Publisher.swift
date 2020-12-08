//
//  Query+Publisher.swift
//
//  Created by William Wolff on 18.10.20.
//  Copyright © 2020 CityXcape. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Combine

extension Query {
    
    public var queryPublisher: AnyPublisher<[QueryDocumentSnapshot], Never> {
        return snapshotPublisher()
    }
    
    public func snapshotPublisher(batchSize: Int? = nil) -> AnyPublisher<[QueryDocumentSnapshot], Never> {
        let ref = self
        return Future<[QueryDocumentSnapshot], Never> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                if let batchSize = batchSize {
                    ref.limit(to: batchSize)
                }

                ref.getDocuments { (querySnapshot, error) in
                    guard error == nil else {
                        promise(.success([]))
                        return
                    }
                    promise(.success(querySnapshot!.documents))
                }
            }
        }.eraseToAnyPublisher()
    }
}
