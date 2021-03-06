require "yaml"
require "colorize"

module Lookout
  class WatcherYML
    YAML.mapping({
      files: String,
      run:   String,
    })
  end

  class Watcher
    CONFIG_FILE = ".lookout.yml"
    setter files
    setter watchers

    def default_yaml
<<-YAML
files: ./**/*
run: echo %file%
YAML
    end

    def initialize(args)
      file = CONFIG_FILE

      @files = [] of String
      @runners = {} of String => Array(String)
      @timestamps = {} of String => String
      @watchers = [] of WatcherYML
      @watchers = args if args

      if File.exists? file
        puts "#{CONFIG_FILE} found..."
        YAML.parse_all(File.read(file)).each do |yaml|
          @watchers << WatcherYML.from_yaml(yaml.to_yaml)
        end
      elsif @watchers.size == 0
        puts "#{CONFIG_FILE} not found, watching current directory"
        @watchers << WatcherYML.from_yaml(default_yaml)
      else
        puts "running custom commands"
        p @watchers
      end

      collect_files
      start_watching
    end

    def start_watching
      puts "😳  #{"Lookout!".colorize(:green)}"
      loop do
        watch_changes
        watch_newfiles
        sleep 1
      end
    end

    def file_creation_date(file : String)
      File.stat(file).mtime.to_s("%Y%m%d%H%M%S")
    end

    def collect_files
      @files = [] of String
      @runners = {} of String => Array(String)
      @timestamps = {} of String => String

      @watchers.each do |watcher|
        Dir.glob(watcher.files) do |file|
          unless File.executable? file
            @files << file
            @timestamps[file] = file_creation_date(file)

            unless @runners.has_key? file
              @runners[file] = [watcher.run]
            else
              @runners[file] << watcher.run
            end
          end
        end
      end
    end

    def run_tasks(file)
      @runners[file].each do |command|
        command = command.gsub(/%file%/, file)
        puts "#{"$".colorize(:dark_gray)} #{command.colorize(:red)}"
        output = `#{command}`
        output.lines.each do |line|
          puts "#{">".colorize(:dark_gray)}    #{line.gsub(/\n$/, "").colorize(:dark_gray)}"
        end
      end
    end

    def watch_changes
      @timestamps.each do |file, file_time|
        begin
          check_time = file_creation_date(file)
          if check_time != file_time
            if File.directory? file
              puts "#{"+".colorize(:green)} #{file}/"
            else
              puts "#{"±".colorize(:yellow)} #{file}"
              is_git = File.exists? "./.git/config"
              if is_git
                git = `which git`.chomp
                unless git.empty?
                  git_stat = `#{git} diff --shortstat -- #{file}`
                  git_stat = git_stat
                    .gsub(/\d+ files? changed,\s+/, "")
                    .gsub(/^\s+|\s+$/, "")
                  puts "#{"└".colorize(:yellow)} #{git_stat.colorize(:dark_gray)}" unless git_stat.empty?
                end
              end
            end
            @timestamps[file] = check_time
            run_tasks file
          end
        rescue
          puts "#{"-".colorize(:red)} #{file}"
          run_tasks file
          collect_files
        end
      end
    end

    def watch_newfiles
      files = [] of String
      @watchers.each do |watcher|
        Dir.glob(watcher.files) do |file|
          unless File.executable? file
            files << file
          end
        end
      end

      if files.size != @files.size
        new_files = files - @files
        new_files.each do |file|
          puts "#{"+".colorize(:green)} #{file}"
          collect_files
          run_tasks file
        end
      end
    end
  end
end
