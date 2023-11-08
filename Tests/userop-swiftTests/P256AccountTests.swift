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
    let salt = BigUInt(1)
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
        let initCode = factoryAddress.addressData +
        factory.contract.method("createAccount", parameters: [owner, salt], extraData: nil)!
        let onlineAddress = try await factory.getAddress(owner: owner, salt: 1).address

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

    func testCreate2() async throws {
        let from = EthereumAddress("0x8ba1f109551bD432803012645Ac136ddd64DBA72")!
        let salt = "HelloWorld".data(using: .utf8)!.sha3(.keccak256)
        let initCode = Data(hex: "0x6394198df16000526103ff60206004601c335afa6040516060f3")
        var data = Data()
        data.append(Data([0xff]))
        data.append(from.addressData)
        data.append(Data(repeating: 0, count: 32 - salt.count))
        data.append(salt)
        data.append(initCode.sha3(.keccak256))
        let hash = data.sha3(.keccak256)
        let addressData = hash[12...]
        let address = addressData.toHexString()
        print("address: \(address)")

        let provider = try await BundlerJsonRpcProvider(url: rpcUrl, bundlerRpc: bundleRpcUrl, network: .Custom(networkID: 97))
        let web3 = Web3(provider: provider)
        let entry = EntryPoint(web3: web3, address: entryPoint)
        let onlineAddress = try await entry.getSenderAddress(initCode: initCode).address
        print("online address: \(onlineAddress)")
    }
    
//    func testCreateAccount() async throws {
//        let signer = SimpleSinger(privateKey: privateKey)
////        let paymaster = VerifyingPaymasterMiddleware(paymasterRpc: URL(string: "0x04A8123a00C9FCDF61a2E0C95A013759FA87aCc0")!)
//        var accountBuilder = try await SimpleAccountBuilder(signer:signer, rpcUrl: rpcUrl, bundleRpcUrl: bundleRpcUrl, entryPoint: entryPoint, factory: factoryAddress, salt: BigInt(1))
//        let senderAddress = accountBuilder.sender.address
//        print("我的--- \(accountBuilder.initCode.hexString)")
//        
//        print(senderAddress)
//        
//        print("*************************************")
//    }
    
    func testEstimateGas() {
        let array = Data(hex: "0x13868836bb7b4dd354df54e8fef4092011a587b15fbfb9cf0000000000000000000000003dda64705be3b4d9c512b707ef480795f45070cc0000000000000000000000000000000000000000000000000000000000000001")
        let gasLimit = array.map { $0 == 0 ? 4 : 16 }
                            .reduce(0, { $0 + $1 }) +
                        200 * array.count / 2 +
                        6 * Int(ceil(Double(array.count) / 64)) +
                        32000 +
                        21000
        var deployerGasLimit = Int(floor(Double(gasLimit) * 64 / 63))
        print("gaslimit", deployerGasLimit)
    }
}
