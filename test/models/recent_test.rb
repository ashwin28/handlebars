require 'test_helper'
require 'digest/md5'

class RecentTest < ActiveSupport::TestCase
  def setup
    @recent = Recent.new(url_string: "http://www.example.com")
  end

  test "should be valid" do
    assert @recent.valid?
  end

  test "url_string should be present" do
    @recent.url_string = "     "
    assert_not @recent.valid?
  end

  test "url_string should be a url" do
    @recent.url_string = "google.com"
    assert_not @recent.valid?
    @recent.url_string = "https://www.google.com"
    assert @recent.valid?
  end

  test "url_string should be hashed" do
    @recent.url_string = "https://www.google.com"
    @recent.save
    assert_equal @recent.url_hash, Digest::MD5.hexdigest("https://www.google.com")
    # check that handles were stored as a hash
    assert_equal @recent.handles.class, Hash
  end
end
