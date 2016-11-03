require 'yaml'

CONFIGURATIONS = YAML.load_file('configurations.yml')['configurations']
CONFIG_DIR = File.expand_path(File.dirname(__FILE__))
OUT_DIR = File.expand_path(File.join(File.dirname(__FILE__), "out"))

def mixins(name)
  CONFIGURATIONS[name]['mixins'].each do |mixin|
    `cp -rp #{CONFIG_DIR}/files/#{mixin}/* #{OUT_DIR}/#{name}/files`
  end
end

def wifi(name)
  config_path = File.join(OUT_DIR, name, "/files/etc/config/wireless")
  wlans = CONFIGURATIONS[name]['wlans']
  wlan_config = File.read(config_path)

  wlans.each do |id, wlan|
    wlan_config.sub!("<radio#{id}-channel>", wlan['channel'].to_s)
    wlan_config.sub!("<wlan#{id}-macaddr>", wlan['bssid'].to_s)
  end
  #wlan_config.gsub!("#	option channel", "	option channel")
  wlan_config.gsub!("#	option macaddr", "	option macaddr")

  File.open(config_path, 'w') do |f|
    f.puts wlan_config
  end
end

def hostname(name)
  `sed -i "s/<hostname>/#{name}/g" #{OUT_DIR}/#{name}/files/etc/config/system`
  `sed -i "s/<hostname>/#{name}/g" #{OUT_DIR}/#{name}/files/etc/collectd.conf`
end

def ip(name)
  ip = CONFIGURATIONS[name]['ip']
  `sed -i "s/<ip>/#{ip}/g" #{OUT_DIR}/#{name}/files/etc/config/network`
end

def config(name)
  config = CONFIGURATIONS[name]['config']
  `cp #{File.join(CONFIG_DIR, "%s.configdiff" % config)} #{File.join(OUT_DIR, name, '.config')}`
end

def outdir(name)
  `mkdir -p #{File.join(OUT_DIR, name, 'files')}`
end

task :ap, [:name] do |t, args|
  outdir args.name
  mixins args.name
  hostname args.name
  wifi args.name
  ip args.name
  config args.name
end

task :all do
  aps = %W(ap-l0-1 ap-l0-2 ap-l1-1 ap-l1-2 ap-c-1 ap-c-2 ap-ma-1 ap-mu-1 ap-noc-1)
  aps = %W(ap-bg-1 ap-bg-2 ap-bg-3 ap-bg-4)

  aps.each do |ap|
    Rake::Task["ap"].reenable
    Rake::Task["ap"].invoke ap
  end
end
