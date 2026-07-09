# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-simp_ds389` is a SIMP *profile* module that stands up a **389 Directory
Server (389ds) instance pre-populated with a SIMP-flavored organizational LDIF
for user accounts**. It wraps `simp/ds389`'s `ds389::instance` defined type,
renders a bootstrap LDIF (users/administrators groups, a host-bind account, a
SUDOers subtree, ACIs, and a no-expire/no-lockout password policy container for
automated accounts), applies a compliance-oriented password policy from module
data, and optionally opens the LDAP ports in the firewall.

The module is **not** a class. Its entire public surface is one *defined type*,
`simp_ds389::instances::accounts` (`manifests/instances/accounts.pp:73`) — there
is no `init.pp` and no `simp_ds389` class. Consumers declare it as a resource
(`simp_ds389::instances::accounts { 'accounts': ... }`); because it is a defined
type, it can be declared more than once to create multiple independent instances,
each keyed by a distinct `$instance_name`.

### Business logic

The module has a single defined type; there are no classes and no other defines.

- **`simp_ds389::instances::accounts`
  (`manifests/instances/accounts.pp:73-133`)** — Public entry defined type (not
  `assert_private()`'d). Key parameters (`accounts.pp:74-92`):
  - `$instance_name` (`String[1]`, default `'accounts'`, `accounts.pp:74`) — the
    unique instance name and the `ds389::instance` resource title.
  - `$base_dn` (`String[2]`, `accounts.pp:75`) — defaults to
    `simplib::lookup('simp_options::ldap::base_dn', { 'default_value' => ... })`
    where the fallback is derived from the node's domain via
    `simplib::ldap::domain_to_dn($facts.get('networking.domain'), true)`.
  - `$root_dn` (`String[2]`, default `'cn=Directory_Manager'`, `accounts.pp:76`)
    — the directory administrator DN. Note the docstring warning
    (`accounts.pp:12-13,18-19`): to work around application bugs, values with
    spaces must not be used for `$root_dn` / `$root_pw`.
  - `$root_pw` (`String[2]`, `accounts.pp:77`) — defaults to a generated
    secret: `simplib::passgen('simp_ds389-rootdn_accounts', { 'length' => 64,
    'complexity' => 0 })`.
  - `$bind_dn` (`String[2]`, `accounts.pp:78`) — defaults to
    `simplib::lookup('simp_options::ldap::bind_dn', ...)` with fallback
    `"cn=hostAuth,ou=Hosts,${base_dn}"`.
  - `$bind_pw` (`String[1]`, `accounts.pp:79`) — defaults to
    `simplib::lookup('simp_options::ldap::bind_pw', ...)` with fallback
    `simplib::passgen("ds389_${instance_name}_bindpw", { 'length' => 64 })`.
  - `$listen_address` (`Simplib::IP`, default `'0.0.0.0'`, `accounts.pp:80`).
  - `$enable_tls` (`Variant[Boolean, Enum['simp']]`, `accounts.pp:81`) — defaults
    to `simplib::lookup('simp_options::pki', { 'default_value' => false })`.
    `'simp'` copies certs from the puppetserver; `true` copies from a local
    directory; `false` disables TLS (`accounts.pp:30-38`).
  - `$firewall` (`Boolean`, `accounts.pp:82`) — defaults to
    `simplib::lookup('simp_options::firewall', { 'default_value' => false })`.
  - `$trusted_nets` (`Simplib::Netlist`, `accounts.pp:83`) — defaults to
    `simplib::lookup('simp_options::trusted_nets', ...)` with fallback
    `['127.0.0.1/32']`.
  - `$port` / `$secure_port` (`Simplib::Port`, defaults `389` / `636`,
    `accounts.pp:84-85`).
  - `$tls_params` / `$instance_params` (`Hash`, default `{}`,
    `accounts.pp:86-87`) — passthrough hashes; `$instance_params` is splatted
    into `ds389::instance` (see below).
  - `$password_policy` (`Ds389::ConfigItem`, **no default in the manifest**,
    `accounts.pp:88`) — required, but satisfied from module data
    (`data/common.yaml:17`), not by the caller. The comment `#data in module`
    marks this.
  - `$users_group_id` / `$administrators_group_id` (`Integer[1]` / `Integer[500]`,
    defaults `100` / `700`, `accounts.pp:91-92`) — POSIX gids baked into the
    bootstrap LDIF.

  Control flow and resources:
  - **Bootstrap LDIF render** (`accounts.pp:95-104`): renders
    `templates/instances/accounts/bootstrap.ldif.epp` via `epp()`, passing
    `base_dn`, `root_dn`, `bind_dn`, `bind_pw`, and the two group ids, into
    `$_bootstrap_ldif_content`. The template emits the domain root entry, a
    Directory Administrators group, `ou=Hosts`/`ou=People`/`ou=Groups`/`ou=SUDOers`
    subtrees, ACIs, `users`/`administrators` posix groups, and a
    no-expire/no-lockout password-policy container for automated accounts.
  - **`ds389::instance { $instance_name }`** (`accounts.pp:106-118`): the core
    resource. Maps this module's params onto the `simp/ds389` defined type
    (`root_pw` → `root_dn_password`, the rendered LDIF → `bootstrap_ldif_content`,
    etc.) and **splats `$instance_params` last with `* => $instance_params`**
    (`accounts.pp:117`) so callers can pass arbitrary additional `ds389::instance`
    arguments.
  - **Firewall branch** (`accounts.pp:120-132`): only when `$firewall` is true.
    Port list is `[$port, $secure_port]` when `$enable_tls` is truthy, else just
    `[$port]` (`accounts.pp:121-125`); it then declares
    `simp_firewalld::rule { "Allow 389DS ${instance_name} instance" }` over
    `$trusted_nets`, `apply_to => 'all'`, tcp `dports => $_ports`
    (`accounts.pp:126-131`).

### Gotchas / non-obvious details

- **There is no `simp_ds389` class and no `init.pp`.** The only definition is
  the defined type `simp_ds389::instances::accounts`. Declare it as a resource;
  `include simp_ds389` will not work. It is *not* auto-included anywhere.
- **It is a defined type, so declare-once assumptions do not hold.** Two
  declarations with the same `$instance_name` will collide on the
  `ds389::instance` title and the firewall rule title (both interpolate
  `$instance_name`); multiple *instances* must each use a unique name.
- **The required `$password_policy` comes from module data, not the caller.**
  It has no manifest default (`accounts.pp:88`), so compilation depends on
  `data/common.yaml:17` (loaded via this module's `hiera.yaml`) providing
  `simp_ds389::instances::accounts::password_policy`. The three passthrough
  hashes have deep-merge `lookup_options` with `knockout_prefix: --`
  (`data/common.yaml:2-14`) — note those `lookup_options` keys are written as
  `simp_ds389::instance::accounts::*` (singular `instance`), which does **not**
  match the actual class path `simp_ds389::instances::accounts::*` (plural). Be
  careful before relying on the merge behavior of `password_policy` /
  `tls_params` / `instance_params`.
- **Secrets are auto-generated by default.** `$root_pw` and `$bind_pw` default to
  `simplib::passgen(...)` (`accounts.pp:77,79`); the values live in the passgen
  store, not in the catalog inputs. Overriding them in the clear is discouraged.
- **`$instance_params` is splatted last** (`accounts.pp:117`), so a key in
  `$instance_params` will override the explicitly-set `ds389::instance` arguments
  above it. Treat it as an escape hatch, not the primary configuration path.
- **`simp_options` is consumed but is not a runtime dependency.** The manifest
  reads the `simp_options::*` seam via `simplib::lookup` (provided by
  `simp/simplib`), yet `simp/simp_options` is not in `metadata.json` — it appears
  only as a fixture (`.fixtures.yml:21`). This is the normal SIMP pattern.
- **No `assert_private()` and no `assert_optional_dependency()` anywhere.** There
  are no optional dependencies; every declared dependency is a hard runtime dep.
- **`$secure_port` is only opened in the firewall when TLS is on**
  (`accounts.pp:121-125`) — enabling `$firewall` without `$enable_tls` opens only
  the plaintext/STARTTLS port.

## The `simp_options` / `simplib::lookup` seam

This is the module's real business-logic seam (the natural target for a
lookup-path unit test). All calls are in `manifests/instances/accounts.pp`:

| Line | Key | `default_value` |
|------|-----|-----------------|
| `accounts.pp:75` | `simp_options::ldap::base_dn` | `sprintf(simplib::ldap::domain_to_dn($facts.get('networking.domain'), true))` |
| `accounts.pp:78` | `simp_options::ldap::bind_dn` | `"cn=hostAuth,ou=Hosts,${base_dn}"` |
| `accounts.pp:79` | `simp_options::ldap::bind_pw` | `simplib::passgen("ds389_${instance_name}_bindpw", { 'length' => 64 })` |
| `accounts.pp:81` | `simp_options::pki` | `false` |
| `accounts.pp:82` | `simp_options::firewall` | `false` |
| `accounts.pp:83` | `simp_options::trusted_nets` | `['127.0.0.1/32']` |

Keep routing SIMP feature toggles through `simplib::lookup('simp_options::*', {
'default_value' => ... })` with an explicit default rather than assuming
`simp_options` is included.

## Dependencies

Module dependencies (from `metadata.json`) — all hard runtime deps; there are
**no** optional dependencies:

- `simp/ds389` `>= 1.0.0 < 3.0.0` (provides the `ds389::instance` defined type
  and the `Ds389::ConfigItem` data type)
- `simp/simplib` `>= 4.9.0 < 6.0.0` (provides `simplib::lookup`,
  `simplib::passgen`, `simplib::ldap::domain_to_dn`, and the `Simplib::IP` /
  `Simplib::Netlist` / `Simplib::Port` data types) — note the unusual
  `< 6.0.0` upper bound
- `simp/simp_firewalld` `>= 0.1.3 < 2.0.0` (provides the `simp_firewalld::rule`
  defined type)
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0`

Fixture-only dependencies (from `.fixtures.yml`, checked out for test
compilation, not runtime deps): `augeas_core`, `augeasproviders_core`,
`firewalld`, `pki`, `systemd`, `vox_selinux`, `selinux`, `simp_openldap`, and
`simp_options` (plus the runtime deps above are also checked out as fixtures).

Runtime requirement (from `metadata.json` `requirements`): `openvox
>= 8.0.0 < 9.0.0`. This is the **new OpenVox baseline** — the module names
`openvox` (not `puppet`) as its runtime; keep this in sync if the requirement
changes.

Supported OS matrix (from `metadata.json`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10.

## Repository layout

- `manifests/instances/accounts.pp` — the sole manifest; the
  `simp_ds389::instances::accounts` defined type (all logic). No `init.pp`.
- `templates/instances/accounts/bootstrap.ldif.epp` — the organizational LDIF
  rendered by the defined type (groups, subtrees, ACIs, SUDOers, password-policy
  container).
- `data/common.yaml` — supplies the required
  `simp_ds389::instances::accounts::password_policy` and the deep-merge
  `lookup_options` for the passthrough hashes.
- `hiera.yaml` — module data hierarchy (v5): OS name+major → OS name → common.
- `metadata.json` — deps, OS matrix, OpenVox requirement.
- `spec/classes/instances/accounts_spec.rb` — rspec-puppet unit tests (default
  compile, params-set, and a bootstrap-LDIF fixture comparison against
  `spec/classes/instances/expected/accounts_bootstrap.txt`).
- `spec/acceptance/suites/default/*` — beaker acceptance suites
  (`01_accounts_spec.rb`, `02_accounts_simp_spec.rb`, `03_accounts_password_spec.rb`);
  15 nodesets under `spec/acceptance/nodesets/`.
- `REFERENCE.md` — generated Puppet Strings reference.
- `types/` and `templates/` contain only `.gitkeep` besides the one template;
  there is **no** `lib/` — this module ships no custom data types, Ruby
  types/providers/functions/facts. Every custom type (`Ds389::ConfigItem`,
  `Simplib::*`) and function (`simplib::*`) comes from the dependencies above.
- **Acceptance runs in CI:** `.github/workflows/pr_tests.yml` has an
  `acceptance` job (matrix `almalinux9`, `almalinux10`) whose final step runs
  `bundle exec rake beaker:suites[default,${{ matrix.node }}]` under
  `BEAKER_HYPERVISOR=vagrant_libvirt`.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run the single defined-type spec
bundle exec rspec spec/classes/instances/accounts_spec.rb

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run the default beaker acceptance suite
bundle exec rake beaker:suites[default]
```

Relevant gem pins (from `Gemfile`): the `puppet_version` default is
`['>= 8', '< 9']`, and the Gemfile installs **both** the `openvox` and `puppet`
gems (`['openvox', 'puppet'].each do |gem_name|`). Other pins:
`puppetlabs_spec_helper ~> 8.0.0`, `simp-rake-helpers ~> 5.24.0`,
`simp-beaker-helpers ~> 2.0.0`, and rubocop `~> 1.88.0`.
`spec/spec_helper.rb` uses `require 'puppetlabs_spec_helper/module_spec_helper'`.

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings on the defined
  type — they drive `REFERENCE.md`. Regenerate `REFERENCE.md` after changing
  docs or parameters.
- Keep the compliance `password_policy` in module data (`data/common.yaml`), not
  hard-coded in the manifest; it is deliberately the module-data default for the
  required `$password_policy` parameter.
- Continue routing SIMP feature toggles through
  `simplib::lookup('simp_options::*', { 'default_value' => ... })` rather than
  assuming `simp_options` is included.
- Keep `$instance_name` interpolated into every per-instance resource title
  (the `ds389::instance` and the `simp_firewalld::rule`) so multiple instances
  stay collision-free.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry a
  **puppetsync** notice — they are baseline-managed and the next sync overwrites
  local edits. Push changes to those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used in `manifests/instances/accounts.pp`.
