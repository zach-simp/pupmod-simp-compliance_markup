# This should be called *before* any classes upon which you wish to enforce
# policies
#
# @param profiles
#   Compliance profile names that you wish to enforce
#
#   * Must be present in a compliance map
#
class compliance_markup::test (
  $testvariable = 'none',
  $vendoredvariable = 'none',
  $v2variable = 'none',
){
  notify { 'compliance_markup::test::testvariable':
    message => "compliance_markup::test::testvariable = ${testvariable}",
  }
  notify { 'compliance_markup::test::vendoredvariable':
    message => "compliance_markup::test::vendoredvariable = ${vendoredvariable}",
  }
  notify { 'compliance_markup::test::v2variable':
    message => "compliance_markup::test::v2variable = ${v2variable}",
  }
}
