#--
###############################################################################
#                                                                             #
# apache_upload_merger -- Apache module providing upload merging              #
#                         functionality                                       #
#                                                                             #
# Copyright (C) 2010 University of Cologne,                                   #
#                    Albertus-Magnus-Platz,                                   #
#                    50932 Cologne, Germany                                   #
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

    MODE = Fcntl::O_CREAT|Fcntl::O_WRONLY|Fcntl::O_EXCL

    # Creates a new RubyHandler instance for the Apache web server. It
    # is to be installed as a custom 404 ErrorDocument handler.
    #
    # The argument +map+ contains key/value pairs of URL prefixes and
    # upload base directories.
    def initialize(map = {})
      @map = {}

      map.each { |prefix, dir|
        @map[prefix] = [%r{\A#{prefix}/(.*)}, dir]
      }
    end

    # If the current +request+ asked for a resource that's not there,
    # it will be copied from one of the appropriate upload directories,
    # determined by its URL prefix. Otherwise, the original error will
    # be thrown.
    def handler(request)
      request.setup_cgi_env

      if url    = request.subprocess_env['REDIRECT_URL'] and
         prefix = request.path_info                      and
         map    = @map[prefix]                           and
         path   = url[map[0], 1]                         and
         src    = Dir[File.join(map[1], '*', path.untaint)].first

        dest = File.join(request.server.document_root, prefix, path)
        copy(src.untaint, dest.untaint)

        request.status = HTTP_OK
        request.internal_redirect(url)

        OK
      else
        DECLINED
      end
    end

    private

    def copy(src, dest)
      File.open(src, 'r') { |r|
        File.open(dest, MODE, r.stat.mode) { |w|
          FileUtils.copy_stream(r, w)
        }
      }
    rescue Errno::EEXIST
    end

  end

end
