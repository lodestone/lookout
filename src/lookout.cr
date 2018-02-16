require "./lookout/*"
require "option_parser"

args = [] of Lookout::WatcherYML
files = "./**/*"
runner = "echo %file%"

OptionParser.parse! do |options|
  options.on "-i", "--init", "Generate a .lookout.yml file" do
    Lookout::Generator.new.generate
    exit
  end

  options.on "-v", "--version", "Display the current version number" do
    puts "Lookout (#{Lookout::VERSION})"
    exit
  end

  options.on "-c", "--command=COMMAND", "command to run" do |cmd|
    runner = cmd
  end

  options.on "-w", "--watch=WATCH", "command to run" do |watch|
    files = watch
  end
end

watcher = {files: files, run: runner}
args << Lookout::WatcherYML.from_yaml(watcher.to_yaml)
Lookout::Watcher.new args
