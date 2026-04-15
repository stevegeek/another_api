# frozen_string_literal: true

require "active_record"

# Backing database for the integration tests. Two modes:
#
# - **PostgreSQL** (preferred) — set DATABASE_URL to a Postgres URL. The full
#   schema (array, jsonb) is available, and `omit_when_no_pg!` becomes a no-op
#   so all tests run.
# - **SQLite in-memory** (default) — used when DATABASE_URL is not set. Schema
#   degrades array/jsonb columns to plain text. Tests that depend on those
#   features call `omit_when_no_pg!` and skip.
module TestInTempDatabase
  PG_AVAILABLE = !ENV["DATABASE_URL"].to_s.empty?

  if PG_AVAILABLE
    require "pg"
    ActiveRecord::Base.establish_connection(ENV.fetch("DATABASE_URL"))
  else
    require "sqlite3"
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
  end

  class ApplicationRecord < ::ActiveRecord::Base
    self.abstract_class = true
  end

  class TestUserModel < ApplicationRecord
    self.table_name = "aql_test_users"
    has_many :test_post_models, foreign_key: :test_user_model_id
  end

  class TestPostModel < ApplicationRecord
    self.table_name = "aql_test_posts"
    belongs_to :test_user_model

    def author_name
      test_user_model&.name
    end
  end

  CreateTestModels = -> {
    ActiveRecord::Schema.define do
      self.verbose = false
      drop_table :aql_test_posts, if_exists: true
      drop_table :aql_test_users, if_exists: true

      create_table :aql_test_users do |t|
        t.string :name
        t.string :email
        t.integer :failed_attempts
        t.datetime :locked_at
        t.string :unlock_token
        t.datetime :deleted_at
        t.boolean :deleted
        t.decimal :favorite_number, precision: 5, scale: 2, default: 0.0
        if PG_AVAILABLE
          t.string :tags, array: true
          t.integer :lottery_numbers, array: true
          t.jsonb :metadata
        else
          t.string :tags             # array degraded
          t.string :lottery_numbers  # array degraded
          t.text :metadata           # jsonb degraded
        end
        t.float :temperature, default: 0.0
        t.date :birthday
        t.time :alarm
        t.timestamps
      end

      create_table :aql_test_posts do |t|
        t.string :title
        t.text :content
        t.references :test_user_model
        t.timestamps
      end
    end
  }

  CreateTestModels.call

  # Wrap each test in a transaction so DB state from one test doesn't leak
  # into the next. Tests run serially — Minitest parallel mode would race.
  def before_setup
    super
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
  end

  def after_teardown
    ActiveRecord::Base.connection.rollback_transaction if ActiveRecord::Base.connection.transaction_open?
    super
  end

  # No-op under PG; skips the test under SQLite.
  def omit_when_no_pg!
    return if TestInTempDatabase::PG_AVAILABLE
    skip "Requires PostgreSQL — array/jsonb features not portable to SQLite. Set DATABASE_URL to enable."
  end
end
