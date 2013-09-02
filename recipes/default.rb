#
# Cookbook Name:: xdebug
# Recipe:: default
#
# Author:: David King, xforty technologies <dking@xforty.com>
# Contributor:: Patrick Connolly, Myplanet Digital <patrick@myplanetdigital.com>
#
# Copyright 2012, xforty technologies
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

include_recipe "php"

# install xdebug apache module

if platform?(%w{debian ubuntu})
    package "php5-xdebug" do
        action :install
    end
elsif platform?(%w{centos redhat fedora amazon scientific})
    php_pear "xdebug" do
        version node['xdebug']['version']
        action :install
    end
end



xdebug_template_dir = node['php']['ext_conf_dir']

# use symlink on debian/ubuntu
if platform?(%w{debian ubuntu})

    xdebug_template_subdir = "../mods-available"

    link "#{xdebug_template_dir}/20-xdebug.ini" do
          to "#{xdebug_template_subdir}/xdebug.ini"
    end

    xdebug_template_dir.concat("/" + xdebug_template_subdir)
end


# get remote of the host
remote_host = node['xdebug']['remote_host']
if remote_host.nil?
    ip = node[:network][:interfaces][:eth1][:addresses].detect{|k,v| v[:family] == "inet" }.first
    remote_host = ip.gsub(/\.\d+$/, '.1')
end

# get php extension directory
extension_dir = %x[ php -i | grep extension_dir | awk '{print $(NF)}' ].strip

# copy over xdebug.ini to node
template "#{xdebug_template_dir}/xdebug.ini" do
  source "xdebug.ini.erb"
  owner "root"
  group "root"
  mode 0644
  # TODO: Move logic from template to recipe later?
  # variable( :extension_dir => node['php']['php_extension_dir'] )
  variables({
      :extension_dir => extension_dir,
      :remote_host => remote_host
  })
  notifies :restart, resources("service[apache2]"), :delayed
end


file node['xdebug']['remote_log'] do
  owner "root"
  group "root"
  mode "0777"
  action :create_if_missing
  not_if { node['xdebug']['remote_log'].empty? }
end

