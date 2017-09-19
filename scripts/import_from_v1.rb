require 'json'
require 'yaml'

output_hash = {
  "controls" => {},
  "ce" => {},
  "checks" => {},
  "profiles" => {},
}
params = {}
Dir.glob("../data/compliance_profiles/**/*.json") do |filename|
  data = JSON.parse(File.read(filename))
  data["compliance_markup::compliance_map"].each do |profile, value|
    if (profile != "version")
      value.each do |key, value|
        unless (params.key?(key))
          params[key] = []
        end
        duplicate = false
        value["profiles"] = [ profile ]
        params[key].each do |entry|
          if (entry["value"] == value["value"])
            duplicate = true
            entry["identifiers"].concat(value["identifiers"])
            entry["identifiers"] = entry["identifiers"].uniq
            entry["profiles"] << profile
            entry["profiles"] = entry["profiles"].uniq
          end
        end
        if (duplicate == false)
          params[key] << value
        end
      end
    end
  end
end

params.each do |key, value|
  if (value.size == 1)
    check_name = "oval:simp.shared.#{key}:def:1"
    output_hash["checks"][check_name] = value[0]
  else
    output = "#{key} = "
    value.each do |entry|

      output += "#{entry["profiles"][0]}:#{entry["value"]} "
      if (entry["profiles"].include?("disa_stig"))
        check_name = "oval:simp.disa.#{key}:def:1"
      else
        check_name = "oval:simp.nist.#{key}:def:1"
      end
      output_hash["checks"][check_name] = entry

    end
    puts output
  end
end

output_hash["checks"].each do |checkname, check|
  ce = {}
  controls = {}
  check["identifiers"].each do |identifier|
    ident = identifier.split("(")[0]
    case ident
    when /RHEL-/
      break
    when /CCI-/
      break
    when /SRG-/
      break
    else
      control = ident
    end
    unless (output_hash["controls"].key?(control))
      family = control.split("-")[0]
      output_hash["controls"][control] = {
        "family" => family
      }
    end
    controls[control] = 0
  end
  ce = {
    "controls" => controls
  }
  output_hash["ce"][checkname] = ce
  profiles = check["profiles"]
  profiles.each do |profilename|
    unless output_hash["profiles"].key?(profilename)
      output_hash["profiles"][profilename] = {
        "ces" => []
      }
    end
    output_hash["profiles"][profilename]["ces"] << checkname
  end
end

output_hash["profiles"].each do |key, value|
  value["ces"].sort!
end

#puts output_hash.to_yaml
# vim: set expandtab ts=2 sw=2:
