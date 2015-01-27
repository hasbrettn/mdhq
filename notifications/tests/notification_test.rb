ENV['RACK_ENV'] = 'test'

# Has to be loaded before the Sinatra DSL, test cases, or app code
require 'simplecov'
SimpleCov.start

require 'rubygems'
require 'sinatra'
require 'test/unit'
require 'rack/test'
require 'base64'
require 'json'
require 'timecop'
require './notification'

class ApplicationTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def make_a_notification(notification)
    put '/notification', notification.to_json
    assert_equal 201, last_response.status

    notification = JSON.parse(last_response.body)
    refute_nil notification['id']
    assert_equal Fixnum, notification['id'].class
    assert_equal "/notification/#{notification['id']}", last_response.headers['Location']

    notification['id'].to_s
  end

  def retrieve_notification(notification_id)
    get '/notification/' + notification_id
    assert_equal 200, last_response.status

    returned_notification = JSON.parse(last_response.body)
    refute_nil returned_notification
    
    returned_notification
  end
  
  def test_add_invalid_notification_no_message
    put '/notification', {"title" => "Title that shouldn't save"}.to_json
    assert_equal 400, last_response.status
  end
  
  def test_add_invalid_notification_no_title
    put '/notification', {"message" => "Message that shouldn't save"}.to_json
    assert_equal 400, last_response.status
  end
  
  def test_add_invalid_notification_no_email_address
    put '/notification', { "title" => "Title that shouldn't save", "message" => "Message that shouldn't save"}.to_json
    assert_equal 400, last_response.status
  end
  
  def test_add_and_retrieve_notification
    # Create a new notification, then retrieve it and
    # assert that we get the same stuff back!

    notification = {
        "title" => "Notification Subject",
        "message" => "Notification message",
        "email_address" => "example@example.com"
    }

    notification_id = make_a_notification(notification)

    # Get the record  we just created
    returned_notification = retrieve_notification(notification_id)

    # Check that the data we got back matches what we sent
    notification.each_key do |k|
      refute_nil returned_notification[k]
      assert_equal notification[k], returned_notification[k]
    end
  end

  #Make a new notification, delete it, then check that it is gone
  def test_add_and_remove_notification
    notification = {
        "title" => "Test subject soon to be removed",
        "message" => "Hopefully deleted message!!",
        "email_address" => "Hopefully deleted e-mail address"
    }

    # Make a new notification and then delete it
    notification_id = make_a_notification(notification)
    delete '/notification/' + notification_id
    assert_equal 204, last_response.status

    # Double check that it's gone
    get '/notification/' + notification_id
    assert_equal 404, last_response.status
  end

  def test_add_and_update_notification_title
    notification = {
        "title" => "Old Title",
        "message" => "Old message contents",
        "email_address" => "Old e-mail address"
    }

    notification_id = make_a_notification(notification)

    # Modify the title of the record 
    notification_update_title = {
      "title" => "New Title"
    }

    post '/notification/' + notification_id, notification_update_title.to_json
    assert_equal 200, last_response.status
    returned_notification = retrieve_notification(notification_id)

    # Make sure it worked
    assert_equal returned_notification['message'], notification['message']
    assert_equal returned_notification['title'], notification_update_title['title']

    # Modify the message of the notification
    notification_update_message = {
        "message" =>"New Message content"
    }

    post '/notification/' + notification_id, notification_update_message.to_json
    assert_equal 200, last_response.status

    returned_notification = retrieve_notification(notification_id)

    # Make sure the modification stuck
    assert_equal returned_notification['message'], notification_update_message['message']
    assert_equal returned_notification['title'], notification_update_title['title']

    post '/notification/' + notification_id, notification.to_json
    assert_equal 200, last_response.status

    returned_notification = retrieve_notification(notification_id)

    assert_equal returned_notification['message'], notification['message']
    assert_equal returned_notification['title'], notification['title']
    
    # Modify the email address of the record 
    notification_update_email_address = {
      "email_address" => "New E-mail Address"
    }

    post '/notification/' + notification_id, notification_update_email_address.to_json
    assert_equal 200, last_response.status
    returned_notification = retrieve_notification(notification_id)

    # Make sure it worked
    assert_equal returned_notification['message'], notification['message']
    assert_equal returned_notification['title'], notification['title']
    assert_equal returned_notification['email_address'], notification_update_email_address['email_address']
  end

  def test_get_non_existent_notification
    get '/notification/ninja'  # non-integer ID == invalid
    assert_equal 404, last_response.status
  end

  def test_update_non_existent_notification
    notification = {
        "title" => "Test title",
        "message" => "Test message",
        "email_address" => "Should not save"
    }

    post '/notification/ninja', notification.to_json
    assert_equal 404, last_response.status
  end

  def test_delete_non_existent_notification
    delete '/notification/ninja'
    assert_equal 404, last_response.status
  end
end
