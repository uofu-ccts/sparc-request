require 'rails_helper'

RSpec.describe Organization, type: :model do

  describe '.all_child_services' do

    let!(:organization)         { create :organization }
    let!(:organization_service) { create :service, organization: organization }
    let!(:core)                 { create :core, parent: organization }
    let!(:core_service)         { create :service, organization: core }
    let!(:program)              { create :program, parent: core }
    let!(:program_service)      { create :service, organization: program }

    context 'inclusive' do

      it 'should return the correct Organization Services' do
        expect(organization.all_child_services).to eq([organization_service, core_service, program_service].sort_by(&:name))
      end

      it 'should return the correct Core Services' do
        expect(core.all_child_services).to eq([core_service, program_service].sort_by(&:name))
      end

      it 'should return the correct Program Services' do
        expect(program.all_child_services).to eq([program_service])
      end
    end

    context 'exclusive' do

      it 'should return the correct Organization Services' do
        expect(organization.all_child_services(false)).to eq([core_service, program_service].sort_by(&:name))
      end

      it 'should return the correct Core Services' do
        expect(core.all_child_services(false)).to eq([program_service])
      end

      it 'should return the correct Program Services' do
        expect(program.all_child_services(false)).to eq([])
      end
    end
  end
end
