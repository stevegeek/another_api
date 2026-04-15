# frozen_string_literal: true

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :bearers, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :api_tokens, force: true do |t|
    t.string :token_digest, null: false
    t.string :token_prefix, null: false
    t.string :token_suffix, null: false
    t.text :scopes, default: "[]"
    t.references :bearer, polymorphic: true, null: false
    t.datetime :revoked_at
    t.datetime :expires_at
    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.string :title, null: false
    t.text :body
    t.references :bearer, null: false
    t.timestamps
  end
end
