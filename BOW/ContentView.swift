//
//  ContentView.swift
//  BOW
//
//  Created by Jacob Davis on 7/27/22.
//

import SwiftUI
import Charts
import BitcoinDevKit
import CodeScanner
import Stripes
import Haptica
import ActivityIndicatorView
import AlertToast

struct ContentView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var priceData: PriceData
    
    var online: Bool {
        switch appState.currentWalletContainer.syncState {
        case .synced:
            return true
        default:
            return false
        }
    }
        
    var body: some View {
        
        ZStack {
            
            Color.background
                .edgesIgnoringSafeArea(.all)

            switch appState.viewState.topItem {
            case .home:
                List {
                    MarketView()
                    
                    if (appState.syncWallet != nil) {
                        HomeHeader()
                        TransactionsView()
                    } else {
                        
                        
                        
                    }

                }
                .scrollIndicators(.hidden)
                .transition(
                    AnyTransition.asymmetric(insertion: .move(edge: .top), removal: .opacity)
                )
                .zIndex(1)
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .padding(appState.leftHandedMode ? .trailing : .leading, 8)
                .refreshable {
                    Task {
                        await appState.sync()
                    }
                }
            case .sendA:
                SendToView()
                    .transition(
                        AnyTransition.asymmetric(insertion: .move(edge: .bottom), removal: .opacity)
                    )
                    .zIndex(2)
            case .some(.sendB):
                SendToAmount()
                    .transition(
                        AnyTransition.asymmetric(insertion: .move(edge: .bottom), removal: .opacity)
                    )
                    .zIndex(3)
            case .scanQR:
                ScanQRView()
                    .transition(
                        AnyTransition.asymmetric(insertion: .move(edge: .bottom), removal: .opacity)
                    )
                    .zIndex(4)
            case .receive:
                ReceiveView()
                    .transition(
                        AnyTransition.asymmetric(insertion: .move(edge: .bottom), removal: .opacity)
                    )
                    .zIndex(5)
            case .settings:
                ScrollView {
                    SettingsView()
                }
                .transition(
                    AnyTransition.asymmetric(insertion: .move(edge: .bottom), removal: .opacity)
                )
                .zIndex(6)
            case .none:
                EmptyView()
            }

        }
        .safeAreaInset(edge: .top) {
            
            VStack(spacing: 0) {
                
                HStack {
                    Text("₿OW")
                    Spacer()
                }
                .font(.system(.title,
                              design: .monospaced,
                              weight: .bold))
                .foregroundColor(.orange)
                .padding(appState.leftHandedMode ? .trailing : .leading, 8)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                HStack {
                    Text("Bitcoin only wallet")
                        .font(.system(.caption,
                                      design: .monospaced,
                                      weight: .bold))
                    Spacer()
                }
                .padding(appState.leftHandedMode ? .trailing : .leading, 8)
                .padding(.bottom, 8)
                
                Rectangle()
                    .foregroundColor(Color.background)
                    .edgesIgnoringSafeArea(.top)
                    .frame(height: 2)
                    .overlay(
                        Rectangle()
                            .foregroundColor(.blue)
                            .frame(height: 2)
                        , alignment: .bottom
                    )
                    .padding(appState.leftHandedMode ? .trailing : .leading, 8)
            }
            .background(Color.background)

        }
        .safeAreaInset(edge: appState.leftHandedMode ? .leading : .trailing, spacing: 0) {
            ZStack {
                Rectangle()
                    .frame(width: 2)
                    .foregroundColor(Color.blue)
                    
                    .overlay(
                        Circle()
                            .frame(width: 48)
                            .foregroundColor(Color.background)
                            .overlay(
                                Circle()
                                    .frame(width: 12)
                                    .foregroundColor(online ? .green : .yellow)
                            )
                            .offset(x: 0, y: -3)

                        , alignment: .top
                    )
                    .offset(x: 0, y: 5)
                ControlBar()
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .preferredColorScheme(.dark)
        
    }
}

struct TransactionsView: View {
    
    @EnvironmentObject var appState: AppState
    
    var transactions: [AppState.TransactionContainer] {
        return appState.currentWalletContainer.transactions
    }
    
    var body: some View {
        VStack {
            
            if transactions.count > 0 {
                ForEach(transactions) { t in
                    TransactionCell(details: t.details, confirmation: t.blockTime ?? BlockTime(height: 0, timestamp: 0))
                }
                .id(UUID())
            } else {
                
                Text("Loading...")
                    .foregroundColor(Color.text)
                    .font(.system(.footnote,
                                  design: .monospaced,
                                  weight: .regular))
                    .padding(12)
                
            }
        }
        .clearListStyle()
        .modifier(BorderStyle(title: "Transactions"))
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
}

struct TransactionCell: View {
    
    let details: TransactionDetails
    let confirmation: BlockTime
    
    @Environment(\.openURL) var openURL
    
    @State private var isWaiting = false
    
    var foreverAnimation: Animation {
        Animation.linear(duration: 0.3)
        .repeatForever()
    }
    
    func getAmount(sent: UInt64, received: UInt64) -> UInt64 {
        if sent > received {
            return sent - received
        } else {
            return received - sent
        }
    }
    
    func getStripeConfig(confirmed: Bool) -> StripesConfig {
        if !confirmed {
            return StripesConfig(background: Color.clear,
                                 foreground: Color.yellow.opacity(0.1), degrees: 45,
                                 barWidth: 10, barSpacing: 10)
        } else {
            return StripesConfig(background: Color.clear, foreground: Color.clear, degrees: 45,
                          barWidth: 10, barSpacing: 10)
        }
    }
    
    var body: some View {
        
        VStack {
            
            HStack {
                Text(details.sent < details.received ? "Received:" : "Sent:")
                Spacer()
                Text(String(format: "%.8f", Double(getAmount(sent: details.sent, received: details.received)) / Double(100000000)) + " ₿")
                    .fontWeight(.semibold)

            }
            .padding(4)
            .background(
                Rectangle()
                    .foregroundColor(Color.text.opacity(0.2))
                    .overlay(
                        Stripes(config: getStripeConfig(confirmed: confirmation.height != 0))
                    )
            )
            
            LabeledContent("Fees:") {
                Text((details.fee ?? 0).formatted())
                    .fontWeight(.semibold)
                Image("sat")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14)
                    .foregroundColor(Color.text)
            }
            .padding(.horizontal, 3)
            
            if confirmation.height != 0 {
                LabeledContent("Block:") {
                    Text(confirmation.height.formatted())
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 3)
            }
            
            if confirmation.height == 0 {
                
                LabeledContent("Confirmed:") {
                    HStack {
                        Spacer()
                        Image(systemName: "clock")
                            .foregroundColor(.yellow)
                        Text("Waiting")
                    }
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 3)
                
            } else {
                
                LabeledContent("Confirmed:") {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text((Date(timeIntervalSince1970: TimeInterval(confirmation.timestamp)).formatted()))
                    }
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 3)
            }
            
            LabeledContent("Txid:") {
                Text(details.txid)
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .padding(.horizontal, 3)
            
            HStack(alignment: .top) {

                Spacer()

                Button(action: {
                    openURL(URL(string: "https://mempool.space/testnet/tx/\(details.txid)")!)
                }) {
                    Text("  More > ")
                        .foregroundColor(Color.background)
                        .padding(2)
                        .background(
                            Rectangle()
                                .foregroundColor(Color.text)
                        )
                }
                .buttonStyle(.plain)

            }
            .padding(.trailing, 4)
            .padding(.bottom, 4)
        }
        .padding(2)
        .background(
            Rectangle()
                .strokeBorder(lineWidth: 2)
                .foregroundColor(
                    confirmation.height != 0 ?
                    Color.text.opacity(0.2) : Color.yellow.opacity(0.2)
                )
        )
        .padding(.top, 6)
        .padding(.bottom, 2)
        .padding(.horizontal, 4)
        .foregroundColor(Color.text)
        .font(.system(.footnote,
                      design: .monospaced,
                      weight: .regular))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                withAnimation {
                    self.isWaiting = confirmation.height == 0
                    print(self.confirmation.height == 0) // TODO:
                }
            }

        }
        .opacity(isWaiting ? 0.5 : 1.0)
        .animation(.default.speed(0.5).repeat(while: isWaiting), value: isWaiting)

    }
    
}

