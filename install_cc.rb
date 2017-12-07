#!/usr/bin/env ruby
require 'fileutils'
require 'digest'

ATOM_URL = 'https://github.com/atom/atom/releases/download/v1.21.1/atom-mac.zip'
ATOM_SHA256_CHECKSUM = 'f8e76f487f347b05ae693e2b9f903656473da3aec75c3647caba0e2b6cea9d62'

# Folder where home is created, and atom download and installed
WORKING_DIR = Dir.pwd
LOCAL_ATOM_PATH = File.join(WORKING_DIR, 'atom')

ATOM_ZIP = 'atom-mac.zip'
ATOM_APP = 'Atom.app'
ATOM_EXECUTABLE = 'Atom.app/Contents/MacOS/Atom'
APM_EXECUTABLE = 'Atom.app/Contents/Resources/app/apm/bin/apm'

ATOM_HOME = 'home'

PLUGINS_TO_INSTALL = %w[
  atom-backspace-death
  atom-backspace-fight
  atom-flashlight
  atom-blank-keyboard
  atom-dvorak
  atom-script
  atom-mirror-mode
  atom-upside-down
  atom-mad-sounds
  atom-random-color
  atom-random-font-size
  atom-strasburger-challenge
  atom-u2i-hackathon
  atom-touchpad
]

def download(what, url, local_path)
  puts "Downloading #{what}..."
  `curl -L #{url} -o #{local_path}`
end

def change_local_dir(dir)
  puts "Changing working directory to #{dir}"
  Dir.chdir(dir)
end

def apm(arguments)
  puts "#{File.join(LOCAL_ATOM_PATH, APM_EXECUTABLE)} #{arguments}"
  `ATOM_HOME=#{File.join(LOCAL_ATOM_PATH, ATOM_HOME)} #{File.join(LOCAL_ATOM_PATH, APM_EXECUTABLE)} #{arguments}`
end

def install_plugin(plugin_name)
  change_local_dir(File.join(WORKING_DIR, plugin_name))
  FileUtils.rm_rf('node_modules')
  `npm install`
  change_local_dir(WORKING_DIR)
  apm("link -d #{plugin_name}")
end

FileUtils.mkdir_p(File.join(LOCAL_ATOM_PATH, ATOM_HOME))

change_local_dir(LOCAL_ATOM_PATH)

if !File.exist?(ATOM_ZIP)
  download('atom', ATOM_URL, ATOM_ZIP)
end

sha256 = Digest::SHA256.file(ATOM_ZIP).hexdigest
raise "Checksum of Atom downloaded to #{File.join(LOCAL_ATOM_PATH, ATOM_ZIP)} doesn't match." if sha256 != ATOM_SHA256_CHECKSUM

if !File.exist?(ATOM_APP)
  puts "Unzipping #{ATOM_ZIP}."
  `unzip #{ATOM_ZIP}`
end

puts 'Running APM'
apm('unlink --dev --all')

puts 'Installing plugins:'
PLUGINS_TO_INSTALL.each_with_index do |plugin_name, index|
  puts "Installing #{plugin_name} (#{index + 1}/#{PLUGINS_TO_INSTALL.size})..."
  install_plugin(plugin_name)
  puts "done"
end

pid = spawn("ATOM_HOME=#{File.join(LOCAL_ATOM_PATH, ATOM_HOME)} #{File.join(LOCAL_ATOM_PATH, ATOM_EXECUTABLE)} -d")
puts "Running Atom. PID: #{pid}"
Process.detach(pid)



