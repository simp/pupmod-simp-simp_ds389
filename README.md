**FIXME**: Ensure the badges are correct and complete, then remove this line!

[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/simp_ds389.svg)](https://forge.puppetlabs.com/simp/simp_ds389)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/simp_ds389.svg)](https://forge.puppetlabs.com/simp/simp_ds389)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-simp_ds389.svg)](https://travis-ci.org/simp/pupmod-simp-simp_ds389)

#### Table of Contents

<!-- vim-markdown-toc GFM -->
1. [Description](#description)
2. [Setup - The basics of getting started with simp_ds389](#setup)
    * [What simp_ds389 affects](#what-simp_ds389-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with simp_ds389](#beginning-with-simp_ds389)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
    * [Acceptance Tests - Beaker env variables](#acceptance-tests)

<!-- vim-markdown-toc -->

## Description

This is a profile module used by SIMP to configure ds389  LDAP instances
for use within the SIMP ecosystem. 

Currently it contains the following instances:

* accounts - Configures an accounts LDAP instance with TLS enabled that will be used to
     hold user accounts and groups and works with other simp modules.


### This is a SIMP module

This module is a component of the [System Integrity Management
Platform](https://simp-project.com), a compliance-management framework built on
Puppet.

If you find any issues, submit them to our [bug
tracker](https://simp-project.atlassian.net/).

**FIXME:** Ensure the *This is a SIMP module* section is correct and complete, then remove this line!

This module is optimally designed for use within a larger SIMP ecosystem, but
it can be used independently:

 * When included within the SIMP ecosystem, security compliance settings will
   be managed from the Puppet server.
 * If used independently, all SIMP-managed security subsystems are disabled by
   default and must be explicitly opted into by administrators.  Please review
   the parameters in
   [`simp/simp_options`](https://github.com/simp/pupmod-simp-simp_options) for
   details.

## Setup

These instances are configured to work within a SIMP eco system.

Each Instance can be used seperately.  See the individual instance for instructions
on configuring it.

## Accounts Instance

### Description
The accounts instance will set up a 389ds LDAP instance to used for user authentication.


* It installs an configures 389ds instance with TLS-enabled communication. It can use
  both legacy TLS and STARTTLS.  It makes use of the pupmod-simp-pki to distribute
  server certificates, making it easy to keep certificates up to date.

* It configures a default password policy the is compliant with most standards.

* It configures a bind user  simp_options::ldap settings.  This bind user is
  used by the pupmod-simp-sssd module  to configure clients to connect to the LDAP server.

* It configures 2 groups:
  - 'user' for general users
  - 'administrators' - used to allow administrator access to systems.  Pupmod-simp-simp
    configures this access in the  simp::admins module.

* It uses the pupmod-simp-simp_firewalld module to configure the firewall on the local system
  to allow remote access restricting access to simp_options::trusted_nets.

### Usage

To set up a 389ds server to use for user authentication with in a SIMP ecosystem
simply include this module.

include 'simp_ds389::instance::accounts'

If passwords are not provided simplib::passgen will automatically generate them.

## Reference

Please refer to the inline documentation within each source file, or to
[REFERENCE.md](./REFERENCE.md) for generated reference material.

## Limitations

The web console is not configured.  You can install it manually if it is needed.

At this time we have not  included setting up replication automatically.

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux
and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

## Development

Please read our [Contribution Guide](https://simp-doc.readthedocs.io/en/stable/contributors_guide/index.html).

### Acceptance tests

This module includes [Beaker](https://github.com/puppetlabs/beaker) acceptance
tests using the SIMP [Beaker Helpers](https://github.com/simp/rubygem-simp-beaker-helpers).
By default the tests use [Vagrant](https://www.vagrantup.com/) with
[VirtualBox](https://www.virtualbox.org) as a back-end; Vagrant and VirtualBox
must both be installed to run these tests without modification. To execute the
tests run the following:

```shell
bundle install
bundle exec rake beaker:suites[default]
```
Some environment variables may be useful:

```shell
BEAKER_debug=true
BEAKER_provision=no
BEAKER_destroy=no
BEAKER_use_fixtures_dir_for_modules=yes
```

* `BEAKER_debug`: show the commands being run on the STU and their output.
* `BEAKER_destroy=no`: prevent the machine destruction after the tests finish so you can inspect the state.
* `BEAKER_provision=no`: prevent the machine from being recreated. This can save a lot of time while you're writing the tests.
* `BEAKER_use_fixtures_dir_for_modules=yes`: cause all module dependencies to be loaded from the `spec/fixtures/modules` directory, based on the contents of `.fixtures.yml`.  The contents of this directory are usually populated by `bundle exec rake spec_prep`.  This can be used to run acceptance tests to run on isolated networks.


Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md)
for more information.
