$:.unshift(File.expand_path("scrubyt/lib", File.dirname(__FILE__)))
require "scrubyt"

class Twube
  def self.plan(origin, destination)
    extractor = Scrubyt::Extractor.new do
      fetch "http://www.tfl.gov.uk/"
      fill_textfield "name_origin", origin
      fill_textfield "name_destination", destination
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
    puts extractor.results.inspect
    suggestions = extractor.results.reject{|r| r[:suggestion].empty? }
    suggestions.map do |suggestion_hash|
      suggestion_hash[:suggestion].inject({}) do |collection, suggestion|
        suggestion.each do |key,value|
          if key == :trip
            collection[:steps] = value.map{|step| step[:step]}
          else
            collection[key] = value
          end
        end
        collection
      end
    end
  end
end

pp Twube.plan("charing cross", "kentish town")