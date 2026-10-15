# frozen_string_literal: true

# Records one local data run of the benches. Standard library only.
# Rails is not loaded. A database row is not this record.

require "json"
require "open3"
require "time"

QUESTION = "What does one frozen local pass of the already-specified public paths cost, when the controls in docs/benchmarks.md are printed with the numbers?"

NOT_STARTED = [
  "storage abstraction",
  "Cloudflare/R2 adapter",
  "Apple Core AI execution adapter",
  "virtualization/microkernel authority boundary",
  "cognitive/differential execution research",
  "E27",
].freeze

PINNED_STATE = "58b8db0ebace624abdd96712379cbf5dfb7ce9b9bbfc0c17d1c00482b6c73c02"
PINNED_MOMENT = "01921ef1f4bf0fa708d90d7d8612bc1f320c52152a0a010868026d2eccc18e32"

def argument(flag, default)
  index = ARGV.index(flag)
  return default unless index && ARGV[index + 1]

  Integer(ARGV[index + 1])
end

def version_of(*command)
  stdout, _stderr, status = Open3.capture3(*command)
  status.success? ? stdout.strip : nil
end

def run_command(command, chdir: nil)
  stdout, stderr, status = Open3.capture3(*command, chdir: chdir)
  {
    "command" => command,
    "status" => status.exitstatus,
    "stdout" => stdout,
    "stderr" => stderr,
  }
end

iterations = argument("--iterations", 100)
execute = ARGV.include?("--execute")
root = File.expand_path("..", __dir__)

record = {
  "recorded_at" => Time.now.utc.iso8601,
  "question" => QUESTION,
  "not_a_speedup" => true,
  "not_e27" => true,
  "phases_not_started" => NOT_STARTED,
  "rails_loaded" => false,
  "iterations" => iterations,
  "toolchains" => {
    "swift" => version_of("swift", "--version"),
    "rustc" => version_of("rustc", "--version"),
    "ruby" => RUBY_DESCRIPTION,
    "rails" => version_of("rails", "-v"),
  },
  "pinned_sinks" => {
    "state_32" => PINNED_STATE,
    "moment_stage_commit" => PINNED_MOMENT,
  },
  "runs" => [],
}

if execute
  record["runs"] << run_command(
    ["swift", "run", "--scratch-path", "/tmp/foundation-build", "FoundationBench", "--iterations", iterations.to_s],
    chdir: root,
  )
  record["runs"] << run_command(
    ["cargo", "+1.99.0", "run", "--locked", "--release", "--manifest-path", "rust/commitment-reader/Cargo.toml", "--bin", "commitment-bench", "--", "--iterations", iterations.to_s],
    chdir: root,
  )
  failed = record["runs"].reject { |run| run["status"].zero? }
  drifted = record["runs"].any? do |run|
    text = run["stdout"].to_s
    text.include?("state-commitment-reread") && !text.include?(PINNED_STATE) ||
      text.include?("practice-fixed-log") && !text.include?(PINNED_MOMENT)
  end
  record["accepted"] = failed.empty? && !drifted
else
  record["accepted"] = nil
  record["plan_only"] = true
end

out_dir = File.join(root, "data-runs")
Dir.mkdir(out_dir) unless Dir.exist?(out_dir)
path = File.join(out_dir, "run-#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.json")
File.write(path, JSON.pretty_generate(record))
puts path
puts "accepted=#{record["accepted"].inspect} rails_loaded=false phases_not_started=#{NOT_STARTED.length}"
exit 1 if execute && record["accepted"] == false
