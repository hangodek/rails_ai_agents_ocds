#!/usr/bin/env ruby
# frozen_string_literal: true
warn "[DEPRECATED] scripts/sync_claude_to_opencode.rb is superseded by: ruby scripts/sync_ai_to_all.rb --target=opencode"
exec RbConfig.ruby, File.expand_path("sync_ai_to_all.rb", __dir__), "--target=opencode", *ARGV
