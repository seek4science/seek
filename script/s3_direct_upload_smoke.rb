# Smoke test for the S3 pieces behind direct browser upload, run against the configured S3 store:
#
#   RAILS_ENV=development bundle exec rails runner script/s3_direct_upload_smoke.rb
#
# Exercises, in order: presigned PUT into the staging prefix (as a browser would, via curl),
# head/size through the adapter, server-side copy to the assets prefix (single and multipart
# strategies), delete, and listing of the staging prefix. Cleans up everything it creates.
#
# What each section proves about the configured store:
#   1. a client holding only a presigned URL can upload into uploads/, and only as signed
#   2. SEEK can see a staged object (existence, size)
#   3. the store supports the copy command used for files up to 5 GB (CopyObject)
#   4. the store supports the copy command used for files over 5 GB (multipart copy)
#   5. the staging prefix can be listed (needed for orphan cleanup)
#   6. everything created can be deleted again
# Requires a running store (e.g. script/start-docker-seaweedfs.sh) and backend: s3 in
# config/seek_storage.yml for the current RAILS_ENV. Exits non-zero on the first failure.
#
# It must be run through `rails runner` (not plain `ruby`) because it uses SEEK's own storage
# classes (Seek::Storage, S3Adapter) and the credentials from config/seek_storage.yml.

require 'aws-sdk-s3'    # the AWS client library; S3Adapter is built on it
require 'open3'         # lets us run `curl` and capture its output
require 'securerandom'  # random names for the throwaway objects

# Direct upload only exists on the S3 backend. On local disk there is nothing to test, so stop here.
unless Seek::Storage.direct_upload_enabled?
  abort "Storage backend is '#{Seek::Storage.status[:backend]}', not s3 - nothing to test."
end

# The two adapters the feature uses. Both point at the SAME bucket, just different prefixes:
#   uploads -> "uploads/<name>"   the staging area a browser uploads into
#   assets  -> "assets/<name>"    where SEEK keeps the real files (what ContentBlob reads)
uploads = Seek::Storage.upload_adapter
assets  = Seek::Storage.adapter_for('dat')
bucket  = Seek::Storage.status[:bucket]
created = [] # every object we create is remembered here as [adapter, key] so it can be deleted at the end

