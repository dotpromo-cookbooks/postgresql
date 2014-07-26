#
# Cookbook Name:: postgresql
# Recipe:: server_redhat
#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright 2009-2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "postgresql::client"

::Chef::Recipe.send(:include, Opscode::PostgresqlHelpers)

version = node['postgresql']['version']
data_dir = node['postgresql']['dir']

# Create a group and user like the package will.
# Otherwise the templates fail.
create_rpm_user_and_group
create_data_dir

install_server_packages

if systemd?
  unless data_dir == "/var/lib/pgsql/#{version}/data"
    path = 'postgresql'
    path << "-#{version}" if node['postgresql']['enable_pgdg_yum']
    template "/etc/systemd/system/#{path}.service" do
      source "postgresql.service.erb"
      mode "0644"
      variables path: path
    end
  end
else
  template "/etc/sysconfig/pgsql/#{node['postgresql']['server']['service_name']}" do
    source "pgsql.sysconfig.erb"
    mode "0644"
    notifies :restart, "service[postgresql]", :delayed
  end
end

setup_command = if systemd?
                  systemd_initdb_cmd
                else
                  sysinit_initdb_cmd
                end
execute setup_command do
  not_if { ::FileTest.exist?(File.join(data_dir, "PG_VERSION")) }
end
