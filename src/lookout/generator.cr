require "yaml"
require "colorize"

module Lookout
  class Generator
    def generate
      file = nil
      files = Dir.glob("./src/*.cr")

      if files.size > 0
        file = files.first
      end

      if file && File.exists? file
        print "Created #{Lookout::Watcher::CONFIG_FILE}".colorize(:green)
        print " of #{file.colorize(:green)}\n"
        File.write "./#{Lookout::Watcher::CONFIG_FILE}", <<-YAML
files: ./**/*.cr
run: crystal build #{file}
---
files: ./shard.yml
run: crystal deps
YAML
      else
        print "Created #{Lookout::Watcher::CONFIG_FILE}\n".colorize(:green)
        File.write "./#{Lookout::Watcher::CONFIG_FILE}", <<-YAML
files: ./**/*
run: echo "File is changed %file%"
YAML
      end
    end
  end
end
