require 'yaml'

CONFIGURATIONS = YAML.load_file('configurations.yml')['configurations']
CONFIG_DIR = File.expand_path(File.dirname(__FILE__))
OUT_DIR = File.expand_path(File.join(File.dirname(__FILE__), "out"))

task :mixins, [:name] do |t, args|
  CONFIGURATIONS[args.name]['mixins'].each do |mixin|
    `cp -rp #{CONFIG_DIR}/files/#{mixin}/* #{OUT_DIR}/#{args.name}/files`
  end
end

task :wifi, [:name] do |t, args|
  config_path = File.join(OUT_DIR, args.name, "/files/etc/config/wireless")
  wlans = CONFIGURATIONS[args.name]['wlans']
  wlan_config = File.read(config_path)

  wlans.each do |id, wlan|
    wlan_config.sub!("<radio#{id}-channel>", wlan['channel'].to_s)
    wlan_config.sub!("<wlan#{id}-macaddr>", wlan['bssid'].to_s)
  end
  wlan_config.gsub!("#	option channel", "	option channel")
  wlan_config.gsub!("#	option macaddr", "	option macaddr")

  File.open(config_path, 'w') do |f|
    f.puts wlan_config
  end
end

task :hostname, [:name] do |t, args|
  `sed -i "s/<hostname>/#{args.name}/g" #{OUT_DIR}/#{args.name}/files/etc/config/system`
  `sed -i "s/<hostname>/#{args.name}/g" #{OUT_DIR}/#{args.name}/files/etc/collectd.conf`
end

task :config, [:name] do |t, args|
  config = CONFIGURATIONS[args.name]['config']
  `cp #{File.join(CONFIG_DIR, "%s.configdiff" % config)} #{File.join(OUT_DIR, args.name)}`
end

task :outdir, [:name] do |t, args|
  `mkdir -p #{File.join(OUT_DIR, args.name, 'files')}`
end

desc 'shit'
task :ap, [:name] => [:outdir, :mixins, :hostname, :wifi]

task :all do
  Rake::Task["ap"].invoke 'ap-bulgaria-1-ac'
end
