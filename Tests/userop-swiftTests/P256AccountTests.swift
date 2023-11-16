//
//  P256AccountTests.swift
//
//
//  Created by liugang zhang on 2023/8/30.
//

import XCTest
import Web3Core
import web3swift
import BigInt

@testable import userop_swift

final class P256AccountTests: XCTestCase {
    let privateKey = Data(hex: "36514c262240227300f9dbdbbb6511017a0b3df8e8b6795ec39b0136b83e9ad0")
    let rpcUrl = URL(string: "https://data-seed-prebsc-1-s1.binance.org:8545")!
    let bundleRpcUrl = URL(string: "https://service-test.onto.app/S7/rpc")!
    let entryPoint = EthereumAddress("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789")!
    let owner = EthereumAddress("0x3DDa64705BE3b4D9c512B707Ef480795f45070CC")!
    let factoryAddress = EthereumAddress("0x13868836bb7b4dd354df54e8fef4092011a587b1")!
    let sender = EthereumAddress("0x378597F7Fd2b950Ff2db5A3E8e4e90e276c7f285")!
    let salt = BigInt(1)
//    func testBindEmail() async throws {
//        let account =  try await P256AccountBuilder(signer: P256R1Signer(),
//                                                    rpcUrl: rpc,
//                                                    bundleRpcUrl: bundler,
//                                                    entryPoint: entryPointAddress,
//                                                    factory: factoryAddress,
//                                                    salt: 1)
//        let data = account.proxy.contract.method("addEmailGuardian", parameters: [
//            "0x36387ffce3ddd8c35b790148d6e6134689f74fe32471a27e8a243634ce213098",
//            "0x416bf2958e0965619fe574411312d6963673c87443f2ca65b34cc4415badc96749b5509d0ef2c43000e34fdd9ef5503bf2a12963c0190c25c1f56889d2efb9031b"
//        ], extraData: nil)!
//        account.execute(to: account.sender, value: 0, data: data)
//
//        let client = try await Client(rpcUrl: rpc, overrideBundlerRpc: bundler, entryPoint: entryPointAddress)
//        let response = try await client.sendUserOperation(builder: account)
//    }
//
//    func testRemoveEmail() async throws {
//        let account =  try await P256AccountBuilder(signer: P256R1Signer(),
//                                                    rpcUrl: rpc,
//                                                    bundleRpcUrl: bundler,
//                                                    entryPoint: entryPointAddress,
//                                                    factory: factoryAddress,
//                                                    salt: 1)
//        let data = account.proxy.contract.method("removeEmailGuardian", parameters: [], extraData: nil)!
//        account.execute(to: account.sender, value: 0, data: data)
//
//        let client = try await Client(rpcUrl: rpc, overrideBundlerRpc: bundler, entryPoint: entryPointAddress)
//        let response = try await client.sendUserOperation(builder: account)
//    }
    func testGetAddress() async throws {


        let provider = try await BundlerJsonRpcProvider(url: rpcUrl, bundlerRpc: bundleRpcUrl, network: .Custom(networkID: 97))
        let web3 = Web3(provider: provider)
        let factory = SimpleAccountFactory(web3: web3, address: factoryAddress)
//        let initCode = factoryAddress.addressData +
//        factory.contract.method("createAccount", parameters: [owner, salt], extraData: nil)!
        let onlineAddress = try await factory.getAddress(owner: owner, salt: 1).address
        let ERC1967Proxy = Data(hex: "0xa2b22da3032e50b55f95ec1d13336102d675f341167aa76db571ef7f8bb7975d")
        let simpleAccount = SimpleAccount(web3: web3, address: owner)
        let initialize = simpleAccount.contract.method("initialize", parameters: [owner], extraData: nil)!
        let initCode = Data(hex: "0xaae4cef5d37af27a91ad34fa0d4df5cb3149421e666b38ecdfd09efd2376bbfd")
        
        let initCodeHash = initCode.sha3(.keccak256)
        let saltData = salt.serialize()
        var data = Data()
        data.append(Data([0xFF]))
        data.append(factoryAddress.addressData)
        data.append(Data(repeating: 0x0, count: 32 - saltData.count))
        data.append(saltData)
        data += initCodeHash

        let hash = data.sha3(.keccak256)
        let addressData = Data(hash[12...])
        let address = addressData.toHexString()

        print("online: \(onlineAddress), address: \(address)")
    }
    
    func testEstimate() async throws {
        let owner = EthereumAddress("0x9bd3cf04e8f82ea6458b5a1cf4bed1f0623c8b04")!
        let sender = EthereumAddress("0x518Cf77C2e79cFA3682CDa25604A6b88942eBE9D")!
        let client = try await Client(rpcUrl: rpcUrl, chainId: BigUInt(97), overrideBundlerRpc: bundleRpcUrl, entryPoint: entryPoint)
        let initCode = client.getInitCode(factoryAddress: factoryAddress, owner: owner, salt: salt)
        let estimate = try await client.estimateUserOperationGas(sender: sender, initCode: initCode)
        let bigGas = (estimate.callGasLimit + estimate.preVerificationGas + estimate.verificationGasLimit) * 5000000000
        let gas = Utilities.formatToPrecision(bigGas)
        print("gas", gas)
        print(estimate)
    }
    
    func testGasPrice() async throws {
        let provider = try await BundlerJsonRpcProvider(url: rpcUrl, bundlerRpc: bundleRpcUrl, network: .Custom(networkID: 97))
        let web3 = Web3(provider: provider)
        let price = try await web3.eth.gasPrice()
        print("gasPrice: \(price)")
    }
}
