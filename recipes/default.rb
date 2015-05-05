
#
# Cookbook Name:: stash
# Recipe:: default
#
# Copyright 2013, Appriss Inc.
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'labrea'
include_recipe 'java'

# Install Apache and modules if needed
if node[:stash][:proxy_type] == "apache"
  include_recipe 'apache2'
  include_recipe 'apache2::mod_rewrite'
  include_recipe 'apache2::mod_proxy'
  include_recipe 'apache2::mod_ssl'
end

Chef::Log.info "Install Path is #{node[:stash][:install_path]}"
Chef::Log.info "Basename is #{node[:stash][:base_name]}"

stash_base_dir = File.join(node[:stash][:install_path],node[:stash][:base_name])

# Create a system user account on the server to run the Atlassian Stash server
user node[:stash][:run_as] do
  system true
  shell  '/bin/bash'
  action :create
end

# Create a home directory for the Atlassian Stash user
directory node[:stash][:home] do
  owner node[:stash][:run_as]
end

# Install or Update the Atlassian Stash package
labrea "atlassian-stash" do
  source node[:stash][:source]
  version node[:stash][:version]
  install_dir node[:stash][:install_path]
  config_files [File.join("atlassian-stash-#{node[:stash][:version]}","atlassian-stash","WEB-INF","classes","stash-application.properties"),
	        File.join("atlassian-stash-#{node[:stash][:version]}","conf","server.xml")]
  notifies :run, "execute[configure stash permissions]", :immediately
#  override_path "atlassian-stash-#{node[:stash][:version]}-standalone"
end

# Set the permissions of the Atlassian Stash directory
execute "configure stash permissions" do
  command "chown -R #{node[:stash][:run_as]} #{node[:stash][:install_path]} #{node[:stash][:home]}"
  action :nothing
end

# Install main config file
#template ::File.join(stash_base_dir,"atlassian-stash","WEB-INF","classes","stash-application.properties") do
#  owner node[:stash][:run_as]
#  source "stash-application.properties.erb"
#  mode 0644
#end

# Add the server.xml configuration for Crowd using the erb template
template ::File.join(stash_base_dir,"conf","server.xml") do
  owner node[:stash][:run_as]
  source "server.xml.erb"
  mode 0644
end

# Install service wrapper

wrapper_home = File.join(stash_base_dir,node[:stash][:jsw][:base_name])

labrea node[:stash][:jsw][:base_name] do
  source node[:stash][:jsw][:source]
  version node[:stash][:jsw][:version]
  install_dir node[:stash][:jsw][:install_path]
  config_files [File.join("#{node[:stash][:jsw][:base_name]}-#{node[:stash][:jsw][:version]}","conf","wrapper.conf")]
  notifies :run, "execute[configure wrapper permissions]", :immediately
end

# Configure wrapper permissions
execute "configure wrapper permissions" do
  command "chown -R #{node[:stash][:run_as]} #{wrapper_home} #{wrapper_home}/*"
  action :nothing
end

# Configure wrapper
template File.join(wrapper_home,"conf","wrapper.conf") do
  owner node[:stash][:run_as]
  source "wrapper.conf.erb"
  mode 0644
  variables({
    :wrapper_home => wrapper_home,
    :stash_base_dir => stash_base_dir,
    :newrelic_jar => File.join(stash_base_dir,'newrelic', 'newrelic.jar')
  })
end

# Modify the session-timeout for stash
execute "modify session timeout" do
  command "sed -i 's/<session-timeout>30<\\/session-timeout>/<session-timeout>180<\\/session-timeout>/' #{stash_base_dir}/conf/web.xml"
  action :run
end

#Install NewRelic if configured
if node[:stash][:newrelic][:enabled]
  include_recipe 'newrelic::java-agent'
  #We need to explictly disable JSP autoinstrument
  newrelic_conf = File.join(stash_base_dir, 'newrelic', 'newrelic.yml')
  ruby_block "disable autoinstrument for JSP pages." do 
    block do
      f = Chef::Util::FileEdit.new(newrelic_conf)
      f.search_file_replace(/auto_instrument: true/,'auto_instrument: false')
      f.write_file
    end
  end
end

# Create wrapper startup script
template File.join(wrapper_home,"bin","stash") do
  owner node[:stash][:run_as]
  source "stash-startup.erb"
  mode 0755
  variables({
    :wrapper_home => wrapper_home
  })
  notifies :run, "execute[install startup script]", :immediately
end

# Create shared directory for the configuration data
directory ::File.join("#{node["stash"]["home"]}","shared") do
  owner node[:stash][:run_as]
  group node[:stash][:run_as]
  mode '0755'
  action :create
end

# Add the stash-config.properties configuration for using the erb template
template ::File.join("#{node["stash"]["home"]}","shared","stash-config.properties") do
  owner node[:stash][:run_as]
  source "stash-config.properties.erb"
  mode 0644
  action :create_if_missing
end

execute "install startup script" do
  command "#{::File.join(wrapper_home,"bin","stash")} install"
  action :nothing
  returns [0,1]
  notifies :restart, "service[stash]", :immediately
end

service "stash" do
  action :nothing
end

# Enable the Apache2 proxy_http module
#execute "a2enmod proxy_http" do
#  command "/usr/sbin/a2enmod proxy_http"
#  notifies :restart, resources(:service => "apache2")
#  action :run
#end

# Add the setenv.sh environment script using the erb template
#template File.join("#{node[:stash][:install_path]}/atlassian-stash","/bin/setenv.sh") do
#  owner node[:stash][:run_as]
#  source "setenv.sh.erb"
#  mode 0644
#end

# Setup the virtualhost for Apache
#web_app "stash" do
#  docroot File.join("#{node[:stash][:install_path]}/atlassian-stash","/") 
#  template "stash.vhost.erb"
#  server_name node[:fqdn]
#  server_aliases [node[:hostname], "stash"]
#end
