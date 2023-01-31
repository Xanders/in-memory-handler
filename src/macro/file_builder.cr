require "./file_to_cache"

path = ARGV[0]

raise "first argument is not a file" unless File.file?(path)

mime = ARGV.size > 1 ? ARGV[1] : ""

puts file_to_cache(path, mime)
