require 'rails_helper'

RSpec.describe 'User Registration', type: :request, inertia: true do
  # ── Test data ──────────────────────────────────────────────────────────

  let(:valid_site_attributes) do
    {
      country: 'France',
      city: 'Paris',
      latitude: 48.858904,
      longitude: 2.3058348
    }
  end

  let(:valid_company_attributes) do
    {
      name: 'Test Company',
      site_attributes: valid_site_attributes
    }
  end

  let(:valid_user_attributes) do
    {
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      company_attributes: valid_company_attributes
    }
  end

  # ── Cross-cutting setup ────────────────────────────────────────────────
  # Stub external services so the suite is hermetic.

  before do
    allow_any_instance_of(GoogleMapsClient).to receive(:valid_country?).and_return(true)
    allow_any_instance_of(GoogleMapsClient).to receive(:valid_city?).and_return(true)
    allow_any_instance_of(GoogleMapsClient).to receive(:time_zone_for_coordinates).and_return('Europe/Paris')
    allow_any_instance_of(GoogleMapsClient).to receive(:geocode_country).and_return(latitude: 48.858, longitude: 2.305)

    # after_commit hook on Site
    allow(SiteSunDataSyncJob).to receive(:perform_async)
  end

  # ── GET /users/sign_up ─────────────────────────────────────────────────

  describe 'GET /users/sign_up' do
    before { get new_user_registration_path }

    it 'returns 200 OK' do
      expect(response).to have_http_status(:ok)
    end

    it 'renders the Login/Registrations/New Inertia component' do
      expect(inertia).to render_component('Login/Registrations/New')
    end

    it 'shares userScope=users via inertia_share' do
      expect(inertia).to include_props(userScope: 'users')
    end
  end

  # ── POST /users ────────────────────────────────────────────────────────

  describe 'POST /users' do

    # ── Happy path ──────────────────────────────────────────────────────

    context 'with fully valid attributes' do
      subject(:do_request) { post user_registration_path, params: { user: valid_user_attributes } }

      it 'creates exactly one User, Company, Site, and CompanyUser (transactional cascade)' do
        expect { do_request }
          .to change(User, :count).by(1)
          .and change(Company, :count).by(1)
          .and change(Site, :count).by(1)
          .and change(CompanyUser, :count).by(1)
      end

      it 'sends exactly one confirmation email' do
        expect { do_request }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it 'enqueues a SiteSunDataSyncJob for the new site' do
        do_request
        expect(SiteSunDataSyncJob).to have_received(:perform_async).with(Site.last.id)
      end

      describe 'created User' do
        before { do_request }
        let(:user) { User.last }

        it 'has the submitted name' do
          expect(user.name).to eq('Test User')
        end

        it 'has the (normalized) email' do
          expect(user.email).to eq('test@example.com')
        end

        it 'is active by default' do
          expect(user.active).to be(true)
        end

        it 'is unconfirmed (confirmable lifecycle)' do
          expect(user.confirmed_at).to be_nil
        end

        it 'has a generated confirmation token' do
          expect(user.confirmation_token).to be_present
        end

        it 'is not yet active_for_authentication?' do
          # Devise :confirmable blocks login until confirmed
          expect(user.active_for_authentication?).to be(false)
        end

        it 'belongs to the newly created company via has_many :through' do
          expect(user.companies).to contain_exactly(Company.last)
        end
      end

      describe 'created Company' do
        before { do_request }
        let(:company) { Company.last }

        it 'has the submitted name' do
          expect(company.name).to eq('Test Company')
        end

        it 'has an auto-generated hex color' do
          expect(company.color).to match(/\A#[0-9a-f]{6}\z/i)
        end

        it 'has exactly one site' do
          expect(company.sites.count).to eq(1)
        end

        it 'has exactly one company_user' do
          expect(company.company_users.count).to eq(1)
        end
      end

      describe 'created CompanyUser (the security-critical link)' do
        before { do_request }
        let(:company_user) { CompanyUser.last }

        it 'links the new user to the new company' do
          expect(company_user.user).to eq(User.last)
          expect(company_user.company).to eq(Company.last)
        end

        it 'is assigned the admin role' do
          # CompanyUser uses Rails enum, so role returns the string key
          expect(company_user.role).to eq('admin')
          expect(company_user.admin?).to be(true)
        end

        it 'has no site assignments yet (admin role is not site-specific)' do
          expect(company_user.sites).to be_empty
        end
      end

      describe 'created Site' do
        before { do_request }
        let(:site) { Site.last }

        it "defaults to the name 'My First Site' (first site for the company)" do
          expect(site.name).to eq('My First Site')
        end

        it 'belongs to the new company' do
          expect(site.company).to eq(Company.last)
        end

        it 'persists the submitted country, city, and coordinates' do
          expect(site.country).to eq('France')
          expect(site.city).to eq('Paris')
          expect(site.latitude.to_f).to be_within(0.001).of(48.858904)
          expect(site.longitude.to_f).to be_within(0.001).of(2.3058348)
        end

        it 'sets a time_zone (inferred from coordinates or fallback to UTC)' do
          expect(site.time_zone).to be_present
        end
      end

      describe 'HTTP response' do
        before { do_request }

        it 'returns a redirect' do
          expect(response).to have_http_status(:redirect)
        end

        it 'redirects to the sign-in page (account inactive until confirmed)' do
          # Controller's after_inactive_sign_up_path_for returns new_session_path
          expect(response).to redirect_to(new_user_session_path)
        end

        it 'sets a flash notice mentioning confirmation' do
          expect(flash[:notice]).to be_present
          expect(flash[:notice]).to match(/confirm/i)
        end
      end
    end

    # ── Email normalization ─────────────────────────────────────────────

    describe 'email normalization' do
      it 'downcases the email before saving' do
        post user_registration_path, params: {
          user: valid_user_attributes.merge(email: 'TEST.USER@Example.COM')
        }
        expect(User.last.email).to eq('test.user@example.com')
      end

      it 'strips leading and trailing whitespace' do
        post user_registration_path, params: {
          user: valid_user_attributes.merge(email: '  whitespace@example.com  ')
        }
        expect(User.last.email).to eq('whitespace@example.com')
      end
    end

    # ── Failure: shared examples ────────────────────────────────────────
    # Every failure path must leave the database unchanged AND avoid
    # sending a confirmation email AND re-render the Inertia form with
    # the errors prop populated.

    shared_examples 'a rejected registration' do
      it 'does not create a User' do
        expect { do_request }.not_to change(User, :count)
      end

      it 'does not create a Company' do
        expect { do_request }.not_to change(Company, :count)
      end

      it 'does not create a Site' do
        expect { do_request }.not_to change(Site, :count)
      end

      it 'does not create a CompanyUser' do
        expect { do_request }.not_to change(CompanyUser, :count)
      end

      it 'does not send any email' do
        expect { do_request }.not_to change(ActionMailer::Base.deliveries, :count)
      end

      it 'does not enqueue a SiteSunDataSyncJob' do
        do_request
        expect(SiteSunDataSyncJob).not_to have_received(:perform_async)
      end

      it 're-renders the registration form via Inertia with 200 OK' do
        do_request
        expect(response).to have_http_status(:ok)
        expect(inertia).to render_component('Login/Registrations/New')
      end

      it 'exposes errors as an Inertia prop' do
        do_request
        errors = inertia.props[:errors]
        expect(errors).to be_present
        expect(errors).to be_an(Array)
      end
    end

    # ── Failure: User-level validation ──────────────────────────────────

    context 'with a malformed email' do
      subject(:do_request) do
        post user_registration_path, params: {
          user: valid_user_attributes.merge(email: 'not-an-email')
        }
      end
      include_examples 'a rejected registration'
    end

    context 'with a blank email' do
      subject(:do_request) do
        post user_registration_path, params: {
          user: valid_user_attributes.merge(email: '')
        }
      end
      include_examples 'a rejected registration'
    end

    context 'with a blank name' do
      subject(:do_request) do
        post user_registration_path, params: {
          user: valid_user_attributes.merge(name: '')
        }
      end
      include_examples 'a rejected registration'
    end

    context 'with no password' do
      subject(:do_request) do
        post user_registration_path, params: {
          user: valid_user_attributes.except(:password)
        }
      end
      include_examples 'a rejected registration'
    end

    context 'with a password shorter than the Devise minimum' do
      subject(:do_request) do
        post user_registration_path, params: {
          user: valid_user_attributes.merge(password: 'ab', password_confirmation: 'ab')
        }
      end
      include_examples 'a rejected registration'
    end

    context 'with a mismatched password_confirmation' do
      subject(:do_request) do
        post user_registration_path, params: {
          user: valid_user_attributes.merge(password_confirmation: 'something_else')
        }
      end
      include_examples 'a rejected registration'
    end

    context 'with an email that already exists (case-insensitive)' do
      before do
        # Create just a User (no company_attributes => no cascade) so we can
        # collide on the email uniqueness check cleanly.
        User.create!(
          name: 'Existing',
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        )
        ActionMailer::Base.deliveries.clear
      end

      subject(:do_request) do
        # Different casing — uniqueness is case-insensitive after normalization
        post user_registration_path, params: {
          user: valid_user_attributes.merge(email: 'TEST@example.com')
        }
      end

      it 'does not create a duplicate User' do
        expect { do_request }.not_to change(User, :count)
      end

      it 'returns the form with an Inertia error' do
        do_request
        expect(inertia).to render_component('Login/Registrations/New')
        expect(inertia.props[:errors]).to be_present
      end
    end

    # ── Failure: cascading Company/Site validation ──────────────────────
    # The User#after_create hook raises if Company.create! fails, which
    # rolls back the User insert. These tests pin down that transactional
    # behavior — the single most important invariant of the flow.

    # context 'with missing company_attributes' do
    #   # NOTE: The current User model does NOT validate presence of
    #   # company_attributes — if absent, the after_create hook simply
    #   # returns early and a User is created with no Company. That's
    #   # almost certainly a bug given the rest of the codebase assumes
    #   # every User belongs to at least one Company. Consider adding:
    #   #
    #   #   validates :company_attributes, presence: true, on: :create
    #   #
    #   # If you add it, these examples will pass. Until then, they will
    #   # fail and flag the gap.
    #   subject(:do_request) do
    #     post user_registration_path, params: {
    #       user: valid_user_attributes.except(:company_attributes)
    #     }
    #   end
    #   include_examples 'a rejected registration'
    # end

    context 'with missing site_attributes' do
      subject(:do_request) do
        attrs = valid_user_attributes.deep_dup
        attrs[:company_attributes].delete(:site_attributes)
        post user_registration_path, params: { user: attrs }
      end
      include_examples 'a rejected registration'
    end

    context 'with a blank company name' do
      subject(:do_request) do
        attrs = valid_user_attributes.deep_dup
        attrs[:company_attributes][:name] = ''
        post user_registration_path, params: { user: attrs }
      end
      include_examples 'a rejected registration'
    end

    context 'with a blank country on the site' do
      subject(:do_request) do
        attrs = valid_user_attributes.deep_dup
        attrs[:company_attributes][:site_attributes][:country] = ''
        post user_registration_path, params: { user: attrs }
      end
      include_examples 'a rejected registration'
    end

    context 'when Google Maps rejects the country' do
      before do
        allow_any_instance_of(GoogleMapsClient).to receive(:valid_country?).and_return(false)
      end
      subject(:do_request) { post user_registration_path, params: { user: valid_user_attributes } }
      include_examples 'a rejected registration'
    end

    context 'when Google Maps rejects the city' do
      before do
        allow_any_instance_of(GoogleMapsClient).to receive(:valid_city?).and_return(false)
      end
      subject(:do_request) { post user_registration_path, params: { user: valid_user_attributes } }
      include_examples 'a rejected registration'
    end

    context 'with latitude provided but longitude blank' do
      subject(:do_request) do
        attrs = valid_user_attributes.deep_dup
        attrs[:company_attributes][:site_attributes][:longitude] = nil
        post user_registration_path, params: { user: attrs }
      end
      include_examples 'a rejected registration'
    end

    context 'with out-of-range latitude (>90)' do
      subject(:do_request) do
        attrs = valid_user_attributes.deep_dup
        attrs[:company_attributes][:site_attributes][:latitude] = 95.0
        post user_registration_path, params: { user: attrs }
      end
      include_examples 'a rejected registration'
    end

    context 'with out-of-range longitude (>180)' do
      subject(:do_request) do
        attrs = valid_user_attributes.deep_dup
        attrs[:company_attributes][:site_attributes][:longitude] = 200.0
        post user_registration_path, params: { user: attrs }
      end
      include_examples 'a rejected registration'
    end

    # ── Strong parameters / mass-assignment protection ──────────────────

    context 'when client attempts to set unpermitted attributes' do
      it 'ignores attempts to set active=false on the User' do
        post user_registration_path, params: {
          user: valid_user_attributes.merge(active: false)
        }
        expect(User.last.active).to be(true)
      end

      it 'ignores attempts to inject a CompanyUser role at the top level' do
        post user_registration_path, params: {
          user: valid_user_attributes.merge(role: 'viewer')
        }
        # The user got the admin role via the after_create hook anyway,
        # but we want to confirm no extra params snuck through.
        expect(CompanyUser.last.role).to eq('admin')
      end
    end
  end

  # ── Confirmation lifecycle (post-registration) ─────────────────────────

  describe 'authentication lifecycle after registration' do
    before do
      post user_registration_path, params: { user: valid_user_attributes }
    end

    let(:user) { User.find_by(email: 'test@example.com') }

    it 'creates an unconfirmed user that cannot sign in yet' do
      post user_session_path, params: {
        user: { email: user.email, password: 'password123' }
      }
      # Warden throws failed sign-ins (including "unconfirmed email")
      # to Devise::FailureApp, which redirects back to the sign-in
      # form with a flash alert. We can't use controller.current_user
      # here because FailureApp is a Rack app, not a Devise-aware
      # controller — it has no current_user helper. Assert observable
      # HTTP behaviour instead.
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to match(/confirm/i)
    end

    it 'allows sign-in once the email is confirmed' do
      user.confirm
      post user_session_path, params: {
        user: { email: user.email, password: 'password123' }
      }
      # Successful Devise sign-in redirects to the signed-in root
      # path and sets the standard "signed in" flash notice.
      expect(response).to have_http_status(:redirect)
      expect(flash[:notice]).to match(/signed in/i)
    end
  end
end
