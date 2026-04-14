# Validates the storage configuration at boot without contacting any remote service.
# Raises with a clear message if seek_storage.yml is missing required fields,
# so misconfiguration is caught immediately rather than at the first file operation.
require 'seek/storage'
Seek::Storage.validate_config!