struct HomeHeader: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var priceData: PriceData
    
    var chart: [CandleMark] {
        return Array(priceData.chart).sorted { $0.time < $1.time }
    }
    
    var price: Double {
        return chart.last?.close ?? priceData.lastPrice
    }
    
    func getUSD() -> Double {
        let b = appState.currentWalletContainer.balance
        let bb = Double(b) / Double(100000000)
        return bb * price
    }
    
    func getBalance() -> Double {
        let b = appState.currentWalletContainer.balance
        let bb = Double(b) / Double(100000000)
        return bb
    }
    
    func getSats() -> UInt64 {
        appState.currentWalletContainer.balance
    }
    
    var body: some View {
        VStack {

            HStack {
                Text("Balance:")
                Spacer()
                Text(getBalance().formatted(.number.precision(.fractionLength(8))) + " ₿")
                    .font(.system(.title2,
                                  design: .monospaced,
                                  weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.2)

            }
            .padding(4)
            .background(
                Rectangle()
                    .foregroundColor(Color.text.opacity(0.2))
            )
            
            LabeledContent("Sats:") {
                Text(getSats().formatted())
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .padding(.horizontal, 3)
            
            LabeledContent("USD Value:") {
                Text(getUSD().formatted(.currency(code: "usd")))
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .padding(.horizontal, 3)
            .padding(.bottom, 4)
            
        }
        .padding(2)
        .background(
            Rectangle()
                .strokeBorder(lineWidth: 2)
                .foregroundColor(Color.text.opacity(0.2))

        )
        .padding(.top, 6)
        .padding(.bottom, 2)
        .padding(.horizontal, 4)
        .foregroundColor(Color.text)
        .font(.system(.footnote,
                      design: .monospaced,
                      weight: .regular))
        .clearListStyle()
        .modifier(BorderStyle(title: "Wallet 1"))
        .padding(.top, 16)
        .padding(.bottom, 8)

    }
}

struct ControlBar: View {
    
    @EnvironmentObject var appState: AppState
    
    var enableAmountSend: Bool {
        return appState.sendToAddress.isValidTestnetAddress() && appState.currentWalletContainer.balance > 0
    }
    
    var enableFinalSend: Bool {
        if enableAmountSend && appState.sendAmount > 0 && appState.sendAmount <= appState.currentWalletContainer.balance {
            return true
        }
        return false
    }
    
    var body: some View {
        VStack(spacing: 12) {
            
            switch appState.viewState.topItem {
            case .home:
                
                Button(action: {
                    withAnimation(Animation.spring().speed(2.0)) {
                        appState.viewState.push(.settings)
                    }
                }) {
                    Image(systemName: "gearshape.fill")
                        .imageScale(.large)
                        .fontWeight(.bold)
                }
                .buttonStyle(.plain)

                Button(action: {
                    withAnimation(Animation.spring().speed(2.0)) {
                        appState.viewState.push(.receive)
                    }
                }) {
                    Image(systemName: "qrcode")
                        .imageScale(.large)
                        .fontWeight(.bold)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation(Animation.spring().speed(2.0)) {
                        appState.viewState.push(.sendA)
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .imageScale(.large)
                        .fontWeight(.bold)
                }
                .buttonStyle(.plain)
                
            case .sendA:
                
                Button(action: {
                    withAnimation(Animation.spring().speed(2.0)) {
                        _ = appState.viewState.pop()
                    }
                }) {
                    Image(systemName: "arrowshape.turn.up.backward.circle")
                        .imageScale(.large)
                        .font(.title2)
                        .fontWeight(.regular)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation(Animation.spring().speed(2.0)) {
                        appState.viewState.push(.scanQR)
                    }
                }) {
                    Image(systemName: "qrcode.viewfinder")
                        .imageScale(.large)
                        .font(.title2)
                        .fontWeight(.regular)
                }
                .buttonStyle(.plain)

                if enableAmountSend {
                    
                    Button(action: {
                        withAnimation(Animation.spring().speed(2.0)) {
                            appState.viewState.push(.sendB)
                        }
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .imageScale(.large)
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    
                }
                
            case .some(.sendB):
                
                Button(action: {
                    withAnimation(Animation.spring().speed(2.0)) {
                        _ = appState.viewState.pop()
                    }
                }) {
                    Image(systemName: "arrowshape.turn.up.backward.circle")
                        .imageScale(.large)
                        .font(.title2)
                        .fontWeight(.regular)
                }
                .buttonStyle(.plain)

                if enableFinalSend {
                    
                    Button(action: {
                        
                        appState.isLoading = true
                        
                        Task {
                            let res = await appState.send()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                appState.isLoading = false
            
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                                    withAnimation(Animation.spring().speed(2.0)) {
                                        _ = appState.viewState.items = [.home]
                                        appState.sendToAddress = ""
                                        appState.sendAmount = .zero
                                    }
                                    Task {
                                        await appState.sync()
                                    }
                                }
                            }
                        }

                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .imageScale(.large)
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    
                }
                
            case .scanQR,.receive,.settings:
                
                Button(action: {
                    withAnimation(Animation.spring().speed(2.0)) {
                        _ = appState.viewState.pop()
                    }
                }) {
                    Image(systemName: "arrowshape.turn.up.backward.circle")
                        .imageScale(.large)
                        .font(.title2)
                        .fontWeight(.regular)
                }
                
            case .none:
                EmptyView()
            }

        }
        .foregroundColor(Color.text)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .foregroundColor(Color.text)
                .overlay(
                    Rectangle()
                        .padding(0)
                        .foregroundColor(Color.background.opacity(1))
                )
        )
        .padding(12)
        .frame(width: 50)
        .disabled(appState.isLoading)
    }
}

struct MarketView: View {
    
    @EnvironmentObject var priceData: PriceData
    @State private var retrying = false
    
    var chart: [CandleMark] {
        return Array(priceData.chart).sorted { $0.time < $1.time }
    }
    
    var price: Double {
        return chart.last?.close ?? priceData.lastPrice
    }

    var yAxis: ClosedRange<Double> {
        var combined = chart.map{ $0.open }
        combined.append(contentsOf: chart.map{ $0.close })
        let sorted = combined.sorted(by: { $0 < $1 })
        let first = (sorted.first ?? 0.0)
        let last = (sorted.last ?? 0.0)
        return first...last
    }
    
    var xAxis: ClosedRange<Date> {
        let sorted = chart.map { $0.time }.sorted(by: { $0 < $1 })
        return sorted.count > 2 ? sorted.first!...sorted.last! : Date.now...Date.now//.addingTimeInterval(100)
    }
    
    var isUp: Bool {
        return chart.last?.close ?? .zero > chart.first?.close ?? .zero ? true : false
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            LazyVStack {
                Text(price.formatted(.currency(code: "usd")))
            }
            .foregroundColor(Color.text)
            .font(.system(.body, design: .monospaced))
            .fontWeight(.bold)
            .padding(.horizontal, 4)
            
            Chart {
                
                ForEach(chart, id: \.close) {
                    LineMark(x: .value("Date", $0.time), y: .value("Price", $0.close))
                        .foregroundStyle(isUp ? .green : .red)
                }
                
                
                if let l = chart.last {
                    PointMark(
                        x: .value("Date", l.time),
                        y: .value("Price", l.close)
                    )
                    .foregroundStyle(isUp ? .green : .red)
                }

            }
            .background(Color.text.opacity(0.1))
            .chartXScale(domain: xAxis, range: .plotDimension(startPadding: 8, endPadding: 8))
            .chartYScale(domain: yAxis, range: .plotDimension(startPadding: 8, endPadding: 8))
            .chartYAxis {
              AxisMarks(values: .automatic) { value in
                AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1]))
                      .foregroundStyle(Color.text.opacity(0.2))
                AxisTick(centered: true, stroke: StrokeStyle(lineWidth: 2))
                  .foregroundStyle(Color.text)
                AxisValueLabel() { // construct Text here
                  if let intValue = value.as(Int.self) {
                    Text("$\(intValue)")
                          .font(.system(.caption2, design: .monospaced)) // style it
                      .foregroundColor(Color.text)
                  }
                }
              }
            }
            .chartXAxis {
              AxisMarks(values: .automatic) { value in
                AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1]))
                      .foregroundStyle(Color.text.opacity(0.2))
//                AxisTick(centered: true, stroke: StrokeStyle(lineWidth: 2))
//                  .foregroundStyle(Color.text)
                AxisValueLabel() { // construct Text here
                  if let intValue = value.as(Date.self) {
                      switch priceData.chartTime {
                      case .oneMin:
                          Text(intValue.formatted(.dateTime.hour().minute()))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      case .fifteenMin:
                          Text(intValue.formatted(.dateTime.hour()))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      case .thirtyMin:
                          Text(intValue.formatted(.dateTime.hour()))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      case .oneHour:
                          Text(intValue.formatted(.dateTime.weekday().hour()))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      case .sixHours:
                          Text(intValue.formatted(.dateTime.day().month(.abbreviated)))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      case .twelveHours:
                          Text(intValue.formatted(.dateTime.day().month()))
                              .font(.system(.caption2, design: .monospaced)) // style it
                              .foregroundColor(Color.text)
                      }
                  }
                }
              }
            }
            .frame(height: 150)
            .padding(4)

            HStack(spacing: 4) {
                Button(action: {
                    priceData.chartTime = .oneMin
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("1m")
                        .foregroundColor(priceData.chartTime == .oneMin ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .oneMin ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                Button(action: {
                    priceData.chartTime = .fifteenMin
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("15m")
                        .foregroundColor(priceData.chartTime == .fifteenMin ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .fifteenMin ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                Button(action: {
                    priceData.chartTime = .thirtyMin
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("30m")
                        .foregroundColor(priceData.chartTime == .thirtyMin ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .thirtyMin ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                Button(action: {
                    priceData.chartTime = .oneHour
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("1hr")
                        .foregroundColor(priceData.chartTime == .oneHour ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .oneHour ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                Button(action: {
                    priceData.chartTime = .sixHours
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("6hr")
                        .foregroundColor(priceData.chartTime == .sixHours ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .sixHours ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                Button(action: {
                    priceData.chartTime = .twelveHours
                    Task {
                        await PriceData.shared.connectCandleSocket()
                    }
                }) {
                    Text("12hr")
                        .foregroundColor(priceData.chartTime == .twelveHours ? Color.background : Color.text)
                        .padding(.horizontal, 6)
                        .background(
                            Rectangle()
                                .foregroundColor(priceData.chartTime == .twelveHours ? Color.text : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
            .background(Color.background)
            .font(.system(.subheadline, design: .monospaced))
            
        }
        .clearListStyle()
        .modifier(BorderStyle(title: "Market"))
        .padding(.top, 16)
        .padding(.bottom, 8)

    }
    
}

struct SendToView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        
        VStack {
            Rectangle()
                .foregroundColor(Color.text.opacity(0.1))
                .frame(height: 66)
                .overlay(
                    
                    TextField("", text: $appState.sendToAddress, axis: .vertical)
                        .font(.system(.body,
                                      design: .monospaced,
                                      weight: .regular))
                        .tint(Color("Background"))
                        .keyboardType(.asciiCapable)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding(2)
                    .padding(8)
                    
                )
                .padding(.horizontal, 2)
                .modifier(BorderStyle(title: "Paste or scan address"))
                .padding(appState.leftHandedMode ? .trailing : .leading, 8)
                .padding(.vertical, 16)
            
            Spacer()
        }
        .padding(.top, 8)
    
    }
}

struct ScanQRView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        CodeScannerView(codeTypes: [.qr], simulatedData: "") { response in
            switch response {
            case .success(let result):
                if result.string.isValidTestnetAddress() {
                    appState.sendToAddress = result.string
                    
                    withAnimation(Animation.spring().speed(2.0)) {
                        appState.viewState.items = [.home, .sendA, .sendB]
                    }

                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        .aspectRatio(contentMode: .fit)
        .padding(4)
        .clearListStyle()
        .modifier(BorderStyle(title: "Scan Address"))
        .padding(.vertical, 16)
        .padding(appState.leftHandedMode ? .trailing : .leading, 8)
    }
}

struct ReceiveView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var toastPresenting = false
    
    var body: some View {
        
        VStack(spacing: 16) {
            if let address = appState.getAddress() {
                Image(uiImage: address.generateQRCode())
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    //.frame(width: 250, height: 250)

                
                Text(address)
                    .font(.system(.body,
                                  design: .monospaced,
                                  weight: .bold))
                
            } else {
                
                Text("Error getting address")

            }

        }
        .padding(12)
        .modifier(BorderStyle(title: "Receiving Address"))
        .padding(.vertical, 16)
        .padding(appState.leftHandedMode ? .trailing : .leading, 8)
        .onTapGesture {
            UIPasteboard.general.string = appState.getAddress()
            Haptic.impact(.light).generate()
            toastPresenting.toggle()
        }
        .toast(isPresenting: $toastPresenting) {
            AlertToast(type: .regular, title: "Address Copied! 😀")
        }
    }
}

struct SendToAmount: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var priceData: PriceData
    
    var chart: [CandleMark] {
        return Array(priceData.chart).sorted { $0.time < $1.time }
    }
    
    var price: Double {
        return chart.last?.close ?? priceData.lastPrice
    }
    
    var formattedSats: String {
        return appState.sendAmount.formatted() + " SATS"
    }

    func formattedUSD() -> String {
        let btcAmount = Double(appState.sendAmount) / Double(100000000)
        return (btcAmount * price).formatted(.currency(code: "usd"))
    }
    
    func formattedBTC() -> String {
        let btcAmount = Double(appState.sendAmount) / Double(100000000)
        return btcAmount.formatted(.number.precision(.fractionLength(8))) + " ₿"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            Color.clear

            VStack {
                
                VStack {
                    
                    Text(formattedSats)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Spacer(minLength: 16)
                    
                    Text(formattedBTC())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .font(.system(.subheadline,
                                      design: .monospaced,
                                      weight: .regular))
                        .foregroundColor(Color.text.opacity(0.8))

                    Text(formattedUSD())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .font(.system(.subheadline,
                                      design: .monospaced,
                                      weight: .regular))
                        .foregroundColor(Color.text.opacity(0.8))

                }
                .padding(8)
                .font(.system(.title,
                              design: .monospaced,
                              weight: .regular))
                .frame(maxWidth: .infinity, maxHeight: 100)
                .background(
                    Color.text.opacity(0.1)
                )
                .padding(4)
                .modifier(BorderStyle(title: "Send Amount"))
                .padding(appState.leftHandedMode ? .trailing : .leading, 8)
                .padding(.vertical, 16)
                
                Text(appState.sendToAddress)
                    .font(.system(.subheadline,
                                  design: .monospaced,
                                  weight: .regular))
                    .padding(8)
                    .background(
                        Color.text.opacity(0.1)
                    )
                    .padding(4)
                    .modifier(BorderStyle(title: "Sending To"))
                    .padding(appState.leftHandedMode ? .trailing : .leading, 8)
                    .padding(.vertical, 16)

            }
            .background(Color.background)
        }
        .safeAreaInset(edge: .bottom) {
            
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                
                GridRow {
                    Button(action: {
                        Haptic.impact(.light).generate()
                        self.appState.sendAmount = UInt64("\(self.appState.sendAmount)".appending("1")) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "1")
                    }
                    Button(action: {
                        Haptic.impact(.light).generate()
                        self.appState.sendAmount = UInt64("\(self.appState.sendAmount)".appending("2")) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "2")
                    }
                    Button(action: {
                        Haptic.impact(.light).generate()
                        self.appState.sendAmount = UInt64("\(self.appState.sendAmount)".appending("3")) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "3")
                    }
                }
                
                GridRow {
                    Button(action: {
                        Haptic.impact(.light).generate()
                        self.appState.sendAmount = UInt64("\(self.appState.sendAmount)".appending("4")) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "4")
                    }
                    Button(action: {
                        Haptic.impact(.light).generate()
                        self.appState.sendAmount = UInt64("\(self.appState.sendAmount)".appending("5")) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "5")
                    }
                    Button(action: {
                        Haptic.impact(.light).generate()
                        self.appState.sendAmount = UInt64("\(self.appState.sendAmount)".appending("6")) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "6")
                    }
                }
                
                GridRow {
                    Button(action: {
                        Haptic.impact(.light).generate()
                        self.appState.sendAmount = UInt64("\(self.appState.sendAmount)".appending("7")) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "7")
                    }
                    Button(action: {
                        Haptic.impact(.light).generate()
                        self.appState.sendAmount = UInt64("\(self.appState.sendAmount)".appending("8")) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "8")
                    }
                    Button(action: {
                        Haptic.impact(.light).generate()
                        self.appState.sendAmount = UInt64("\(self.appState.sendAmount)".appending("9")) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "9")
                    }
                }
                
                GridRow {
                    Button(action: {}) {
                        Rectangle()
                            .keypadButtonStyle(title: "")
                    }
                    .disabled(true)
                    .hidden()
                    Button(action: {
                        Haptic.impact(.light).generate()
                        self.appState.sendAmount = UInt64("\(self.appState.sendAmount)".appending("0")) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "0")
                    }
                    Button(action: {
                        Haptic.impact(.light).generate()
                        var na = "\(self.appState.sendAmount)"
                        _ = na.removeLast()
                        self.appState.sendAmount = UInt64(na) ?? 0
                    }) {
                        Rectangle()
                            .keypadButtonStyle(title: "<")
                    }
                }
                
                
            }
            .frame(maxHeight: 300)
            .padding(.vertical, 16)
            .padding(appState.leftHandedMode ? .trailing : .leading, 8)
            
        }
        .disabled(appState.isLoading)
        .opacity(appState.isLoading ? 0.2 : 1.0)
        .overlay(
            ActivityIndicatorView(isVisible: $appState.isLoading, type: .equalizer())
                .frame(width: 60.0, height: 60.0)
                .foregroundColor(.blue)
        )
    }
    
}

struct SettingsView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            
            Toggle("Left handed mode", isOn: $appState.leftHandedMode)
                .toggleStyle(SwitchToggleStyle(tint: .mint))
                .font(.system(.body,
                               design: .monospaced,
                               weight: .regular))
                .padding(8)

            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 2)
        .modifier(BorderStyle(title: "Settings"))
        .padding(appState.leftHandedMode ? .trailing : .leading, 8)
        .padding(.vertical, 16)
    }
}

struct ContentView_Previews: PreviewProvider {
    static let appState = AppState()
    static var previews: some View {
        ContentView()
            .environmentObject(appState)
            .environmentObject(PriceData.shared)
            .task {
                await appState.load()
                await appState.sync()
                await PriceData.shared.connectTickerSocket()
                await PriceData.shared.connectCandleSocket()
            }
    }
}
