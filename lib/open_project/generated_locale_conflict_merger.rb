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
      merged = merge_value(
        load_yaml(1, path),
        load_yaml(2, path),
        load_yaml(3, path),
        path:
      )

      raise "no merged content produced" if merged.equal?(MISSING)

      file_writer.write(path, YAML.dump(merged))
      git.add(path)
      out.puts "Auto-resolved #{path}"
      path
    end

    def load_yaml(stage, path)
      git.show(stage, path).then do |contents|
        YAML.safe_load(contents, aliases: true) || {}
      end
    rescue Psych::SyntaxError => e
      raise "invalid YAML in stage #{stage}: #{e.message}"
    rescue Git::MissingStageEntry
      MISSING
    end

    def merge_value(base, ours, theirs, path:)
      resolution = resolve_without_recursion(base, ours, theirs)
      return resolution unless resolution.equal?(UNDECIDED)

      if hash_like?(base) && hash_like?(ours) && hash_like?(theirs)
        merge_hash(base, ours, theirs, path:)
      else
        raise "conflicting scalar values at #{path}"
      end
    end

    def resolve_without_recursion(base, ours, theirs)
      return MISSING if missing?(ours) && missing?(theirs)
      return theirs if equal_value?(ours, base)
      return ours if equal_value?(theirs, base)
      return ours if equal_value?(ours, theirs)

      UNDECIDED
    end

    def merge_hash(base, ours, theirs, path:)
      base_hash = unwrap_hash(base)
      ours_hash = unwrap_hash(ours)
      theirs_hash = unwrap_hash(theirs)

      merged_hash(base_hash, ours_hash, theirs_hash, path)
    end

    def merged_hash(base_hash, ours_hash, theirs_hash, path)
      merged_keys(base_hash, ours_hash, theirs_hash).each_with_object({}) do |key, merged|
        merge_hash_key(base_hash, ours_hash, theirs_hash, path, key, merged)
      end
    end

    def merged_keys(base_hash, ours_hash, theirs_hash)
      (base_hash.keys + ours_hash.keys + theirs_hash.keys).uniq
    end

    def merge_hash_key(base_hash, ours_hash, theirs_hash, path, key, merged)
      merged_value = merge_value(
        fetch(base_hash, key),
        fetch(ours_hash, key),
        fetch(theirs_hash, key),
        path: "#{path}.#{key}"
      )

      merged[key] = merged_value unless missing?(merged_value)
    end

    def hash_like?(value)
      missing?(value) || value.is_a?(Hash)
    end

    def unwrap_hash(value)
      missing?(value) ? {} : value
    end

    def fetch(hash, key)
      hash.key?(key) ? hash[key] : MISSING
    end

    def equal_value?(left, right)
      left == right || (missing?(left) && missing?(right))
    end

    def missing?(value)
      value.equal?(MISSING)
    end

    class Git
      class MissingStageEntry < StandardError; end

      def conflicted_files
        capture!("git", "diff", "--name-only", "--diff-filter=U").lines.map(&:strip).reject(&:empty?)
      end

      def show(stage, path)
        object_id = stage_object_id(stage, path)
        capture!("git", "cat-file", "blob", object_id)
      end

      def add(path)
        system("git", "add", "--", path, exception: true)
      end

      private

      def capture!(*command)
        stdout, status = Open3.capture2e(*command)
        raise "command failed: #{command.join(' ')}" unless status.success?

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
