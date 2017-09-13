module SeedDataHelper

  def self.create_institution(identity_id, options={})
    name = options.delete(:name)
    abbreviation = options.delete(:abbreviation) || name
    is_available = options.delete(:is_available) || true
    institution =  Institution.where({:name => name, :abbreviation => abbreviation, :is_available => is_available}).first_or_create
    institution.save!()
    catalog_manger = CatalogManager.where({identity_id: identity_id, organization_id: institution.id}).first_or_create
    catalog_manger.update_attributes({edit_historic_data: true})
    catalog_manger.save!()
    institution
  end

  def self.create_provider(institution_id, pricing_setup_id, options={})
    name = options.delete(:name)
    abbreviation = options.delete(:abbreviation) || name
    provider = Provider.where({:name => name, :abbreviation => abbreviation, :parent_id => institution_id}).first_or_create
    provider.build_subsidy_map()
    # create pricing map
    unless PricingSetup.exists?(organization_id: provider.id)
      default = {
        :organization_id => provider.id,
        :display_date => Date.today,
        :effective_date => Date.today - 1.days,
        :federal => 100,
        :corporate => 100,
        :other => 100,
        :member => 100,
        :charge_master => false,
        :college_rate_type => 'full',
        :federal_rate_type => 'full',
        :industry_rate_type => 'full',
        :investigator_rate_type => 'full',
        :internal_rate_type => 'full',
        :foundation_rate_type => 'full'
      }
      provider.pricing_setups.create! default
    end
    provider.save!()
    provider
  end

  def self.create_program(provider_id, options={})
    name = options.delete(:name)
    abbreviation = options.delete(:abbreviation) || name
    program = Program.where({:name => name, :abbreviation => abbreviation, :parent_id => provider_id}).first_or_create
    program.build_subsidy_map()
    program.save!()
    program
  end

  def self.create_core(program_id, options={})
    name = options.delete(:name)
    abbreviation = options.delete(:abbreviation) || name
    core = Core.where({:name => name, :abbreviation => abbreviation, :parent_id => program_id}).first_or_create
    core.build_subsidy_map()
    core.save!()
    core
  end

  def self.create_service(organization_id, options={})
    name = options.delete(:name)
    order = options.delete(:order)
    full_rate = options.delete(:full_rate) || 1
    federal_rate = options.delete(:federal_rate) || full_rate
    corporate_rate = options.delete(:corporate_rate) || full_rate
    other_rate = options.delete(:other_rate) || full_rate
    member_rate = options.delete(:member_rate) || full_rate
    display_date = options.delete(:display_date) || Date.today
    effective_date = options.delete(:effective_date) || display_date - 1.days
    unit_factor = options.delete(:unit_factor) || 1
    unit_type = options.delete(:unit_type) || 'Per Extraction'
    unit_minimum = options.delete(:unit_minimum) || 1
    service = Service.where({organization_id: organization_id, is_available: true, name: name, order: order}).first_or_create
    service.pricing_maps.build({
      full_rate: full_rate,
      federal_rate: federal_rate,
      corporate_rate: corporate_rate,
      other_rate: other_rate,
      member_rate: member_rate,
      display_date: display_date,
      effective_date: effective_date,
      unit_factor: unit_factor,
      unit_type: unit_type,
      unit_minimum: unit_minimum})
    service.save!
    service
  end
end
