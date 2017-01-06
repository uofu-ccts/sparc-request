# Copyright © 2011-2016 MUSC Foundation for Research Development~
# All rights reserved.~

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:~

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.~

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following~
# disclaimer in the documentation and/or other materials provided with the distribution.~

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products~
# derived from this software without specific prior written permission.~

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,~
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT~
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL~
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS~
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR~
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.~

require 'rails_helper'

RSpec.describe Arm, type: :model do
  describe '#update_visit_group_window_after' do
    let!(:protocol) { create(:protocol_without_validations) }
    let(:arm)       { create(:arm, protocol: protocol, visit_count: 1, line_item_count:1) }

    shared_examples 'window_after invalid' do
      it 'should add a message to errors[:invalid_window_after]' do
        expect(arm.errors[:invalid_window_after]).not_to be_empty
      end

      it 'should not set specfied VisitGroup\'s window_after' do
        expect(arm.reload.visit_groups[0].window_after).to eq(0)
      end
    end

    shared_examples 'window_after valid' do
      it 'should not add messages to errors[:invalid_window_after]' do
        expect(arm.errors[:invalid_window_after]).to be_empty
      end
    end

    context 'window_after not a valid integer' do
      before(:each) { arm.update_visit_group_window_after 'sparc', 0 }

      it_behaves_like 'window_after invalid'
    end

    context 'window_after negative' do
      before(:each) { arm.update_visit_group_window_after '-1', 0 }

      it_behaves_like 'window_after invalid'
    end

    context 'window_after == 0' do
      before(:each) { arm.update_visit_group_window_after '0', 0 }

      it 'should set VisitGroup\'s window_after to 0' do
        expect(arm.reload.visit_groups[0].window_after).to eq 0
      end

      it_behaves_like 'window_after valid'
    end

    context 'window_after > 0' do
      before(:each) { arm.update_visit_group_window_after '1', 0 }

      it 'should set VisitGroup\'s window_after' do
        expect(arm.reload.visit_groups[0].window_after).to eq 1
      end

      it_behaves_like 'window_after valid'
    end
  end
end
