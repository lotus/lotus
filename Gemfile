# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "hanami-utils",      "~> 2.0.alpha", require: false, git: "https://github.com/hanami/utils.git",      branch: "unstable"
gem "hanami-router",     "~> 2.0.alpha", require: false, git: "https://github.com/hanami/router.git",     branch: "hanami-application-router-support"
gem "hanami-controller", "~> 2.0.alpha", require: false, git: "https://github.com/hanami/controller.git", branch: "unstable"
gem "hanami-cli",        "~> 1.0.alpha", require: false, git: "https://github.com/hanami/cli.git",        branch: "unstable"

gem "hanami-devtools", require: false, git: "https://github.com/hanami/devtools.git"
