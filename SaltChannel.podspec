Pod::Spec.new do |s|
  s.name             = 'SaltChannel'
  s.version          = '1.0.0'
  s.summary          = 'A light-weight secure channel protocol based on TweetNaCl.'

  s.description      = <<-DESC
  This repo contains the specification and the Java reference implementation of
  Salt Channel - a simple, light-weight secure channel protocol based on TweetNaCl
  by Bernstein et al. Salt Channel is "Powered by Curve25519".

  Salt Channel is simpler than TLS and works well on small embedded processors.
  It has a lower handshake overhead. See this comparison. Salt Channel always uses
  mutual authentication and forward secrecy. The protocol supports secret client IDs.
  TLS does not currently do this, however, this property is included in the April 2017
  TLS 1.3 draft.

  The development of the code in this repository and the protocol itself has been
  financed by ASSA ABLOY AB -- the global leader in door opening solutions.
  Thank you for supporting this work.

  We also thank Daniel Bernstein for developing the underlying cryptographic
  algorithms. Our work is completely based on his work.
  DESC

  s.homepage = 'https://github.com/assaabloy-ppi/salt-channel/blob/master/files/spec/spec-salt-channel-v1.md'

  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'kpernyer' => 'kenneth.pernyer@assaabloy.com' }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  s.source = { :git => 'https://github.com/assaabloy-ppi/salt-channel-swift.git', :tag => s.version.to_s }

  s.source_files = 'Sources/*.{swift}'
  s.public_header_files = "Sources/SaltChannel.h"
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
end
