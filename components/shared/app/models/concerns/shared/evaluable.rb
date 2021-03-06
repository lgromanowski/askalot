module Shared::Evaluable
  extend ActiveSupport::Concern

  included do
    has_many :evaluations, as: :evaluable, dependent: :destroy

    scope :evaluated, lambda { joins(:evaluations).uniq }
  end

  def evaluated_by?(user)
    evaluations.exists?(author: user)
  end
end
