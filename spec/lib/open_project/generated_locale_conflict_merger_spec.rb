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

RSpec.describe OpenProject::GeneratedLocaleConflictMerger do
  let(:git) { instance_double(described_class::Git) }
  let(:file_writer) { class_double(File) }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  subject(:merger) do
    described_class.new(
      git:,
      file_writer:,
      out: stdout,
      err: stderr
    )
  end

  describe "#call" do
    let(:generated_path) { "config/locales/crowdin/es.yml" }
    let(:other_path) { "docs/api/apiv3/openapi-spec.yml" }

    before do
      allow(git).to receive(:conflicted_files).and_return(conflicted_files)
      allow(file_writer).to receive(:write)
      allow(git).to receive(:add)
    end

    context "when there are no conflicted files" do
      let(:conflicted_files) { [] }

      it "returns an empty result" do
        result = merger.call

        expect(result.resolved_files).to eq([])
        expect(result.remaining_unresolved_files).to eq([])
      end
    end

    context "when only non-generated files are conflicted" do
      let(:conflicted_files) { [other_path] }

      it "leaves them unresolved" do
        result = merger.call

        expect(result.resolved_files).to eq([])
        expect(result.remaining_unresolved_files).to eq([other_path])
        expect(stderr.string).to include(other_path)
      end
    end

    context "when only one side changed a generated locale file" do
      let(:conflicted_files) { [generated_path] }

      before do
        allow(git).to receive(:show).with(1, generated_path).and_return(<<~YAML)
          ---
          es:
            title: Old
        YAML
        allow(git).to receive(:show).with(2, generated_path).and_return(<<~YAML)
          ---
          es:
            title: Old
        YAML
        allow(git).to receive(:show).with(3, generated_path).and_return(<<~YAML)
          ---
          es:
            title: New
        YAML
      end

      it "writes the changed side and stages the file" do
        result = merger.call

        expect(file_writer).to have_received(:write).with(generated_path, "---\nes:\n  title: New\n")
        expect(git).to have_received(:add).with(generated_path)
        expect(result.resolved_files).to eq([generated_path])
        expect(result.remaining_unresolved_files).to eq([])
      end
    end

    context "when both sides changed different nested keys" do
      let(:conflicted_files) { [generated_path] }

      before do
        allow(git).to receive(:show).with(1, generated_path).and_return(<<~YAML)
          ---
          es:
            first: Old first
            second: Old second
        YAML
        allow(git).to receive(:show).with(2, generated_path).and_return(<<~YAML)
          ---
          es:
            first: New first
            second: Old second
        YAML
        allow(git).to receive(:show).with(3, generated_path).and_return(<<~YAML)
          ---
          es:
            first: Old first
            second: New second
        YAML
      end

      it "merges the nested hash" do
        merger.call

        expect(file_writer).to have_received(:write).with(generated_path, <<~YAML)
          ---
          es:
            first: New first
            second: New second
        YAML
      end
    end

    context "when both sides changed the same leaf differently" do
      let(:conflicted_files) { [generated_path] }

      before do
        allow(git).to receive(:show).with(1, generated_path).and_return(<<~YAML)
          ---
          es:
            title: Old
        YAML
        allow(git).to receive(:show).with(2, generated_path).and_return(<<~YAML)
          ---
          es:
            title: Release value
        YAML
        allow(git).to receive(:show).with(3, generated_path).and_return(<<~YAML)
          ---
          es:
            title: Dev value
        YAML
      end

      it "leaves the file unresolved" do
        result = merger.call

        expect(file_writer).not_to have_received(:write)
        expect(git).not_to have_received(:add)
        expect(result.resolved_files).to eq([])
        expect(result.remaining_unresolved_files).to eq([generated_path])
        expect(stderr.string).to include("Leaving #{generated_path} unresolved")
      end
    end

    context "when a generated locale file contains invalid yaml" do
      let(:conflicted_files) { [generated_path] }

      before do
        allow(git).to receive(:show).with(1, generated_path).and_return("---\nes:\n  title: Old\n")
        allow(git).to receive(:show).with(2, generated_path).and_return("---\nes:\n  title: [broken\n")
        allow(git).to receive(:show).with(3, generated_path).and_return("---\nes:\n  title: New\n")
      end

      it "leaves the file unresolved" do
        result = merger.call

        expect(result.remaining_unresolved_files).to eq([generated_path])
        expect(stderr.string).to include("invalid YAML")
      end
    end

    context "when a key was removed on one side only" do
      let(:conflicted_files) { [generated_path] }

      before do
        allow(git).to receive(:show).with(1, generated_path).and_return(<<~YAML)
          ---
          es:
            keep: Keep
            remove_me: Remove me
        YAML
        allow(git).to receive(:show).with(2, generated_path).and_return(<<~YAML)
          ---
          es:
            keep: Keep
        YAML
        allow(git).to receive(:show).with(3, generated_path).and_return(<<~YAML)
          ---
          es:
            keep: Keep
            remove_me: Remove me
        YAML
      end

      it "keeps the deletion" do
        merger.call

        expect(file_writer).to have_received(:write).with(generated_path, <<~YAML)
          ---
          es:
            keep: Keep
        YAML
      end
    end

    context "when a stage entry is missing for an added file" do
      let(:conflicted_files) { [generated_path] }

      before do
        allow(git).to receive(:show).with(1, generated_path)
                                  .and_raise(described_class::Git::MissingStageEntry, "missing stage 1")
        allow(git).to receive(:show).with(2, generated_path)
                                  .and_raise(described_class::Git::MissingStageEntry, "missing stage 2")
        allow(git).to receive(:show).with(3, generated_path).and_return(<<~YAML)
          ---
          es:
            added: true
        YAML
      end

      it "accepts the added file contents" do
        result = merger.call

        expect(file_writer).to have_received(:write).with(generated_path, "---\nes:\n  added: true\n")
        expect(result.resolved_files).to eq([generated_path])
      end
    end

    context "when generated and non-generated conflicts are mixed" do
      let(:conflicted_files) { [generated_path, other_path] }

      before do
        allow(git).to receive(:show).with(1, generated_path).and_return("---\nes:\n  title: Old\n")
        allow(git).to receive(:show).with(2, generated_path).and_return("---\nes:\n  title: Old\n")
        allow(git).to receive(:show).with(3, generated_path).and_return("---\nes:\n  title: New\n")
      end

      it "resolves only the generated file" do
        result = merger.call

        expect(result.resolved_files).to eq([generated_path])
        expect(result.remaining_unresolved_files).to eq([other_path])
      end
    end
  end
end
