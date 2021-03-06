require 'spec_helper'

describe ActiveFedora::Model do
  
  before(:each) do 
    module ModelIntegrationSpec
      class Basic < ActiveFedora::Base
        has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
          m.field "foo", :string
          m.field "bar", :string
          m.field "baz", :string
        end

        delegate_to :properties, [:foo, :bar, :baz], multiple: true

        def to_solr(doc = {})
          doc = super
          doc[ActiveFedora::SolrService.solr_name('foo', :sortable)] = doc[ActiveFedora::SolrService.solr_name('foo', type: :string)]
          doc
        end
      
      end
    end

  end
  
  after(:each) do
    Object.send(:remove_const, :ModelIntegrationSpec)
  end


  describe "When there is one object in the store" do
    before do
      @test_instance = ModelIntegrationSpec::Basic.new
      @test_instance.save
    end

    after do
      @test_instance.delete
    end

    
    describe ".all" do
      it "should return an array of instances of the calling Class" do
        result = ModelIntegrationSpec::Basic.all
        result.should be_instance_of(Array)
        # this test is meaningless if the array length is zero
        result.length.should > 0
        result.each do |obj|
          obj.class.should == ModelIntegrationSpec::Basic
        end
      end
    end

    describe ".first" do
      it "should return one instance of the calling class" do
        ModelIntegrationSpec::Basic.first.should == @test_instance
      end
    end
  end

  describe "with multiple objects" do
    before do
      @test_instance1 = ModelIntegrationSpec::Basic.create!(:foo=>'Beta', :bar=>'Chips')
      @test_instance2 = ModelIntegrationSpec::Basic.create!(:foo=>'Alpha', :bar=>'Peanuts')
      @test_instance3 = ModelIntegrationSpec::Basic.create!(:foo=>'Sigma', :bar=>'Peanuts')
    end
    after do
      @test_instance1.delete
      @test_instance2.delete
      @test_instance3.delete
    end
    it "should query" do
      ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('foo', type: :string)=> 'Beta').should == [@test_instance1]
      ModelIntegrationSpec::Basic.where('foo' => 'Beta').should == [@test_instance1]
    end
    it "should order" do
      ModelIntegrationSpec::Basic.order(ActiveFedora::SolrService.solr_name('foo', :sortable) + ' asc').should == [@test_instance2, @test_instance1, @test_instance3]
    end
    it "should limit" do
      ModelIntegrationSpec::Basic.limit(1).should == [@test_instance1]
    end

    it "should chain queries" do
      ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('bar', type: :string) => 'Peanuts').order(ActiveFedora::SolrService.solr_name('foo', :sortable) + ' asc').limit(1).should == [@test_instance2]
    end

    it "should chain count" do
      ModelIntegrationSpec::Basic.where(ActiveFedora::SolrService.solr_name('bar', type: :string) => 'Peanuts').count.should == 2 
    end
  end
end

