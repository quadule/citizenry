class Authentication < ActiveRecord::Base
  belongs_to :user
  serialize :info

  before_validation_on_create :initialize_user_if_absent
  validates_presence_of :user

  SETTINGS['auth_credentials'].each do |provider, opts|
    scope "via_#{provider.to_sym}", where("provider = ?", provider)
  end

  def self.new_from_omniauth(omniauth, options={})
    options.reverse_merge!(:provider => omniauth['provider'], :uid => omniauth['uid'])

    auth = self.new(options)
    auth.extract_credentials_from_omniauth(omniauth)
    auth.extract_info_from_omniauth(omniauth)

    auth
  end

  def self.create_from_omniauth(omniauth, options={})
    self.new_from_omniauth(omniauth, options).save
  end

  def self.create_from_omniauth!(omniauth, options={})
    self.new_from_omniauth(omniauth, options).save!
  end

  def extract_credentials_from_omniauth(omniauth)
    if omniauth.has_key?('credentials')
      self.access_token = omniauth['credentials']['token']
      self.access_token_secret = omniauth['credentials']['secret']
    end
  end

  # We only want to retain certain user info from omniauth responses, depending on the provider.
  def extract_info_from_omniauth(omniauth)
    if omniauth.has_key?('extra') && omniauth['extra'].has_key?('user_hash')
      self.info = omniauth['user_info'].merge(omniauth['extra']['user_hash'])
    else
      self.info = omniauth['user_info']
    end
  end

  private
  def initialize_user_if_absent
    self.build_user unless self.user.present?
  end
end


# == Schema Information
#
# Table name: authentications
#
#  id                  :integer(4)      not null, primary key
#  user_id             :integer(4)
#  provider            :string(255)
#  uid                 :string(255)
#  info                :text
#  created_at          :datetime
#  updated_at          :datetime
#  access_token        :string(255)
#  access_token_secret :string(255)
#
