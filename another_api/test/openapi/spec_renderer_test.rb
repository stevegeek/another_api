# frozen_string_literal: true

require "test_helper"
require "another_api/openapi"
require "tmpdir"
require "fileutils"

class AnotherApi::OpenAPI::SpecRendererTest < Minitest::Test
  def setup
    @prev = AnotherApi::OpenAPI.instance_variable_get(:@configuration)
    AnotherApi::OpenAPI.reset_configuration!
    AnotherApi::OpenAPI::SpecRenderer.reset!
    AnotherApi::OpenAPI::EndpointRegistry.clear!

    # Tiny watched dir under a tmp path; isolated per test.
    @watch_dir = Dir.mktmpdir("openapi-spec-renderer-test-")
    @watched_file = File.join(@watch_dir, "thing.rb")
    File.write(@watched_file, "# placeholder")

    AnotherApi::OpenAPI.configure do |c|
      c.title = "Cache Test API"
      c.version = "0.0"
      c.eager_load_controllers = false
      c.watched_dirs = [@watch_dir]
    end
  end

  def teardown
    FileUtils.remove_entry(@watch_dir) if @watch_dir && File.exist?(@watch_dir)
    AnotherApi::OpenAPI::SpecRenderer.reset!
    AnotherApi::OpenAPI::EndpointRegistry.clear!
    AnotherApi::OpenAPI.instance_variable_set(:@configuration, @prev)
  end

  def test_render_hash_returns_full_spec
    spec = AnotherApi::OpenAPI::SpecRenderer.render_hash
    assert_equal "Cache Test API", spec[:info][:title]
    assert_equal "3.1.0", spec[:openapi]
  end

  def test_render_json_returns_pretty_json_of_the_hash
    json = AnotherApi::OpenAPI::SpecRenderer.render_json
    parsed = JSON.parse(json)
    assert_equal "Cache Test API", parsed["info"]["title"]
    # Pretty-printed JSON contains newlines.
    assert_includes json, "\n"
  end

  def test_repeated_render_hash_returns_same_object_when_no_changes
    first = AnotherApi::OpenAPI::SpecRenderer.render_hash
    second = AnotherApi::OpenAPI::SpecRenderer.render_hash
    assert_same first, second, "expected cached object reuse on identical mtime"
  end

  def test_modifying_a_watched_file_invalidates_the_dev_cache
    first = AnotherApi::OpenAPI::SpecRenderer.render_hash

    sleep 1.05  # filesystem mtime resolution is 1s on many filesystems
    File.write(@watched_file, "# changed")

    second = AnotherApi::OpenAPI::SpecRenderer.render_hash
    refute_same first, second, "expected cache to be invalidated by mtime change"
    # Content equality is fine; we just need a fresh object.
    assert_equal first[:info][:title], second[:info][:title]
  end

  def test_production_mode_reuses_cache_even_when_files_change
    # Simulate Rails.env.production?
    Rails.env = "production"
    first = AnotherApi::OpenAPI::SpecRenderer.render_hash

    sleep 1.05
    File.write(@watched_file, "# changed in prod")

    second = AnotherApi::OpenAPI::SpecRenderer.render_hash
    assert_same first, second, "production mode should not invalidate on mtime"
  ensure
    Rails.env = "test"
  end

  def test_reset_forces_recompute
    first = AnotherApi::OpenAPI::SpecRenderer.render_hash
    AnotherApi::OpenAPI::SpecRenderer.reset!
    second = AnotherApi::OpenAPI::SpecRenderer.render_hash
    refute_same first, second, "reset! should clear the cache so the next call recomputes"
  end

  def test_current_max_mtime_tolerates_missing_watched_dirs
    AnotherApi::OpenAPI.configuration.watched_dirs = ["definitely/not/a/real/dir"]
    # Should not raise — missing dirs are skipped.
    spec = AnotherApi::OpenAPI::SpecRenderer.render_hash
    assert_equal "Cache Test API", spec[:info][:title]
  end
end
