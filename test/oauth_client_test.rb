require File.dirname(__FILE__) + '/test_helper'

class Tqurl::OAuthClient::AbstractOAuthClientTest < Test::Unit::TestCase
  attr_reader :client, :options
  def setup
    Tqurl::OAuthClient.instance_variable_set(:@rcfile, nil)

    @options                = Tqurl::Options.test_exemplar
    @client                 = Tqurl::OAuthClient.test_exemplar
    options.base_url        = 'api.twitter.com'
    options.request_method  = 'get'
    options.path            = '/path/does/not/matter.xml'
    options.data            = {}
    options.headers         = {}

    Tqurl.options           = options
  end

  def teardown
    super
    Tqurl.options = Tqurl::Options.new
    # Make sure we don't do any disk IO in these tests
    assert !File.exists?(Tqurl::RCFile.file_path)
  end

  def test_nothing
    # Appeasing test/unit
  end
end

class Tqurl::OAuthClient::BasicRCFileLoadingTest < Tqurl::OAuthClient::AbstractOAuthClientTest
  def test_rcfile_is_memoized
    mock.proxy(Tqurl::RCFile).new.times(1)

    Tqurl::OAuthClient.rcfile
    Tqurl::OAuthClient.rcfile
  end

  def test_forced_reloading
    mock.proxy(Tqurl::RCFile).new.times(2)

    Tqurl::OAuthClient.rcfile
    Tqurl::OAuthClient.rcfile(:reload)
    Tqurl::OAuthClient.rcfile
  end
end

class Tqurl::OAuthClient::ClientLoadingFromOptionsTest < Tqurl::OAuthClient::AbstractOAuthClientTest
  def test_if_username_is_supplied_and_no_profile_exists_for_username_then_new_client_is_created
    mock(Tqurl::OAuthClient).load_client_for_username(options.username).never
    mock(Tqurl::OAuthClient).load_new_client_from_options(options).times(1)
    mock(Tqurl::OAuthClient).load_default_client.never

    Tqurl::OAuthClient.load_from_options(options)
  end

  def test_if_username_is_supplied_and_profile_exists_for_username_then_client_is_loaded
    mock(Tqurl::OAuthClient.rcfile).save.times(1)
    Tqurl::OAuthClient.rcfile << client

    mock(Tqurl::OAuthClient).load_client_for_username_and_consumer_key(options.username, options.consumer_key).times(1)
    mock(Tqurl::OAuthClient).load_new_client_from_options(options).never
    mock(Tqurl::OAuthClient).load_default_client.never

    Tqurl::OAuthClient.load_from_options(options)
  end

  def test_if_username_is_not_provided_then_the_default_client_is_loaded
    options.username = nil

    mock(Tqurl::OAuthClient).load_client_for_username(options.username).never
    mock(Tqurl::OAuthClient).load_new_client_from_options(options).never
    mock(Tqurl::OAuthClient).load_default_client.times(1)

    Tqurl::OAuthClient.load_from_options(options)
  end
end

class Tqurl::OAuthClient::ClientLoadingForUsernameTest < Tqurl::OAuthClient::AbstractOAuthClientTest
  def test_attempting_to_load_a_username_that_is_not_in_the_file_fails
    assert_nil Tqurl::OAuthClient.rcfile[client.username]

    assert_raises Tqurl::Exception do
      Tqurl::OAuthClient.load_client_for_username_and_consumer_key(client.username, client.consumer_key)
    end
  end

  def test_loading_a_username_that_exists
    mock(Tqurl::OAuthClient.rcfile).save.times(1)

    Tqurl::OAuthClient.rcfile << client

    client_from_file = Tqurl::OAuthClient.load_client_for_username_and_consumer_key(client.username, client.consumer_key)
    assert_equal client.to_hash, client_from_file.to_hash
  end
end

class Tqurl::OAuthClient::DefaultClientLoadingTest < Tqurl::OAuthClient::AbstractOAuthClientTest
  def test_loading_default_client_when_there_is_none_fails
    assert_nil Tqurl::OAuthClient.rcfile.default_profile

    assert_raises Tqurl::Exception do
      Tqurl::OAuthClient.load_default_client
    end
  end

  def test_loading_default_client_from_file
    mock(Tqurl::OAuthClient.rcfile).save.times(1)

    Tqurl::OAuthClient.rcfile << client
    assert_equal [client.username, client.consumer_key], Tqurl::OAuthClient.rcfile.default_profile

    client_from_file = Tqurl::OAuthClient.load_default_client

    assert_equal client.to_hash, client_from_file.to_hash
  end
end

class Tqurl::OAuthClient::NewClientLoadingFromOptionsTest < Tqurl::OAuthClient::AbstractOAuthClientTest
  attr_reader :new_client
  def setup
    super
    @new_client = Tqurl::OAuthClient.load_new_client_from_options(options)
  end

  def test_password_is_included
    assert_equal options.password, new_client.password
  end

  def test_oauth_options_are_passed_through
    assert_equal client.to_hash, new_client.to_hash
  end
end

class Tqurl::OAuthClient::PerformingRequestsFromOptionsTest < Tqurl::OAuthClient::AbstractOAuthClientTest
  def test_request_is_made_using_request_method_and_path_and_data_in_options
    client = Tqurl::OAuthClient.test_exemplar
    mock(client).get(options.path, options.data)

    client.perform_request_from_options(options)
  end
end

class Tqurl::OAuthClient::CredentialsForAccessTokenExchangeTest < Tqurl::OAuthClient::AbstractOAuthClientTest
  def test_successful_exchange_parses_token_and_secret_from_response_body
    parsed_response = {:oauth_token        => "123456789",
                       :oauth_token_secret => "abcdefghi",
                       :user_id            => "3191321",
                       :screen_name        => "noradio",
                       :x_auth_expires     => "0"}

    mock(client.consumer).
      token_request(:post,
                    client.consumer.access_token_path,
                    nil,
                    {},
                    client.client_auth_parameters) { parsed_response }

   assert client.needs_to_authorize?
   client.exchange_credentials_for_access_token
   assert !client.needs_to_authorize?
  end
end
