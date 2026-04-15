# frozen_string_literal: true

class Post < ApplicationRecord
  include AnotherApi::Serializes

  belongs_to :bearer

  validates :title, presence: true
end
