#
# Cookbook Name:: masala_cassandra
# Recipe:: datadog
#
# Copyright 2016, Paytm Labs
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

primary_if = node['network']['interfaces'][node['system']['primary_interface']]
primary_addrs = primary_if['addresses']
primary_addrs_ipv4 = primary_addrs.select { |_addr, attrs| attrs['family'] == 'inet' }
primary_ip = primary_addrs_ipv4.keys.first

if node['masala_base']['dd_enable'] and not node['masala_base']['dd_api_key'].nil?
  node.set['datadog']['cassandra']['instances'] = [
      {
          host: primary_ip,
          port: node['cassandra']['jmx_port'],
          name: node['cassandra']['cluster_name']
      }
  ]
  node.set['datadog']['cassandra']['version'] = (node['cassandra']['version'].to_f >= 2.2) ? 2 : 1
  include_recipe 'datadog::cassandra'
end

# register process monitor
if node['masala_base']['dd_enable'] && !node['masala_base']['dd_api_key'].nil?
  ruby_block "datadog-process-monitor-cassandra" do
    block do
      node.set['masala_base']['dd_proc_mon']['cassandra'] = {
        search_string: ['org.apache.cassandra.service.CassandraDaemon'],
        exact_match: false,
        thresholds: {
         critical: [1, 1]
        }
      }
    end
    notifies :run, 'ruby_block[datadog-process-monitors-render]'
  end
end
