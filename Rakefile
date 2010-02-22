require %q{lib/apache/upload_merger/version}

begin
  require 'hen'

  Hen.lay! {{
    :gem => {
      :name         => %q{apache_upload_merger},
      :version      => Apache::UploadMerger::VERSION,
      :summary      => %q{Apache module providing upload merging functionality.},
      :files        => FileList['lib/**/*.rb'].to_a,
      :extra_files  => FileList['[A-Z]*'].to_a,
      :dependencies => %w[]
    }
  }}
rescue LoadError
  abort "Please install the 'hen' gem first."
end

### Place your custom Rake tasks here.
