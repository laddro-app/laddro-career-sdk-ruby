# laddro-career

Ruby SDK for the [Laddro Career API](https://api.laddro.com/reference).

## Install

```bash
gem install laddro-career
```

## Usage

```ruby
require "laddro"

client = Laddro.new("laddro_live_...")

# List resumes
resumes = client.list_resumes
resumes["items"].each { |r| puts r["title"] }

# Tailor a resume
pdf = client.tailor(
  positionName: "Senior Frontend Engineer",
  jobUrl: "https://jobs.example.com/sfe"
)
File.write("tailored.pdf", pdf)

# Generate cover letter
cl = client.generate_cover_letter(
  positionName: "Product Manager",
  jobUrl: "https://jobs.example.com/pm"
)

# Browse templates (no auth)
client = Laddro.new
templates = client.list_templates

# BYOK
client.update_ai_settings(
  provider: "Anthropic",
  model: "claude-sonnet-4-20250514",
  apiKey: "sk-ant-..."
)
```

## License

MIT
