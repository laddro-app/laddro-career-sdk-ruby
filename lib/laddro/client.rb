require "net/http"
require "json"
require "uri"

module Laddro
  class Client
    attr_reader :base_url

    def initialize(api_key = nil, base_url: "https://api.laddro.com")
      @api_key = api_key
      @base_url = base_url.chomp("/")
    end

    def list_templates
      get("/v1/templates")["templates"]
    end

    def get_template(template_id)
      get("/v1/templates/#{template_id}")
    end

    def list_fonts
      get("/v1/fonts")["fonts"]
    end

    def list_languages
      get("/v1/languages")["languages"]
    end

    def list_models
      get("/v1/models")["models"]
    end

    def list_resumes(limit: 20, offset: 0)
      get("/v1/resumes?limit=#{limit}&offset=#{offset}")
    end

    def get_resume(resume_id)
      get("/v1/resumes/#{resume_id}")
    end

    def render_resume(resume_id, options)
      put_binary("/v1/resumes/#{resume_id}/render", options)
    end

    def tailor(request)
      post_binary("/v1/tailor", request)
    end

    def tailor_detailed(request)
      post_binary_detailed("/v1/tailor", request)
    end

    def export_pdf(request)
      post_binary("/v1/export", request)
    end

    def list_cover_letters(limit: 20, offset: 0)
      get("/v1/cover-letters?limit=#{limit}&offset=#{offset}")
    end

    def get_cover_letter(id)
      get("/v1/cover-letters/#{id}")
    end

    def create_cover_letter(request)
      post("/v1/cover-letters", request)
    end

    def generate_cover_letter(request)
      post_binary("/v1/cover-letters/generate", request)
    end

    def generate_cover_letter_detailed(request)
      post_binary_detailed("/v1/cover-letters/generate", request)
    end

    def render_cover_letter(id, options)
      put_binary("/v1/cover-letters/#{id}/render", options)
    end

    def get_settings
      get("/v1/settings")
    end

    def update_ai_settings(request)
      put("/v1/settings/model", request)
    end

    def delete_ai_settings
      delete("/v1/settings/model")
    end

    private

    def get(path)
      request(:get, path)
    end

    def post(path, body)
      request(:post, path, body)
    end

    def put(path, body)
      request(:put, path, body)
    end

    def delete(path)
      request(:delete, path)
    end

    def post_binary(path, body)
      request_binary(:post, path, body)
    end

    def post_binary_detailed(path, body)
      request_binary_detailed(:post, path, body)
    end

    def put_binary(path, body)
      request_binary(:put, path, body)
    end

    def request(method, path, body = nil)
      response = execute(method, path, body)
      handle_error(response) unless response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    end

    def request_binary(method, path, body = nil)
      request_binary_detailed(method, path, body)[:data]
    end

    def request_binary_detailed(method, path, body = nil)
      response = execute(method, path, body)
      handle_error(response) unless response.is_a?(Net::HTTPSuccess)
      {
        data: response.body,
        metadata: artifact_metadata(response)
      }
    end

    def execute(method, path, body)
      uri = URI("#{@base_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.read_timeout = 120

      req = case method
            when :get then Net::HTTP::Get.new(uri)
            when :post then Net::HTTP::Post.new(uri)
            when :put then Net::HTTP::Put.new(uri)
            when :delete then Net::HTTP::Delete.new(uri)
            end

      req["x-api-key"] = @api_key if @api_key
      if body
        req["Content-Type"] = "application/json"
        req.body = body.is_a?(String) ? body : JSON.generate(body)
      end

      http.request(req)
    end

    def handle_error(response)
      body = JSON.parse(response.body) rescue {}
      message = body["error"] || response.message
      code = body["code"]
      raise APIError.new(message, response.code.to_i, code)
    end

    def artifact_metadata(response)
      {
        resume_id: response["x-resume-id"],
        cover_letter_id: response["x-cover-letter-id"],
        filename: content_disposition_filename(response["content-disposition"]),
        mime_type: response["content-type"]&.split(";")&.first
      }
    end

    def content_disposition_filename(value)
      return nil unless value

      value.split(";").each do |part|
        key, filename = part.strip.split("=", 2)
        next unless key&.downcase&.start_with?("filename")

        filename = filename.to_s.delete_prefix("UTF-8''").delete_prefix('"').delete_suffix('"')
        return URI.decode_www_form_component(filename)
      end
      nil
    end
  end
end
