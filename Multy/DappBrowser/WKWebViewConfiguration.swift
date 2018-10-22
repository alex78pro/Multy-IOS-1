// Copyright DApps Platform Inc. All rights reserved.

import Foundation
import WebKit
import JavaScriptCore
import TrustCore
extension WKWebViewConfiguration {

    static func make(for address: String, in messageHandler: WKScriptMessageHandler) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        
//        let rpcURL = "https://mainnet.infura.io/llyrtzQ3YhkdESt2Fzrk"
        let rpcURL = "https://rinkeby.infura.io/v3/78ae782ed28e48c0b3f74ca69c4f7ca8"
        let chainID = 4
        
        var js = ""

        guard
            let bundlePath = Bundle.main.path(forResource: "TrustWeb3Provider", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath) else { return config }

        if let filepath = bundle.path(forResource: "trust-min", ofType: "js") {
            do {
                js += try String(contentsOfFile: filepath)
            } catch { }
        }

        js +=
        """
        const addressHex = "\(address.lowercased())"
        const rpcURL = "\(rpcURL)"
        const chainID = "\(chainID)"

        function executeCallback (id, error, value) {
            Trust.executeCallback(id, error, value)
        }

        Trust.init(rpcURL, {
            getAccounts: function (cb) { cb(null, [addressHex]) },
            processTransaction: function (tx, cb){
                console.log('signing a transaction', tx)
                const { id = 8888 } = tx
                Trust.addCallback(id, cb)
                webkit.messageHandlers.signTransaction.postMessage({"name": "signTransaction", "object": tx, id: id})
            },
            signMessage: function (msgParams, cb) {
                const { data } = msgParams
                const { id = 8888 } = msgParams
                console.log("signing a message", msgParams)
                Trust.addCallback(id, cb)
                webkit.messageHandlers.signMessage.postMessage({"name": "signMessage", "object": { data }, id: id})
            },
            signPersonalMessage: function (msgParams, cb) {
                const { data } = msgParams
                const { id = 8888 } = msgParams
                console.log("signing a personal message", msgParams)
                Trust.addCallback(id, cb)
                webkit.messageHandlers.signPersonalMessage.postMessage({"name": "signPersonalMessage", "object": { data }, id: id})
            },
            signTypedMessage: function (msgParams, cb) {
                const { data } = msgParams
                const { id = 8888 } = msgParams
                console.log("signing a typed message", msgParams)
                Trust.addCallback(id, cb)
                webkit.messageHandlers.signTypedMessage.postMessage({"name": "signTypedMessage", "object": { data }, id: id})
            }
        }, {
            address: addressHex,
            networkVersion: chainID
        })

        web3.setProvider = function () {
            console.debug('Trust Wallet - overrode web3.setProvider')
        }

        web3.eth.defaultAccount = addressHex

        web3.version.getNetwork = function(cb) {
            cb(null, chainID)
        }

        web3.eth.getCoinbase = function(cb) {
            return cb(null, addressHex)
        }

        """
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.add(messageHandler, name: DappOperationType.signTransaction.rawValue)
        config.userContentController.add(messageHandler, name: DappOperationType.signPersonalMessage.rawValue)
        config.userContentController.add(messageHandler, name: DappOperationType.signMessage.rawValue)
        config.userContentController.add(messageHandler, name: DappOperationType.signTypedMessage.rawValue)
        config.userContentController.addUserScript(userScript)
        return config
    }
}
