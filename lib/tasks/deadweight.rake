
require 'deadweight'

Deadweight::RakeTask.new do |dw|
	dw.stylesheets = ["/assets/application.css"]
	dw.pages = ['/']
end