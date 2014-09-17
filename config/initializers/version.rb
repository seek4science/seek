# Work out a version number with as much information as possible

git_dir = File.join(File.dirname(__FILE__), "..", "..", ".git")

c = if File.exist?(git_dir) && File.directory?(git_dir)
      begin
        "-" + `git rev-parse --short HEAD`.chomp
      rescue
        ""
      end
    else
      ""
    end

$version = "1.2.0#{c}"
