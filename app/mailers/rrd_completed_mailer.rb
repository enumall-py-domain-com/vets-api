# frozen_string_literal: true

class RrdCompletedMailer < ApplicationMailer
  def build(submission)
    @submission = submission
    @disability_struct = RapidReadyForDecision::Constants.first_disability(submission) || {}
    @rrd_status = submission.rrd_status
    @error_message = submission.form.dig('rrd_metadata', 'error') if @rrd_status == 'error'
    @bp_readings_count = submission.form.dig('rrd_metadata', 'med_stats', 'bp_readings_count') || 'N/A'
    @active_medications_count = submission.form.dig('rrd_metadata', 'med_stats', 'medications_count') || 'N/A'
    @asthma_medications_count = submission.form.dig('rrd_metadata', 'med_stats', 'asthma_medications_count') || 'N/A'
    @pdf_guid = submission.form.dig('rrd_metadata', 'pdf_guid') || 'N/A'

    template = File.read('app/mailers/views/rrd_completed_mailer.html.erb')

    environment = "[#{Settings.vsp_environment}] " unless Settings.vsp_environment == 'production'
    mail(
      to: Settings.rrd.event_tracking.recipients,
      subject: "#{environment}RRD claim - #{@disability_struct[:code]} - #{@rrd_status.to_s.humanize}",
      body: ERB.new(template).result(binding)
    )
  end
end
