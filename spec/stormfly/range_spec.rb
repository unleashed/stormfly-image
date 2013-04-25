require 'spec_helper'

module StormFly::Image
  describe Block::Range do
    describe '.new' do
      context '(range_begin, range_end)' do
        shared_examples_for 'a well-constructed Range' do
          it 'does not raise error' do
            r = nil
            expect { r = Block::Range.new(@new_begin, @new_end) }.to_not raise_error
          end

          it 'creates an instance of Range' do
            Block::Range.new(@new_begin, @new_end).should be_an_instance_of(Block::Range)
          end
        end

        context 'when passed an ending greater than the beginning' do
          before :each do
            @new_begin = 100
            @new_end = 101
          end

          it_behaves_like 'a well-constructed Range'
        end

        context 'when passed an ending equal to the beginning' do
          before :each do
            @new_begin = 100
            @new_end = @new_begin
          end

          it_behaves_like 'a well-constructed Range'
        end

        context 'when passed an ending lesser than the beginning' do
          it 'refuses to create a new instance with a beginning greater than the ending' do
            expect { Block::Range.new(101, 100) }.to raise_error
          end
        end
      end

      context '(Range)' do
        it 'builds a Block::Range out of a Range object' do
          pending "Tests need to be written"
        end
      end
    end

    context 'when creating a new instance'
      before :each do
        @begin = 100
        @end = 500
        @within = 250
        @r = Block::Range.new(@begin, @end)
      end

      it 'responds to begin' do
        @r.should respond_to(:begin)
      end

      it 'responds to end' do
        @r.should respond_to(:end)
      end

      it '#begin returns the beginning specified for .new' do
        @r.begin.should == @begin
      end

      it '#end returns the ending specified for .new' do
        @r.end.should == @end
      end

      it 'has its beginning lesser or equal than the ending' do
        @r.begin.should <= @r.end
      end

      it 'has its ending greater or equal than the beginning' do
        @r.end.should >= @r.begin
      end

      it 'covers the beginning' do
        @r.should cover(@r.begin)
      end

      it 'does not cover the ending' do
        @r.should_not cover(@r.end)
      end

      it 'does not cover before the beginning' do
        @r.should_not cover(@r.begin.pred)
      end

      it 'does not cover after the ending' do
        @r.should_not cover(@r.end.succ)
      end

      it 'covers a value within the beginning and the ending' do
        if @r.begin.succ >= @r.end
          r = Block::Range.new(@r.begin, @r.end.succ)
        else
          r = @r
        end
        r.should cover(@r.begin.succ)
      end
    end

    describe 'merge' do
      before :each do
        @r = Block::Range.new 100, 250
      end

      it 'responds to merge' do
        @r.should respond_to(:merge)
      end

      shared_examples_for 'mergeable ranges' do
        it 'merges correctly' do
          expect { @r.merge(@s) }.to_not raise_error
        end

        context 'when merged' do
          before :each do
            @rr = @r.merge @s
          end

          it 'merges the beginning correctly' do
            @rr.begin.should <= @s.begin
          end

          it 'merges the ending correctly' do
            @rr.end.should >= @s.end
          end
        end
      end

      shared_examples_for 'unmergeable ranges' do
        it 'raises an error when merging' do
          expect { @r.merge(@s) }.to raise_error
        end
      end

      context 'when merging an included range' do
        before :each do
          @s = Block::Range.new(@r.begin, @r.end)
        end

        it_behaves_like 'mergeable ranges'
      end

      context 'when merging an excluded range' do
        before :each do
          @s = Block::Range.new(@r.end.succ, @r.end.succ.succ)
        end

        it_behaves_like 'unmergeable ranges'
      end

      context 'when merging a range with a lower beginning and included end' do
        before :each do
          @s = Block::Range.new(@r.begin.pred, @r.end)
        end

        it_behaves_like 'mergeable ranges'

        it 'begins with the lower beginning' do
          @rr = @r.merge @s
          @rr.begin.should == @s.begin
        end

        it 'ends with the original ending' do
          @rr = @r.merge @s
          @rr.end.should == @r.end
        end
      end

      context 'when merging a range with a greater ending and included beginning' do
        before :each do
          @s = Block::Range.new(@r.begin, @r.end.succ)
        end

        it_behaves_like 'mergeable ranges'

        it 'begins with the original beginning' do
          @rr = @r.merge @s
          @rr.begin.should == @r.begin
        end

        it 'ends with the greater ending' do
          @rr = @r.merge @s
          @rr.end.should == @s.end
        end
      end

      context 'when merging a range with a lower beginning and greater ending' do
        before :each do
          @s = Block::Range.new(@r.begin.pred, @r.end.succ)
        end

        it_behaves_like 'mergeable ranges'

        it 'begins with the lower beginning' do
          @rr = @r.merge @s
          @rr.begin.should == @s.begin
        end

        it 'ends with the greater ending' do
          @rr = @r.merge @s
          @rr.end.should == @s.end
        end
      end
    end
end
