require 'spec_helper'

describe "DataMapper::Resource" do

  before(:all) do
    class ::GreenSmoothie
      include DataMapper::Resource
      property :id, Serial
      property :name, String
    end

    class ::Milkshake
      include DataMapper::Resource
      property :id,               Serial
      property :name,             String,  :field => 'ml_name'
      property :contains_lactose, Boolean, :field => 'bl_lactose'
    end
  end

  after do
    GreenSmoothie.destroy!
  end

  supported_by :all do

    it "should find/create using find_or_create" do
      DataMapper.repository(:default) do
        green_smoothie = GreenSmoothie.new(:name => 'Banana')
        green_smoothie.save
        GreenSmoothie.find_or_create({:name => 'Banana'}).id.should eql(green_smoothie.id)
        GreenSmoothie.find_or_create({:name => 'Strawberry'}).id.should eql(2)
      end
    end

    it "should use find_by and use the name attribute to find a record" do
      DataMapper.repository(:default) do
        green_smoothie = GreenSmoothie.create({:name => 'Banana'})
        green_smoothie.should == GreenSmoothie.find_by_name('Banana')
      end
    end

    it "should use find_all_by to find records using an attribute" do
      DataMapper.repository(:default) do
        green_smoothie = GreenSmoothie.create({:name => 'Banana'})
        green_smoothie2 = GreenSmoothie.create({:name => 'Banana'})
        found_records = GreenSmoothie.find_all_by_name('Banana')
        found_records.length.should == 2
        found_records.each do |found_record|
          [green_smoothie, green_smoothie2].include?(found_record).should be(true)
        end
      end
    end

    ###

    describe '#find' do
      describe 'when given a symbol' do
        before :each do
          @green_smoothie = GreenSmoothie.create(:name => 'Banana')
          @green_smoothie2 = GreenSmoothie.create(:name => 'Banana')
        end

        it 'should return all records when asked for :all' do
          found_records = GreenSmoothie.find(:all)
          found_records.length.should == 2
          found_records.each do |found_record|
            [@green_smoothie, @green_smoothie2].include?(found_record).should be(true)
          end
        end

        it 'should return the first record when asked for :first' do
          GreenSmoothie.find(:first).should == @green_smoothie
        end

        it 'should return the last record when asked for :last' do
          GreenSmoothie.find(:last).should == @green_smoothie2
        end
      end

      describe 'with a valid key' do
        before :all do
          @resource = GreenSmoothie.create(:name => 'Banana')
        end

        subject { GreenSmoothie.find(@resource.id) }

        it { should == @resource }
      end

      describe 'with an unknown key' do
        subject { GreenSmoothie.find(0) }

        it { should be_nil }
      end

      describe 'with no arguments' do
        subject { GreenSmoothie.find }

        it 'should raise an exception' do
          method(:subject).should raise_error(ArgumentError)
        end
      end
    end

  end

  supported_by :sqlite, :mysql, :postgres do

    describe '#find_by_sql' do
      before(:each) do
        DataMapper.repository(:default) do
          @resource = GreenSmoothie.create({:name => 'Banana'})
        end
      end

      it 'should find the resource when given a string' do
        DataMapper.repository(:default) do
          found = GreenSmoothie.find_by_sql <<-SQL
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          found.should_not be_empty
          found.first.should == @resource
        end
      end

      it 'should find the resource when given an array containing SQL and bind values' do
        DataMapper.repository(:default) do
          found = GreenSmoothie.find_by_sql [<<-SQL, @resource.id]
            SELECT id, name FROM green_smoothies WHERE id = ?
          SQL

          found.should_not be_empty
          found.first.should == @resource
        end
      end

      it 'should return an empty collection when nothing is found' do
        DataMapper.repository(:default) do
          found = GreenSmoothie.find_by_sql [<<-SQL, 0]
            SELECT id, name FROM green_smoothies WHERE id = ?
          SQL

          found.should be_kind_of(DataMapper::Collection)
          found.should be_empty
        end
      end

      it 'should raise an error if no SQL string or Query is given' do
        DataMapper.repository(:default) do
          lambda { GreenSmoothie.find_by_sql nil }.should raise_error(ArgumentError, /requires a query/)
        end
      end

      it 'should raise an error if an unacceptable argument is given' do
        DataMapper.repository(:default) do
          lambda { GreenSmoothie.find_by_sql :go }.should raise_error(ArgumentError)
        end
      end

      it 'should accept a Query instance' do
        query = GreenSmoothie.find_by_sql([<<-SQL, @resource.id]).query
          SELECT id, name FROM green_smoothies WHERE id = ?
        SQL

        found = GreenSmoothie.find_by_sql(query)
        found.should_not be_empty
        found.first.should == @resource
      end

      it 'should respect the property field option and map appropriately when custom field names are specified' do
        milkshake = Milkshake.new(:name => 'strawberry', :contains_lactose => true)
        milkshake.save

        found_by_first = Milkshake.first
        found_by_sql   = Milkshake.find_by_sql(<<-SQL
          SELECT * FROM milkshakes LIMIT 1
        SQL
        )

        found_by_first.should == found_by_sql.first
      end

      # Options.

      describe ':repository option' do

        with_alternate_adapter do
          it 'should use repository identified by the given symbol' do
            alternate_repository = DataMapper::Spec.spec_adapters[:alternate].name
            found = GreenSmoothie.find_by_sql <<-SQL, :repository => alternate_repository
              SELECT id, name FROM green_smoothies LIMIT 1
            SQL

            found.repository.should == DataMapper.repository(alternate_repository)
          end
        end

        it 'should use the default repository if no repository option is specified' do
          found = GreenSmoothie.find_by_sql <<-SQL
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          found.repository.should == DataMapper.repository(:default)
        end
      end

      describe ':reload option' do
        it 'should reload existing resources in the identity map if given true' do
          found = GreenSmoothie.find_by_sql <<-SQL, :reload => true
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          found.query.reload?.should be(true)
        end

        it 'should not reload existing resources in the identity map if given false' do
          found = GreenSmoothie.find_by_sql <<-SQL, :reload => false
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          found.query.reload?.should be(false)
        end

        it 'should default to false' do
          found = GreenSmoothie.find_by_sql <<-SQL
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          found.query.reload?.should be(false)
        end
      end

      describe ':properties option' do
        it 'should accept an array of symbols' do
          properties = GreenSmoothie.properties

          found = GreenSmoothie.find_by_sql <<-SQL, :properties => properties.map { |property| property.name }
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          resource = found.first
          properties.each { |property| property.should be_loaded(resource) }
        end

        it 'should accept a single Symbol' do
          property = GreenSmoothie.properties[:id]

          found = GreenSmoothie.find_by_sql <<-SQL, :properties => property.name
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          resource = found.first

          property.should be_loaded(resource)
          GreenSmoothie.properties[:name].should_not be_loaded(resource)
        end

        it 'should accept a PropertySet' do
          properties = GreenSmoothie.properties

          found = GreenSmoothie.find_by_sql <<-SQL, :properties => properties
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          resource = found.first
          properties.each { |property| property.should be_loaded(resource) }
        end

        it 'should accept a single property' do
          property = GreenSmoothie.properties[:id]

          found = GreenSmoothie.find_by_sql <<-SQL, :properties => property
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          resource = found.first

          property.should be_loaded(resource)
          GreenSmoothie.properties[:name].should_not be_loaded(resource)
        end

        it 'should accept an array of Properties' do
          properties = GreenSmoothie.properties.to_a

          found = GreenSmoothie.find_by_sql <<-SQL, :properties => properties
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          resource = found.first
          properties.each { |property| property.should be_loaded(resource) }
        end

        it 'should use the given properties in preference over those in the SQL query' do
          properties = GreenSmoothie.properties

          found = GreenSmoothie.find_by_sql <<-SQL, :properties => properties
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          resource = found.first
          properties.each { |property| property.should be_loaded(resource) }
        end

        it 'should use the default properties if none are specified' do
          found = GreenSmoothie.find_by_sql <<-SQL
            SELECT id, name FROM green_smoothies LIMIT 1
          SQL

          resource = found.first
          GreenSmoothie.properties.each { |property| property.should be_loaded(resource) }
        end
      end
    end # find_by_sql

  end

end
