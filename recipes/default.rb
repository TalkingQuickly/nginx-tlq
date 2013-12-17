# Add the stable nginx repo, stock ubuntu version
# tends to be at least one major version behind

# need this for add-apt-repository to work properly
package 'python-software-properties'

bash 'adding stable nginx ppa' do
  user 'root'
  code <<-EOC
    add-apt-repository ppa:nginx/stable
    apt-get update
  EOC
end

# install nginx
package "nginx"

# create the new main nginx config file
# do as little as possible in here, most 
# of this should be configured per site
template "/etc/nginx/nginx.conf" do
  owner "root"
  group "root"
  mode "0644"
  source "nginx.conf.erb"
  notifies :run, "execute[restart-nginx]", :immediately
end

# monit pass through
if @node[:monit_address]
  template "/etc/nginx/sites-enabled/monit" do
    owner "deploy"
    group "deploy"
    mode "0644"
    source "monit_interface.erb"
    notifies :run, "execute[restart-nginx]", :immediately
  end
end

# open port 80
bash "allowing nginx traffic through firewall" do
  user "root"
  code "ufw allow 80 && ufw allow 443"
end

execute "restart-nginx" do
  command "/etc/init.d/nginx restart"
  action :nothing
end
