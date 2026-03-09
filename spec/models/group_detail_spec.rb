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

RSpec.describe GroupDetail do
  let(:group) { create(:group) }

  subject { group.detail }

  describe "associations" do
    it { is_expected.to belong_to(:group).with_foreign_key(:principal_id) }
    it { is_expected.to belong_to(:parent).class_name("Group").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_uniqueness_of(:group) }

    describe "parent validation" do
      context "when parent_id is nil" do
        it "is valid" do
          subject.parent_id = nil
          expect(subject).to be_valid
        end
      end

      context "when parent_id references an existing group" do
        let(:parent_group) { create(:group) }

        it "is valid" do
          subject.parent_id = parent_group.id
          expect(subject).to be_valid
        end
      end

      context "when parent_id references a non-existent record" do
        it "is invalid" do
          subject.parent_id = 0
          expect(subject).not_to be_valid
          expect(subject.errors[:parent]).to be_present
        end
      end
    end
  end
end
