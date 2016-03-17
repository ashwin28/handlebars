require 'test_helper'

class HandlebarTest < ActionView::TestCase
  test "fetch_url_as_string method's status codes and string return" do
    # good request
    url1 = 'https://www.google.com/webhp?ie=utf-8&oe=utf-8#q=notarealsiteeeee.com'
    # forbidden request
    url2 = 'http://www.google.co.uk/sorry/?continue=http://www.google.co.uk/search%3Fq%3Dhello%26oq%3Dhello%26ie%3DUTF-8'
    # bad request
    url3 = 'http://www.notarealsiteeeee.com'
    # not found
    url4 = 'https://github.com/sunspot/sunspot/slow'

    assert_equal fetch_url_as_string(url1).last, ["200", "OK"]
    assert_equal fetch_url_as_string(url2).last, ["403", "Forbidden"]
    assert_equal fetch_url_as_string(url3).last, ["400", "Bad Request"]
    assert_equal fetch_url_as_string(url4).last, ["404", "Not Found"]

    assert_equal fetch_url_as_string(url1).first.empty?, false
    assert_equal fetch_url_as_string(url2).first.empty?, false
    assert_equal fetch_url_as_string(url3).first.empty?, true
    assert_equal fetch_url_as_string(url4).first.empty?, true
  end

  test "parse_relevent_handles method's return array" do
    # empty string
    s1 = ''
    # a twitter handle
    s2 = '@ibm'
    # a twitter handle different case, same profile
    s3 = '@iBm'
    # a twitter handle from a profile link
    s4 = 'https://twitter.com/ibm'
    # do not get the email, just the handles
    s5 = '@niceface,me@ibm.com@coolbeans withthetwitterhandle@notreal'
    # multiple handles in a row, no duplicates
    s6 = '@ashwin1@ashwin2@ashwin1'
    # remove tags and find the handle
    s7 = '<a href="https://twitter.com/appleface"><s>@</s>SaysHi</a>'
    # more tags and bad handles
    s8 = '@abcdeabcdeabcdef <div>@ab<div>cdeabcd<div>eabcdef</div></div></div>'
    # get handle from html comments
    s9 = '<!-- Write your comments here and tweet about it @CommentUrCode -->'

    assert_equal parse_relevent_handles(s1), []
    assert_equal parse_relevent_handles(s2), ["@ibm"]
    assert_equal parse_relevent_handles(s3), ["@ibm"]
    assert_equal parse_relevent_handles(s4), ["@ibm"]
    assert_equal parse_relevent_handles(s5), ["@niceface", "@coolbeans", "@notreal"]
    assert_equal parse_relevent_handles(s6), ["@ashwin1", "@ashwin2"]
    assert_equal parse_relevent_handles(s7), ["@appleface", "@sayshi"]
    assert_equal parse_relevent_handles(s8), []
    assert_equal parse_relevent_handles(s9), ["@commenturcode"]
  end

  test "verify_handle and get_relevent_user_info method's returns" do
    # good handle
    h1 = '@ibm'
    # same handle diff case
    h2 = '@IbM'
    subset1 = [:handle, :profile_name, :location, :joined, :url, :tweets,
               :following, :followers, :likes, :tweet_title, :tweet_text]
    # no tweets, just :handle, :profile_name, :joined info
    h3 = '@bugface'
    subset2 = [:handle, :profile_name, :joined]
    # protected profile
    h4 = '@asdfjacobchan'
    subset3 = [:handle, :profile_name, :location, :joined, :url, :tweets,
               :following, :followers, :likes]
    # suspended account
    h5 = '@milfs'
    # not a real account
    h6 = '@applefacyyyyy'

    assert_equal verify_handle(h1).keys & subset1, subset1
    assert_equal verify_handle(h2).keys & subset1, subset1
    assert_equal verify_handle(h3).keys & subset2, subset2
    assert_equal verify_handle(h4).keys & subset3, subset3
    assert_equal verify_handle(h5), h5
    assert_equal verify_handle(h6), h6
  end

  test "validate_handles method's returns" do
    # idea is to have 3 good and 2 bad handles
    a = %w[ @ibm @milfs @asdfjacobchan @bugface @applefacyyyyy]
    subset = [:IBM ,:asdfjacobchan ,:bugface]

    assert_equal validate_handles(a)[:good].class, Hash
    assert_equal validate_handles(a)[:good].keys & subset, subset
    assert_equal validate_handles(a)[:bad].class, Array
    assert_equal validate_handles(a)[:bad], ['@milfs', '@applefacyyyyy']
  end
end