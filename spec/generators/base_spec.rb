# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::Base do
  subject(:generator) { described_class.new(BetterStructureSql::Configuration.new) }

  def quote(identifier)
    generator.send(:quote_identifier, identifier)
  end

  describe 'identifier quoting by the connected adapter' do
    it 'uses backticks, doubling embedded ones, on MySQL' do
      allow(ActiveRecord::Base).to receive(:connection).and_return(double('connection', adapter_name: 'Mysql2'))

      expect(quote('a`b')).to eq('`a``b`')
    end

    it 'uses double quotes, doubling embedded ones, without an established connection' do
      allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)

      expect(quote('a"b')).to eq('"a""b"')
    end

    it 'raises any other connection failure instead of guessing the quoting' do
      allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::StatementInvalid)

      expect { quote('users') }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
