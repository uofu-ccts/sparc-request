module HttpHelper

  def file_for_upload
    fixture_file_upload(File.join(Rails.root, 'spec/fixtures/files/text_document.txt'), 'plain/txt')
  end
end

RSpec.configure do |config|
  config.include HttpHelper
end
