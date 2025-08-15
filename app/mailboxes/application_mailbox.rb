class ApplicationMailbox < ActionMailbox::Base
  routing :all => :data_mailbox
end
