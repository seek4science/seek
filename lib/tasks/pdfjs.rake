namespace :pdfjs do
  PDFJS_VERSION = '2.16.105'
  PDFJS_ZIP_URL = "https://github.com/mozilla/pdf.js/releases/download/v#{PDFJS_VERSION}/pdfjs-#{PDFJS_VERSION}-dist.zip"

  desc "Download pdfjs-dist #{PDFJS_VERSION} and install into vendor/assets/. Commit the result."
  task :install do
    require 'tmpdir'
    require 'open-uri'
    require 'zip'

    Dir.mktmpdir do |tmpdir|
      zip_path = File.join(tmpdir, "pdfjs-#{PDFJS_VERSION}-dist.zip")

      puts "Downloading PDF.js #{PDFJS_VERSION}..."
      URI.open(PDFJS_ZIP_URL, 'rb') { |r| IO.copy_stream(r, zip_path) }

      puts 'Extracting...'
      dist = File.join(tmpdir, 'dist')
      FileUtils.mkdir_p(dist)
      Zip::File.open(zip_path) do |zip|
        zip.each do |entry|
          next if entry.directory?
          dest = File.join(dist, entry.name)
          FileUtils.mkdir_p(File.dirname(dest))
          entry.extract(dest) { true }
        end
      end

      js_dest = Rails.root.join('vendor/assets/javascripts/pdfjs')
      FileUtils.cp("#{dist}/build/pdf.js",        "#{js_dest}/pdf.js")
      FileUtils.cp("#{dist}/build/pdf.worker.js", "#{js_dest}/pdf.worker.js")
      FileUtils.cp("#{dist}/web/viewer.js",       "#{js_dest}/viewer.js")

      # Transform url(images/FILE) references to use Sprockets asset_path helpers
      css = File.read("#{dist}/web/viewer.css")
      css.gsub!(/url\("?images\/([^")]+)"?\)/) do
        %(url("<%= asset_path('pdfjs/images/#{Regexp.last_match(1)}') %>"))
      end
      File.write(Rails.root.join('vendor/assets/stylesheets/pdfjs/viewer.css.erb'), css)

      img_dest = Rails.root.join('vendor/assets/images/pdfjs')
      FileUtils.rm_rf(img_dest)
      FileUtils.mkdir_p(img_dest)
      FileUtils.cp_r("#{dist}/web/images/.", img_dest)
    end

    %w[compatibility.js debugger.js l10n.js viewer.js.erb].each do |f|
      path = Rails.root.join("vendor/assets/javascripts/pdfjs/#{f}")
      FileUtils.rm_f(path)
    end

    puts "PDF.js #{PDFJS_VERSION} installed into vendor/assets. Review changes and commit."
  end
end
