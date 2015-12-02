module Puppet::Parser::Functions
require 'pry'
  newfunction(:compliance_map, :doc => <<-'ENDHEREDOC') do |args|
      This function provides a mechanism for mapping compliance data to
      settings in Puppet.

      It is primarily designed for use in classes to validate that parameters
      are properly set.

      When called, the parameters in the calling class will be evaluated
      against top level parameters or Hiera data, in that order.

      The variable space against which the class parameters will be evaluated
      must be structured as the following hash:

        compliance::<compliance_profile>::<class_name>::<parameter> :
          'identifier' : 'ID String'
          'value'      : 'Compliant Value'

      For instance, if you were mapping to NIST 800-53 in the SSH class, you
      could use something like the following in Hiera:

        compliance::nist_800_53::ssh::permit_root_login :
          'identifier' : 'CCE-1234'
          'value'      : false

      Alternatively, you may add compliance data to your modules outside of a
      parameter mapping. This is useful if you have more advanced logic that is
      required to meet a particular internal requirement.

      The following optional parameters may be used to add your own compliance data:
        :compliance_profile => 'A String that denotes the complince profile to
                                which you are mapping.'
        :identifier         => 'A unique identifier String for the policy to
                                which you are mapping.'
        :notes              => 'An *optional* String that allows for arbitrary
                                notes to include in the compliance report'

      Example:
        if $::circumstance {
          compliance_map('nist_800_53','CCE-1234','Note about this section')
          ...code that applies CCE-1234...
        }
    ENDHEREDOC

    # There is no way to silence the global warnings on looking up a qualified
    # variable, so we're going to hack around it here.
    def self.lookup_global_silent(param)
      find_global_scope.to_hash[param]
    end

    # Pick up our compiler hitchhiker
    hitchhiker = @compiler.instance_variable_get(:@compliance_map_function_data)
    if hitchhiker
      @compliance_map = hitchhiker
    end

    # Set the API version for our report in case we change the format in the
    # future.
    report_api_version = '0.0.1'

    # What profile are we using?
    if args && !args.empty?
      custom_compliance_profile = args.shift
      custom_compliance_identifier = args.shift
      custom_compliance_notes = args.shift

      unless custom_compliance_profile.is_a?(String)
        raise Puppet::ParseError, "compliance_map(): First parameter must be a compliance profile String"
      end

      unless custom_compliance_identifier.is_a?(String)
        raise Puppet::ParseError, "compliance_map(): Second parameter must be a compliance identifier String"
      end

      if custom_compliance_notes
        unless custom_compliance_identifier.is_a?(String)
          raise Puppet::ParseError, "compliance_map(): Third parameter must be a compliance notes String"
        end
      end
    end

    compliance_profile = lookup_global_silent('compliance_profile')

    # Obtain the file position
    file = @source.file
    line = @source.line
    name = @source.name

    unless file
      # We can't figure out where we are at the top level.
      raise Puppet::ParseError, "compliance_map() cannot be used at top scope"
    end

    resource_name = %(#{@resource.type}::#{@resource.title})

    # Obtain the list of variables in the class
    class_params = @resource.parameters.keys

    # Obtain the associated Hiera variables that do not match the settings in
    # the class.
    difference_params = Hash.new
    hiera_unknown = '__COMPLIANCE_UNKNOWN__'

    class_params.each do |param|
      _compliance_namespace = %(compliance::#{compliance_profile}::#{name}::#{param})

      # Allow for ENC Settings
      _found_param = lookup_global_silent(_compliance_namespace)
      unless _found_param
        # If not using an ENC, look in Hiera
        _found_param = function_hiera([_compliance_namespace,hiera_unknown])
      end

      _current_param = @resource.parameters[param].value

      unless _found_param == hiera_unknown
        # Compare the string version of the values, reporting differences in
        # non-string values is not useful.
        if _found_param['value'].to_s != _current_param.to_s
          difference_params[param] = {
            'identifier'    => _found_param['identifier'],
            'compliant_param' => _found_param['value'],
            'system_param'    => _current_param
          }
        end
      end
    end

    # Create the validation report
    unless @compliance_map
      @compliance_map = { 'version' => report_api_version }
    end

    unless @compliance_map['compliance_profiles']
      @compliance_map['compliance_profiles'] = {}
    end

    if compliance_profile && !difference_params.empty?
      unless @compliance_map['compliance_profiles'][compliance_profile]
        @compliance_map['compliance_profiles'][compliance_profile] = {}
      end

      unless @compliance_map['compliance_profiles'][compliance_profile][resource_name]
        @compliance_map['compliance_profiles'][compliance_profile][resource_name] = {}
      end
    end

    if custom_compliance_profile
      unless @compliance_map['compliance_profiles'][custom_compliance_profile]
        @compliance_map['compliance_profiles'][custom_compliance_profile] = {}
      end

      unless @compliance_map['compliance_profiles'][custom_compliance_profile][resource_name]
        @compliance_map['compliance_profiles'][custom_compliance_profile][resource_name] = {}
      end
    end

    generate_report = false
    # Perform the parameter mapping
    unless difference_params.empty?
      unless @compliance_map['compliance_profiles'][compliance_profile][resource_name]['parameters']
        @compliance_map['compliance_profiles'][compliance_profile][resource_name]['parameters'] = []
      end

      difference_params.keys.each do |param|
        @compliance_map['compliance_profiles'][compliance_profile][resource_name]['parameters'] |= [difference_params[param]]
      end

      generate_report = true
    end

    # Add in custom materials if they exist
    if custom_compliance_profile
      unless @compliance_map['compliance_profiles'][custom_compliance_profile][resource_name]['custom_entries']
        @compliance_map['compliance_profiles'][custom_compliance_profile][resource_name]['custom_entries'] = []
      end

      _data_hash = {
        'location' => %(#{file}:#{line}),
        'identifier' => custom_compliance_identifier
      }

      if custom_compliance_notes
        _data_hash['notes'] = custom_compliance_notes
      end

      @compliance_map['compliance_profiles'][custom_compliance_profile][resource_name]['custom_entries'] |= [_data_hash]

      generate_report = true
    end

    if generate_report
      compliance_report_target = %(#{Puppet[:vardir]}/compliance_report.yaml)

      # Retrieve the catalog resource if it already exists, create one if it does
      # not
      compliance_resource = catalog.resources.find{|res| res.type == 'File' && res.name == compliance_report_target}

      if compliance_resource
        # This is a massive hack that should be removed in the future.
        # Some version of Puppet, including the latest 3.X, do not check to see
        # if a resource has the 'remove' capabiltity defined before calling it.
        # We patch in the method here just to work around this issue.
        unless compliance_resource.respond_to?(:remove)
          compliance_resource.define_singleton_method(:remove) do
            # Nothing to do
          end
        end

        catalog.remove_resource(compliance_resource)
      else
        compliance_resource = Puppet::Parser::Resource.new('file',compliance_report_target, :scope => self, :source => self.source)
        compliance_resource.set_parameter('owner',Process.uid)
        compliance_resource.set_parameter('group',Process.gid)
        compliance_resource.set_parameter('mode','0600')
      end
  
      compliance_resource.set_parameter('content',%(#{@compliance_map.to_yaml}\n))
      
      # Inject new information into the catalog
      catalog.add_resource(compliance_resource)

      # This gets a little hairy, we need to persist the compliance map across
      # the entire compilation so we hitch a ride on the compiler.
      @compiler.instance_variable_set(:@compliance_map_function_data, @compliance_map)
    end
  end
end
