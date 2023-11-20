//
//  Client.swift
//  
//
//  Created by liugang zhang on 2023/8/24.
//

import Foundation
import BigInt
import Web3Core
import web3swift

/// Wrap the response of `eth_sendUserOperation` RPC call
public struct SendUserOperationResponse {
    public let userOpHash: String
    public let entryPoint: IEntryPoint

    /// Loop to wait the transaction to be mined
    ///
    /// - Returns: `UserOperationEvent` event log
    public func wait() async throws -> EventLog? {
        let end = Date().addingTimeInterval(30)
        while Date().distance(to: end) > 0 {
            let events = try await entryPoint.queryUserOperationEvent(userOpHash: userOpHash)
            if !events.isEmpty {
                return events[0]
            }
        }

        return nil
    }
}

public protocol IClient {
    func buildUserOperation(builder: IUserOperationBuilder) async throws -> UserOperation

    func sendUserOperation(builder: IUserOperationBuilder, onBuild: ((UserOperation) -> Void)?) async throws -> SendUserOperationResponse
}

extension IClient {
    public func sendUserOperation(builder: IUserOperationBuilder)  async throws -> SendUserOperationResponse {
        try await sendUserOperation(builder: builder, onBuild: nil)
    }
}

public class Client: IClient {
    private let provider: JsonRpcProvider
    private let web3: Web3

    public let entryPoint: EntryPoint

    public var chainId: BigUInt {
        web3.provider.network!.chainID
    }

    public init(rpcUrl: URL,
                chainId: BigUInt,
                overrideBundlerRpc: URL? = nil,
                entryPoint: EthereumAddress) async throws {
        self.provider = try await BundlerJsonRpcProvider(url: rpcUrl, bundlerRpc: overrideBundlerRpc, network: .Custom(networkID: chainId))
        self.web3 = Web3(provider: provider)
        self.entryPoint = EntryPoint(web3: web3, address: entryPoint)
    }

    public func buildUserOperation(builder: IUserOperationBuilder) async throws -> UserOperation {
        try await builder.build(entryPoint: entryPoint.address, chainId: chainId)
    }

    public func sendUserOperation(builder: IUserOperationBuilder, onBuild: ((UserOperation) -> Void)?) async throws -> SendUserOperationResponse {
        let op = try await buildUserOperation(builder: builder)
        onBuild?(op)

        defer {
            builder.reset()
        }

        return try await sendUserOperation(userOp: op)
    }

    public func sendUserOperation(userOp: UserOperation) async throws -> SendUserOperationResponse {
        let userOphash: String  = try await provider.send("eth_sendUserOperation", parameter: [userOp, entryPoint.address]).result
        return .init(userOpHash: userOphash, entryPoint: entryPoint)
    }
    
    public func getInitCode(factoryAddress: EthereumAddress, owner: EthereumAddress, salt: BigInt) -> Data {
        let contract = try! EthereumContract(Abi.simpleAccountFactory, at: factoryAddress)
        let initCode = factoryAddress.addressData +
        contract.method("createAccount", parameters: [owner, salt], extraData: nil)!
        return initCode
    }
    
    public func estimateUserOperationGas(sender: EthereumAddress, initCode: Data) async throws -> GasEstimate {
        let nonce = try await entryPoint.getNonce(sender: sender, key: 0)
        let signature = Data(hex: "44d801a0ea587407f474fd1bb97f518c20f58c43c72132ac843fab17c6a3563e5a5da3fe961a96ee82e21a98a445f88c71457c73eca559fb51a48e0a93514c971b")
        
        let initCode = nonce == 0 ? initCode : Data()
        let callData = Data(hex: "0xb61d27f60000000000000000000000003dda64705be3b4d9c512b707ef480795f45070cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000044a9059cbb0000000000000000000000003dda64705be3b4d9c512b707ef480795f45070cc00000000000000000000000000000000000000000000000000000000000f424000000000000000000000000000000000000000000000000000000000")
        let paymasterAndData = Data(hex: "0xe93eca6595fe94091dc1af46aac2a8b5d799077000000000000000000000000000000000000000000000000000000000654c91f60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003c2e091c4fed6ff6c8b6910cde2c881cbca60f272c1ece8b90afefac6a33db7d5c2adc188658e1f578a938fca18730ad9017729d276fce0cd9b681ee2a3872a01c")
        let op = UserOperation(sender: sender, nonce: nonce, initCode: initCode, callData: callData, callGasLimit: 35000, verificationGasLimit: 70000, preVerificationGas: 21000, maxFeePerGas: 5650000000, maxPriorityFeePerGas: 5650000000, paymasterAndData: paymasterAndData, signature: signature)
        let estimate: GasEstimate = try await provider.send("eth_estimateUserOperationGas", parameter: [op, entryPoint.address]).result
        return estimate
    }
}
