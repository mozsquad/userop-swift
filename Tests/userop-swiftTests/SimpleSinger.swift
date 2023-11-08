//
//  SimpleSinger.swift
//  
//
//  Created by yan on 2023/11/3.
//

import Foundation
import Web3Core
import userop_swift

public class SimpleSinger: NSObject, Signer {
    private let privateKey: Data
    
    public init(privateKey: Data) {
        self.privateKey = privateKey
    }
    
    public func getAddress() async -> EthereumAddress {
        try! await Utilities.publicToAddress(getPublicKey())!
    }
    
    public func getPublicKey() async throws -> Data {
        Utilities.privateToPublic(privateKey)!
    }
    
    public func signMessage(_ data: Data) async throws -> Data {
        let (compressedSignature, _) = SECP256K1.signForRecovery(hash: data,
                                                                 privateKey: privateKey,
                                                                 useExtraEntropy: false)
        return compressedSignature!
    }
    
}
