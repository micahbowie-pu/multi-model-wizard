# frozen_string_literal: true

require 'spec_helper'
require 'multi_model_wizard/dynamic_validation'

RSpec.describe MultiModelWizard::Wizard do
  let(:dummy_class) { Class.new { include MultiModelWizard::Wizard } }
  let(:test_class) { dummy_class.new }

  describe '#session_params' do
    context 'when redis is configured' do
      it 'uses redis session params' do 
        allow(test_class).to receive(:store_in_redis?).and_return(true)

        expect(test_class).to receive(:redis_session_params)

        test_class.session_params
      end
    end

    context 'when redis is NOT configured' do
      it 'uses cookie session params' do 
        allow(test_class).to receive(:store_in_redis?).and_return(false)

        expect(test_class).to receive(:cookie_session_params)

        test_class.session_params
      end
    end
  end

  describe '#clear_session_params' do
    context 'when redis is configured' do
      it 'clears redis session params' do 
        allow(test_class).to receive(:store_in_redis?).and_return(true)

        expect(test_class).to receive(:clear_redis_session_params)

        test_class.clear_session_params
      end
    end

    context 'when redis is NOT configured' do
      it 'clears cookie session params' do 
        allow(test_class).to receive(:store_in_redis?).and_return(false)

        expect(test_class).to receive(:clear_cookie_session_params)

        test_class.clear_session_params
      end
    end
  end

  describe '#set_session_params' do
    context 'when redis is configured' do
      it 'sets redis session params' do 
        allow(test_class).to receive(:store_in_redis?).and_return(true)

        expect(test_class).to receive(:set_redis_session_params)

        test_class.set_session_params({ multi_model_wizard: 'is the best' })
      end
    end

    context 'when redis is NOT configured' do
      it 'sets cookie session params' do 
        allow(test_class).to receive(:store_in_redis?).and_return(false)

        expect(test_class).to receive(:set_cookie_session_params)

        test_class.set_session_params({ multi_model_wizard: 'is the best' })
      end
    end
  end

  describe '#wizard_form_uuid' do
    context 'when there is an existing signed cookie' do
      it 'returns the signed_cookie' do
        uuid = SecureRandom.uuid
        allow(test_class).to receive(:get_signed_cookie).and_return(uuid)

        expect(test_class.wizard_form_uuid).to eq(uuid)
      end
    end

    context 'when there is NOT an existing signed cookie' do
      it 'returns the a new uuid' do
        allow(test_class).to receive(:get_signed_cookie).and_return(nil)
        allow(test_class).to receive(:set_signed_cookie).and_return({ signed: 'by cookies' })

        expect(test_class.wizard_form_uuid).to be_a(String)
      end

      it 'sets the new uuid' do
        allow(test_class).to receive(:get_signed_cookie).and_return(nil)

        expect(test_class).to receive(:set_signed_cookie)

        test_class.wizard_form_uuid
      end
    end
  end

  describe '#multi_model_wizard_form_key' do
    it 'returns the configured form key value' do
      expect(test_class.multi_model_wizard_form_key).to eq(::MultiModelWizard.configuration.form_key)
    end
  end
end
