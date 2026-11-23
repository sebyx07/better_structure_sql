# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

RSpec.describe BetterStructureSql::ZipGenerator do
  let(:target_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(target_dir) }

  def zip_with(entries)
    Zip::OutputStream.write_buffer do |zip|
      entries.each do |name, content|
        zip.put_next_entry(name)
        zip.write(content)
      end
    end.string
  end

  describe '.extract_to_directory' do
    it 'round-trips a file map' do
      file_map = { '_header.sql' => "SET x;\n", '05_tables/000001.sql' => "CREATE TABLE a ();\n" }

      described_class.extract_to_directory(described_class.create_from_file_map(file_map), target_dir)

      extracted = Dir.glob("#{target_dir}/**/*").select { |f| File.file?(f) }.to_h do |f|
        [f.delete_prefix("#{target_dir}/"), File.read(f)]
      end
      expect(extracted).to eq(file_map)
    end

    it 'overwrites files already present in the target directory' do
      File.write(File.join(target_dir, '_header.sql'), 'stale')

      described_class.extract_to_directory(zip_with('_header.sql' => 'fresh'), target_dir)

      expect(File.read(File.join(target_dir, '_header.sql'))).to eq('fresh')
    end

    it 'refuses entries that traverse outside the target directory' do
      zip = zip_with('ok.sql' => 'SELECT 1;', '../escaped.sql' => 'DROP TABLE users;')

      expect { described_class.extract_to_directory(zip, target_dir) }
        .to raise_error(described_class::ZipError, /Unsafe path/)
      expect(File.exist?(File.expand_path('../escaped.sql', target_dir))).to be false
    end

    it 'does not confuse a sibling directory sharing the target prefix with the target' do
      sibling = "#{target_dir}-sibling"
      zip = zip_with("../#{File.basename(sibling)}/x.sql" => 'SELECT 1;')

      expect { described_class.extract_to_directory(zip, target_dir) }
        .to raise_error(described_class::ZipError, /Unsafe path/)
      expect(Dir.exist?(sibling)).to be false
    end

    it 'enforces the file count limit' do
      stub_const("#{described_class}::MAX_FILES_IN_ZIP", 1)
      zip = zip_with('a.sql' => 'SELECT 1;', 'b.sql' => 'SELECT 2;')

      expect { described_class.extract_to_directory(zip, target_dir) }
        .to raise_error(described_class::ZipError, /Too many files/)
      expect(Dir.children(target_dir)).to be_empty
    end

    it 'enforces the uncompressed size limit' do
      stub_const("#{described_class}::MAX_UNCOMPRESSED_SIZE", 10)

      expect { described_class.extract_to_directory(zip_with('a.sql' => 'x' * 11), target_dir) }
        .to raise_error(described_class::ZipError, /too large/)
    end

    it 'stops inflating an entry that is larger than its declared size' do
      zip = zip_with('a.sql' => 'x' * 5_000)
      allow(described_class).to receive(:validate_zip!)
      stub_const("#{described_class}::MAX_UNCOMPRESSED_SIZE", 1_000)

      expect { described_class.extract_to_directory(zip, target_dir) }
        .to raise_error(described_class::ZipError, /too large/)
    end
  end

  describe '.create_from_directory' do
    it 'stores paths relative to the directory in sorted order' do
      FileUtils.mkdir_p(File.join(target_dir, '05_tables'))
      File.write(File.join(target_dir, '_header.sql'), 'h')
      File.write(File.join(target_dir, '05_tables', '000001.sql'), 't')

      names = []
      Zip::File.open_buffer(StringIO.new(described_class.create_from_directory(target_dir))) do |zip|
        names = zip.map(&:name)
      end

      expect(names).to eq(['05_tables/000001.sql', '_header.sql'])
    end
  end
end
