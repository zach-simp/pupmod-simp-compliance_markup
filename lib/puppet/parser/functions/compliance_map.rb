module Puppet::Parser::Functions

  newfunction(:compliance_map, :type => :rvalue, :arity => -2, :doc => <<-'ENDHEREDOC') do |args|
    This function provides a mechanism for mapping compliance data to settings in Puppet.

    It is primarily designed for use in classes to validate that parameters are properly set.
    ENDHEREDOC

    args = args.shift.dup

    # Obtain the file position

    # Obtain the list of variables in the class

    # Obtain the associated Hiera variables

    # Map the variables for validation

    # Create the validation report

    # Inject into the catalog
  end
end
