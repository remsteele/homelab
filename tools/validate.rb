#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "ipaddr"
require "set"

ROOT = File.expand_path("..", __dir__)
DATA = File.join(ROOT, "data")
ALLOWED_STATES = Set.new(%w[confirmed historical planned proposed needs_verification]).freeze

errors = []
documents = {}

Dir[File.join(DATA, "*.yaml")].sort.each do |path|
  begin
    doc = YAML.load_file(path)
    documents[File.basename(path)] = doc
    errors << "#{path}: root must be a mapping" unless doc.is_a?(Hash)
    errors << "#{path}: schema_version must be 1" unless doc.is_a?(Hash) && doc["schema_version"] == 1
  rescue StandardError => e
    errors << "#{path}: YAML parse failed: #{e.message}"
  end
end

expected = %w[
  site.yaml physical.yaml networks.yaml hosts.yaml dns_dhcp.yaml services.yaml
  firewall.yaml storage.yaml media_migrations.yaml connections.yaml security.yaml issues.yaml plans.yaml
  verification.yaml
]
expected.each do |name|
  errors << "data/#{name}: missing" unless documents.key?(name)
end

def walk(value, path = [], &block)
  yield value, path
  case value
  when Hash
    value.each { |key, child| walk(child, path + [key.to_s], &block) }
  when Array
    value.each_with_index { |child, index| walk(child, path + [index.to_s], &block) }
  end
end

documents.each do |name, doc|
  walk(doc) do |value, path|
    next unless path.last == "status"
    next if ALLOWED_STATES.include?(value.to_s)

    errors << "data/#{name}: #{path.join('.')} has unknown state #{value.inspect}"
  end
end

hosts_doc = documents["hosts.yaml"] || {}
hosts = Array(hosts_doc["hosts"])
host_ids = hosts.map { |host| host["id"] }
duplicate_hosts = host_ids.group_by(&:itself).select { |_id, values| values.length > 1 }.keys
duplicate_hosts.each { |id| errors << "data/hosts.yaml: duplicate host id #{id}" }

current_vmids = hosts.map { |host| host["vmid"] }.compact
current_vmids.group_by(&:itself).select { |_id, values| values.length > 1 }.each_key do |id|
  errors << "data/hosts.yaml: duplicate current VMID #{id}"
end

current_ips = {}
hosts.each do |host|
  Array(host["addresses"]).each do |address|
    next unless address.is_a?(Hash) && address["status"] == "confirmed"
    ip = address["ip"].to_s
    begin
      IPAddr.new(ip)
    rescue IPAddr::InvalidAddressError
      errors << "data/hosts.yaml: #{host['id']} has invalid IP #{ip.inspect}"
      next
    end
    if current_ips.key?(ip)
      errors << "data/hosts.yaml: duplicate confirmed IP #{ip} on #{current_ips[ip]} and #{host['id']}"
    else
      current_ips[ip] = host["id"]
    end
  end
end

networks_doc = documents["networks.yaml"] || {}
vlans = Array(networks_doc["vlans"])
vlan_ids = vlans.map { |vlan| vlan["id"] }.to_set
vlans.select { |vlan| vlan["status"] == "confirmed" }.each do |vlan|
  begin
    subnet = IPAddr.new(vlan["subnet"])
    gateway = IPAddr.new(vlan["gateway"])
    errors << "data/networks.yaml: #{vlan['id']} gateway is outside subnet" unless subnet.include?(gateway)
  rescue StandardError => e
    errors << "data/networks.yaml: #{vlan['id']} invalid addressing: #{e.message}"
  end
end

hosts.each do |host|
  Array(host["addresses"]).each do |address|
    next unless address.is_a?(Hash) && address["vlan"]
    errors << "data/hosts.yaml: #{host['id']} references unknown VLAN #{address['vlan']}" unless vlan_ids.include?(address["vlan"])
  end
end

services = Array((documents["services.yaml"] || {})["services"])
service_ids = services.map { |service| service["id"] }
service_ids.group_by(&:itself).select { |_id, values| values.length > 1 }.each_key do |id|
  errors << "data/services.yaml: duplicate service id #{id}"
end
services.each do |service|
  host = service["host"]
  errors << "data/services.yaml: #{service['id']} references unknown host #{host}" unless host_ids.include?(host)
end

dns_doc = documents["dns_dhcp.yaml"] || {}
confirmed_subnets = vlans.select { |vlan| vlan["status"] == "confirmed" }.to_h { |vlan| [vlan["id"], IPAddr.new(vlan["subnet"])] }
Array(dns_doc["dhcp_pools"]).each do |pool|
  subnet = confirmed_subnets[pool["vlan"]]
  unless subnet
    errors << "data/dns_dhcp.yaml: pool references unknown confirmed VLAN #{pool['vlan']}"
    next
  end
  begin
    first = IPAddr.new(pool["start"])
    last = IPAddr.new(pool["end"])
    errors << "data/dns_dhcp.yaml: #{pool['vlan']} pool is outside subnet" unless subnet.include?(first) && subnet.include?(last)
    errors << "data/dns_dhcp.yaml: #{pool['vlan']} pool start is after end" if first.to_i > last.to_i
  rescue StandardError => e
    errors << "data/dns_dhcp.yaml: invalid pool for #{pool['vlan']}: #{e.message}"
  end
end

forbidden_text = [
  /-----BEGIN (?:OPENSSH|RSA|EC|DSA|PRIVATE) PRIVATE KEY-----/,
  /^\s*PrivateKey\s*=/,
  /cloudflare[_ -]api[_ -]token\s*[:=]\s*(?!excluded|<)/i
]
scan_paths = Dir[File.join(ROOT, "**", "*.{yaml,md,txt}")].reject { |path| path.include?("/.git/") }
scan_paths.each do |path|
  text = File.read(path)
  forbidden_text.each do |pattern|
    errors << "#{path}: possible secret material matches #{pattern.inspect}" if text.match?(pattern)
  end
end

if errors.empty?
  puts "Validated #{documents.length} data files, #{hosts.length} current hosts, #{services.length} services, and #{current_ips.length} confirmed host addresses."
  exit 0
end

warn "Validation failed with #{errors.length} error(s):"
errors.each { |error| warn "- #{error}" }
exit 1

