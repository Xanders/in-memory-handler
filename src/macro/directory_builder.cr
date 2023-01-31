require "./file_to_cache"

raise "first argument is not a directory" unless File.directory?(ARGV[0])

root = File.expand_path(ARGV[0])

puts "{"

Dir[File.join(root, "**/*")].each do |path|
  next path if File.directory?(path)

  key = path.sub(/^#{root}/, "").sub(/((?<!^)\/)?index\.html$/, "").sub(/\.html$/, "")

  puts "  \"#{key}\" => {#{file_to_cache(path)}},"
end

print "}"
