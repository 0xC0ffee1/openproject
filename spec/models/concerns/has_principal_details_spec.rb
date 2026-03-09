# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe HasPrincipalDetails do
  # Test through Group, which is the real consumer of this concern
  let(:group) { create(:group) }

  describe "detail association" do
    it "auto-builds a detail record for new instances" do
      new_group = Group.new(lastname: "Test")
      expect(new_group.detail).to be_present
      expect(new_group.detail).to be_a(GroupDetail)
      expect(new_group.detail).to be_new_record
    end

    it "does not overwrite an existing detail on persisted records" do
      expect(group.detail).to be_persisted
      detail_id = group.detail.id

      reloaded = Group.find(group.id)
      expect(reloaded.detail.id).to eq(detail_id)
    end

    it "destroys the detail when the principal is destroyed" do
      detail_id = group.detail.id
      group.destroy!

      expect(GroupDetail.find_by(id: detail_id)).to be_nil
    end

    it "aliases the concrete association to #detail" do
      expect(group.detail).to eq(group.group_detail)
    end
  end

  describe "attribute delegation" do
    it "delegates simple attribute readers" do
      group.detail.organizational_unit = true
      expect(group.organizational_unit).to be true
    end

    it "delegates simple attribute writers" do
      group.organizational_unit = true
      expect(group.detail.organizational_unit).to be true
    end

    describe "belongs_to association delegation" do
      let(:parent_group) { create(:group) }

      it "delegates the association reader" do
        group.detail.parent = parent_group
        expect(group.parent).to eq(parent_group)
      end

      it "delegates the association writer" do
        group.parent = parent_group
        expect(group.detail.parent).to eq(parent_group)
      end

      it "delegates the _id reader" do
        group.detail.parent_id = parent_group.id
        expect(group.parent_id).to eq(parent_group.id)
      end

      it "delegates the _id writer" do
        group.parent_id = parent_group.id
        expect(group.detail.parent_id).to eq(parent_group.id)
      end
    end
  end

  describe "error promotion" do
    it "promotes detail validation errors onto the principal" do
      group.parent_id = 0

      expect(group).not_to be_valid
      expect(group.errors[:parent]).to be_present
    end

    it "is valid when the detail is valid" do
      expect(group).to be_valid
    end
  end
end
