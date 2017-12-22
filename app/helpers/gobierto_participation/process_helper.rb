# frozen_string_literal: true

module GobiertoParticipation
  module ProcessHelper
    def stage_url(stage)
      case stage.stage_type
      when "information"
        gobierto_participation_process_information_path(process_id: stage.process.slug)
      when "agenda"
        gobierto_participation_process_events_path(process_id: stage.process.slug)
      when "polls"
        gobierto_participation_process_polls_path(process_id: stage.process.slug)
      when "ideas"
        gobierto_participation_process_contribution_containers_path(process_id: current_process.slug)
      when "documents"
        gobierto_participation_process_file_attachments_path(process_id: stage.process.slug)
      when "pages"
        gobierto_participation_process_pages_path(process_id: stage.process.slug)
      end
    end
  end
end
