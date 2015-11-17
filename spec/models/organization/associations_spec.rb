require 'rails_helper'

RSpec.describe Organization, type: :model do

  it { is_expected.to have_one(:subsidy_map) }

  it { is_expected.to belong_to(:parent) }

  it { is_expected.to have_many(:catalog_managers) }
  it { is_expected.to have_many(:clinical_providers) }
  it { is_expected.to have_many(:services) }
  it { is_expected.to have_many(:sub_service_requests) }
  it { is_expected.to have_many(:available_statuses) }
  it { is_expected.to have_many(:service_providers) }
  it { is_expected.to have_many(:identities) }
  it { is_expected.to have_many(:super_users) }
  it { is_expected.to have_many(:pricing_setups) }
  it { is_expected.to have_many(:submission_emails) }
  it { is_expected.to have_many(:children) }
end
