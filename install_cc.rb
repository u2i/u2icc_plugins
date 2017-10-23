#!/usr/bin/env ruby
require 'fileutils'
require 'digest'

ATOM_URL = 'https://github.com/atom/atom/releases/download/v1.21.1/atom-mac.zip'
LOCAL_ATOM_PATH = './atom'
ATOM_ZIP = 'atom-mac.zip'
ATOM_SHA256_CHECKSUM = 'f8e76f487f347b05ae693e2b9f903656473da3aec75c3647caba0e2b6cea9d62'
ATOM_APP = 'Atom.app'
ATOM_EXECUTABLE = 'Atom.app/Contents/MacOS/Atom'
ATOM_HOME = 'home'

def download(what, url, local_path)
  puts "Downloading #{what}"
  `wget #{url} > #{local_path}`
end

FileUtils.mkdir_p(LOCAL_ATOM_PATH)

puts "Changing working directory to #{LOCAL_ATOM_PATH}"
Dir.chdir(LOCAL_ATOM_PATH)

FileUtils.mkdir_p(ATOM_HOME)

if !File.exist?(ATOM_ZIP)
  download('atom', ATOM_URL, ATOM_ZIP)
end

sha256 = Digest::SHA256.file(ATOM_ZIP).hexdigest
raise "Checksum of atom downloaded to #{File.join(LOCAL_ATOM_PATH, ATOM_ZIP)} doesn't match." if sha256 != ATOM_SHA256_CHECKSUM

if !File.exist?(ATOM_APP)
  puts "Unzipping #{ATOM_ZIP}."
  `unzip #{ATOM_ZIP}`
end

pid = spawn("ATOM_HOME=#{ATOM_HOME} #{ATOM_EXECUTABLE}")
puts "Running Atom. PID: #{pid}"
Process.detach(pid)

