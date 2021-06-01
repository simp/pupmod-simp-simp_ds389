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

This is a profile module used by SIMP to configure 389ds LDAP instances
for use within the SIMP ecosystem.

Currently it contains the following instances:

* accounts - Configures a TLS-enabled accounts LDAP instance that will be
     used to hold user accounts and groups and works with other SIMP modules.


### This is a SIMP module

This module is a component of the [System Integrity Management
Platform](https://simp-project.com), a compliance-management framework built on
Puppet.

If you find any issues, submit them to our [bug
tracker](https://simp-project.atlassian.net/).

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

The 389ds instances in this module are configured to work within a SIMP eco system.

Each instance can be used separately.  See the individual instance for instructions
on configuring it.

## Accounts Instance

### Description

The accounts instance, `simp_ds389::instance::accounts`,  will set up a 389ds
LDAP instance to be used for user authentication.

* It installs an configures a 389ds instance with TLS-enabled communication.

  * It can be configured for either TLS and STARTTLS.

* It configures a default password policy the is compliant with most standards.
* It configures a bind user.
* It configures 2 groups:
  - 'user' - group for general users
  - 'administrators' - group to allow administrator access to systems.

* It configures the firewall to allow access to the LDAP instance.

### Usage

To set up a 389ds server to use for user authentication with in a SIMP ecosystem
simply include this module.

include 'simp_ds389::instance::accounts'

If the root DN and bind DN password parameters are not explicitly set,
they will be automatically generated using `simplib::passgen`.

## Reference

Please refer to the inline documentation within each source file, or to
[REFERENCE.md](./REFERENCE.md) for generated reference material.

You may also be interested in the documentation for the
[`simp/ds389`](https://github.com/simp/pupmod-simp-ds389) module, which
is what this module uses to install 389ds and create 389ds instances.

## Limitations

The 389ds management console GUI is not configured.  You can install it
manually if it is needed.

At this time replication is not configured automatically.

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
