require 'sinatra'
require 'sinatra/reloader' if development?
require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

class SefariaDict < Sinatra::Base
  # Configure the application
  configure do
    set :public_folder, 'public'
    set :views, 'views'
    enable :sessions
  end

  # Helper method to fix relative URLs
  helpers do
    def fix_sefaria_links(content)
      sefaria_base = "https://www.sefaria.org"
      if content.is_a?(String)
        content.gsub(/href=["'](?!http)([^"']*)["']/) do
          "href=\"#{sefaria_base}#{$1}\""
        end
      elsif content.is_a?(Hash)
        content.transform_values { |value| fix_sefaria_links(value) }
      elsif content.is_a?(Array)
        content.map { |item| fix_sefaria_links(item) }
      else
        content
      end
    end
    
    def fix_sefaria_url(url)
      return url if url.nil? || url.empty? || url.start_with?('http')
      "https://www.sefaria.org#{url.start_with?('/') ? '' : '/'}#{url}"
    end
  end

  # Base Sefaria API URL
  SEFARIA_API_BASE = "https://www.sefaria.org/api/words"
  
  # Home page
  get '/' do
    erb :index
  end

  # Search endpoint
  get '/search' do
    query = params[:query]
    redirect '/' if query.nil? || query.empty?
    
    encoded_query = URI.encode_www_form_component(query)
    url = URI("#{SEFARIA_API_BASE}/#{encoded_query}")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["accept"] = 'application/json'
    
    response = http.request(request)
    
    @response_code = response.code
    @raw_response = response.body[0..1000]
    if @raw_response.is_a?(String)
      @raw_response = @raw_response.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
    else
      @raw_response = "No raw response available"
    end
    
    if response.code == "200"
      begin
        full_results = JSON.parse(response.body)
        puts "Full results: #{full_results.inspect}"
        @results = Array(full_results).select { |entry| entry["parent_lexicon"] == "Jastrow Dictionary" }
        puts "Filtered @results: #{@results.inspect}"
        @results = fix_sefaria_links(@results)
        @original_query = query
        erb :search_results
      rescue JSON::ParserError => e
        @error = "JSON parse error: #{e.message}"
        erb :error
      end
    else
      @error = "API returned status code: #{response.code}"
      erb :error
    end
  end

  # View a specific term details
  get '/term/:word' do
    word = params[:word]
    encoded_word = URI.encode_www_form_component(word)
    url = URI("#{SEFARIA_API_BASE}/#{encoded_word}")
    @request_url = url.to_s
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["accept"] = 'application/json'
    
    response = http.request(request)
    
    @response_code = response.code
    @raw_response = response.body[0..1000]
    if @raw_response.is_a?(String)
      @raw_response = @raw_response.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
    else
      @raw_response = "No raw response available"
    end
    
    if response.code == "200"
      begin
        @term_data = JSON.parse(response.body)
        @term_data = fix_sefaria_links(@term_data)
        erb :term_details
      rescue JSON::ParserError => e
        @error = "JSON parse error: #{e.message}"
        erb :error
      end
    else
      @error = "API returned status code: #{response.code} for term: #{word}"
      erb :error
    end
  end

  # Error handling
  not_found do
    erb :not_found
  end

  # Start the application
  run! if app_file == $0
end