require "shrine"
require "shrine/storage/s3"

s3_options = {
  access_key_id:     "seek", # "AccessKey" value
  secret_access_key: "seek1234", # "SecretKey" value
  endpoint:          "http://localhost:9000",   # "Endpoint"  value
  bucket:            "example",     # name of the bucket you created
  region:            "us-east-1",
  force_path_style:  true,

}

# both `cache` and `store` storages are needed
Shrine.storages = {
  cache: Shrine::Storage::S3.new(prefix: "cache", **s3_options),
  store: Shrine::Storage::S3.new(**s3_options),
}

Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data # for retaining the cached file across form redisplays
Shrine.plugin :restore_cached_data # re-extract metadata when attaching a cached file
Shrine.plugin :derivation_endpoint, secret_key: "squirrel", upload: true, upload_redirect: true
