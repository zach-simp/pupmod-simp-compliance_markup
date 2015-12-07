# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# http://docs.puppetlabs.com/guides/tests_smoke.html
#
class test (
  $var_one = '1',
  $var_two = '2'
) {
  compliance_map()

  compliance_map('pci','CCE-1234',"Don't do things because stuff")

  compliance_map('pci','CCE-0000',"thingy")
}

class test2 {
  compliance_map('pci','CCE-1235',"Don't do things because other stuff")

  compliance_map('XXX','CCE-1111')
}

$compliance_profile = ['pci','XXX']

compliance_map()

compliance_map('pci','CCE-1234',"Don't do things because stuff")

#include 'test'
#include 'test2'
