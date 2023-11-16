//
//  GasEstimateMiddleware.swift
//  
//
//  Created by liugang zhang on 2023/8/23.
//

import Foundation
import BigInt
import Web3Core

public struct GasEstimate: APIResultType {
    public let preVerificationGas: BigUInt
    public let verificationGasLimit: BigUInt
    public let callGasLimit: BigUInt
}

extension GasEstimate {
    enum CodingKeys: CodingKey {
        case preVerificationGas
        case verificationGasLimit
        case callGasLimit
        case verificationGas
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            let preVerificationGas = try container.decodeHex(BigUInt.self, forKey: .preVerificationGas) + 3000
            var tempGasLimit = try? container.decodeHex(BigUInt.self, forKey: .verificationGasLimit)
            tempGasLimit = tempGasLimit ?? (try? container.decodeHex(BigUInt.self, forKey: .verificationGas))
            if tempGasLimit != nil {
                tempGasLimit! += 60000
            }
            let verificationGasLimit = tempGasLimit ?? BigUInt(600000)
            
            let callGasLimit = try container.decodeHex(BigUInt.self, forKey: .callGasLimit) + 600000
            self.init(preVerificationGas: preVerificationGas,
                      verificationGasLimit: verificationGasLimit,
                      callGasLimit: callGasLimit)
        } catch {
            let preVerificationGas = try container.decode(Int.self, forKey: .preVerificationGas) + 3000
            var tempGasLimit = try? container.decode(Int.self, forKey: .verificationGasLimit)
            tempGasLimit = tempGasLimit ?? (try? container.decode(Int.self, forKey: .verificationGas))
            if tempGasLimit != nil {
                tempGasLimit! += 60000
            }
            let verificationGasLimit = tempGasLimit ?? 600000
            let callGasLimit = try container.decode(Int.self, forKey: .callGasLimit) + 600000
            self.init(preVerificationGas: BigUInt(preVerificationGas),
                      verificationGasLimit: BigUInt(verificationGasLimit),
                      callGasLimit: BigUInt(callGasLimit))
        }
    }
}

/// Middleware to estiamte `UserOperation` gas from bundler server.
public struct GasEstimateMiddleware: UserOperationMiddleware {
    let rpcProvider: JsonRpcProvider

    public init(rpcProvider: JsonRpcProvider) {
        self.rpcProvider = rpcProvider
    }

    public func process(_ ctx: inout UserOperationMiddlewareContext) async throws {
        let estimate: GasEstimate = try await rpcProvider.send("eth_estimateUserOperationGas", parameter: [ctx.op, ctx.entryPoint]).result

        ctx.op.preVerificationGas = estimate.preVerificationGas
        ctx.op.verificationGasLimit = estimate.verificationGasLimit
        ctx.op.callGasLimit = estimate.callGasLimit
    }
}
