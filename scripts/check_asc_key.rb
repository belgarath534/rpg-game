# Talks to Apple directly (no fastlane) to see exactly why an App Store Connect API key is accepted or rejected.
# Prints only HTTP status codes and Apple's error messages, never the key.
require "openssl"
require "base64"
require "json"
require "net/http"

def b64(data) = Base64.urlsafe_encode64(data, padding: false)

def make_jwt(key, kid, payload)
  header = { alg: "ES256", kid: kid, typ: "JWT" }
  signing_input = "#{b64(header.to_json)}.#{b64(payload.to_json)}"
  der = key.sign(OpenSSL::Digest.new("SHA256"), signing_input)
  r, s = OpenSSL::ASN1.decode(der).value.map { |n| n.value.to_s(2).rjust(32, "\0")[-32..] }
  "#{signing_input}.#{b64(r + s)}"
end

def ask_apple(token)
  uri = URI("https://api.appstoreconnect.apple.com/v1/bundleIds?limit=1")
  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{token}"
  Net::HTTP.start(uri.host, 443, use_ssl: true) { |http| http.request(request) }
end

key = OpenSSL::PKey.read(File.read(ENV.fetch("ASC_KEY_PATH")))
kid = ENV["FILE_KEY_ID"].to_s.empty? ? ENV.fetch("ASC_KEY_ID").strip : ENV["FILE_KEY_ID"]
issuer = (ENV["ASC_ISSUER_ID_PUBLIC"] || ENV.fetch("ASC_ISSUER_ID")).strip
now = Time.now.to_i
puts "Runner clock (UTC): #{Time.now.utc}"
puts "Testing Key ID #{kid} with Issuer ID #{issuer[0, 8]}..."

tests = {
  "Team key" => { iss: issuer, iat: now, exp: now + 600, aud: "appstoreconnect-v1" },
  "Individual key" => { sub: "user", iat: now, exp: now + 600, aud: "appstoreconnect-v1" },
}
accepted = nil
tests.each do |name, payload|
  response = ask_apple(make_jwt(key, kid, payload))
  if response.code == "200"
    puts "✅ Apple ACCEPTS this as a #{name}"
    accepted ||= name
  else
    puts "❌ As a #{name}: HTTP #{response.code}"
    errors = (JSON.parse(response.body)["errors"] rescue nil) || []
    errors.each { |e| puts "   #{e['code']}: #{e['title']} — #{e['detail']}" }
  end
end
File.write(ENV["GITHUB_ENV"], "ASC_KEY_TYPE=#{accepted == 'Individual key' ? 'individual' : 'team'}\n", mode: "a") if ENV["GITHUB_ENV"]
