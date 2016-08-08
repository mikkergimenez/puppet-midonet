# == Class: midonet
#
# Install all the midonet modules in a single machine with all
# the default parameters.
#
# == Examples
#
# The only way to call this class is using the include reserved word:
#
#     include midonet
#
# To more advanced usage of the midonet puppet module, check out the
# documentation for the midonet's modules:
#
# - midonet::repository
# - midonet::midonet_agent
# - midonet::midonet_api
# - midonet::midonet_cli
# - midonet::neutron_plugin
#
# === Authors
#
# Midonet (http://midonet.org)
#
# === Copyright
#
# Copyright (c) 2015 Midokura SARL, All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class midonet {

    include ::midonet::params

    # Add midonet-agent
    class { 'midonet::agent':
      controller_host => '127.0.0.1',
      metadata_port   => '8775',
      shared_secret   => 'testmido',
      zookeeper_hosts => [{
          'ip' => $::ipaddress}
          ],
    }

    # Add midonet-cluster
    class {'midonet::cluster':
        zookeeper_hosts      => [{
          'ip' => $::ipaddress}
          ],
        cassandra_servers    => ['127.0.0.1'],
        cassandra_rep_factor => '1',
        keystone_admin_token => 'testmido',
        keystone_host        => '127.0.0.1'
    }

    # Add midonet-cli
    class {'midonet::cli':}

    # Register the host (and make sure dependencies are installed)
    if $::osfamily == 'RedHat' {
      $rubygems_pkg_name = 'rubygems'
    }
    elsif $::osfamily == 'Debian' {
      $rubygems_pkg_name = 'ruby'
    }
    else {
      fail("OS ${::operatingsystem} not supported")
    }
    package { $rubygems_pkg_name: ensure => installed, } ->
    exec { "${midonet::params::gem_bin_path} install faraday multipart-post": } ->
    midonet_host_registry { $::hostname:
      ensure          => present,
      midonet_api_url => 'http://127.0.0.1:8181/midonet-api',
      username        => 'midogod',
      password        => 'midogod',
      require         => Class['midonet::agent']
    }

}
