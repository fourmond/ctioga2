# We come up with a "SVN revision"
if File.directory?("#{srcdir_root}/.git")
  Dir.chdir(srcdir_root) do
    date = `git log --format=format:"%ad" -1`
    version = `git describe --tags`
    File.open("lib/ctioga2/version.rb", "w") do |f|
      f.puts <<"EOF"
# Automatically generated file.
module CTioga2

  module Version
    GIT_VERSION = "#{version}"
    GIT_DATE = "#{date}"
  end
end
EOF
    end
  end
end

