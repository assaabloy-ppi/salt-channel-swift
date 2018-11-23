SaltChannel Swift
===================

[![Build Status](https://travis-ci.org/assaabloy-ppi/salt-channel-swift.svg?branch=master)](https://travis-ci.org/assaabloy-ppi/salt-channel-swift)
[![Codebeat Quality](https://codebeat.co/badges/82efe8db-c3e8-4817-b263-032199150179)](https://codebeat.co/projects/github-com-assaabloy-ppi-saltchannel-swift-master)
[![Code Coverage](https://codecov.io/gh/assaabloy-ppi/saltchannel-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/assaabloy-ppi/saltchannel-swift)

Salt Channel version 2 implemented in Swift. To be used for iOS, MacOS and Linux projects. Read more about [Salt Channel](https://github.com/assaabloy-ppi/salt-channel)


Salt Channel
------------

Salt Channel is a simple, light-weight secure channel protocol based on TweetNaCl
by Bernstein et al. Salt Channel is "Powered by Curve25519".

Salt Channel is simpler than TLS and works well on small embedded processors.
It has a lower handshake overhead. See this comparison. Salt Channel always uses
mutual authentication and forward secrecy. The protocol supports secret client IDs.

The development of the code in this repository and the protocol itself has been
financed by ASSA ABLOY AB -- the global leader in door opening solutions.
Thank you for supporting this work.

Session Format
--------------

An overview of a typical Salt Channel session is shown below.
```  
    CLIENT                                                 SERVER

    ProtocolIndicator
    ClientEncKey
    [ServerSigKey]               ---M1----->

                                 <--M2------         ServerEncKey

                                                     ServerSigKey
                                 <--E(M3)---           Signature1

    ClientSigKey
    Signature2                   ---E(M4)--->

    AppPacket                    <--E(AppPacket)-->     AppPacket

        Figure: Salt Channel messages. "E()" is used to indicate that a
        message is encrypted and authenticated. Header and Time fields are not
        included in the figure. They are included in every message.
```

Howto use
---------

SaltChannel is Open Source and managed in Github. Download or clone using this link:
[github.com/assaabloy-ppi/salt-channel-swift](
https://github.com/assaabloy-ppi/salt-channel-swift.git)

You can also use various Package managers, e.g. Cocoapods
### Podfile

```
platform :ios, '10.3'

target 'YourProject' do
  use_frameworks!
  pod 'SaltChannel', :git => 'https://github.com/assaabloy-ppi/salt-channel-swift.git', :tag => '2.1.0'

  target 'YourProjet-tests' do
    inherit! :search_paths
  end
end
```

### Pod install
```shell
% pod install
```

Important Interfaces
--------------------

### ByteChannel.swift
```swift
protocol ByteChannel {
    /// Register a Callback and and Errorhandler
    func register(callback: @escaping (Data) -> Void, errorhandler: @escaping (Error) -> Void

    /// Write data to the Channel
    func write(_ data: [Data]) throws
}
```

### Protocol.swift
```swift
enum Constants {
    static let protocolId   = Data("SCv2".utf8)
    static let serverprefix = Data("SC-SIG01".utf8)
    static let clientprefix = Data("SC-SIG02".utf8)
}

typealias Protocol = Client & Host

protocol Peer {
    func writeApp(time: TimeInterval, message: Data) -> Data
    func writeMultiApp(data: Data) throws -> (time: TimeInterval, message: Data)

    func readApp(data: Data) throws -> [String]
    func readMultiApp(data: Data) throws -> [String]
}

protocol Client: Peer {
    func writeM1(time: TimeInterval, myEncPub: Data, serverSignPub: Data?) throws -> Data
    func readM2(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data)
    func readM3(data: Data, m1Hash: Data, m2Hash: Data) throws -> (time: TimeInterval, remoteSignPub: Data)
    func writeM4(time: TimeInterval, clientSignSec: Data, clientSignPub: Data, m1Hash: Data, m2Hash: Data) throws -> Data

    func writeA1(time: TimeInterval, message: Data) -> Data
    func readA2(data: Data) throws -> [String]
}

protocol Host: Peer {
    func readM1(data: Data) throws -> (time: TimeInterval, remoteEncPub: Data, hash: Data)
    func writeM2(time: TimeInterval, myEncPub: Data) throws -> Data
    func writeM3(time: TimeInterval, myEncPub: Data) throws -> Data
    func readM4(data: Data) throws -> (time: TimeInterval, message: Data)

    func writeA2(time: TimeInterval, message: Data) -> Data
    func readA1(data: Data) throws -> (time: TimeInterval, message: Data)
}
```
