require 'rails_helper'

RSpec.describe 'User Registration', type: :request, inertia: true do
  before do
    @valid_user_attributes = {
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      company_attributes: {
        name: 'Test Company',
        site_attributes: {
          country: 'France',
          city: 'Paris',
          latitude: 48.858904,
          longitude: 2.3058348,
          altitude: 35.0
        }
      }
    }
  end

  shared_examples 'user registration fails' do
    it 'does not create a user' do
      expect(User.count).to eq(@user_count)
    end

    it 'does not create a company' do
      expect(Company.count).to eq(@company_count)
    end

    it 'does not create a site' do
      expect(Site.count).to eq(@site_count)
    end

    it 'does not send a confirmation email' do
      expect(ActionMailer::Base.deliveries.count).to eq(@email_count)
    end

    it 'renders the appropriate response' do
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:inertia)
    end
  end

  describe 'GET /users/sign_up' do
    it 'renders the registration page with Inertia' do
      get new_user_registration_path
      expect(response).to be_successful
      expect(inertia).to render_component 'devise/registrations/new'
      expect(inertia).to include_props({ userScope: 'users' })
    end
  end

  describe 'POST /users' do
    context 'with valid attributes' do
      before do
        @user_count = User.count
        @company_count = Company.count
        @site_count = Site.count
        @email_count = ActionMailer::Base.deliveries.count

        post user_registration_path, params: { user: @valid_user_attributes }
      end

      it 'creates a user to confirm email' do
        user = User.last
        expect(User.count).to eq(@user_count + 1)
        expect(user.name).to eq(@valid_user_attributes[:name])
        expect(user.email).to eq(@valid_user_attributes[:email])
        expect(user.active).to eq(true)
        expect(user.confirmed_at).to eq(nil)
      end

      it 'creates an active company' do
        company = Company.last
        expect(Company.count).to eq(@company_count + 1)
        expect(company.name).to eq(@valid_user_attributes[:company_attributes][:name])
        expect(company.active).to eq(true)
      end

      it 'creates an active site' do
        site = Site.last
        expect(Site.count).to eq(@site_count + 1)
        expect(site.name).to eq(@valid_user_attributes[:company_attributes][:site_attributes][:name])
        expect(site.active).to eq(true)
      end

      it 'sends confirmation email' do
        mail = ActionMailer::Base.deliveries.last
        expect(ActionMailer::Base.deliveries.count).to eq(@email_count + 1)
        expect(mail.to).to include(@valid_user_attributes[:email])
      end

      it 'renders the appropriate response' do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('A message with a confirmation link has been sent to your email address. Please follow the link to activate your account.')
      end

      it 'associates the user with the company and site' do
        user = User.last
        company = Company.last
        site = Site.last
        expect(user.company).to eq(company)
        expect(company.sites).to include(site)
        expect(company.users).to include(user)
      end
    end

    context 'with invalid email' do
      before do
        @user_count = User.count
        @company_count = Company.count
        @site_count = Site.count
        @email_count = ActionMailer::Base.deliveries.count

        invalid_user_attributes = @valid_user_attributes.deep_dup
        invalid_user_attributes[:email] = 'invalid-email'

        post user_registration_path, params: { user: invalid_user_attributes }
      end

      include_examples 'user registration fails'
    end

    context 'with missing password' do
      before do
        @user_count = User.count
        @company_count = Company.count
        @site_count = Site.count
        @email_count = ActionMailer::Base.deliveries.count

        invalid_user_attributes = @valid_user_attributes.deep_dup
        invalid_user_attributes.delete(:password)

        post user_registration_path, params: { user: invalid_user_attributes }
      end

      include_examples 'user registration fails'
    end

    context 'with password confirmation mismatch' do
      before do
        @user_count = User.count
        @company_count = Company.count
        @site_count = Site.count
        @email_count = ActionMailer::Base.deliveries.count

        invalid_user_attributes = @valid_user_attributes.deep_dup
        invalid_user_attributes[:password_confirmation] = 'different_password'

        post user_registration_path, params: { user: invalid_user_attributes }
      end

      include_examples 'user registration fails'
    end

    context 'without company attributes' do
      before do
        @user_count = User.count
        @company_count = Company.count
        @site_count = Site.count
        @email_count = ActionMailer::Base.deliveries.count

        invalid_attributes = @valid_user_attributes.dup
        invalid_attributes.delete(:company_attributes)

        post user_registration_path, params: { user: invalid_attributes }
      end

      include_examples 'user registration fails'
    end

    context 'with missing site' do
      before do
        @user_count = User.count
        @company_count = Company.count
        @site_count = Site.count
        @email_count = ActionMailer::Base.deliveries.count

        invalid_attributes = @valid_user_attributes.deep_dup
        invalid_attributes[:company_attributes].delete(:site_attributes)

        post user_registration_path, params: { user: invalid_attributes }
      end

      include_examples 'user registration fails'
    end
  end
end
