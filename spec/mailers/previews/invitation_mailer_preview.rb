# Preview all emails at http://localhost:3000/rails/mailers/invitation_mailer
class InvitationMailerPreview < ActionMailer::Preview
  def invite_user
    user = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      name: Faker::Name.name,
      email: Faker::Internet.email
    )

    client = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 100),
      name: Faker::Company.name
    )

    role = RoleManageable::ROLES.keys.sample

    invitation = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      email: Faker::Internet.email,
      inviter: user,
      inviter_type: 'User',
      client: client,
      role: role,
      token: Faker::Alphanumeric.alphanumeric(number: 32),
      expires_at: Faker::Time.forward(days: 7),
      accept_url: "http://localhost:3000/invitations/accept?token=#{Faker::Alphanumeric.alphanumeric(number: 32)}"
    )

    InvitationMailer.invite(invitation)
  end

  def invite_user_admin_role
    user = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      name: Faker::Name.name,
      email: Faker::Internet.email
    )

    client = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 100),
      name: Faker::Company.name
    )

    role = RoleManageable.highest_role

    invitation = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      email: Faker::Internet.email,
      inviter: user,
      inviter_type: 'User',
      client: client,
      role: role,
      token: Faker::Alphanumeric.alphanumeric(number: 32),
      expires_at: Faker::Time.forward(days: 7),
      accept_url: "http://localhost:3000/invitations/accept?token=#{Faker::Alphanumeric.alphanumeric(number: 32)}"
    )

    InvitationMailer.invite(invitation)
  end

  def invite_user_manager_role
    user = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      name: Faker::Name.name,
      email: Faker::Internet.email
    )

    client = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 100),
      name: Faker::Company.name
    )

    role = 'manager'

    invitation = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      email: Faker::Internet.email,
      inviter: user,
      inviter_type: 'User',
      client: client,
      role: role,
      token: Faker::Alphanumeric.alphanumeric(number: 32),
      expires_at: Faker::Time.forward(days: 7),
      accept_url: "http://localhost:3000/invitations/accept?token=#{Faker::Alphanumeric.alphanumeric(number: 32)}"
    )

    InvitationMailer.invite(invitation)
  end

  def invite_user_viewer_role
    user = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      name: Faker::Name.name,
      email: Faker::Internet.email
    )

    client = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 100),
      name: Faker::Company.name
    )

    role = 'viewer'

    invitation = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      email: Faker::Internet.email,
      inviter: user,
      inviter_type: 'User',
      client: client,
      role: role,
      token: Faker::Alphanumeric.alphanumeric(number: 32),
      expires_at: Faker::Time.forward(days: 7),
      accept_url: "http://localhost:3000/invitations/accept?token=#{Faker::Alphanumeric.alphanumeric(number: 32)}"
    )

    InvitationMailer.invite(invitation)
  end

  def invite_admin_user
    admin_user = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 50),
      name: Faker::Name.name,
      email: Faker::Internet.email(domain: 'admin')
    )

    invitation = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      email: Faker::Internet.email,
      inviter: admin_user,
      inviter_type: 'AdminUser',
      token: Faker::Alphanumeric.alphanumeric(number: 32),
      expires_at: Faker::Time.forward(days: 7),
      accept_url: "http://localhost:3000/admin/invitations/accept?token=#{Faker::Alphanumeric.alphanumeric(number: 32)}"
    )

    InvitationMailer.invite(invitation)
  end

  def invite_user_expired
    user = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      name: Faker::Name.name,
      email: Faker::Internet.email
    )

    client = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 100),
      name: Faker::Company.name
    )

    role = RoleManageable::ROLES.keys.sample

    invitation = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      email: Faker::Internet.email,
      inviter: user,
      inviter_type: 'User',
      client: client,
      role: role,
      token: Faker::Alphanumeric.alphanumeric(number: 32),
      expires_at: Faker::Time.backward(days: 2), # Expired invitation
      accept_url: "http://localhost:3000/invitations/accept?token=#{Faker::Alphanumeric.alphanumeric(number: 32)}"
    )

    InvitationMailer.invite(invitation)
  end

  def invite_user_long_company_name
    user = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      name: Faker::Name.name,
      email: Faker::Internet.email
    )

    client = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 100),
      name: "#{Faker::Company.name} #{Faker::Company.suffix} International Solutions and Consulting Services LLC"
    )

    role = RoleManageable.highest_role

    invitation = OpenStruct.new(
      id: Faker::Number.between(from: 1, to: 1000),
      email: Faker::Internet.email,
      inviter: user,
      inviter_type: "User",
      client: client,
      role: role,
      token: Faker::Alphanumeric.alphanumeric(number: 32),
      expires_at: Faker::Time.forward(days: 1), # Expires soon
      accept_url: "http://localhost:3000/invitations/accept?token=#{Faker::Alphanumeric.alphanumeric(number: 32)}"
    )

    InvitationMailer.invite(invitation)
  end
end
