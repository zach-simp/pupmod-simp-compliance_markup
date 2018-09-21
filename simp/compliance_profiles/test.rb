require 'yaml'
Dir.glob("profile*.yaml") do |filename|
	data = YAML.load(File.read(filename))
	if (data.key?("profiles"))
		data["profiles"].each do |key, value|
			newprofile = {}
			value.each do |nkey, nvalue|
				newhash = {}
				nvalue.each do |control|
					newhash[control] = true
				end
				newprofile[nkey] = newhash
			end
			data["profiles"][key] = newprofile
		end
	end
	File.open(filename, 'w') { |file| file.write(data.to_yaml) }
end
