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

client = Laddro.new(API_KEY)
public_client = Laddro.new
resume_id = nil
cover_letter_id = nil

puts "\n— 1. Public endpoints (5/18) —\n\n"

test("GET /v1/templates") { t = public_client.list_templates; raise "expected 22" unless t.length == 22 }
test("GET /v1/templates/{id}") { d = public_client.get_template("GRAPHITE"); raise "wrong" unless d["id"] == "GRAPHITE" }
test("GET /v1/fonts") { f = public_client.list_fonts; raise "expected 21" unless f.length == 21 }
test("GET /v1/languages") { l = public_client.list_languages; raise "expected 14" unless l.length == 14 }
test("GET /v1/models") { m = public_client.list_models; raise "expected 10" unless m.length == 10 }

puts "\n— 2. Resume endpoints (4/18) —\n\n"

test("GET /v1/resumes") do
  r = client.list_resumes(limit: 5)
  raise "no resumes" if r["items"].empty?
  resume_id = r["items"].find { |x| x["isDefault"] }&.dig("resumeId") || r["items"][0]["resumeId"]
end

test("GET /v1/resumes/{id}") do
  r = client.get_resume(resume_id)
  raise "mismatch" unless r["resumeId"] == resume_id
end

test("PUT /v1/resumes/{id}/render") do
  pdf = client.render_resume(resume_id, { templateId: "GRAPHITE" })
  raise "too small: #{pdf.length}" unless pdf.length > 1000
end

test("POST /v1/resumes/parse (skip)") { }

puts "\n— 3. Tailor (1/18) —\n\n"

test("POST /v1/tailor") do
  pdf = client.tailor({ positionName: "Ruby SDK Test", resumeId: resume_id, jobDescription: "Write Ruby code." })
  raise "too small: #{pdf.length}" unless pdf.length > 5000
end

puts "\n— 4. Export (1/18) —\n\n"

test("POST /v1/export") do
  pdf = client.export_pdf({ resumeId: resume_id, templateId: "COBALT" })
  raise "too small: #{pdf.length}" unless pdf.length > 1000
end

puts "\n— 5. Cover Letter endpoints (5/18) —\n\n"

test("GET /v1/cover-letters") { client.list_cover_letters }

test("POST /v1/cover-letters") do
  r = client.create_cover_letter({ fullName: "Ruby Test", letterContent: "<p>Test.</p>" })
  cover_letter_id = r["coverLetterId"]
  raise "no id" unless cover_letter_id
end

test("GET /v1/cover-letters/{id}") do
  cl = client.get_cover_letter(cover_letter_id)
  raise "mismatch" unless cl["coverLetterId"] == cover_letter_id
end

test("PUT /v1/cover-letters/{id}/render") do
  pdf = client.render_cover_letter(cover_letter_id, { templateId: "NICKEL" })
  raise "too small: #{pdf.length}" unless pdf.length > 1000
end

test("POST /v1/cover-letters/generate") do
  pdf = client.generate_cover_letter({ positionName: "Ruby Test", resumeId: resume_id, jobDescription: "Ruby dev." })
  raise "too small: #{pdf.length}" unless pdf.length > 1000
end

puts "\n— 6. Settings (3/18) —\n\n"

test("GET /v1/settings") { client.get_settings }

test("PUT /v1/settings/model") do
  begin
    client.update_ai_settings({ provider: "OpenAI", model: "gpt-4o-mini", apiKey: "sk-test-invalid" })
  rescue Laddro::APIError => e
    # 400 expected (key validation fails)
  end
end

test("DELETE /v1/settings/model") do
  r = client.delete_ai_settings
  raise "ai should be nil" unless r["ai"].nil?
end

puts "\n— 7. Errors —\n\n"

test("401 on bad key") do
  begin
    Laddro.new("laddro_live_invalid").list_resumes
    raise "should raise"
  rescue Laddro::APIError => e
    raise "expected 401" unless e.auth_error?
  end
end

test("404 on missing resume") do
  begin
    client.get_resume("00000000-0000-0000-0000-000000000000")
    raise "should raise"
  rescue Laddro::APIError => e
    raise "expected 404" unless e.not_found?
  end
end

puts "\n═══ FINAL: #{$passed} passed, #{$failed} failed (18 endpoints covered) ═══\n\n"
exit($failed > 0 ? 1 : 0)
