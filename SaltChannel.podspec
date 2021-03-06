Pod::Spec.new do |s|
  s.name             = 'SaltChannel'
  s.version          = '2.1.1'
  s.summary          = 'A light-weight secure channel protocol based on TweetNaCl.'

  s.description      = <<-DESC
  This repo contains the Swift implementation of
  Salt Channel - a simple, light-weight secure channel protocol based on TweetNaCl
  by Bernstein et al. Salt Channel is "Powered by Curve25519".

  Salt Channel is simpler than TLS and works well on small embedded processors.
  It has a low handshake overhead. Salt Channel always uses
  mutual authentication and forward secrecy. The protocol supports secret client IDs.

  The development of the code in this repository and the protocol itself has been
  financed by ASSA ABLOY AB -- the global leader in door opening solutions.
  Thank you for supporting this work.
  DESC

  s.homepage = 'https://github.com/assaabloy-ppi/salt-channel/blob/master/files/spec/salt-channel-v2-final2.md'

  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { 'kpernyer'  => 'kenneth.pernyer@assaabloy.com',
                'TheHawkis' => 'hakan.ohlsson@assaabloy.com' }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.13'

  s.source = { :git => 'https://github.com/assaabloy-ppi/salt-channel-swift.git', :tag => s.version.to_s }
  s.source_files = 'Sources/*.{swift,h}'
  s.public_header_files = "Sources/SaltChannel.h"

  s.dependency 'Sodium', '~> 0.8'
  s.swift_version = '4.0'
end
