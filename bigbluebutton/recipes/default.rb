#
# Cookbook Name:: bigbluebutton
# Recipe:: default
#
# Copyright 2011, Example Com
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

# MySQL Server install
include_recipe "mysql::server"

# Make sure that the package list is up to date on Ubuntu/Debian.
include_recipe "apt" if [ 'debian', 'ubuntu' ].member? node[:platform]

ruby_block "bigbluebutton_install_flag" do
  block do
    node.set['bigbluebutton_installed'] = true
    node.save
  end
  action :nothing
end

bash "Installing the package key for bigbluebutton repository" do
  user 'root'
  code 'wget http://ubuntu.bigbluebutton.org/bigbluebutton.asc -O- | sudo apt-key add -'
  not_if { node.attribute?("bigbluebutton_installed") }
end

bash "Adding the bigbluebutton repository URL" do
  user 'root'
  if node['bigbluebutton'] && node['bigbluebutton']['beta']
    code 'echo "deb http://ubuntu.bigbluebutton.org/lucid_dev_08/ bigbluebutton-lucid main" | sudo tee /etc/apt/sources.list.d/bigbluebutton.list'
  else
    code 'echo "deb http://ubuntu.bigbluebutton.org/lucid/ bigbluebutton-lucid main" | sudo tee /etc/apt/sources.list.d/bigbluebutton.list'
  end
  not_if { node.attribute?("bigbluebutton_installed") }
end

bash "Ensuring multiverse is enabled" do
  user 'root'
  code 'echo "deb http://us.archive.ubuntu.com/ubuntu/ lucid multiverse" | sudo tee -a /etc/apt/sources.list'
  not_if { node.attribute?("bigbluebutton_installed") }
end

package 'python-software-properties'

bash "Adding repository with bbb-freeswitch-config .deb package" do
  user 'root'
  code 'add-apt-repository  ppa:freeswitch-drivers/freeswitch-nightly-drivers; apt-get update'
  not_if { node.attribute?("bigbluebutton_installed") }
end

unless node['bigbluebutton'] && node['bigbluebutton']['beta']
  package 'bbb-freeswitch-config' do
    not_if { node.attribute?("bigbluebutton_installed") }
  end
end



# BigBlueButton password access to MySQL server
if platform?(%w{debian ubuntu})

  directory "/var/cache/local/preseeding" do
    owner "root"
    group "root"
    mode 0755
    recursive true
  end

  execute "preseed bigbluebutton" do
    command "debconf-set-selections /var/cache/local/preseeding/bigbluebutton.seed"
    action :nothing
  end

  template "/var/cache/local/preseeding/bigbluebutton.seed" do
    source "bigbluebutton.seed.erb"
    owner "root"
    group "root"
    mode "0600"
    notifies :run, resources(:execute => "preseed bigbluebutton"), :immediately
  end
end

# To be run after the chef run, enqueued by bigbluebutton package installation
bash "Configure bigbluebutton" do
  code "/usr/local/bin/bbb-conf --setip #{node[:fqdn]} && /usr/local/bin/bbb-conf --clean && /usr/local/bin/bbb-conf --check"
  user 'root'
  action :nothing
end

package 'bigbluebutton' do
  not_if { node.attribute?("bigbluebutton_installed") }
  notifies :create, "ruby_block[bigbluebutton_install_flag]", :immediately
  notifies :run, 'bash[Configure bigbluebutton]', :delayed
end

cookbook_file "/etc/init.d/red5" do
  source "red5.init"
  mode 0750
  owner "root"
  group "root"
end