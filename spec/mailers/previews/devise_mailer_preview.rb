# Preview all emails at http://localhost:3000/rails/mailers/devise_mailer
class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    user = sample_user
    token = Faker::Alphanumeric.alphanumeric(number: 20)
    Devise::Mailer.confirmation_instructions(user, token)
  end

  def reconfirmation_instructions
    user = sample_user(
      email: Faker::Internet.email,
      unconfirmed_email: Faker::Internet.email
    )

    token = Faker::Alphanumeric.alphanumeric(number: 20)
    Devise::Mailer.confirmation_instructions(user, token)
  end

  def reset_password_instructions
    user = sample_user
    token = Faker::Alphanumeric.alphanumeric(number: 20)
    Devise::Mailer.reset_password_instructions(user, token)
  end

  def unlock_instructions
    user = sample_user(
      failed_attempts: Faker::Number.between(from: 3, to: 10),
      locked_at: Faker::Time.between(from: 2.hours.ago, to: 30.minutes.ago)
    )

    token = Faker::Alphanumeric.alphanumeric(number: 20)
    Devise::Mailer.unlock_instructions(user, token)
  end

  def email_changed
    user = sample_user

    # Simulate the old email using Faker
    old_email = Faker::Internet.email
    user.define_singleton_method(:email_was) { old_email }

    Devise::Mailer.email_changed(user)
  end

  def password_change
    user = sample_user
    Devise::Mailer.password_change(user)
  end

  private
    def sample_user(**attributes)
      default_attributes = {
        email: Faker::Internet.email,
        name: Faker::Name.name,
        created_at: Faker::Time.between(from: 1.year.ago, to: 1.week.ago),
        updated_at: Faker::Time.between(from: 1.week.ago, to: 1.day.ago)
      }

      User.new(default_attributes.merge(attributes))
    end
end

