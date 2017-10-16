SaltChannel Swift
===================
[![Build Status](https://travis-ci.org/assaabloy-ppi/salt-channel-swift.svg?branch=master)](https://travis-ci.org/assaabloy-ppi/salt-channel-swift)


Salt-channel version 2 implemented in Swift. Can be used for iOS, MacOS and Linux projects. Read more about [Salt Channel](https://github.com/assaabloy-ppi/salt-channel/blob/master/files/spec/spec-salt-channel-v2-draft7.md)


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
------

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
  pod 'SaltChannel', :git => 'https://github.com/assaabloy-ppi/salt-channel-swift.git'

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

Appendix A: Example session data
================================

Example session data for a simple echo server scenario.
Fixed key pairs are used for a deterministic result. Obviously, such
an approach *must not* be used in production. The encryption key
pair *must* be generated for each session to achieve the security goals.

On the application layer, a simple request-response exchange occurs.
The client sends the application data: 0x010505050505 and the same
bytes are echoed back by the server.

No timestamps are used, neither by the server nor the client.
The Time fields of the messages are all set to zero.


    ======== ExampleSessionData ========

    Example session data for Salt Channel v2.

    ---- key pairs, secret key first ----

    client signature key pair:
        55f4d1d198093c84de9ee9a6299e0f6891c2e1d0b369efb592a9e3f169fb0f795529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b
        5529ce8ccf68c0b8ac19d437ab0f5b32723782608e93c6264f184ba152c2357b
    client encryption key pair:
        77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a
        8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a
    server signature key pair:
        7a772fa9014b423300076a2ff646463952f141e2aa8d98263c690c0d72eed52d07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b
        07e28d4ee32bfdc4b07d41c92193c0c25ee6b3094c6296f373413b373d36168b
    server encryption key pair:
        5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb
        de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f

    --- Log entries ----

     42 -->   WRITE
        534376320100000000008520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a
    <--  38   READ
        020000000000de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f
    <-- 120   READ
        0600e47d66e90702aa81a7b45710278d02a8c6cddb69b86e299a47a9b1f1c18666e5cf8b000742bad609bfd9bf2ef2798743ee092b07eb32a45f27cda22cbbd0f0bb7ad264be1c8f6e080d053be016d5b04a4aebffc19b6f816f9a02e71b496f4628ae471c8e40f9afc0de42c9023cfcd1b07807f43b4e25
    120 -->   WRITE
        0600b4c3e5c6e4a405e91e69a113b396b941b32ffd053d58a54bdcc8eef60a47d0bf53057418b6054eb260cca4d827c068edff9efb48f0eb8454ee0b1215dfa08b3ebb3ecd2977d9b6bde03d4726411082c9b735e4ba74e4a22578faf6cf3697364efe2be6635c4c617ad12e6d18f77a23eb069f8cb38173
     30 -->   WRITE_WITH_PREVIOUS
        06005089769da0def9f37289f9e5ff6e78710b9747d8a0971591abf2e4fb
    <--  30   READ
        068082eb9d3660b82984f3c1c1051f8751ab5585b7d0ad354d9b5c56f755

    ---- Other ----

    session key: 1b27556473e985d462cd51197a9a46c76009549eac6474f206c4ee0844f68389
    app request:  010505050505
    app response: 010505050505
    total bytes: 380
    total bytes, handshake only: 320


Note to authors: the above output was generated with the Java class
saltchannel.dev.ExampleSessionData, date: 2017-10-06.
