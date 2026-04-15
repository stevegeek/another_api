# frozen_string_literal: true

require "test_helper"

class AnotherApi::TokenGenerationTest < Minitest::Test
  def setup
    @prev = AnotherApi.configuration.token_secret
    AnotherApi.configuration.token_secret = "test-secret"
    AnotherApi.configuration.token_prefix = "tk"
  end

  def teardown
    AnotherApi.configuration.token_secret = @prev
  end

  def test_generate_returns_a_complete_token_descriptor
    result = AnotherApi::TokenGeneration.generate
    assert result[:raw_token].start_with?("tk_")
    assert_equal AnotherApi::TokenGeneration.digest(result[:raw_token]), result[:token_digest]
    assert_match(/\A[A-HJ-NP-Za-km-z1-9]{4}\z/, result[:token_prefix])
    assert_match(/\A[A-HJ-NP-Za-km-z1-9]{4}\z/, result[:token_suffix])
  end

  def test_generate_accepts_a_custom_prefix_argument
    result = AnotherApi::TokenGeneration.generate(prefix: "custom")
    assert result[:raw_token].start_with?("custom_")
  end

  def test_digest_is_stable_for_a_given_input_and_secret
    a = AnotherApi::TokenGeneration.digest("hello")
    b = AnotherApi::TokenGeneration.digest("hello")
    assert_equal a, b
  end

  def test_digest_changes_when_the_secret_changes
    a = AnotherApi::TokenGeneration.digest("hello")
    AnotherApi.configuration.token_secret = "different-secret"
    b = AnotherApi::TokenGeneration.digest("hello")
    refute_equal a, b
  end

  def test_digest_raises_when_secret_is_unset
    AnotherApi.configuration.token_secret = nil
    assert_raises(AnotherApi::ConfigurationError) { AnotherApi::TokenGeneration.digest("hello") }
  end

  def test_digest_raises_when_secret_is_empty_string
    AnotherApi.configuration.token_secret = ""
    assert_raises(AnotherApi::ConfigurationError) { AnotherApi::TokenGeneration.digest("hello") }
  end
end
