#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
DATA = File.join(ROOT, "data")
OUT = File.join(ROOT, "docs", "generated")
FileUtils.mkdir_p(OUT)

hosts = YAML.load_file(File.join(DATA, "hosts.yaml"))["hosts"]
services = YAML.load_file(File.join(DATA, "services.yaml"))["services"]

address_lines = [
  "# Address book",
  "",
  "Generated from `data/hosts.yaml` by `tools/generate_docs.rb`. Do not edit by hand.",
  "",
  "| Host | Type | VMID | Power | Address | VLAN | MAC | State |",
  "|---|---|---:|---|---|---|---|---|"
]

hosts.each do |host|
  addresses = Array(host["addresses"])
  addresses = [{}] if addresses.empty?
  addresses.each_with_index do |address, index|
    interface = Array(host["interfaces"]).find do |candidate|
      candidate["vlan"] == address["vlan"] || candidate["name"] == address["interface"]
    end || {}
    address_lines << [
      index.zero? ? host["id"] : "↳",
      index.zero? ? host["kind"] : "",
      index.zero? ? host["vmid"] : "",
      index.zero? ? (host["power_state"] || "—") : "",
      address["ip"] || "—",
      address["vlan"] || address["interface"] || "—",
      interface["mac"] || "—",
      address["status"] || host["status"]
    ].map { |value| value.to_s.gsub("|", "\\|") }.join(" | ").then { |row| "| #{row} |" }
  end
end

endpoint_lines = [
  "# Service endpoints",
  "",
  "Generated from `data/services.yaml` by `tools/generate_docs.rb`. Do not edit by hand.",
  "",
  "| Service | Host | Listener | User URL / public endpoint | Availability | State |",
  "|---|---|---|---|---|---|"
]

services.each do |service|
  listeners = Array(service["listen"]).map do |listener|
    "#{listener['protocol']} #{listener['address']}:#{listener['port']}"
  end
  endpoint = service["url"]
  endpoint = Array(service["urls"]).join("<br>") if endpoint.nil? && service["urls"]
  endpoint ||= service["public_endpoint"]
  endpoint ||= service["future_url"]
  endpoint ||= "—"
  availability = service["availability"] || service["current_availability"] || "—"
  endpoint_lines << "| #{service['id']} | #{service['host']} | #{listeners.join('<br>')} | #{endpoint} | #{availability} | #{service['status']} |"
end

File.write(File.join(OUT, "address-book.md"), address_lines.join("\n") + "\n")
File.write(File.join(OUT, "service-endpoints.md"), endpoint_lines.join("\n") + "\n")
puts "Generated docs/generated/address-book.md and docs/generated/service-endpoints.md"

