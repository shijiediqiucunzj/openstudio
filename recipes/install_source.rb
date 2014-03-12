#
# Author:: Nicholas Long (<nicholas.long@.nrel.gov>)
# Cookbook Name:: openstudio
# Recipe:: install_build
#

chef_gem "facter"

# install some extra packages to make this work right.
case node['platform_family']
  when "debian"
    # boost dependencies
    package 'libxext-dev'
    package 'libbz2-dev'                      
    package 'libxt-dev'
    
    # qt dependencies [x11 for webkit(only?)] 
    # qt-4.8 X11 requirements - http://qt-project.org/doc/qt-4.8/requirements-x11.html
    %w(libfontconfig1-dev libfreetype6-dev libx11-dev libxcursor-dev libxext-dev libxfixes-dev libxft-dev libxi-dev libxrandr-dev libxrender-dev).each do |p|
      package p
    end
  when "rhel"
    
    # qt dependencies
    %w(fontconfig-devel freetype-devel libXrandr-devel libXcursor-devel libXfixes-devel libXinerama-devel libXi-devel libXt-devel libXext-devel libX11-devel libSM-devel libICE-devel libXrender-devel ) .each do |p|
      package p
    end
    
    # boost dependencies
    package 'bzip2-devel'
end

include_recipe "ark"

require 'facter'

# Check if the system has enough memory per core for the build process 
number_of_available_cores = node[:openstudio][:source][:cores] || Facter.processorcount.to_i - 1
number_of_available_cores = 1 if number_of_available_cores == 0
available_memory = Facter.memorytotal.to_f

Chef::Log.info "Available Cores: #{number_of_available_cores}. Memory: #{available_memory} GB"
mem_core_ratio = available_memory / number_of_available_cores
Chef::Log.info "Mem:Core Ratio = #{mem_core_ratio}"
raise "Not enough memory per core to build openstudio (#{mem_core_ratio})" if mem_core_ratio < 1

if platform_family?("debian") || platform_family?("rhel")
  ark "openstudio" do
    url "#{node[:openstudio][:source][:url]}/#{node[:openstudio][:source][:version]}.tar.gz"
    version node[:openstudio][:source][:version]
    prefix_root '/usr/local'
    cmake_opts ["-DCMAKE_BUILD_TYPE=Release", "-DBUILD_PACKAGE=true"]
    make_opts ["-j#{number_of_available_cores}", "> build.log 2>&1"]
    make_timeout 3600 * 4 # four hours
    action :install_with_cmake
  end 
else
  Chef::Log.warn("Building on a #{node['platform_family']} system is not yet not supported by this cookbook")
  # If working with RHEL/CENTOS then you need to install specific versions of boost and perhaps
  # other dependencies; however these dependencies are not available by packages and need to be compiled.
end




