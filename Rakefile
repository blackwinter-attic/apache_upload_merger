require File.expand_path(%q{../lib/apache/upload_merger/version}, __FILE__)

begin
  require 'hen'

  Hen.lay! {{
    :gem => {
      :name         => %q{apache_upload_merger},
      :version      => Apache::UploadMerger::VERSION,
      :summary      => %q{Apache module providing upload merging functionality.},
      :author       => %q{Jens Wille},
      :email        => %q{jens.wille@gmail.com},
      :license      => %q{AGPL},
      :homepage     => :blackwinter,
      :dependencies => %w[]
    }
  }}
rescue LoadError => err
  abort "Please install the `hen' gem first. (#{err})"
end
