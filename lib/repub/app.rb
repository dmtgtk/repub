require 'repub'

ARGV = ['http://www.berzinarchives.com/web/x/prn/p.html_272733222.html', 'tmp']
#ARGV = ['http://www.berzinarchives.com/web/x/prn/p.html_308144925.html', 'tmp']

if ARGV.size == 0
  puts <<-END
    usage:
      #{File.basename(__FILE__)} url [temp]
  END
  exit 1
end

# begin
  RePub::Fetcher.fetch(ARGV[0], ARGV[1], true) do |f|
    RePub::Parser.parse(f.asset_name, f.asset_root) do |p|
      puts "* Processing:\t#{p.title}"
      RePub::Writer.write(p)
      puts "* Done."
    end
  end
# rescue Exception => ex
#   puts "* Conversion failed: #{ex.message}"
#   exit 1
# end
