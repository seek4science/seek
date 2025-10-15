output = `curl --verbose --silent http://localhost:3000/statistics/application_status 2>&1`
if $?.success? && output.include?('FAIRDOM-SEEK is running | search is enabled | 7 delayed jobs running')
  exit 0
else
  puts "::group::Docker logs"
  puts `docker compose --file docker-compose.yml --file docker-compose.build.yml logs`
  puts "::endgroup::"
  puts "::group::curl output"
  puts output
  puts "::endgroup::"
  exit 1
end
