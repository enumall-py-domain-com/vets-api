# frozen_string_literal: true

require 'vetext/service'

module Mobile
  module V0
    class PushNotificationsController < ApplicationController
      def register
        result = service.register(
          params[:app_name],
          params[:device_token],
          @current_user.icn,
          params[:os_name],
          params[:device_name] || params[:osName]
        )

        render json: Mobile::V0::PushRegisterSerializer.new(params[:app_name], result.body[:sid])
      end

      def get_prefs
        render json: Mobile::V0::PushGetPrefsSerializer.new(params[:endpoint_sid],
                                                            service.get_preferences(params[:endpoint_sid]).body)
      end

      def set_prefs
        service.set_preference(params[:endpoint_sid], params[:preference], params[:enabled].to_s.downcase == 'true')

        render json: {}, status: :ok
      end

      def send_notification
        service.send_notification(params[:app_name], @current_user.icn, params[:template_id], params[:personalization])
        render json: {}, status: :ok
      end

      private

      def service
        @service ||= VEText::Service.new
      end
    end
  end
end
