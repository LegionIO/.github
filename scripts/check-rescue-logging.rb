#!/usr/bin/env ruby
# frozen_string_literal: true

# Multi-line rescue block analyzer for LegionIO CI.
# Finds rescue blocks that capture an exception variable but never log or re-raise it.
#
# Usage:
#   ruby check-rescue-logging.rb [--severity warning] file1.rb file2.rb ...
#   echo "lib/foo.rb" | ruby check-rescue-logging.rb --stdin
#
# Output: GitHub annotation format (::warning file=X,line=N,title=...)

LOG_PATTERN = /
  Legion::Logging\.(debug|info|warn|error|fatal)\b |
  \blog\.(debug|info|warn|error|fatal)\b           |
  \blogger\.(debug|info|warn|error|fatal)\b         |
  \brunner_exception\b
/x

RAISE_PATTERN = /\braise\b/

RESCUE_CAPTURE = /^\s*rescue\b.*=>\s*(\w+)/

# Lines that close a rescue body
BLOCK_END = /^\s*(end|rescue|ensure|else)\b/

EXCLUDE_GLOBS = [
  '**/spec/**',
  '**/legion-logging/lib/**'
].freeze

severity = 'warning'
use_stdin = false

args = ARGV.dup
while args.first&.start_with?('--')
  flag = args.shift
  case flag
  when '--severity'
    severity = args.shift
  when '--stdin'
    use_stdin = true
  end
end

files = if use_stdin
          $stdin.read.split("\n").map(&:strip).reject(&:empty?)
        else
          args
        end

total = 0
errors = 0

files.each do |file|
  next unless File.exist?(file)
  next if EXCLUDE_GLOBS.any? { |glob| File.fnmatch?(glob, file, File::FNM_PATHNAME) }

  lines = File.readlines(file)
  i = 0
  while i < lines.length
    line = lines[i]
    match = line.match(RESCUE_CAPTURE)
    if match
      rescue_line = i + 1
      rescue_indent = line[/^\s*/].length
      var = match[1]

      # Scan the rescue body
      body_has_log = false
      body_has_raise = false
      j = i + 1
      while j < lines.length
        body_line = lines[j]

        # Stop at the next block boundary at the same or lesser indentation
        if j > i + 1 && body_line.match?(BLOCK_END)
          body_indent = body_line[/^\s*/].length
          break if body_indent <= rescue_indent
        end

        body_has_log = true if body_line.match?(LOG_PATTERN)
        body_has_raise = true if body_line.match?(RAISE_PATTERN)
        break if body_has_log || body_has_raise

        j += 1
      end

      unless body_has_log || body_has_raise
        total += 1
        errors += 1 if severity == 'error'
        puts "::#{severity} file=#{file},line=#{rescue_line},title=rescue-silent-capture" \
             "::Exception captured as `#{var}` but never logged or re-raised. " \
             "Add `log.error(#{var}.message)` or `Legion::Logging.error(#{var}.message)`."
      end
    end
    i += 1
  end
end

$stderr.puts "Rescue logging (multi-line): #{total} findings (#{errors} errors)"
exit(errors.positive? ? 1 : 0)
