# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ and
# the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

module SupplejackApi
  module ApiRecord
    describe RecordFragment do

  		let!(:record) { FactoryGirl.build(:record, record_id: 1234) }
      let!(:fragment) { record.fragments.build(priority: 0) }
      let(:fragment_class) { RecordFragment }

      before { record.save }

      describe 'schema_class' do
      	it 'should return RecordSchema' do
      		expect(RecordFragment.schema_class).to eq RecordSchema
      	end
      end

      describe 'build_mongoid_schema' do
        before do
          allow(RecordSchema).to receive(:fields) do
            {
              title: double(:field, name: :title, type: :string).as_null_object,
              count: double(:field, name: :count, type: :integer).as_null_object,
              date: double(:field, name: :date, type: :datetime).as_null_object,
              is_active: double(:field, name: :is_active, type: :boolean).as_null_object,
              subject: double(:field, name: :subject, type: :string, multi_value: true).as_null_object,
              sort_date: double(:field, name: :sort_date, type: :string, store: false).as_null_object,
            }
          end
          allow(fragment_class).to receive(:field)

          allow(RecordSchema).to receive(:mongo_indexes) do
            {
              count_date: double(:mongo_index, name: :count_date, fields: [{ count: 1, date: 1 }], index_options: {background: true}).as_null_object
            }
          end
          allow(fragment_class).to receive(:mongo_indexes)
        end

        after do
          fragment_class.build_mongoid_schema
        end

        context 'creating fields' do
          it 'defines a string field' do
            expect(fragment_class).to receive(:field).with(:title, type: String)
          end

          it 'defines a integer field' do
            expect(fragment_class).to receive(:field).with(:count, type: Integer)
          end

          it 'defines a datetime field' do
            expect(fragment_class).to receive(:field).with(:date, type: DateTime)
          end

          it 'defines a boolean field' do
            expect(fragment_class).to receive(:field).with(:is_active, type: Boolean)
          end

          it 'defines a multivalue field' do
            expect(fragment_class).to receive(:field).with(:subject, type: Array)
          end

          it 'does not define a field with stored false' do
            expect(fragment_class).to_not receive(:field).with(:sort_date, anything)
          end
        end

        context 'creating indexes' do
          it 'should create a single field index' do
            expect(fragment_class).to receive(:index).with({:count=>1, :date=>1}, {:background=>true})
          end
        end
      end

      describe '.mutable_fields' do
        {name: String, email: Array, nz_citizen: Boolean}.each do |name, type|
          it 'should return a hash that includes the key #{name} and value #{type}' do
            type = Mongoid::Boolean if type == Boolean
            expect(fragment_class.mutable_fields[name.to_s]).to eq type
          end
        end

        it 'should not include the source_id' do
          expect(fragment_class.mutable_fields).to_not have_key('source_id')
        end

        it 'should memoize the mutable_fields' do
          fragment_class.class_variable_set('@@mutable_fields', nil)
          allow(fragment_class).to receive(:fields).once.and_return({})
          fragment_class.mutable_fields
          fragment_class.mutable_fields
          fragment_class.class_variable_set('@@mutable_fields', nil)
        end
      end

      context 'default scope' do
        it 'should order the fragments from lower to higher priority' do
          fragment3 = record.fragments.create(priority: 3)
          fragment1 = record.fragments.create(priority: 1)
          fragment_1 = record.fragments.create(priority: -1)
          record.reload
          expect(record.fragments.map(&:priority)).to eq [-1, 0, 1, 3]
        end
      end

      describe '#primary?' do
        it 'returns true when priority is 0' do
          fragment.priority = 0
          expect(fragment.primary?).to be_truthy
        end

        it 'returns false when priority is 1' do
          fragment.priority = 1
          expect(fragment.primary?).to be_falsey
        end
      end

      describe '#clear_attributes' do
        let(:record) { FactoryGirl.create(:record) }
        let(:fragment) { record.fragments.create(nz_citizen: true) }

        it 'clears the existing nz_citizen' do
          fragment.clear_attributes
          expect(fragment.nz_citizen).to be_nil
        end
      end

      describe '#update_from_harvest' do
        it 'updates the name with the value' do
          fragment.update_from_harvest({name: 'John Smith'})
          expect(fragment.name).to eq 'John Smith'
        end

        it 'handles nil values' do
          fragment.update_from_harvest(nil)
        end

        it 'ignores invalid fields' do
          fragment.update_from_harvest({invalid_field: 'http://yahoo.com'})
          expect(fragment['invalid_field']).to be_nil
        end

        it 'stores uniq values for each field' do
          fragment.update_from_harvest({children: ['Jim', 'Bob', 'Jim']})
          expect(fragment.children).to eq ['Jim', 'Bob']
        end

        it 'updates the updated_at even if the attributes didn\'t change' do
          new_time = Time.now + 1.day
          Timecop.freeze(new_time) do
            fragment.update_from_harvest({})
            expect(fragment.updated_at.to_i).to eq(new_time.to_i)
          end
        end

        it 'uses the attribute setters for strings' do
          allow(fragment).to receive('name=').with('John Smith')
          fragment.update_from_harvest({:name => 'John Smith'})
        end

        it 'uses the attribute setters for Arrays' do
          allow(fragment).to receive('children=').with(['Jim', 'Bob'])
          fragment.update_from_harvest({:children => ['Jim', 'Bob']})
        end

        it 'stores the first element in the array for non array fields' do
          fragment.update_from_harvest({name: ['John Smith', 'Jim Bob']})
          expect(fragment.name).to eq 'John Smith'
        end

        it 'should set the source_id' do
          fragment.update_from_harvest({source_id: ['census']})
          expect(fragment.source_id).to eq 'census'
        end
      end

    end
  end
end
