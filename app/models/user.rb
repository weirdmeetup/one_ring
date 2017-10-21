class User < ApplicationRecord
  has_one :secure_token, dependent: :destroy

  delegate :token, to: :secure_token, allow_nil: true

  def self.sign_in!(auth)
    find_or_initialize_by(provider: auth.provider, uid: auth.uid).tap do |user|
      if user.persisted?
        user.secure_token.update!(token: auth.credentials.token)
      else
        user.assign_attributes(name: auth.info.user.name)
        user.build_secure_token(token: auth.credentials.token)
        transaction { user.save! }
      end
    end
  end
end
