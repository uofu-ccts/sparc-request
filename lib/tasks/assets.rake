require 'pathname'
require 'fileutils'
require 'colorize'

def walk(start, &block)
  Dir.foreach(start) do |x|
    path = File.join(start, x)
    if x == "." or x == ".."
      next
    elsif File.directory?(path)
      walk(path, &block)
    else
      yield x
    end
  end
end

namespace :assets do
  desc "recursively copy assets from app/assets to themes/assets"
  task :copy_assets, [:dry_run] => :environment do |t, args|
    identicalSet = Set.new
    existingSet = Set.new
    root = Pathname.new(Rails.root.join('app', 'assets'))
    Dir.glob(Rails.root.join('app', 'assets', '**', '*')) do |path|
      relativePath = Pathname.new(path).relative_path_from(root).to_s
      compare = Rails.root.join('themes', 'assets', relativePath)

      if File.directory?(path)

      else
        if File.file?(compare)
          if FileUtils.compare_file(compare, path)
            identicalSet.add(path)
          end
          existingSet.add(compare)
        elsif %w(.css .scss).include? File.extname(path)
          dir = File.dirname compare
          if args['dry_run'].present?
            puts "Copying #{path.to_s.green} to #{dir.to_s.red}"
            puts
          else
            if !File.exist? dir

              FileUtils.mkdir_p dir
            end
            FileUtils.cp(path, dir)
          end



        end
      end

    end
  end

end
