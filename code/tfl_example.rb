$:.unshift(File.expand_path("scrubyt/lib", File.dirname(__FILE__)))
require "scrubyt"

@extractor = Scrubyt::Extractor.new do
  fetch "http://www.tfl.gov.uk/"
  fill_textfield "name_origin", "charing cross"
  fill_textfield "name_destination", "kentish town"
  submit
  suggestion "//table" do
    departs "//td[@class='depart']", :required => true
    arrives "//td[@class='arrive']", :required => true
    duration "//td[@class='duration']", :required => true
    trip_detail "//td[6]//a" do
      step "//table[@class='routedetails']//tr/td[2]/a"
    end
  end
end

pp @extractor.results
