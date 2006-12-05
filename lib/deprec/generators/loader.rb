module Deprec
  module Generators
    class RailsLoader
      def self.load!(options)
        require "#{options[:apply_to]}/config/environment"
        require "rails_generator"
        require "rails_generator/scripts/generate"

        Rails::Generator::Base.sources << Rails::Generator::PathSource.new(
          :deprec, File.dirname(__FILE__))

        args = ["deprec"]
        args << (options[:application] || "Application")
        args << (options[:domain] || "www.mynewsite.com")

        Rails::Generator::Scripts::Generate.new.run(args)
      end
    end
  end
end