require File.dirname(__FILE__) + '/test_helper'

class Tqurl::AccountInformationController::DispatchWithNoAuthorizedAccountsTest < Test::Unit::TestCase
  attr_reader :options, :client, :controller
  def setup
    @options    = Tqurl::Options.new
    @client     = Tqurl::OAuthClient.load_new_client_from_options(options)
    @controller = Tqurl::AccountInformationController.new(client, options)
    mock(Tqurl::OAuthClient.rcfile).empty? { true }
  end

  def test_message_indicates_when_no_accounts_are_authorized
    mock(Tqurl::CLI).puts(Tqurl::AccountInformationController::NO_AUTHORIZED_ACCOUNTS_MESSAGE).times(1)

    controller.dispatch
  end
end

class Tqurl::AccountInformationController::DispatchWithOneAuthorizedAccountTest < Test::Unit::TestCase
  attr_reader :options, :client, :controller
  def setup
    @options    = Tqurl::Options.test_exemplar
    @client     = Tqurl::OAuthClient.load_new_client_from_options(options)
    mock(Tqurl::OAuthClient.rcfile).save.times(1)
    Tqurl::OAuthClient.rcfile << client
    @controller = Tqurl::AccountInformationController.new(client, options)
  end

  def test_authorized_account_is_displayed_and_marked_as_the_default
    mock(Tqurl::CLI).puts(client.username).times(1).ordered
    mock(Tqurl::CLI).puts("  #{client.consumer_key} (default)").times(1).ordered

    controller.dispatch
  end
end

class Tqurl::AccountInformationController::DispatchWithOneUsernameThatHasAuthorizedMultipleAccountsTest < Test::Unit::TestCase
  attr_reader :default_client_options, :default_client, :other_client_options, :other_client, :controller
  def setup
    @default_client_options = Tqurl::Options.test_exemplar
    @default_client         = Tqurl::OAuthClient.load_new_client_from_options(default_client_options)

    @other_client_options             = Tqurl::Options.test_exemplar
    other_client_options.consumer_key = default_client_options.consumer_key.reverse
    @other_client                     = Tqurl::OAuthClient.load_new_client_from_options(other_client_options)
    mock(Tqurl::OAuthClient.rcfile).save.times(2)

    Tqurl::OAuthClient.rcfile << default_client
    Tqurl::OAuthClient.rcfile << other_client

    @controller = Tqurl::AccountInformationController.new(other_client, other_client_options)
  end

  def test_authorized_account_is_displayed_and_marked_as_the_default
    mock(Tqurl::CLI).puts(default_client.username).times(1)
    mock(Tqurl::CLI).puts("  #{default_client.consumer_key} (default)").times(1)
    mock(Tqurl::CLI).puts("  #{other_client.consumer_key}").times(1)

    controller.dispatch
  end
end