#!/usr/bin/env ruby
require 'fileutils'
require 'digest'

##CONFIG:
TEAM_TOKEN = (ENV['TEAM_TOKEN'] || 'winterns').strip

RUBY_INTERPRETER_VERSION = '2.4.2'
NODE_VERSION             = '9.2.0'
PYTHON_VERSION           = '2.7.14'
# GO_VERSION               = '1.9.2'

CABLE_SERVER_URL = (ENV['CABLE_SERVER_URL'] || 'ws://localhost:3000/cable').strip

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

ATOM_URL             = 'https://github.com/atom/atom/releases/download/v1.14.2/atom-mac.zip'
ATOM_SHA256_CHECKSUM = '0ff141e683e8c3d9c0b17def2db7fe05ba05e7dd1b46bae7f3ae3d7d1782452a'

WORKING_DIR     = Dir.pwd
LOCAL_ATOM_PATH = File.join(WORKING_DIR, 'atom') # Folder where home is created, and atom downloaded and installed
ATOM_HOME       = File.join(LOCAL_ATOM_PATH, 'home')
CONFIG_PATH     = File.join(ATOM_HOME, 'config.cson')

ATOM_ZIP        = 'atom-mac.zip'
ATOM_APP        = 'Atom.app'
ATOM_EXECUTABLE = 'Atom.app/Contents/MacOS/Atom'
APM_EXECUTABLE  = 'Atom.app/Contents/Resources/app/apm/bin/apm'

LOGO = <<TEXT
                    ./oyy+ohho-                                                                     
                 :osyssss/---/shy/`                                                                 
             .+syysssssss/------:oyho-`                                                             
          -shysssssssssss/---------:+yhs/.                                                          
      ./ymmmdyyyysssssssy/-------/+oso::ohyo:                                                       
  `:odmmmmmmdyyyyyyyyysyy/---:/+ssssso:----/shy/`                                                   
+smmmmmmmmmmdyyyyyyyyyyyy+/+osssssssss:-------:+yhs.                                                
hdmmmmmmmmmmdyyyyyyyyyyso++sssssssssss:--------:/+dM/                                               
yyyyhdmmmmmmdyyyyyysso+++/--:+osssssss:-----:+osssdMy                                               
yyyyyyyhdmmmdyyyso+++++++/-----:/osyys:-:/+ossssssdMy                                               
yyyyyyyyyyyhhso++++++++++/---------:+o+ossssssssssdMy                          `://ooooso/.`    //ss
yyyyyyyyyso+/`-:/++++++++/---------...+oosssssssssdMy                         `h.`   ` ``-odh. :d` o
yyyyysso++++/````.-/+++++/------.````.++++ossyssyydMy                         `mdmmNNNNmh- .mm..dsod
yyso++++++++/````````-:/+/--..```````.+ooooooossyydMy         -+oys.    /ooy+   .--.   `sy  yM: /hhN
so++++++++++/``````````.:+-``````````.oooooooooossdMy         y` /M+   -s  hM/        `-o. -NN.:d` o
yyyso+++++++/```````.:/++oo+/:.``````.oooooosoo+++hMy         y` /M+   -s  hMo     `:++. .sNN/ :d` o
yyyyyysoo+++/```.-//+++++oooooo+/-```.oossoo++++++hMy         y` /M+   -s  hMo   -++. .+dMdo`  :d` o
yyyyyyyyyyso/.:/+++++++++oooooossss+:-oo++++++++++hMy         y` /M+   -s  hMo  ++``/hMds-     :d` o
yyyyyyyyyyhdy://+++++++++ooossssssyhddoo++++++++++hMy         h` /My   -s  hMo s- :mNs:        :d` o
yyyyyyhddmmmy---://++++++osssssyhdmmmdoooooo++++++hMy         d: .NN` `/s  hMo/s .mMo------.   :d` o
yyyhdmmmmmmmy-------://++ssyhdmmmmmmmdsooossssoo++hMy         +d` -ooo/-`  hMooo `+////////+mh`:d` o
dmmmmmmmmmmmy----------:oydmmmmmmmmmmdsssssssssssymMo          omy+//+ohd++mM:oh+++++++++++oNN.-m++d
ymNNmmmmmmmmy-------:+ydmyoshdmmmmmmmdsssssssyhmNMd/            `:oyyys++sys:  :syyyyyyyyyyyo-  -oyo
  -odMNNmmmmy---:/shmmmmmyoooosydmmmmdssssydmMmy:`                                                  
     ./sNNNmy:oydmmmmmmmmyosssssssyhddyhmNMdo.                                                      
         -+dNNNmmmmmmmmmmyssssssssyydNMmy/                                                          
            `/hNNNmmmmmmmysssssyhmNMho-                                                             
                .odNNNmmmhsyydNMNs/`                                                                
                   `/ymNNdmNMh+-
TEXT

ATOM_CONFIG = <<CSON
"*":
  core:
    automaticallyUpdate: false
    telemetryConsent: "no"
  welcome:
    showOnStartup: false
  "exception-reporting":
    userId: "20f7e564-5f32-429e-a279-9688edbdd5b3"
  "u2i-hackathon":
    cableServerUrl: "#{CABLE_SERVER_URL}"
    commandOverwrites:
      "File Based":
        JavaScript:
          command: "docker"
          prependArgs: ['run', '--rm', '-i', '-w/', '-v/tmp/:/tmp/', 'node', 'node']
        Python:
          command: "docker"
          prependArgs: ['run', '--rm', '-i', '-w/', '-v/tmp/:/tmp/', 'python', 'python']
        Ruby:
          command: "docker"
          prependArgs: ['run', '--rm', '-i', '-w/', '-v/tmp/:/tmp/', 'ruby', 'ruby']
    languages: [
      {
        name: "JavaScript (node.js)"
        extension: "js"
        execDirectory: "/tmp/"
        printVersionCommand: "docker run --rm node:#{NODE_VERSION} node --version"
      }
      {
        name: "Python"
        extension: "py"
        execDirectory: "/tmp/"
        printVersionCommand: "docker run --rm python:#{PYTHON_VERSION} python --version"
      }
      {
        name: "Ruby"
        extension: "rb"
        execDirectory: "/tmp/"
        printVersionCommand: "docker run --rm ruby:#{RUBY_INTERPRETER_VERSION} ruby --version"
      }
    ]
    solutionFolder: "/tmp/u2icc-solutions/"
    token: "#{TEAM_TOKEN}"
CSON

# Utils

def command?(name)
  `which #{name}`
  $?.success?
