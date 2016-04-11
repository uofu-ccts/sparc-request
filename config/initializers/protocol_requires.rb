require Rails.root.join('lib/portal/protocol_finder.rb')
Dir[Rails.root.join('lib', 'protocols_controller', '*.rb')].each { |file| require file }

