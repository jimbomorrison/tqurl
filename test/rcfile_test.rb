require File.dirname(__FILE__) + '/test_helper'

class Tqurl::RCFile::PathConstructionTest < Test::Unit::TestCase
  def test_file_path_appends_file_to_directory
    assert_equal File.join(Tqurl::RCFile.directory, Tqurl::RCFile::FILE), Tqurl::RCFile.file_path
  end
end

class Tqurl::RCFile::LoadingTest < Test::Unit::TestCase
  def test_load_parses_and_loads_file_if_it_exists
    mock(YAML).load_file(Tqurl::RCFile.file_path).times(1)
    mock(Tqurl::RCFile).default_rcfile_structure.never

    Tqurl::RCFile.load
  end

  def test_load_returns_default_file_structure_if_file_does_not_exist
    mock(YAML).load_file(Tqurl::RCFile.file_path) { raise Errno::ENOENT }.times(1)
    mock(Tqurl::RCFile).default_rcfile_structure.times(1)

    Tqurl::RCFile.load
  end
end

class Tqurl::RCFile::InitializationTest < Test::Unit::TestCase
  def test_initializing_when_the_file_does_not_exist_loads_default_rcfile_structure
    mock(YAML).load_file(Tqurl::RCFile.file_path) { raise Errno::ENOENT }.times(1)

    rcfile = Tqurl::RCFile.new
    assert_equal Tqurl::RCFile.default_rcfile_structure, rcfile.data
  end

  def test_initializing_when_the_file_does_exists_loads_content_of_file
    mock_content_of_rcfile = {'this data' => 'does not matter'}
    mock(YAML).load_file(Tqurl::RCFile.file_path) { mock_content_of_rcfile }.times(1)
    mock(Tqurl::RCFile).default_rcfile_structure.never

    rcfile = Tqurl::RCFile.new
    assert_equal mock_content_of_rcfile, rcfile.data
  end
end

class Tqurl::RCFile::DefaultProfileFromDefaultRCFileTest < Test::Unit::TestCase
  attr_reader :rcfile
  def setup
    mock(YAML).load_file(Tqurl::RCFile.file_path) { raise Errno::ENOENT }.times(1)
    mock.proxy(Tqurl::RCFile).default_rcfile_structure.times(any_times)

    @rcfile = Tqurl::RCFile.new
  end

  def test_default_rcfile_structure_has_no_default_profile
    assert_nil rcfile.default_profile
  end

  def test_rcfile_is_considered_empty_at_first
    assert rcfile.empty?
  end

  def test_setting_default_profile
    options  = Tqurl::Options.test_exemplar

    client = Tqurl::OAuthClient.load_new_client_from_options(options)
    rcfile.default_profile = client
    assert_equal [options.username, options.consumer_key], rcfile.default_profile
  end
end

class Tqurl::RCFile::UpdatingTest < Test::Unit::TestCase
  attr_reader :rcfile
  def setup
    mock(YAML).load_file(Tqurl::RCFile.file_path) { raise Errno::ENOENT }.times(1)

    @rcfile = Tqurl::RCFile.new
    assert rcfile.profiles.empty?
    assert_nil rcfile.default_profile
    mock(rcfile).save.times(any_times)
  end

  def test_adding_the_first_client_sets_it_as_default_profile
    client = Tqurl::OAuthClient.test_exemplar

    rcfile << client
    assert_equal [client.username, client.consumer_key], rcfile.default_profile
    assert rcfile.has_oauth_profile_for_username_with_consumer_key?(client.username, client.consumer_key)
    assert_equal({client.username => {client.consumer_key => client.to_hash}}, rcfile.profiles)
  end

  def test_adding_additional_clients_does_not_change_default_profile
    first_client = Tqurl::OAuthClient.test_exemplar

    rcfile << first_client
    assert_equal [first_client.username, first_client.consumer_key], rcfile.default_profile
    assert rcfile.has_oauth_profile_for_username_with_consumer_key?(first_client.username, first_client.consumer_key)

    additional_client = Tqurl::OAuthClient.test_exemplar(:username => 'additional_exemplar_username')

    rcfile << additional_client
    assert_equal [first_client.username, first_client.consumer_key], rcfile.default_profile
    assert rcfile.has_oauth_profile_for_username_with_consumer_key?(additional_client.username, additional_client.consumer_key)

    expected_profiles = {
      first_client.username      => {first_client.consumer_key      => first_client.to_hash},
      additional_client.username => {additional_client.consumer_key => additional_client.to_hash}
    }

    assert_equal expected_profiles, rcfile.profiles
  end
end

class Tqurl::RCFile::SavingTest < Test::Unit::TestCase
  attr_reader :rcfile
  def setup
    delete_rcfile
    assert !rcfile_exists?
    @rcfile = Tqurl::RCFile.new
    assert !rcfile_exists?
  end

  def teardown
    super
    delete_rcfile
  end

  def test_save_writes_profiles_to_disk
    client = Tqurl::OAuthClient.test_exemplar
    rcfile << client
    assert rcfile_exists?
  end

  private
    def rcfile_exists?
      File.exists?(Tqurl::RCFile.file_path)
    end

    def delete_rcfile
      File.unlink(Tqurl::RCFile.file_path)
    rescue Errno::ENOENT
      # Do nothing
    end
end