end

def execute(cmd)
  `#{cmd}`
  raise "Error running #{name}." unless $?.success?
end

def download(what, url, local_path)
  puts "Downloading #{what}..."
  execute("curl -L #{url} -o #{local_path}")
end

def change_local_dir(dir)
  puts "Changing working directory to #{dir}"
  Dir.chdir(dir)
end

def apm(arguments)
  puts "#{File.join(LOCAL_ATOM_PATH, APM_EXECUTABLE)} #{arguments}"
  execute("ATOM_HOME=#{ATOM_HOME} #{File.join(LOCAL_ATOM_PATH, APM_EXECUTABLE)} #{arguments}")
end

def install_plugin(plugin_name)
  change_local_dir(File.join(WORKING_DIR, plugin_name))
  FileUtils.rm_rf('node_modules')
  execute("npm install")
  change_local_dir(WORKING_DIR)
  apm("link -d #{plugin_name}")
end

def configure
  puts "Writing config..."
  File.open(CONFIG_PATH, 'w+') do |file|
    file.puts(ATOM_CONFIG)
  end
end

def install
  puts LOGO

  puts 'Creating paths...'

  FileUtils.mkdir_p(LOCAL_ATOM_PATH)
  FileUtils.mkdir_p(ATOM_HOME)
  change_local_dir(LOCAL_ATOM_PATH)

  puts 'Checking if Atom already downloaded...'
  if !File.exist?(ATOM_ZIP)
    download('atom', ATOM_URL, ATOM_ZIP)
  end
  sha256 = Digest::SHA256.file(ATOM_ZIP).hexdigest
  raise "Checksum of Atom downloaded to #{File.join(LOCAL_ATOM_PATH, ATOM_ZIP)} doesn't match." if sha256 != ATOM_SHA256_CHECKSUM

  if !File.exist?(ATOM_APP)
    puts "Unzipping #{ATOM_ZIP}."
    execute("unzip #{ATOM_ZIP}")
  end

  configure

  puts 'Running APM to install plugins...'
  apm('unlink --dev --all')

  PLUGINS_TO_INSTALL.each_with_index do |plugin_name, index|
    puts "Installing #{plugin_name} (#{index + 1}/#{PLUGINS_TO_INSTALL.size})..."
    install_plugin(plugin_name)
    puts "done"
  end

  puts 'Checking if docker installed...'
  raise 'No docker command found' unless command?('docker')

  docker_images = %W[
  node:#{NODE_VERSION}
  python:#{PYTHON_VERSION}
  ruby:#{RUBY_INTERPRETER_VERSION}
  ]

  docker_images.each do |docker_image_name|
    puts "Pulling #{docker_image_name}. It may take a while..."
    execute("docker pull #{docker_image_name}")
  end
end

def run
  atom_cmd = "ATOM_HOME=#{ATOM_HOME} #{File.join(LOCAL_ATOM_PATH, ATOM_EXECUTABLE)} -d --clear-window-state"
  pid      = spawn(atom_cmd)
  puts "Running Atom. PID: #{pid}"
  Process.detach(pid)
end

case ARGV[0]
  when 'run'
    run
  when 'install'
    install
    run
  when 'configure'
    configure
  else
    puts <<-INFO
      USAGE:
          TEAM_TOKEN='winterns' CABLE_SERVER_URL='ws://localhost:3000/cable' ruby install_cc.rb install
          TEAM_TOKEN='winterns' CABLE_SERVER_URL='ws://localhost:3000/cable' ruby install_cc.rb configure
          ruby install_cc.rb run
    INFO
end
