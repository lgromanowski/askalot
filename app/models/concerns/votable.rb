module Votable
  extend ActiveSupport::Concern

  included do
    has_many :votes, as: :votable, dependent: :destroy
    has_many :voters, through: :votes, source: :voter

    scope :voted, lambda { joins(:votes).uniq }

    scope :by_votes, lambda { order(arel_table[:votes_lb_wsci_bp].desc, arel_table[:created_at].desc) }
  end

  def voted_by?(user)
    votes.exists?(voter: user)
  end

  def upvoted_by?(user)
    votes.positive.exists?(voter: user)
  end

  def downvoted_by?(user)
    votes.negative.exists?(voter: user)
  end

  def toggle_vote_by!(user, positive)
    vote = Vote.unscoped.find_or_create_by! votable:self, voter: user

    if vote.positive == positive && !vote.deleted?
      vote.mark_as_deleted_by! user
    else
      vote.positive = positive
      vote.unmark_as_deleted! if vote.deleted?
      vote.save!
    end

    update_votes_caches!

    vote
  end

  def toggle_voteup_by!(user)
    toggle_vote_by! user, true
  end

  def toggle_votedown_by!(user)
    toggle_vote_by! user, false
  end

  private

  def update_votes_caches!
    positive = votes.positive.size
    negative = votes.negative.size

    self.votes_difference = positive - negative
    self.votes_lb_wsci_bp = Ratain.lb_wsci_bp positive, positive + negative

    self.save!
  end
end
