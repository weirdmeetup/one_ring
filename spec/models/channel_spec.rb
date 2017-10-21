require 'rails_helper'

describe Channel, type: :model do
  describe '#default_channel?' do
    let(:channel) { Channel.new(name: name) }

    context 'with normal name' do
      let(:name) { 'channel' }

      it 'returns false' do
        expect(channel).not_to be_default_channel
      end
    end

    context 'with name started underscore' do
      let(:name) { '_channel' }

      it 'returns true' do
        expect(channel).to be_default_channel
      end
    end
  end
end
