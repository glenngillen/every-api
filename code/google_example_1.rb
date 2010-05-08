$:.unshift(File.expand_path("scrubyt/lib", File.dirname(__FILE__)))
require "scrubyt"

@extractor = Scrubyt::Extractor.new do
  fetch "http://www.google.com/"
  fill_textfield "q", "twitter mashup"
  submit
  mashup "//li[@class='g']//h3[@class='r']"
end

pp @extractor.results