institution = SeedDataHelper.create_institution(1, name: 'Biomedical Informatics Department')
institution = SeedDataHelper.create_institution(1, name: 'University of Utah')
institution = SeedDataHelper.create_institution(1, name: 'National Cancer Institute')
institution = SeedDataHelper.create_institution(1, name: 'National Eye Institute')
institution = SeedDataHelper.create_institution(1, name: 'National Heart Institute')
institution = SeedDataHelper.create_institution(1, name: 'University of California')
institution = SeedDataHelper.create_institution(1, name: 'Center for Clinical and Translational Science')


provider = SeedDataHelper.create_provider(institution.id, 1, name: 'REDCap')
provider = SeedDataHelper.create_provider(institution.id, 1, name: 'Study Design and BioStatisticcs')
provider = SeedDataHelper.create_provider(institution.id, 1, name: 'Foundations for Discovery')

program = SeedDataHelper.create_program(provider.id, name: 'Precision Medicine')
program = SeedDataHelper.create_program(provider.id, name: 'Population Health')
program = SeedDataHelper.create_program(provider.id, name: 'Clinical Trials Support')
program = SeedDataHelper.create_program(provider.id, name: 'Workforce Development')

core = SeedDataHelper.create_core(program.id, name: 'CTRC')
service = SeedDataHelper.create_service(core.id, name: 'Automated DNA Extraction', order: 1)
service = SeedDataHelper.create_service(core.id, name: 'Manual DNA Extraction', order: 2)
service = SeedDataHelper.create_service(core.id, name: 'Automated RNA Extraction', order: 3)
service = SeedDataHelper.create_service(core.id, name: 'Manual RNA Extraction', order: 4)
