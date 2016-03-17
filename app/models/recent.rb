require './lib/assets/handlebars.rb'
require 'digest/md5'

class Recent < ActiveRecord::Base
  before_save :hash_url, :get_handles
  serialize :handles
  validates_presence_of :url_string, message: "can't be empty!"
  validates_format_of :url_string, with: URI::regexp(%w[http https]),
                      message: "needs to start with http:// or https://"

  protected
    def hash_url
      self.url_hash = Digest::MD5.hexdigest(url_string)
    end

    # find row by url_hash
    def self.check_by_hash(url)
      Recent.find_by(url_hash: Digest::MD5.hexdigest(url))
    end

    # fetch the url, parse the url, and store the result hash
    def get_handles
      self.handles = validate_handles(parse_relevent_handles(fetch_url_as_string(self.url_string).first))
    end
end
