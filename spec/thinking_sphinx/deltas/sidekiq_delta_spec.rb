require 'spec_helper'

describe ThinkingSphinx::Deltas::SidekiqDelta do
  before :each do
    ThinkingSphinx.updates_enabled = true
    ThinkingSphinx.deltas_enabled  = true

    Sidekiq.redis = MockRedis.new
  end

  describe '#index' do
    def flag_as_deleted_document_in_set?
      Sidekiq.redis{|r| r.sismember(ThinkingSphinx::Deltas::SidekiqDelta::FlagAsDeletedSet.set_name('foo_core'), 42) }
    end

    subject do
      ThinkingSphinx::Deltas::SidekiqDelta.new(
        stub('instance'), {}
      ).tap do |s| 
        s.stub(:toggled).and_return(true)
        s.stub(:lock)
        s.stub(:unlock)
        s.stub(:locked?).and_return(false)
      end
    end

    let(:model) do
      stub('foo').tap do |m|
        m.stub(:name => 'foo')
        m.stub(:source_of_sphinx_index => m)
        m.stub(:core_index_names  => ['foo_core'])
        m.stub(:delta_index_names => ['foo_delta'])
      end
    end

    let(:instance) do
      stub('instance').tap do |i|
        i.stub(:sphinx_document_id => 42)
      end
    end

    before :each do
      Resque.stub(:enqueue => true)
    end

    context 'updates disabled' do
      before :each do
        ThinkingSphinx.updates_enabled = false
      end

      it "should not enqueue a delta job" do
        ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob.should_not_receive(:perform_async)
        subject.index(model)
      end

      it "should not add a flag as deleted document to the set" do
        subject.index(model, instance)
        flag_as_deleted_document_in_set?.should be_false
      end
    end

    context 'deltas disabled' do
      before :each do
        ThinkingSphinx.deltas_enabled = false
      end

      it "should not enqueue a delta job" do
        ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob.should_not_receive(:perform_async)
        subject.index(model)
      end

      it "should not add a flag as deleted document to the set" do
        subject.index(model, instance)
        flag_as_deleted_document_in_set?.should be_false
      end
    end

    context "instance isn't toggled" do
      before :each do
        subject.stub(:toggled => false)
      end

      it "should not enqueue a delta job" do
        ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob.should_not_receive(:perform_async)
        subject.index(model, instance)
      end

      it "should not add a flag as deleted document to the set" do
        subject.index(model, instance)
        flag_as_deleted_document_in_set?.should be_false
      end
    end

    it "should enqueue a delta job" do
      ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob.should_receive(:peform_async).once.with(
        'foo_delta'
      )
      subject.index(model)
    end

    it "should add the flag as deleted document id to the set" do
      subject.index(model, instance)
      flag_as_deleted_document_in_set?.should be_true
    end

    context "delta index is locked" do
      before :each do
        ThinkingSphinx::Deltas::SidekiqDelta.stub(:locked?).and_return(true)
      end

      it "should not enqueue a delta job" do
        ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob.should_not_receive(:perform_async)
        subject.index(model, instance)
      end

      it "should add the flag as deleted document id to the set" do
        subject.index(model, instance)
        flag_as_deleted_document_in_set?.should be_true
      end
    end
  end

  describe '.clear_thinking_sphinx_queues' do
    subject { ThinkingSphinx::Deltas::SidekiqDelta.clear_thinking_sphinx_queues }

    before :all do
      class RandomJob
        @queue = 'ts_delta'
      end
    end

    before :each do
      ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob.perform_async('foo_delta')
      ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob.perform_async('bar_delta')

      Sidekiq::Client.enqueue(RandomJob, '1234')
    end

    it 'should remove all jobs' do
      subject
      Resque.size('ts_delta').should eq(0)
    end
  end

  describe '.lock' do
    it 'should set the lock key in redis' do
      ThinkingSphinx::Deltas::SidekiqDelta.lock('foo')
      Resque.redis.get("#{ThinkingSphinx::Deltas::SidekiqDelta.job_prefix}:index:foo:locked").should eql('true')
    end
  end

  describe '.unlock' do
    it 'should unset the lock key in redis' do
      Resque.redis.set("#{ThinkingSphinx::Deltas::SidekiqDelta.job_prefix}:index:foo:locked", 'true')
      ThinkingSphinx::Deltas::SidekiqDelta.unlock('foo')
      Resque.redis.get("#{ThinkingSphinx::Deltas::SidekiqDelta.job_prefix}:index:foo:locked").should be_nil
    end
  end

  describe '.locked?' do
    subject { ThinkingSphinx::Deltas::SidekiqDelta.locked?('foo') }

    context "when lock key in redis is true" do
      before { Resque.redis.set("#{ThinkingSphinx::Deltas::SidekiqDelta.job_prefix}:index:foo:locked", 'true') }
      it { should be_true }
    end

    context "when lock key in redis is nil" do
      it { should be_false }
    end
  end

  describe '.prepare_for_core_index' do
    subject { ThinkingSphinx::Deltas::SidekiqDelta.prepare_for_core_index('foo') }

    before :each do
      Resque.stub(:dequeue)
      ThinkingSphinx::Deltas::SidekiqDelta::FlagAsDeletedSet.stub(:clear!)
    end

    it "should call FlagAsDeletedSet.clear!" do
      ThinkingSphinx::Deltas::SidekiqDelta::FlagAsDeletedSet.should_receive(:clear!).with('foo_core')
      subject
    end

    it "should clear delta jobs" do
      Resque.should_receive(:dequeue).with(ThinkingSphinx::Deltas::SidekiqDelta::DeltaJob, 'foo_delta')
      subject
    end
  end
end
