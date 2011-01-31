# If we are managed by git-svn and not svn, we provide SVN information
# on the fly.
if File.directory?("#{srcdir_root}/.git")
  svn_info = `cd #{srcdir_root}; git svn info`
  svn_info =~ /Last\s+Changed\s+Date\s*:\s*(.*)/
  date = $1
  svn_info =~ /Last\s+Changed\s+Rev\s*:\s*(.*)/
  rev = $1
  File.open("lib/ctioga2/git-fools-svn.rb", "w") do |f|
    f.puts <<"EOF"
# Automatically generated file.
module CTioga2


   Version::register_svn_info('$Revision: #{rev}$', 
                              '$Date: #{date}$')
end
EOF
end
end

