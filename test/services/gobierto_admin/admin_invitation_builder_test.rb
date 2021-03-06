# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  class AdminInvitationBuilderTest < ActiveSupport::TestCase
    def admin_invitation_builder
      @admin_invitation_builder ||= begin
        AdminInvitationBuilder.new("wadus@gobierto.dev", site_ids)
      end
    end

    def site
      @site ||= sites(:madrid)
    end

    def admin
      @admin ||= gobierto_admin_admins(:tony)
    end

    def site_ids
      [site.id]
    end

    def test_call
      assert admin_invitation_builder.call
    end

    def test_admin_creation
      assert_difference "Admin.count", 1 do
        admin_invitation_builder.call
      end
    end

    def test_invalid_admin_creation
      refute AdminInvitationBuilder.new(admin.email, site_ids).call

      assert_no_difference "Admin.count" do
        AdminInvitationBuilder.new(admin.email, site_ids).call
      end
    end

    def test_admin_site_assignment
      admin_invitation_builder.call
      assert_equal site_ids, admin_invitation_builder.admin.site_ids
    end
  end
end
