# We come up with a "SVN revision"
if File.directory?("#{srcdir_root}/.git")
  git_log = File.popen("cd #{srcdir_root}; git log")
  date = nil
  svn_rev = nil
  svn_age = -1                   # Number of commits posterior to last SVN
  git_commit = nil
  while l = git_log.gets
    case l 
    when /commit\s+(\S+)/
      git_commit = $1
      svn_age += 1
    when /Date:\s*(.*)/
      date ||= $1
    when /git-svn-id:\s*\S+@(\d+)/
      svn_rev = $1.to_i
      git_log.close
      break
    end
  end
  if svn_age > 0
    svn_rev = "#{svn_rev}+git#{svn_age}"
  end
  File.open("lib/ctioga2/git-fools-svn.rb", "w") do |f|
    f.puts <<"EOF"
# Automatically generated file.
module CTioga2


   Version::register_svn_info('$Revision: #{svn_rev}$', 
                              '$Date: #{date}$')
end
EOF
end
end

