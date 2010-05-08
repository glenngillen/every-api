require "#{File.dirname(__FILE__)}/form_helpers.rb"
module Scrubyt
  class ScrapeNextJSONPage < StandardError; end
  module Navigation
    include FormHelpers
    private
      def fetch(url)
        if options[:fetch_page]
          url = options.delete(:fetch_page)
        end
        sleep(@options[:rate_limit]) if @options[:rate_limit]
        full_url = resolve_url(url)
        notify(:fetch, full_url)
        @agent_doc = @agent.get(full_url)
        store_url_helpers(@agent_doc.uri.to_s)
      rescue WWW::Mechanize::ResponseCodeError => err
      rescue Errno::ETIMEDOUT
      rescue EOFError
      rescue SocketError
      end
    
      def fetch_next(result_name, *args)      
        return if options[:fetch_page]  # We are already fetching the next page...
        reset_required_failure!
        clear_current_result!
        locator = args.shift
        opts = args.first || {}
        @options[:limit] ||= 500
        @options[:limit].times do
          @options[:limit] -= 1
          link = parsed_doc.search(clean_xpath(locator)).first
          if link
            url = get_value(link, attribute(opts))
            url = process_proc(url,opts[:script])
            notify(:fetch_page, url)
            full_url = resolve_url(url)
            reset_page_state!
            options.merge!(:fetch_page => full_url)
            if options[:json]
              raise ScrapeNextJSONPage.new(full_url)
            else
              instance_eval(&extractor_definition)
            end
          end
        end
      end
      
      # fetch_detail is called when there is a detail block
      # Detail blocks accept the following options
      #   :required if set to true, will not be saved if one of the fields is missing
      #   :if takes a proc that accepts the url as argument. If the proc return falses the url is skipped
      def fetch_detail(result_name, *args, &block)
        reset_required_failure!
        clear_current_result!
        locator = args.shift
        opts = args.first || {}
        all_required = opts[:required] == :all
        locator = clean_xpath(locator).sub(%r{(/a[^/]*).*}, "\\1")
        parsed_doc.search(locator).each do |element|
          url = get_value(element, attribute(args))
          next if opts[:if] && !opts[:if].call(url)
          full_url = resolve_url(url)
          result_name = result_name.to_s.gsub(/_detail$/,"").to_sym
          notify(:next_detail, result_name, full_url, args)
          options = @options
          options.delete(:hash)
          options[:json] = args.detect{|h| h.has_key?(:json)}[:json].to_json if args.detect{|h| h.has_key?(:json)}
          child_extractor_options = options.merge(:url => full_url, 
                                                   :detail => true)
          child_extractor_options.delete(:fetch_page)
          detail_result = Extractor.new(child_extractor_options, &block).results
          if should_return_result?(detail_result, all_required)
            if options[:detail] && options[:child]
              @results << { result_name => detail_result }
            else
              @results = { result_name => detail_result }
            end
            notify(:save_results, result_name, @results)
          end
        end        
      end
      
      def resolve_url(url)
        case url
        when %r{^http[s]*:|^file:}
          return url
        when %r{^/}
          return previous_base_path + url
        when %r{^\.}
          return append_relative_path(url)
        when /^\?/
          return append_query_string(url)
        when /^\&/
          return previous_page + "?" + replace_querystring_values(url)
        else
          previous_path + url
        end
      end
      
      def append_relative_path(url)
        if previous_was_server_root?
          return previous_base_path + url.sub(%r{^(../)*}, "/")
        end
        append_path(url)
      end

      def key_already_exists?(key)
        previous_query.match(%r{#{key}=[^&]*})
      end

      def previous_was_server_root?
        previous_base_path.sub(%r{/$},"") == previous_path.sub(%r{/$},"")
      end
      
      def append_query_string(url)
        previous_page + url
      end
      
      def append_path(url)
        previous_path + url
      end
      
      def replace_querystring_values(url)
        new_querystring = previous_query
        url.split("&").each do |param|
          if !param.empty?
            key, value = param.split("=")
            if key_already_exists?(key)
              new_querystring.gsub!(%r{#{key}=[^&]*},"#{key}=#{value}")
            else
              new_querystring += "&#{key}=#{value}"
            end
          end
        end
        new_querystring
      end
      
      def store_url_helpers(url)
        @previous_url = url
        @previous_page = url.match(/[^\?]*/)[0]
        @previous_query = nil
        @previous_query = url.match(/\?(.*)/)[1] if has_query_string?(url)
        @previous_base_path = url.match(%r{.*://[^/]*|.*:[^/]*})[0]
        @previous_path = url.match(%r{.*/})[0]
      end
      
      def has_query_string?(url)
        url.match(/\?(.*)/)
      end

  end
end