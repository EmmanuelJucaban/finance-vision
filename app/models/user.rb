class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :user_stocks, dependent: :destroy
  has_many :stocks, through: :user_stocks
  has_many :friendships
  has_many :friends, through: :friendships

  def full_name
    return "#{first_name} #{last_name}".strip if (first_name || last_name)
    "Anonymous"
  end

  def can_add_stock?(ticker_symbol)
    under_stock_limit? && !stock_already_added?(ticker_symbol)
  end

  def under_stock_limit?
    (user_stocks.count < 10)
  end

  def stock_already_added?(ticker_symbol)
    stock = Stock.find_by_ticker(ticker_symbol)
    return false unless stock
    user_stocks.where(stock_id: stock.id).exists?
  end

  def not_friends_with?(friend_id)
    # If this friend ID doesnt match up with any one in the list of friendship
    friendships.where(friend_id: friend_id).count < 1
  end

  def except_current_user(users)
    # Rejects the only user that matches the callers id
    users.reject { |user| user.id == self.id }
  end

  # this self is a class level method
  def self.search(param)
    return user.none if param.blank?
    param.strip!
    param.downcase!
    (first_name_matches(param) + last_name_matches(param) + email_matches(param)).uniq
  end


  def self.first_name_matches(param)
    matches("first_name", param)
  end

  def self.last_name_matches(param)
    matches("last_name", param)
  end

  def self.email_matches(param)
    matches("email", param)
  end

  def self.matches(field_name, param)
    # Wild card means that it doesnt have to be an exact match
    where("lower(#{field_name}) like?", "%#{param}%")
  end
end
