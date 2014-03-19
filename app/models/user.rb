class User < ActiveRecord::Base
  # TODO (jharinek) consider https://github.com/ryanb/cancan/wiki/Separate-Role-Model
  ROLES = [:student, :teacher, :administrator]

  devise :database_authenticatable,
         :confirmable,
         :lockable,
         :recoverable,
         :registerable,
         :rememberable,
         :trackable,
         :validatable,

         authentication_keys: [:login]

  has_many :questions, foreign_key: :author_id, dependent: :destroy
  has_many :answers,   foreign_key: :author_id, dependent: :destroy
  has_many :comments,  foreign_key: :author_id, dependent: :destroy

  has_many :labelings, dependent: :destroy
  has_many :labels, through: :labelings, foreign_key: :author_id

  has_many :followings, dependent: :destroy
  has_many :followers, through: :followings, class_name: :User, foreign_key: :follower_id
  has_many :followees, through: :followings, class_name: :User, foreign_key: :followee_id

  has_many :favorites,     foreign_key: :favorer_id,   dependent: :destroy
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :views,         foreign_key: :viewer_id,    dependent: :destroy
  has_many :votes,         foreign_key: :voter_id,     dependent: :destroy
  has_many :watchings,     foreign_key: :watcher_id,   dependent: :destroy

  # TODO (jharinek) gravatar_email - do not allow blank, but needs to be fixed

  validates :role, presence: true

  # TODO (smolnar) consult usage of functional indices for nick, login and email uniqueness checking
  validates :login, format: { with: /\A[A-Za-z0-9_]+\z/ }, presence: true, uniqueness: { case_sensitive: false }
  validates :nick,  format: { with: /\A[A-Za-z0-9_]+\z/ }, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 20 }, if: :login?

  validates :gravatar_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/ }, allow_blank: true

  validates :first, format: { with: /\A\p{Lu}\p{Ll}*\z/u }, allow_blank: true
  validates :last,  format: { with: /\A\p{Lu}\p{Ll}*\z/u }, allow_blank: true

  Social.networks.each do |key, network|
    validates key, format: { with: network.regexp }, allow_blank: true
  end

  symbolize :role, in: ROLES

  before_validation :resolve_nick, on: :create

  scope :questions, lambda { joins(:questions) }
  scope :answers,   lambda { joins(:answers) }
  scope :favorites, lambda { joins(:favorites) }

  def login=(value)
    write_attribute :login, value.to_s.downcase

    self.nick ||= login
  end

  def name
    (value = "#{first} #{middle} #{last}".squeeze(' ').strip).blank? ? nil : value
  end

  def can_destroy?
    false
  end

  def gravatar_email
    (value = read_attribute :gravatar_email).blank? ? email : value
  end

  def role?(base)
    ROLES.index(base.to_sym) <= ROLES.index(role)
  end

  def urls
    Hash[Social.networks.map { |key, network| [network, url(key)] }.select { |data| !data.second.blank? }]
  end

  def url(key)
    (value = read_attribute key).blank? ? nil : { original: value, shown: value.gsub(/\Ahttps?\:\/\//, '') }
  end

  def self.create_without_confirmation!(attributes)
    user = User.new(attributes)

    user.skip_confirmation!
    user.save!
    user
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    login      = conditions.delete(:login)

    return where(conditions).first unless login

    where(conditions).where(["login = :value OR email = :value", { value: login.downcase }]).first
  end

  protected

  def password_required?
    ais_login ? false : super
  end

  def resolve_nick
    nick, k = self.nick, 1

    self.nick = "#{nick}#{k += 1}" while User.where(nick: self.nick).where.not(id: self.id).exists?
  end
end
