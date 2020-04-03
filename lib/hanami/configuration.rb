# frozen_string_literal: true

require "uri"
require "concurrent/hash"
require "concurrent/array"
require "dry/inflector"

module Hanami
  # Hanami application configuration
  #
  # @since 2.0.0
  #
  # rubocop:disable Metrics/ClassLength
  class Configuration
    require "hanami/configuration/cookies"
    require "hanami/configuration/sessions"
    require "hanami/configuration/middleware"
    require "hanami/configuration/security"

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def initialize(env:)
      @settings = Concurrent::Hash.new

      self.env = env
      self.environments = DEFAULT_ENVIRONMENTS.clone

      self.root = Dir.pwd
      self.slices_dir = DEFAULT_SLICES_DIR
      settings[:slices] = {}

      self.settings_path = DEFAULT_SETTINGS_PATH
      self.settings_loader_options = {}

      self.base_url = DEFAULT_BASE_URL

      self.logger   = DEFAULT_LOGGER.clone
      self.rack_logger_filter_params = DEFAULT_RACK_LOGGER_FILTER_PARAMS.clone
      self.routes   = DEFAULT_ROUTES
      self.cookies  = DEFAULT_COOKIES
      self.sessions = DEFAULT_SESSIONS

      self.default_request_format  = DEFAULT_REQUEST_FORMAT
      self.default_response_format = DEFAULT_RESPONSE_FORMAT

      self.middleware = Middleware.new
      self.security   = Security.new

      self.inflections = Dry::Inflector.new
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def finalize
      environment_for(env).each do |blk|
        instance_eval(&blk)
      end

      self
    end

    def environment(name, &blk)
      environment_for(name).push(blk)
    end

    def env=(value)
      settings[:env] = value
    end

    def env
      settings.fetch(:env)
    end

    def root=(root)
      settings[:root] = root
    end

    def root
      settings.fetch(:root)
    end

    def slices_dir=(dir)
      settings[:slices_dir] = dir
    end

    def slices_dir
      settings.fetch(:slices_dir)
    end

    def slices_namespace=(namespace)
      settings[:slices_namespace] = namespace
    end

    def slices_namespace
      settings.fetch(:slices_namespace) { Object }
    end

    def slice(slice_name, &block)
      settings[:slices][slice_name] = block
    end

    def slices
      settings[:slices]
    end

    def settings_path=(value)
      settings[:settings_path] = value
    end

    def settings_path
      settings.fetch(:settings_path)
    end

    def settings_loader=(loader)
      settings[:settings_loader] = loader
    end

    def settings_loader
      settings.fetch(:settings_loader) {
        require "hanami/application/settings/loader"
        settings[:settings_loader] = Application::Settings::Loader
      }
    end

    def settings_loader_options=(options)
      settings[:settings_loader_options] = options
    end

    def settings_loader_options
      settings[:settings_loader_options]
    end

    def base_url=(value)
      settings[:base_url] = URI.parse(value)
    end

    def base_url
      settings.fetch(:base_url)
    end

    def logger=(options)
      settings[:logger] = options
    end

    def logger
      settings.fetch(:logger)
    end

    def rack_logger_filter_params=(params)
      settings[:rack_logger_filter_params] = params
    end

    def rack_logger_filter_params
      settings[:rack_logger_filter_params]
    end

    def routes=(value)
      settings[:routes] = value
    end

    def routes
      settings.fetch(:routes)
    end

    def cookies=(options)
      settings[:cookies] = Cookies.new(options)
    end

    def cookies
      settings.fetch(:cookies)
    end

    def sessions=(*args)
      settings[:sessions] = Sessions.new(args)
    end

    def sessions
      settings.fetch(:sessions)
    end

    def default_request_format=(value)
      settings[:default_request_format] = value
    end

    def default_request_format
      settings.fetch(:default_request_format)
    end

    def default_response_format=(value)
      settings[:default_response_format] = value
    end

    def default_response_format
      settings.fetch(:default_response_format)
    end

    def middleware
      settings.fetch(:middleware)
    end

    def security=(value)
      settings[:security] = value
    end

    def security
      settings.fetch(:security)
    end

    def inflections(&blk)
      if blk.nil?
        settings.fetch(:inflections)
      else
        settings[:inflections] = Dry::Inflector.new(&blk)
      end
    end

    alias inflector inflections

    def router_settings
      {
        base_url: base_url
      }
    end

    def router_resolver=(resolver)
      settings[:router_resolver] = resolver
    end

    def router_resolver
      settings.fetch(:router_resolver) do
        require_relative "application/routing/resolver"
        Application::Routing::Resolver
      end
    end

    def for_each_middleware(&blk)
      stack = middleware.stack.dup
      stack += sessions.middleware if sessions.enabled?

      stack.each(&blk)
    end

    protected

    def environment_for(name)
      settings[:environments][name]
    end

    def environments=(values)
      settings[:environments] = values
    end

    def middleware=(value)
      settings[:middleware] = value
    end

    def inflections=(value)
      settings[:inflections] = value
    end

    private

    DEFAULT_ENVIRONMENTS = Concurrent::Hash.new { |h, k| h[k] = Concurrent::Array.new }
    private_constant :DEFAULT_ENVIRONMENTS

    DEFAULT_SLICES_DIR = "slices"
    private_constant :DEFAULT_SLICES_DIR

    DEFAULT_BASE_URL = "http://0.0.0.0:2300"
    private_constant :DEFAULT_BASE_URL

    DEFAULT_LOGGER = { level: :debug }.freeze
    private_constant :DEFAULT_LOGGER

    DEFAULT_RACK_LOGGER_FILTER_PARAMS = %w[_csrf password password_confirmation].freeze
    private_constant :DEFAULT_RACK_LOGGER_FILTER_PARAMS

    DEFAULT_ROUTES = File.join("config", "routes")
    private_constant :DEFAULT_ROUTES

    DEFAULT_SETTINGS_PATH = File.join("config", "settings")
    private_constant :DEFAULT_SETTINGS_PATH

    DEFAULT_COOKIES = Cookies.null
    private_constant :DEFAULT_COOKIES

    DEFAULT_SESSIONS = Sessions.null
    private_constant :DEFAULT_SESSIONS

    DEFAULT_REQUEST_FORMAT = :html
    private_constant :DEFAULT_REQUEST_FORMAT

    DEFAULT_RESPONSE_FORMAT = :html
    private_constant :DEFAULT_RESPONSE_FORMAT

    attr_reader :settings
  end
  # rubocop:enable Metrics/ClassLength
end
