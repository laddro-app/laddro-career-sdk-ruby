#!/usr/bin/env ruby

require_relative "../lib/laddro"

API_KEY = ENV["LADDRO_API_KEY"]
abort "Set LADDRO_API_KEY" unless API_KEY

$passed = 0
$failed = 0

def test(name)
  yield
  puts "  ✓ #{name}"
  $passed += 1
rescue => e
  puts "  ✗ #{name}: #{e.message}"
  $failed += 1
end

puts "\n— Public endpoints —\n\n"

test("list templates") do
  client = Laddro.new
  templates = client.list_templates
  raise "expected 20+, got #{templates.length}" unless templates.length >= 20
  puts "    → #{templates.length} templates"
end

test("get template GRAPHITE") do
  client = Laddro.new
  detail = client.get_template("GRAPHITE")
  raise "wrong id" unless detail["id"] == "GRAPHITE"
  raise "no colors" if detail["availableColors"].empty?
  puts "    → #{detail['availableColors'].length} colors"
end

test("list fonts") do
  client = Laddro.new
  fonts = client.list_fonts
  raise "expected 20+, got #{fonts.length}" unless fonts.length >= 20
  puts "    → #{fonts.length} fonts"
end

test("list languages") do
  client = Laddro.new
  languages = client.list_languages
  raise "expected 14, got #{languages.length}" unless languages.length == 14
  puts "    → #{languages.length} languages"
end

test("list models") do
  client = Laddro.new
  models = client.list_models
  raise "expected 10+, got #{models.length}" unless models.length >= 10
  puts "    → #{models.length} providers"
end

puts "\n— Protected endpoints —\n\n"

test("list resumes") do
  client = Laddro.new(API_KEY)
  result = client.list_resumes(limit: 5)
  raise "missing items" unless result["items"]
  puts "    → #{result['items'].length} resumes"
end

test("get settings") do
  client = Laddro.new(API_KEY)
  result = client.get_settings
  raise "missing ai field" unless result.key?("ai")
end

test("list cover letters") do
  client = Laddro.new(API_KEY)
  result = client.list_cover_letters(limit: 5)
  raise "missing items" unless result["items"]
  puts "    → #{result['items'].length} cover letters"
end

test("get resume by id") do
  client = Laddro.new(API_KEY)
  list = client.list_resumes(limit: 1)
  id = list["items"][0]["resumeId"]
  resume = client.get_resume(id)
  raise "id mismatch" unless resume["resumeId"] == id
  puts "    → #{resume['title']}"
end

test("auth error on bad key") do
  client = Laddro.new("laddro_live_invalid")
  begin
    client.list_resumes
    raise "should have raised"
  rescue Laddro::APIError => e
    raise "expected 401, got #{e.status}" unless e.auth_error?
  end
end

puts "\n— Results: #{$passed} passed, #{$failed} failed —\n\n"
exit($failed > 0 ? 1 : 0)
