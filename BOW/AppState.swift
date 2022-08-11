//
//  AppState.swift
//  BOW
//
//  Created by Jacob Davis on 7/27/22.
//

import Foundation
import BitcoinDevKit
import SwiftUI

class AppState: ObservableObject {
    
    enum ViewState {
        case home, sendA, sendB, scanQR, receive, settings
    }
    
    @Published var viewState = Stack<ViewState>(items: [.home])
    
    @Published var sendToAddress: String = ""
    @Published var sendAmount: UInt64 = .zero
    @Published var isLoading: Bool = false
    
    @AppStorage("left_handed_mode") var leftHandedMode: Bool = false
    
    struct WalletContainer {
        
        enum State {
            case empty
            case loading
            case failed(Error)
            case loaded
        }
        
        enum SyncState {
            case empty
            case syncing
            case synced
            case failed(Error)
        }
        
        var transactions: [TransactionContainer] = []
        var balance: UInt64 = 0
        
        var state: State = .empty
        var syncState: SyncState = .empty
    }
    
    struct TransactionContainer: Identifiable {
        var id: String {
            return details.txid
        }
        let details: TransactionDetails
        var blockTime: BlockTime?
    }
    
    struct SyncWallet {
        let db: DatabaseConfig
        let blockchain: Blockchain
        let wallet: Wallet
    }
    
    var syncWallet: SyncWallet? = nil
    @Published var currentWalletContainer: WalletContainer = WalletContainer()

    func load() async {
        
        await self.updateState(state: .loading)
        let db = DatabaseConfig.memory
        
        // JUST FOR TESTING. Keys/seeds would normally be stored in keychain
        let key = try? restoreExtendedKey(network: .testnet, mnemonic: "whisper unusual decorate art chunk ritual reform news maid math giant virtual", password: nil)
        let xprv = key?.xprv ?? ""
        
        let descriptor = "wpkh(" + xprv + "/84h/1h/0h/0/*" + ")"
//        let electrum = ElectrumConfig(url: "ssl://electrum.blockstream.info:60002", socks5: nil, retry: 5, timeout: nil, stopGap: 10)
//        let blockchainConfig = BlockchainConfig.electrum(config: electrum)
        
        let esploraConfig = EsploraConfig(baseUrl: "https://blockstream.info/testnet/api/", proxy: nil, concurrency: 4, stopGap: 10, timeout: nil)
        
        let blockchainConfig = BlockchainConfig.esplora(config: esploraConfig)
        
        do {
            
            let blockchain = try Blockchain(config: blockchainConfig)
            let wallet = try Wallet(descriptor: descriptor, changeDescriptor: nil, network: Network.testnet, databaseConfig: db)
            
            self.syncWallet = SyncWallet(db: db, blockchain: blockchain, wallet: wallet)
            await updateState(state: .loaded)

        } catch let error {
            await updateState(state: WalletContainer.State.failed(error))
        }

    }
    
    func sync() async {

        guard let blockchain = syncWallet?.blockchain else {
            return
        }
        
        switch currentWalletContainer.state {
            
        case .loaded:
            
            await updateSyncState(syncState: .syncing)
             
            do {
                try self.syncWallet?.wallet.sync(blockchain: blockchain, progress: nil)
                await updateSyncState(syncState: .synced)
                
                let balance = try self.syncWallet?.wallet.getBalance()
                await self.updateBalance(balance: balance)
                
                let transactions = try self.syncWallet?.wallet.getTransactions()
                await self.updateTransactions(transactions: transactions ?? [])
            } catch {
                await self.updateSyncState(syncState: WalletContainer.SyncState.failed(error))
                print(error)
            }
            
        default:
            print("UFad")
        }

    }
    
    @MainActor
    func updateTransactions(transactions: [BitcoinDevKit.Transaction]) {
        
        let txs = transactions.map({
            switch $0 {
            case .confirmed(let details, let blockTime):
                return TransactionContainer(details: details, blockTime: blockTime)
            case .unconfirmed(let details):
                return TransactionContainer(details: details, blockTime: nil)
            }
        })
        
        var unconfirmed = txs.filter({ $0.blockTime == nil })
        let confirmed = txs
            .filter({ $0.blockTime != nil })
            .sorted(by: { ($0.blockTime?.height ?? .zero) > ($1.blockTime?.height ?? .zero) })
        
        unconfirmed.append(contentsOf: confirmed)
        
        self.currentWalletContainer.transactions = Array(unconfirmed.prefix(10))
    }
    
    @MainActor
    func updateBalance(balance: UInt64?) {
        if let balance = balance {
            self.currentWalletContainer.balance = balance
        }
    }
    
    @MainActor
    func updateState(state: WalletContainer.State) {
        self.currentWalletContainer.state = state
    }
    
    @MainActor
    func updateSyncState(syncState: WalletContainer.SyncState) {
        self.currentWalletContainer.syncState = syncState
    }
    
    func send() async  -> Bool {
        
        guard let syncWallet = syncWallet else {
            return false
        }
        
        if !sendToAddress.isValidTestnetAddress() {
            return false
        }
        
        if sendAmount == 0 || sendAmount > currentWalletContainer.balance {
            return false
        }
        
        do {
            
            let txBuilder = TxBuilder().addRecipient(address: sendToAddress, amount: sendAmount)
            let pbst = try txBuilder.finish(wallet: syncWallet.wallet)
            _ = try syncWallet.wallet.sign(psbt: pbst)
            try syncWallet.blockchain.broadcast(psbt: pbst)
            print(pbst.txid())
//            await sync()
            return true
        } catch {
            print(error)
            return false
        }
        
    }
    
    func getAddress() -> String? {
        let address = try? self.syncWallet?.wallet.getAddress(addressIndex: .lastUnused).address
        return address
    }
    
}
