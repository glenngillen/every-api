$:.unshift(File.expand_path("scrubyt/lib", File.dirname(__FILE__)))
require "scrubyt"

@extractor = Scrubyt::Extractor.new do
  fetch "http://www.google.com/"
  fill_textfield "q", "twitter mashup"
  submit
  mashup "//li[@class='g']" do
    title "//h3[@class='r']"
    summary "//div[@class='s']"
  end
end

pp @extractor.results