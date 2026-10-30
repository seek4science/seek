module Seek
  module Storage
    # Removes objects left behind in the direct-upload staging area.
    #
    # A browser upload lands under the 'uploads/' prefix and is moved to 'assets/' when the form is
    # submitted. If the form never is (tab closed, user navigated away), the object stays with nothing
    # pointing at it. Anything older than max_age is such a leftover: a signed upload URL lives 15 minutes,
    # and no form is left open for a day. Objects younger than max_age are never touched, because their
    # form may still be on someone's screen.
    #
    # Does nothing on the local backend, which has no staging area.
    class StaleUploadCleaner
      DEFAULT_MAX_AGE = 1.day

      Result = Struct.new(:examined, :stale, :deleted, :dry_run, keyword_init: true) do
        def summary
          action = dry_run ? 'would be deleted (dry run)' : 'deleted'
          "Staging area: #{examined} object(s) examined, #{stale} older than the limit, #{deleted} #{action}."
        end
      end

      def initialize(max_age: DEFAULT_MAX_AGE, dry_run: false, adapter: Seek::Storage.upload_adapter, logger: nil)
        @max_age = max_age
        @dry_run = dry_run
        @adapter = adapter
        @logger = logger
      end

      def run
        result = Result.new(examined: 0, stale: 0, deleted: 0, dry_run: @dry_run)
        return result if @adapter.nil?

        cutoff = Time.now - @max_age
        @adapter.each_object do |key, last_modified|
          result.examined += 1
          purge(key, last_modified, result) if last_modified < cutoff
        end
        result
      end

      private

      def purge(key, last_modified, result)
        result.stale += 1
        log("#{@dry_run ? 'would delete' : 'deleting'} #{key} (last modified #{last_modified.utc.iso8601})")
        return if @dry_run

        @adapter.delete(key)
        result.deleted += 1
      end

      def log(message)
        @logger&.info("[StaleUploadCleaner] #{message}")
      end
    end
  end
end
