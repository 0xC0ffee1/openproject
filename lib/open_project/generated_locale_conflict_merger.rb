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

require "open3"
require "yaml"

module OpenProject
  class GeneratedLocaleConflictMerger
    StageContent = Data.define(:raw, :parsed)
    Result = Data.define(:resolved_files, :remaining_unresolved_files)

    GENERATED_LOCALE_PATTERNS = [
      %r{\Aconfig/locales/crowdin/.+\.yml\z},
      %r{\Amodules/[^/]+/config/locales/crowdin/.+\.yml\z}
    ].freeze
    MISSING = Object.new
    UNDECIDED = Object.new

    def initialize(git: Git.new, file_writer: File, out: $stdout, err: $stderr)
      @git = git
      @file_writer = file_writer
      @out = out
      @err = err
    end

    def call
      generated_files, remaining_unresolved_files = partition_conflicted_files
      resolved_files = resolve_generated_files(generated_files, remaining_unresolved_files)
      log_remaining_unresolved_files(remaining_unresolved_files)

      Result.new(
        resolved_files:,
        remaining_unresolved_files:
      )
    end

    private

    attr_reader :err, :file_writer, :git, :out

    def partition_conflicted_files
      git.conflicted_files.partition { |path| generated_locale?(path) }
    end

    def resolve_generated_files(generated_files, remaining_unresolved_files)
      generated_files.each_with_object([]) do |path, resolved|
        resolved << merge_file(path)
      rescue StandardError => e
        err.puts "Leaving #{path} unresolved: #{e.message}"
        remaining_unresolved_files << path
      end
    end

    def log_remaining_unresolved_files(remaining_unresolved_files)
      return if remaining_unresolved_files.empty?

      err.puts "Files still requiring manual resolution:"
      remaining_unresolved_files.each { |path| err.puts "  #{path}" }
    end

    def generated_locale?(path)
      GENERATED_LOCALE_PATTERNS.any? { |pattern| pattern.match?(path) }
    end

    def merge_file(path)
      base, ours, theirs = load_stages(path)

      merged = merge_value(
        base.parsed,
        ours.parsed,
        theirs.parsed,
        path:
      )

      if missing?(merged)
        git.rm(path)
        out.puts "Auto-removed #{path}"
        return path
      end

      write_merged_file(path, merged, base:, ours:, theirs:)
    end

    def load_stage(stage, path)
      git.cat_file(stage, path).then do |contents|
        StageContent.new(
          raw: contents,
          parsed: YAML.safe_load(contents, permitted_classes: [Symbol], aliases: true) || {}
        )
      end
    rescue Psych::SyntaxError => e
      raise "invalid YAML in stage #{stage}: #{e.message}"
    rescue Git::MissingStageEntry
      StageContent.new(raw: nil, parsed: MISSING)
    end

    def load_stages(path)
      (1..3).map { |stage| load_stage(stage, path) }
    end

    def write_merged_file(path, merged, base:, ours:, theirs:)
      file_writer.write(path, raw_yaml_for(merged, base:, ours:, theirs:) || YAML.dump(merged))
      git.add(path)
      out.puts "Auto-resolved #{path}"
      path
    end

    def raw_yaml_for(merged, base:, ours:, theirs:)
      [theirs, ours, base].each do |stage|
        return stage.raw if !missing?(stage.parsed) && merged == stage.parsed
      end

      nil
    end

    def merge_value(base, ours, theirs, path:)
      resolution = resolve_without_recursion(base, ours, theirs)
      return resolution unless resolution.equal?(UNDECIDED)

      if recursive_hash_merge?(base, ours, theirs)
        merge_hash(base, ours, theirs, path:)
      else
        theirs
      end
    end

    def resolve_without_recursion(base, ours, theirs)
      return MISSING if missing?(ours) && missing?(theirs)
      return theirs if ours == base
      return ours if theirs == base
      return ours if ours == theirs

      UNDECIDED
    end

    def merge_hash(base, ours, theirs, path:)
      base, ours, theirs = [base, ours, theirs].map { |value| missing?(value) ? {} : value }

      merge_hash_entries(base, ours, theirs, path)
    end

    def merge_hash_entries(base, ours, theirs, path)
      (base.keys + ours.keys + theirs.keys).uniq.each_with_object({}) do |key, merged|
        merged_value = merge_value(
          base.fetch(key, MISSING),
          ours.fetch(key, MISSING),
          theirs.fetch(key, MISSING),
          path: "#{path}.#{key}"
        )

        merged[key] = merged_value unless missing?(merged_value)
      end
    end

    def recursive_hash_merge?(base, ours, theirs)
      [base, ours, theirs].all? { |value| missing?(value) || value.is_a?(Hash) }
    end

    def missing?(value)
      value.equal?(MISSING)
    end

    class Git
      class MissingStageEntry < StandardError; end

      def conflicted_files
        capture!("git", "diff", "--name-only", "--diff-filter=U").lines.map(&:strip).reject(&:empty?)
      end

      def cat_file(stage, path)
        object_id = stage_object_id(stage, path)
        capture!("git", "cat-file", "blob", object_id)
      end

      def add(path)
        system("git", "add", "--", path, exception: true)
      end

      def rm(path)
        system("git", "rm", "--", path, exception: true)
      end

      private

      def capture!(*command)
        stdout, status = Open3.capture2e(*command)
        unless status.success?
          message = "command failed: #{command.join(' ')}"
          message << "\n\nOutput:\n#{stdout}" unless stdout.strip.empty?
          raise message
        end

        stdout
      end

      def stage_object_id(stage, path)
        output = capture!("git", "ls-files", "--stage", "--", path)
        object_id = output.lines.filter_map do |line|
          _mode, sha, line_stage, _path = line.split(/\s+/, 4)
          sha if line_stage == stage.to_s
        end.first

        raise MissingStageEntry, "missing stage #{stage}" if object_id.nil?

        object_id
      end
    end
  end
end
