platform :ios, '11.0'

target 'SaltChannel' do
  # Workaround for https://github.com/jedisct1/swift-sodium/issues/155:
  pod 'Sodium', git: 'https://github.com/jedisct1/swift-sodium.git', branch: 'master' # '~> 0.6'

  target 'SaltChannel-Tests' do
    inherit! :search_paths
  end
end