# Prints PASS/FAIL for one assertion and stops the whole script on the first FAIL.
def check(label, passed, detail = nil)
  status = passed ? 'PASS  ' : 'FAIL  '
  puts "  #{status} #{label}#{detail ? " (#{detail})" : ''}"
  abort('smoke test failed') unless passed
end

# Prints a detail line (keys, URLs, sizes) so a run leaves a readable trace of what was touched.
# Presigned URLs are shown in full on purpose: they expire within minutes and only ever point at
# throwaway smoke objects.
def info(label, value)
  puts "         #{label}: #{value}"
end

# Uploads `body` to `url` with an HTTP PUT, exactly as a browser would, and returns the HTTP status
# code. curl is used instead of the AWS client on purpose: the point is to prove that a client that
# knows nothing about AWS credentials can upload with only the presigned URL.
def curl_put(url, body, content_type)
  http_code_token = '%{http_code}' # rubocop:disable Style/FormatStringToken -- curl's token, not Ruby's
  code, = Open3.capture2e('curl', '-s', '-o', '/dev/null', '-w', http_code_token, '-X', 'PUT',
                          '-H', "Content-Type: #{content_type}", '--data-binary', body, url)
  code.to_i
end

# --- Header: where are we talking to? ---
status = Seek::Storage.status
puts 'S3 direct-upload smoke test'
info 'backend',    status[:backend]
info 'bucket',     bucket
info 'endpoint',   status[:endpoint] || 'AWS (default)'
info 'staging',    "#{uploads.full_key('<token>')}   (uploads adapter)"
info 'permanent',  "#{assets.full_key('<uuid>.dat')}  (assets adapter)"
puts

begin
  # ------------------------------------------------------------------------------------------------
  # 1. Presigned PUT -> staging prefix
  #    This is what will happen when a user picks a file in the browser: SEEK makes a signed URL,
  #    the browser PUTs the file to it, and the object appears under uploads/.
  # ------------------------------------------------------------------------------------------------
  puts '1. Presigned upload into the staging prefix'
  token = SecureRandom.uuid                       # the random staging name SEEK invents per upload
  body  = "smoke #{Time.now.utc.iso8601}\n"       # a tiny, recognisable file content
  # Ask the adapter for a signed upload URL. SEEK computes this locally from the
  # bucket secret; no request goes to S3 here. Valid for 120 s and ONLY for Content-Type text/plain.
  url   = uploads.presigned_upload_url(token, content_type: 'text/plain', expires_in: 120)
  info 'token',        token
  info 'staging key',  uploads.full_key(token)
  info 'body',         "#{body.bytesize} B, Content-Type text/plain"
  info 'presigned URL (valid 120 s)', url
  check 'presigned_upload_url points at the staging prefix', url.include?("uploads/#{token}")
  # The "browser" uploads: plain HTTP PUT with the signed Content-Type -> S3 must answer 200.
  check 'PUT with the signed Content-Type is accepted', curl_put(url, body, 'text/plain') == 200
  created << [uploads, token]
  # Same URL but a different Content-Type: the signature no longer matches -> S3 must answer 403.
  # This proves the URL can only be used for what SEEK signed it for.
  check 'PUT with a different Content-Type is rejected', curl_put(url, body, 'application/octet-stream') == 403

  # ------------------------------------------------------------------------------------------------
  # 2. Adapter sees it
  #    What SEEK does when the form is submitted: confirm the staged object
  #    really exists and is not empty, before creating a ContentBlob for it.
  # ------------------------------------------------------------------------------------------------
  puts '2. Staging object as seen through the uploads adapter'
  info 'exist?', uploads.exist?(token) # HEAD request on uploads/<token>
  info 'size',   "#{uploads.size(token)} B" # Content-Length from that HEAD
  check 'staging object exists', uploads.exist?(token)
  check 'staging object has the right size', uploads.size(token) == body.bytesize

  # ------------------------------------------------------------------------------------------------
  # 3. Single-call server-side copy
  #    PURPOSE: prove this store supports the copy command used for files UP TO 5 GB (CopyObject).
  #    What ContentBlob does on save for a directly uploaded file: promote uploads/<token> to its permanent
  #    key under assets/. The copy happens INSIDE S3 - the bytes never come back through SEEK.
  #    For anything up to 5 GB copy_object uses one CopyObject request.
  # ------------------------------------------------------------------------------------------------
  puts '3. Server-side copy, single CopyObject (size below the 5 GB limit)'
  dest = "smoke-#{token}.dat" # stands in for "<uuid>.dat"
  info 'copy source', "#{bucket}/#{uploads.full_key(token)}"
  info 'copy target', "#{bucket}/#{assets.full_key(dest)}"
  # S3Adapter#copy_object: source is the FULL key in the bucket ("uploads/..."), target is a key on the
  # assets adapter ("smoke-....dat" -> "assets/smoke-....dat"). size decides single vs multipart.
  assets.copy_object(uploads.full_key(token), dest, size: body.bytesize)
  created << [assets, dest]
  check 'single copy_object lands in assets/', assets.exist?(dest)
  check 'copied content is identical', assets.open(dest).read == body # read it back and compare bytes

  # ------------------------------------------------------------------------------------------------
  # 4. Multipart server-side copy
  #    PURPOSE: prove this store supports the copy command used for files OVER 5 GB (multipart copy /
  #    UploadPartCopy). It tests the copy METHOD, not a big file: the 6 MB object is only a prop.
  #    The other branch of copy_object, used for files over 5 GB. We cannot sensibly create a 5 GB
  #    object here, so we create a 6 MB one (the smallest multipart allows) and call the multipart
  #    copy directly, to prove THIS STORE supports it (UploadPartCopy). The object goes into the
  #    bucket with an ordinary put (adapter.write), not a presigned URL - how it got there does not
  #    matter for this test.
  # ------------------------------------------------------------------------------------------------
  puts '4. Server-side copy, multipart (forced on a 6 MB object)'
  big_token = SecureRandom.uuid
  big_body  = 'x' * (6 * 1024 * 1024)              # 6 MB of 'x' in memory
  uploads.write(big_token, big_body)               # ordinary put_object into uploads/<big_token>
  created << [uploads, big_token]
  big_dest = "smoke-big-#{token}.dat"
  info 'copy source', "#{bucket}/#{uploads.full_key(big_token)}  (#{big_body.bytesize} B)"
  info 'copy target', "#{bucket}/#{assets.full_key(big_dest)}"
  # Same SDK call copy_object makes for > 5 GB: create multipart upload, UploadPartCopy per part,
  # complete. content_length is required because the SDK does not look the size up itself.
  Aws::S3::Object.new(bucket_name: bucket, key: assets.full_key(big_dest),
                      client: assets.instance_variable_get(:@client))
                 .copy_from("#{bucket}/#{uploads.full_key(big_token)}",
                            multipart_copy: true, content_length: big_body.bytesize, metadata_directive: 'REPLACE')
  created << [assets, big_dest]
  info 'target size', "#{assets.size(big_dest)} B"
  check 'multipart copy lands in assets/ with the right size', assets.size(big_dest) == big_body.bytesize

  # ------------------------------------------------------------------------------------------------
  # 5. Listing the staging prefix
  #    What cleaning up abandoned uploads relies on: being able to list everything under uploads/
  #    so abandoned uploads can be found and deleted.
  # ------------------------------------------------------------------------------------------------
  puts '5. Listing the staging prefix'
  client = uploads.instance_variable_get(:@client) # the raw AWS client
  keys = client.list_objects_v2(bucket: bucket, prefix: 'uploads/').contents.map(&:key)
  info 'objects under uploads/', keys.size
  keys.each { |k| info '  -', k }
  staged_seen = keys.include?("uploads/#{token}") && keys.include?("uploads/#{big_token}")
  check 'list_objects_v2 on uploads/ sees the staged objects', staged_seen
ensure
  # ------------------------------------------------------------------------------------------------
  # 6. Cleanup - runs even if a check failed above, so the bucket is left as we found it.
  #    This is also why you see nothing in the SeaweedFS UI after a run: S3 has no folders, so when
  #    the last object under uploads/ is deleted the "folder" disappears too.
  # ------------------------------------------------------------------------------------------------
  puts '6. Cleanup'
  created.each do |adapter, key|
    info 'delete', adapter.full_key(key)
    adapter.delete(key)
  end
  leftovers = created.select { |adapter, key| adapter.exist?(key) }
  check 'cleanup removed everything this script created', leftovers.empty?
end

puts 'SMOKE OK'
