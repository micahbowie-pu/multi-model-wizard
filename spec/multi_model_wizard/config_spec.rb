# frozen_string_literal: true

require 'spec_helper'
require 'multi_model_wizard/config'

RSpec.describe MultiModelWizard::Config do
  describe '#initialize' do
    it 'inits with cookies as the default store' do
      expect(described_class.new.store[:location]).to eq(:cookies)
    end

    it 'inits with multi_model_wizard_form as the default form key' do
      expect(described_class.new.form_key).to eq('multi_model_wizard_form')
    end
  end
end
