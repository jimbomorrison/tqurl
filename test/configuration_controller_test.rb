require File.dirname(__FILE__) + '/test_helper'

class Tqurl::ConfigurationController::DispatchTest < Test::Unit::TestCase
  def test_error_message_is_displayed_if_setting_is_unrecognized
    options = Tqurl::Options.test_exemplar
    client  = Tqurl::OAuthClient.test_exemplar

    options.subcommands = ['unrecognized', 'value']

    mock(Tqurl::CLI).puts(Tqurl::ConfigurationController::UNRECOGNIZED_SETTING_MESSAGE % 'unrecognized').times(1)
    mock(Tqurl::OAuthClient.rcfile).save.times(0)

    controller = Tqurl::ConfigurationController.new(client, options)
    controller.dispatch
  end
end

class Tqurl::ConfigurationController::DispatchDefaultSettingTest < Test::Unit::TestCase
  def test_setting_default_profile_just_by_username
    options = Tqurl::Options.test_exemplar
    client  = Tqurl::OAuthClient.test_exemplar

    options.subcommands = ['default', client.username]
    mock(Tqurl::OAuthClient).load_client_for_username(client.username).times(1) { client }
    mock(Tqurl::OAuthClient.rcfile).default_profile = client
    mock(Tqurl::OAuthClient.rcfile).save.times(1)

    controller = Tqurl::ConfigurationController.new(client, options)
    controller.dispatch
  end

  def test_setting_default_profile_by_username_and_consumer_key
    options = Tqurl::Options.test_exemplar
    client  = Tqurl::OAuthClient.test_exemplar

    options.subcommands = ['default', client.username, client.consumer_key]
    mock(Tqurl::OAuthClient).load_client_for_username_and_consumer_key(client.username, client.consumer_key).times(1) { client }
    mock(Tqurl::OAuthClient.rcfile).default_profile = client
    mock(Tqurl::OAuthClient.rcfile).save.times(1)

    controller = Tqurl::ConfigurationController.new(client, options)
    controller.dispatch
  end
end