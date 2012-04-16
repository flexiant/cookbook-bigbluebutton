#
# Cookbook Name:: bigbluebutton
# Recipe:: beta
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

# Make sure that the package list is up to date on Ubuntu/Debian.
include_recipe "apt" if ['debian', 'ubuntu'].member? node[:platform]

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
  code 'echo "deb http://ubuntu.bigbluebutton.org/lucid_dev_08/ bigbluebutton-lucid main" | sudo tee /etc/apt/sources.list.d/bigbluebutton.list'
  not_if { node.attribute?("bigbluebutton_installed") }
end

bash "Ensuring multiverse is enabled" do
  user 'root'
  code 'echo "deb http://us.archive.ubuntu.com/ubuntu/ lucid multiverse" | sudo tee -a /etc/apt/sources.list'
  not_if { node.attribute?("bigbluebutton_installed") }
end

script "Setting up rvmsudo replace sudo" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  mv /usr/bin/sudo /usr/bin/sudo.orig
  if [ `file /usr/bin/sudo.orig | grep bash | wc  -c` != "0" ]
  then
     ln -s /usr/local/rvm/bin/rvmsudo /usr/bin/sudo
  else
     echo "No need to update"
  fi
  sed -i "s/command sudo /command sudo.orig /" /usr/bin/sudo
  EOH
end

gem_package "god" do
  action :install
end

package 'bigbluebutton' do
  not_if { node.attribute?("bigbluebutton_installed") }
end

package 'bbb-demo' do
  not_if { node.attribute?("bigbluebutton_installed") }
  notifies :create, "ruby_block[bigbluebutton_install_flag]", :immediately
  notifies :run, 'bash[Configure bigbluebutton]', :delayed
end

# To be run after the chef run, enqueued by bigbluebutton package installation
bash "Configure bigbluebutton" do
  code "/usr/local/bin/bbb-conf --setip #{node[:fqdn]} && /usr/local/bin/bbb-conf --clean && /usr/local/bin/bbb-conf --check"
  user 'root'
  action :nothing
end