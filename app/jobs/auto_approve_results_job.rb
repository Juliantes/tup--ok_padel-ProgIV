class AutoApproveResultsJob < ApplicationJob
  queue_as :default

  def perform
    threshold = ENV.fetch("AUTO_APPROVE_AFTER_HOURS", "48").to_i

    Match.pending_auto_approval(threshold_hours: threshold).find_each do |match|
      match.auto_approve_result!
    rescue StandardError => e
      Rails.logger.error("[AutoApproveResultsJob] match_id=#{match.id} #{e.class}: #{e.message}")
    end
  end
end
