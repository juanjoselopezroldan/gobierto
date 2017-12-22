# frozen_string_literal: true

module GobiertoAdmin
  module GobiertoParticipation
    module ProcessStagesHelper
      def admin_stage_url(stage)
        case stage.stage_type
        when "information"
          edit_admin_participation_process_process_information_path(id: current_process,
                                                                    process_id: current_process)
        when "agenda"
          admin_participation_process_events_path(stage.process)
        when "polls"
          admin_participation_process_polls_path(stage.process)
        when "ideas"
          admin_participation_process_contribution_containers_path(stage.process)
        when "documents"
          admin_participation_process_file_attachments_path(stage.process)
        when "pages"
          admin_participation_process_pages_path(stage.process)
        end
      end
    end
  end
end
