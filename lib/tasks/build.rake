
desc "Build native extension"
task :build => [:build_rb, :build_ext] do
end

task :build_rb do
  `cd lib && ragel -R querybuilder_rb.rl`
end

task :build_ext => [:ragel_ext, :extconf] do
  `cd lib && make`
end

task :extconf do
  `cd lib && ruby extconf.rb`
end

task :ragel_ext do
  `cd lib && ragel querybuilder_ext.rl`
end