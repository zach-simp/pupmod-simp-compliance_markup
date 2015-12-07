[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-compliance_markup.svg)](https://travis-ci.org/simp/pupmod-simp-compliance_markup)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with compliance_markup](#setup)
    * [What compliance_markup affects](#what-compliance_markup-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with compliance_markup](#beginning-with-compliance_markup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
      * [Acceptance Tests - Beaker env variables](#acceptance-tests)

## Overview

This module adds a function `compliance_map()` to the Puppet language. The
`compliance_map()` function provides the ability for users to compare their
in-scope class parameters against a set of *compliant* parameters, either in
Hiera or at the global scope. Users may also provide custom inline policy
documentation and mapping documentation.

The goal of this module is to make it easier for users to both detect, and
report on, deviations from a given policy inside their Puppet codebase.

## Module Description

This module provides the function `compliance_map()` and does not provide any
manifest code.

## Setup

### What compliance_markup affects

Presently, the `compliance_map()` function will create a File resource
targeting `Puppet[:vardir]/compliance_report.yaml`. It may, in the future,
create a file on the server and/or upload materials directly to PuppetDB.

## Usage

This function provides a mechanism for mapping compliance data to settings in
Puppet.

It is primarily designed for use in classes to validate that parameters are
properly set.

When called, the parameters in the calling class will be evaluated against top
level parameters or Hiera data, in that order.

The variable space against which the class parameters will be evaluated must be
structured as the following hash:

```
  compliance::<compliance_profile>::<class_name>::<parameter> :
    'identifier' : 'ID String'
    'value'      : 'Compliant Value'
```

For instance, if you were mapping to NIST 800-53 in the SSH class, you could
use something like the following in Hiera:

```
  compliance::nist_800_53::ssh::permit_root_login :
    'identifier' : 'CCE-1234'
    'value'      : false
```

Alternatively, you may add compliance data to your modules outside of a
parameter mapping. This is useful if you have more advanced logic that is
required to meet a particular internal requirement.

**NOTE:** The parser does not know what line number and, possibly, what file
the function is being called from based on the version of the Puppet parser
being used.

The following optional parameters may be used to add your own compliance data:

```ruby
:compliance_profile => 'A String, or Array, that denotes the compliance
                        profile(s) to which you are mapping.'
:identifier         => 'A unique identifier String for the policy to which you
                        are mapping.'
:notes              => 'An *optional* String that allows for arbitrary notes to
                        include in the compliance report'
```

## Reference

### Example 1 - Standard Usage

**Manifest**

```ruby
class foo (
  $var_one => 'one',
  $var_two => 'two'
) {
  # This will validate all parameters
  compliance_map()
}

$compliance_profile = 'my_policy'

include 'foo'
```

**Hiera.yaml**

```yaml
:backends:
  - 'yaml'
:yaml:
  :datadir: '/path/to/your/hieradata'
:hierarchy:
  "compliance_profiles/%{compliance_profile}"
  "global"
```

**Hieradata**

```yaml
---
# In file /path/to/your/hieradata/compliance_profiles/my_policy.yaml
compliance::my_policy::foo::var_one :
  'identifier' : 'CCE-1234'
  'value' : 'not one'
```

### Example 2 - Custom Compliance Map

```ruby
if $::circumstance {
  compliance_map('nist_800_53','CCE-1234','Note about this section')
  ...code that applies CCE-1234...
}
```

## Limitations

Depending on the version of Puppet being used, the `compliance_map()` function
may not be able to precisely determine where the function has been called and a
best guess may be provided.

## Development

Patches are welcome to the code on the [Onyx Point Github](https://github.com/onyxpoint) account. If you provide code, you are
guaranteeing that you own the rights for the code or you have been given rights
to contribute the code.

### Acceptance tests

To run the tests for this module perform the following actions after installing
`bundler`:

```shell
bundle update
bundle exec rake acceptance
```

## Packaging

Running `rake pkg:rpm[...]` will develop an RPM that is designed to be
integrated into a [SIMP](https://github.com/simp) environment. This module is
not restricted to, or dependent on, the SIMP environment in any way.
