#
# Cookbook Name:: stash
# Attributes:: stash
#
# Copyright 2008-2011, Opscode, Inc.
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

# The openssl cookbook supplies the secure_password library to generate random passwords
default[:stash][:virtual_host_name]  = "stash.#{domain}"
default[:stash][:virtual_host_alias] = "stash.#{domain}"
# type-version-standalone
default[:stash][:base_name]	    = "atlassian-stash"
default[:stash][:version]           = "2.1.1"
default[:stash][:install_path]      = "/opt/stash"
default[:stash][:home]              = "/var/lib/stash"
default[:stash][:source]            = "http://www.atlassian.com/software/stash/downloads/binary/#{node[:stash][:base_name]}-#{node[:stash][:version]}.tar.gz"
default[:stash][:run_as]          = "stash"
default[:stash][:min_mem]	    = 384
default[:stash][:max_mem]	    = 768
default[:stash][:ssl]		    = true
default[:stash][:database][:type]   = "mysql"
default[:stash][:database][:host]     = "localhost"
default[:stash][:database][:user]     = "stash"
default[:stash][:database][:name]     = "stash"
default[:stash][:service][:type]      = "jsw"
if node[:opsworks][:instance][:architecture]
  default[:stash][:jsw][:arch]          = node[:opsworks][:instance][:architecture].gsub!(/_/,"-")
else
  default[:stash][:jsw][:arch]          = node[:kernel][:machine].gsub!(/_/,"-")
end
default[:stash][:jsw][:base_name]     = "wrapper-linux-#{node[:stash][:jsw][:arch]}"
default[:stash][:jsw][:version]       = "3.5.20"
default[:stash][:jsw][:install_path]  = ::File.join(node[:stash][:install_path],"#{node[:stash][:base_name]}")
default[:stash][:jsw][:source]        = "http://wrapper.tanukisoftware.com/download/#{node[:stash][:jsw][:version]}/wrapper-linux-#{node[:stash][:jsw][:arch]}-#{node[:stash][:jsw][:version]}.tar.gz"
# Confluence doesn't support OpenJDK http://stash.atlassian.com/browse/CONF-16431
# FIXME: There are some hardcoded paths like JAVA_HOME
set[:java][:install_flavor]    = "oracle"

