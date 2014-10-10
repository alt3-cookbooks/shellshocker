# Exit on Windows platforms
return if node[:platform] == 'windows'

# Download latest shellshocker detection script
git 'Shellshocker' do
  user 'vagrant'
  group 'vagrant'
  repository node[:shellshocker][:repository]
  destination node[:shellshocker][:directory]
end

# Delete flag-file if found
file "#{node[:shellshocker][:directory]}/#{node[:shellshocker][:log]}" do
  action :delete
end

##
# Always run the detection script to scan for previously unknown exploits.
#
# Command used: when the script exits <> 0 run the script again to awk-fetch
# the found vulnerabilities and write them to the flag-file in /tmp so they
# can be displayed later.
#
# ./shellshock_test.sh >/dev/null 2>&1 || ./shellshock_test.sh 2>&1 | awk '/VULNERABLE/' > /tmp/shellshock.detected
##
execute "Shellshocker bash exploit detection" do
  user 'vagrant'
  group 'vagrant'
  command "#{node[:shellshocker][:directory]}/#{node[:shellshocker][:script]} > /dev/null 2>&1 || #{node[:shellshocker][:directory]}/#{node[:shellshocker][:script]} 2>&1 | awk '/VULNERABLE/' > #{node[:shellshocker][:directory]}/#{node[:shellshocker][:log]}"
end

# Screen feedback
ruby_block "Shellshocker feedback" do
  block do
    if !File.exist?("#{node[:shellshocker][:directory]}/#{node[:shellshocker][:log]}")
      puts "==> Shellshocker did not detect any known bash vulnerabilities.";
    else
      content = File.open("#{node[:shellshocker][:directory]}/#{node[:shellshocker][:log]}", 'r'){ |file| file.read }
      puts "==> Shellshocker detected bash vulnerabilities:";
      content.each_line do |line|
        puts "- " + line
      end
    end
  end
end

# Upgrade bash to latest version
package "Bash upgrade to mitigate Shellshock" do
  package_name 'bash'
  action :upgrade
  only_if "test -f #{node[:shellshocker][:directory]}/#{node[:shellshocker][:log]}"
end

##
## Make Shellshocker run at login
## @todo move to separate recipe
##
#template "Run Shellshocker at login" do
#  path "#{node[:shellshocker][:profile_directory]}/run_shellshocker_at_login.sh"
#  source "run_shellshocker_at_login.erb"
#  variables ({
#    :shellshocker_directory => node[:shellshocker][:directory],
#    :shellshocker_script => "#{node[:shellshocker][:directory]}/#{node[:shellshocker][:script]}"
#  })
#end
