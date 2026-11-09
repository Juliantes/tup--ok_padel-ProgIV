# frozen_string_literal: true

module Api
  module V1
    class AddressesController < BaseController
      def autocomplete
        query = params[:q].to_s
        @addresses = if query.strip.length < 3
          []
        else
          AddressAutocomplete.new.call(query)
        end
      rescue AddressAutocomplete::GeoapifyUnavailable
        render_error("address autocomplete unavailable", status: :service_unavailable)
      end
    end
  end
end
