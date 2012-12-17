module CapybaraSupport
  def create_default_data
    identity = Identity.last

    institution = FactoryGirl.create(:institution,
      name:                 'Medical University of South Carolina',
      order:                1,
      obisid:               '87d1220c5abf9f9608121672be000412',
      abbreviation:         'MUSC', is_available:         1)
    institution.save!

    cm = CatalogManager.create(
      organization_id:      institution.id,
      identity_id:          identity.id,
      edit_historic_data: true 
    )
    cm.save!

    provider = FactoryGirl.create(:provider,
      name:                 'South Carolina Clinical and Translational Institute (SCTR)',
      order:                1,
      css_class:            'blue-provider',
      obisid:               '87d1220c5abf9f9608121672be0011ff',
      parent_id:            institution.id,
      abbreviation:         'SCTR1',
      process_ssrs:         0,
      is_available:         1)
    provider.save!

    program = FactoryGirl.create(:program,
      type:                 'Program',
      name:                 'Office of Biomedical Informatics',
      order:                1,
      description:          'The Biomedical Informatics Programs goal is to integrate..',
      obisid:               '87d1220c5abf9f9608121672be021963',
      parent_id:            provider.id,
      abbreviation:         'Informatics',
      process_ssrs:         0,
      is_available:         1)
    program.save!
    
    subsidy_map = SubsidyMap.create(
      organization_id:      program.id,
      max_dollar_cap:       121.0000,
      max_percentage:       12.00
    )
    subsidy_map.save!

    core = FactoryGirl.create(:core,
      type:                 'Core',
      name:                 'Clinical Data Warehouse',
      order:                1,
      obisid:               '179eae3982ab1e4047051381fb7b1610',
      parent_id:            program.id,
      abbreviation:         'Clinical Data Warehouse')
    core.save!

    service = FactoryGirl.create(:service,
      obisid:               '87d1220c5abf9f9608121672be03867a',
      name:                 'MUSC Research Data Request (CDW)',
      abbreviation:         'CDW',
      order:                1,
      cpt_code:             '',
      organization_id:      core.id)
    service.save!
    
    pricing_map = FactoryGirl.create(:pricing_map,
      service_id:                   service.id,
      display_date:                 Date.yesterday,
      effective_date:               Date.yesterday,
      unit_type:                    'Per Query',
      unit_factor:                  1,
      is_one_time_fee:              1,
      full_rate:                    4500.0000,
      exclude_from_indirect_cost:   0,
      unit_minimum:                 1)
    pricing_map.save!

    pricing_setup = FactoryGirl.create(:pricing_setup,
      organization_id:              program.id,
      display_date:                 Date.today,
      effective_date:               Date.today,
      college_rate_type:            'full',
      federal_rate_type:            'full',
      foundation_rate_type:         'full',
      industry_rate_type:           'full',
      investigator_rate_type:       'full',
      internal_rate_type:           'full')
    pricing_setup.save!

  end
  
  def retry_on_timeout(n = 3, &block)
    block.call
  rescue Capybara::TimeoutError, Capybara::ElementNotFound => e
    if n > 0
      puts "Catched error: #{e.message}. #{n-1} more attempts."
      retry_on_timeout(n - 1, &block)
    else
      raise
    end
  end
      
  def default_catalog_manager_setup
    create_default_data
    ## Logs in the default identity.
    visit catalog_manager_root_path
    sign_in
    ## This is used to reveal all nodes in the js tree to make it easier to access during testing.
    page.execute_script("$('#catalog').find('.jstree-closed').attr('class', 'jstree-open');")
  end  
  
end
