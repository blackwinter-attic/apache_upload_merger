#--
###############################################################################
#                                                                             #
# apache_upload_merger -- Apache module providing upload merging              #
#                         functionality                                       #
#                                                                             #
# Copyright (C) 2010 University of Cologne,                                   #
#                    Albertus-Magnus-Platz,                                   #
#                    50923 Cologne, Germany                                   #
#                                                                             #
# Authors:                                                                    #
#     Jens Wille <jens.wille@uni-koeln.de>                                    #
#                                                                             #
# apache_upload_merger is free software: you can redistribute it and/or       #
# modify it under the terms of the GNU General Public License as published by #
# the Free Software Foundation, either version 3 of the License, or (at your  #
# option) any later version.                                                  #
#                                                                             #
# apache_upload_merger is distributed in the hope that it will be useful, but #
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with apache_upload_merger. If not, see <http://www.gnu.org/licenses/>.      #
#                                                                             #
###############################################################################
#++

require 'fcntl'
require 'fileutils'

module Apache

  class UploadMerger

    DEFAULT_MERGE_THRESHOLD = 32 * 1024 * 1024

    CREATE_MODE = Fcntl::O_CREAT|Fcntl::O_WRONLY|Fcntl::O_EXCL

    # Creates a new RubyHandler instance for the Apache web server. It
    # is to be installed as a custom 404 ErrorDocument handler.
    #
    # The argument +map+ contains key/value pairs of URL prefixes and
    # upload base directories.
    #
    # +strategy+ determines how merging happens:
    #
    # <tt>:symlink</tt>:: Files are symlinked
    # <tt>:copy</tt>::    Files are copied
    # <tt>Integer</tt>::  Files whose size is below that threshold are
    #                     copied, others are symlinked (default)
    def initialize(map = {}, strategy = DEFAULT_MERGE_THRESHOLD)
      @map, @strategy = {}, strategy

      define_merger

      map.each { |prefix, dir|
        @map[prefix] = [%r{\A#{prefix}/(.*)}, dir]
      }
    end

    # If the current +request+ asked for a resource that's not there,
    # it will be merged from one of the appropriate upload directories,
    # determined by its URL prefix. If no matching resource could be
    # found, the original error will be thrown.
    def handler(request)
      request.add_common_vars  # REDIRECT_URL

      if url    = request.subprocess_env['REDIRECT_URL'] and
         prefix = request.path_info.untaint              and
         map    = @map[prefix]                           and
         path   = url[map[0], 1].untaint                 and
         src    = find(map[1], path)

        merge(src, File.join(request.server.document_root, prefix, path))

        request.status = HTTP_OK
        request.internal_redirect(url)

        OK
      else
        DECLINED
      end
    end

    private

    # TODO: make it fast *and* secure
    def find(dir, path)
      Dir["#{dir}/*/"].find { |subdir|
        file = File.join(subdir, path).untaint
        return file if File.exists?(file)
      }
    end

    def define_merger
      class << self; self; end.send :alias_method, :merge, case @strategy
        when :symlink, :copy then @strategy
        when Integer         then :copy_or_symlink
        else raise ArgumentError, "illegal strategy #{@strategy.inspect}"
      end
    end

    def copy_or_symlink(src, dest)
      stat = File.stat(src)
      stat.size > @strategy ? symlink(src, dest) : copy(src, dest, stat)
    end

    def symlink(src, dest)
      File.symlink(src, dest)
    rescue Errno::EEXIST
    end

    # TODO: optimize?
    def copy(src, dest, stat = File.stat(src))
      File.open(src) { |src_|
        File.open(dest, CREATE_MODE, stat.mode) { |dest_|
          FileUtils.copy_stream(src_, dest_)
        }
      }
    rescue Errno::EEXIST
    end

  end

end
